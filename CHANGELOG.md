# Changelog — Worklist

Format: version — date — summary.

## 1.4.1+8 — 2026-07-13 (FINAL RELEASE)
- Final production-readiness audit (auth, SQLite, Firebase, notifications,
  UI, performance, security, docs).
- Removed all `[STEP]` debug `debugPrint` traces from
  `firebase_cloud_service.dart` and `auth_provider.dart`.
- Removed temporary RTDB "MINIMAL TEST" `print()` scaffolding from
  `auth_provider.dart` (it wrote junk to `diagnostics/test` and
  spamed stdout on every auth-state change).
- Hardened Firebase sync verification: 0 FK violations at spec stress
  volume; confirmed indexes, latest-wins conflict resolution,
  queued upload/download, offline retry (exponential backoff), and
  Android↔Windows convergence per Google account.
- Notification engine: batch dedupe (one history load per `refresh()`)
  and metrics persistence pruned to a 14-day rolling window with
  debounced writes (no unbounded growth).
- Added project documentation: README, RELEASE_NOTES, CHANGELOG,
  NOTIFICATIONS_ARCHITECTURE, SYSTEM_ARCHITECTURE.
- `flutter analyze` clean (0 errors/warnings); Android + Windows
  `--release` builds green; `dist/` refreshed.

## 1.4.0 — Notification framework (Phases 1–12, prior sprints)
- P1: notification engine, rules, scheduler, history repository.
- P2–P5: payment / payroll / inventory / sites / workers reminder rules.
- P6: Notification Center UI + route.
- P7: background scheduling (Android WorkManager + Windows timer).
- P8: notification settings UI + smart summaries.
- P9: interactive notifications (deep links, status actions, snooze).
- P10: analytics & diagnostics (metrics store + diagnostics screen).
- P11: local business-insight engine (no AI/cloud APIs).
- P12: cross-device notification-metadata sync (read/unread/dismissed/
  archived/snoozed + history + preferences) over Firebase RTDB.

## 1.0.0 — Initial
- SQLite local store, auth (username/password + Google Sign-In),
  site/worker/attendance/payment/inventory/payroll/service
  management, Firebase RTDB business sync.
