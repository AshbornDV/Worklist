#!/usr/bin/env python3
"""SkillSpector install gate for .codex/skills.

Two modes:

    python .codex/hooks/skill_gate.py scan <path>   # gate a staged skill
    python .codex/hooks/skill_gate.py hook          # Codex PreToolUse hook

`scan` exit codes: 0 = passed, 1 = blocked, 2 = scanner missing or unusable.

`hook` reads a Codex PreToolUse payload on stdin and denies any command that
writes into .codex/skills unless it goes through install_skill.py, which scans
the staged skill first. Hooks are a guardrail, not a full enforcement boundary:
hosted tools never reach a hook, and a determined caller can still work around
a deny.
"""

import json
import os
import re
import shutil
import subprocess
import sys

BLOCK_SEVERITIES = {"HIGH", "CRITICAL"}
SCAN_TIMEOUT_SECONDS = 300

HOOK_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(HOOK_DIR))
SKILLS_DIR = os.path.join(REPO_ROOT, ".codex", "skills")
INSTALLER = os.path.join(HOOK_DIR, "install_skill.py")

# Any way a shell command can move bytes into the skills directory.
WRITE_VERB = re.compile(
    r"(?:^|[\s;&|(])(?:cp|mv|rsync|install|unzip|tar|tee|ln|curl|wget|touch|sed|patch|git\s+clone|git\s+checkout|git\s+pull)\b",
    re.IGNORECASE,
)
REDIRECT = re.compile(r">\s*[^&\s|]*\.codex[\\/]+skills", re.IGNORECASE)
SKILLS_PATH = re.compile(r"\.codex[\\/]+skills", re.IGNORECASE)


def find_scanner():
    """Locate the skillspector executable, including uv's tool bin directory."""
    found = shutil.which("skillspector")
    if found:
        return found
    candidates = [
        os.path.join(os.path.expanduser("~"), ".local", "bin", "skillspector.exe"),
        os.path.join(os.path.expanduser("~"), ".local", "bin", "skillspector"),
    ]
    for candidate in candidates:
        if os.path.isfile(candidate):
            return candidate
    return None


def _load_report(stdout):
    """Parse the scan report, tolerating log lines around the JSON body."""
    try:
        return json.loads(stdout)
    except ValueError:
        pass
    start, end = stdout.find("{"), stdout.rfind("}")
    if start == -1 or end <= start:
        raise ValueError("no JSON object in scanner output")
    return json.loads(stdout[start : end + 1])


def scan_skill(path):
    """Run SkillSpector and return its parsed report. Raises ScanError."""
    scanner = find_scanner()
    if not scanner:
        raise ScanError(
            "skillspector not found. Install it with:\n"
            "  uv tool install --python 3.12 git+https://github.com/NVIDIA/SkillSpector.git"
        )
    cmd = [scanner, "scan", str(path), "--no-llm", "--format", "json"]
    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, timeout=SCAN_TIMEOUT_SECONDS
        )
    except subprocess.TimeoutExpired:
        raise ScanError(f"scan timed out after {SCAN_TIMEOUT_SECONDS}s")
    except OSError as exc:
        raise ScanError(f"could not run skillspector: {exc}")
    try:
        return _load_report(proc.stdout)
    except ValueError as exc:
        detail = (proc.stderr or proc.stdout or "").strip().splitlines()
        tail = detail[-1] if detail else "no output"
        raise ScanError(f"unreadable scan report ({exc}); scanner said: {tail}")


class ScanError(Exception):
    """The scan could not produce a trustworthy verdict."""


def evaluate(report):
    """Return (blocked, reasons) for a parsed report. Fails closed."""
    reasons = []

    if not report.get("execution_successful", False):
        return True, ["scanner reported execution_successful=false (fail closed)"]

    completeness = report.get("analysis_completeness") or {}
    if completeness.get("is_complete") is False:
        coverage = completeness.get("coverage_percent", "unknown")
        reasons.append(f"scan coverage incomplete ({coverage}% inspected)")

    issues = report.get("issues") or []
    for issue in issues:
        severity = str(issue.get("severity", "")).upper()
        if severity not in BLOCK_SEVERITIES:
            continue
        location = issue.get("location") or {}
        where = location.get("file") or "?"
        line = location.get("start_line")
        where = f"{where}:{line}" if line else where
        label = f"{issue.get('id', '?')} {issue.get('category', '')}".strip()
        pattern = issue.get("pattern") or issue.get("finding") or ""
        reasons.append(f"{severity} {label} - {pattern} ({where})".replace("  ", " "))

    risk = report.get("risk_assessment") or {}
    for key in ("max_issue_severity", "severity"):
        severity = str(risk.get(key, "")).upper()
        if severity in BLOCK_SEVERITIES and not reasons:
            reasons.append(f"risk_assessment.{key}={severity}")

    return bool(reasons), reasons


def format_verdict(report, reasons):
    risk = report.get("risk_assessment") or {}
    issues = report.get("issues") or []
    lines = [
        f"skill: {report.get('skill', {}).get('name', '?')}",
        f"score: {risk.get('score', '?')}  severity: {risk.get('severity', '?')}"
        f"  recommendation: {risk.get('recommendation', '?')}  issues: {len(issues)}",
    ]
    lines += [f"  - {reason}" for reason in reasons]
    return "\n".join(lines)


def gate(path):
    """Scan a path and return (blocked, message)."""
    if not os.path.exists(path):
        return True, f"target does not exist: {path}"
    try:
        report = scan_skill(path)
    except ScanError as exc:
        return True, f"gate could not verify this skill: {exc}"
    blocked, reasons = evaluate(report)
    if blocked:
        reasons = reasons or ["scan did not pass"]
        return True, format_verdict(report, reasons)
    return False, format_verdict(report, ["no HIGH or CRITICAL findings"])


def _strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from _strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from _strings(item)


def _deny(reason):
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            }
        )
    )
    return 0


def hook_main():
    """Deny unvetted writes into .codex/skills."""
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return 0  # malformed payload: stay out of the way

    tool_name = payload.get("tool_name") or ""
    tool_input = payload.get("tool_input") or {}

    if tool_name == "Bash":
        command = tool_input.get("command") or ""
        if "install_skill.py" in command or not SKILLS_PATH.search(command):
            return 0
        if REDIRECT.search(command) or WRITE_VERB.search(command):
            return _deny(
                "Writing into .codex/skills is gate-only. Install skills through the "
                "scanner instead:\n"
                f'  python "{INSTALLER}" <dir|zip|git-url> [--name NAME]\n'
                "It stages the skill, runs NVIDIA SkillSpector, and refuses HIGH or "
                "CRITICAL findings. Direct copies bypass that check."
            )
        return 0

    # apply_patch / Edit / Write: any mention of the skills path is a write.
    for text in _strings(tool_input):
        if SKILLS_PATH.search(text):
            return _deny(
                "Editing .codex/skills directly is gate-only. Use "
                f'python "{INSTALLER}" <dir|zip|git-url> so the skill is scanned first.'
            )
    return 0


def main(argv):
    if len(argv) >= 2 and argv[1] == "hook":
        return hook_main()
    if len(argv) >= 3 and argv[1] == "scan":
        blocked, message = gate(argv[2])
        stream = sys.stderr if blocked else sys.stdout
        print(("BLOCKED\n" if blocked else "PASSED\n") + message, file=stream)
        return 1 if blocked else 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
