#!/usr/bin/env python3
"""Install a skill into .codex/skills only if NVIDIA SkillSpector clears it.

    python .codex/hooks/install_skill.py <dir|zip|git-url> [--name NAME] [--force]

The skill is staged in a temporary directory, scanned there, and copied into
.codex/skills/<name> only when the scan reports no HIGH or CRITICAL findings.
Exit codes: 0 = installed, 1 = blocked or refused, 2 = bad usage.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from skill_gate import SKILLS_DIR, gate  # noqa: E402

GIT_PREFIXES = ("git@", "ssh://", "git://")
SAFE_NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


def is_remote(source):
    return source.startswith(("http://", "https://")) or source.startswith(GIT_PREFIXES)


def derive_name(source):
    if is_remote(source):
        tail = source.rstrip("/").split("/")[-1]
        return tail[:-4] if tail.endswith(".git") else tail
    base = os.path.basename(os.path.normpath(source))
    return base[:-4] if base.lower().endswith(".zip") else base


def frontmatter_name(staged):
    """Read `name:` from the staged SKILL.md frontmatter, if present."""
    skill_md = os.path.join(staged, "SKILL.md")
    if not os.path.isfile(skill_md):
        return None
    with open(skill_md, encoding="utf-8", errors="replace") as fh:
        lines = fh.read(4000).splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for line in lines[1:]:
        if line.strip() == "---":
            break
        key, sep, value = line.partition(":")
        if sep and key.strip() == "name":
            return value.strip().strip("\"'") or None
    return None


def stage(source, target):
    """Copy, clone or extract the candidate skill into `target`."""
    if is_remote(source):
        print(f"cloning {source}")
        result = subprocess.run(
            ["git", "clone", "--depth", "1", source, target],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise RuntimeError(f"git clone failed: {result.stderr.strip()[:400]}")
        shutil.rmtree(os.path.join(target, ".git"), ignore_errors=True)
        return

    if not os.path.exists(source):
        raise RuntimeError(f"source does not exist: {source}")

    if os.path.isdir(source):
        shutil.copytree(source, target)
        return

    if source.lower().endswith((".zip", ".tar", ".tar.gz", ".tgz")):
        unpack = os.path.join(target, "_unpacked")
        shutil.unpack_archive(source, unpack)
        entries = os.listdir(unpack)
        # A well-formed archive holds one top-level folder; use it if so.
        if len(entries) == 1 and os.path.isdir(os.path.join(unpack, entries[0])):
            shutil.move(os.path.join(unpack, entries[0]), target)
            shutil.rmtree(unpack, ignore_errors=True)
        else:
            shutil.move(unpack, target)
        return

    raise RuntimeError(
        f"unsupported source (expected a directory, zip/tar archive or git URL): {source}"
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", help="skill directory, archive, or git URL")
    parser.add_argument("--name", help="folder name under .codex/skills (default: SKILL.md name)")
    parser.add_argument("--force", action="store_true", help="replace an existing skill")
    args = parser.parse_args(argv)

    os.makedirs(SKILLS_DIR, exist_ok=True)
    staging = tempfile.mkdtemp(prefix="skill-stage-")
    try:
        staged = os.path.join(staging, "candidate")
        try:
            stage(args.source, staged)
        except Exception as exc:  # noqa: BLE001 - reported to the caller verbatim
            print(f"could not stage {args.source}: {exc}", file=sys.stderr)
            return 1

        name = args.name or frontmatter_name(staged) or derive_name(args.source)
        if not name or not SAFE_NAME.match(name):
            print(
                f"invalid skill name {name!r}; it must be a plain folder name. "
                "Pass --name to override.",
                file=sys.stderr,
            )
            return 2

        destination = os.path.join(SKILLS_DIR, name)
        if os.path.exists(destination) and not args.force:
            print(
                f"{name} is already installed at {destination}. "
                "Pass --force to replace it (it will be scanned again).",
                file=sys.stderr,
            )
            return 1

        print(f"scanning staged copy of {name} ...")
        blocked, message = gate(staged)
        stream = sys.stderr if blocked else sys.stdout
        print(("BLOCKED\n" if blocked else "PASSED\n") + message, file=stream)
        if blocked:
            print(f"\n{name} was NOT installed.", file=sys.stderr)
            return 1

        if os.path.exists(destination):
            shutil.rmtree(destination)
        shutil.copytree(staged, destination)
        print(f"installed {name} -> {destination}")
        return 0
    finally:
        shutil.rmtree(staging, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
