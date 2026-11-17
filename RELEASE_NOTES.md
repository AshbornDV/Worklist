# Release Notes — Worklist

**Version:** 1.4.1+8
**Build date:** 2026-07-13
**Flutter:** 3.41.9 (stable)
**Dart:** 3.7.x (bundled with Flutter 3.41.9)
**Platforms:** Windows (desktop), Android (phone + tablet)

## Release Highlights
- **Production-readiness audit (final release phase)** completed across
  auth, SQLite, Firebase, notifications, UI, performance, security,
  and documentation.
- **Removed leftover debug logging** — all `[STEP]` trace `debugPrint`
  calls in `firebase_cloud_service.dart` and `auth_provider.dart`, plus
  the temporary RTDB "MINIMAL TEST" `print()` scaffolding in
  `auth_provider.dart`, were deleted. No production debug output remains.
- **Hardened Firebase sync** — verified foreign-key integrity (0
  violations at spec stress volume), covering indexes, latest-wins
  conflict resolution, queued upload/download, offline retry with
  exponential backoff, and per-Google-account convergence
  (Android ↔ Windows).
- **Notification engine performance** — batch dedupe (single history
  load per `refresh()`) and metrics persistence that prunes to a
  14-day rolling window with debounced writes (no unbounded growth,
  no per-event disk thrash).
- **Project documentation** — `README.md`, `RELEASE_NOTES.md`,
  `CHANGELOG.md`, `NOTIFICATIONS_ARCHITECTURE.md`,
  `SYSTEM_ARCHITECTURE.md` added.

## What Was Verified
- `flutter analyze lib` — **0 errors, 0 warnings** (3 cosmetic info hints).
- `flutter test` — harness present, passes (no real unit suite yet).
- Android + Windows `--release` builds succeed.
- SQLite stress test at 500 sites / 10,000 workers / 50,000 attendance
  / 20,000 payments / 20,000 inventory / 5,000 services:
  **0 FK violations**, all hot queries sub-millisecond to single-digit ms.

## Known Limitations
- **Windows has no OS-level background task** — notifications are
  delivered while the app process is alive (in-process 15-min timer) or
  via the Startup-folder launch approximation. Closed-app delivery is
  not possible on Windows by OS design.
- **Android WorkManager enforces a 15-minute minimum** between
  periodic runs; reminders may lag up to 15 min.
- **No automated unit/integration test suite** beyond the Flutter
  default harness; verification is build/lint/stress-backed.
- Notification history (SharedPreferences) is unbounded over very long
  usage; daily metrics are pruned to 14 days but the raw history map
  is not capped.
