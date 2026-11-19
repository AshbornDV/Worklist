# Worklist — Site & Worker Management

A cross-platform (Windows + Android) field-operations app for construction/site
managers. Track sites, workers, attendance, payments, inventory, payroll, and
services, with a local-first SQLite store synced to Firebase per Google account.

## Platforms
- **Windows** (desktop, `flutter build windows --release`)
- **Android** (phone/tablet, `flutter build apk --release`)

Responsive UI adapts across phone (<600dp), tablet (600–1023dp) and
desktop (≥1024dp). Handheld form factors always use the compact
(phone) layout; Windows uses the full responsive shell.

## Quick start
```bash
flutter pub get
flutter run -d windows      # desktop
flutter run -d <android-device>  # Android
```

## Architecture (summary)
- **Data layer** — single user-scoped SQLite database (`sqflite` +
  `sqflite_common_ffi`) with foreign keys + covering indexes. Per-user
  row isolation via `user_id`.
- **Sync layer** — `FirebaseCloudService` mirrors business data and
  notification *metadata* to Firebase Realtime Database keyed by Google `uid`.
  Conflict resolution is latest-wins per record; offline edits are queued
  and retried with exponential backoff.
- **Notification framework** — self-contained pipeline:
  `NotificationRule`s → `NotificationRuleEvaluator` → dedupe via
  `NotificationHistoryRepository` → `NotificationScheduler`. Background
  delivery via Android WorkManager (15-min floor) and a Windows in-process
  timer. See `NOTIFICATIONS_ARCHITECTURE.md`.
- **State** — `provider` for app-wide providers (`AuthProvider`,
  `SiteProvider`, `WorkerProvider`, `StoreProductProvider`,
  `UserServiceProvider`, `SyncService`, theme).

See `SYSTEM_ARCHITECTURE.md` for the full component map.

## Release artifacts
Built releases live in `dist/`:
- `Worklist.apk` — Android release
- `windows.zip` / `worklist-windows/` — Windows release folder

## Documentation
- `README.md` — this file
- `RELEASE_NOTES.md` — per-version highlights + known limitations
- `CHANGELOG.md` — chronological change log
- `NOTIFICATIONS_ARCHITECTURE.md` — notification subsystem design
- `SYSTEM_ARCHITECTURE.md` — overall system design

## License
Proprietary — Parash Newar. All rights reserved.
