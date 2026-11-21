# Worklist — Site & Worker Management

<p align="center">
  <b>A robust, offline-first cross-platform field-operations management system built with Flutter and Firebase.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Android-blue" alt="Platforms">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-Realtime%20DB%20%7C%20Auth-FFCA28?logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License">
</p>

---

## Overview

**Worklist** is a comprehensive field-operations suite tailored for construction and site managers. It provides seamless management of sites, workers, daily attendance, payroll, advance payments, construction payments, inventory/stock, services, documents, and business reports.

Featuring a **local-first SQLite architecture** with multi-device Firebase cloud synchronization, Worklist ensures uninterrupted field productivity even in zero-connectivity environments.

---

## Key Features

- **Site & Worker Management** — track multiple construction sites, assign workers, monitor active status, maintain contact and role records
- **Attendance & Payroll** — daily attendance logging, advance payment tracking, construction payment milestones, automated salary and payroll calculations
- **Inventory & Stock Control** — store product tracking, material allocation per site, consumption analytics
- **Services & Documents** — site-specific subcontractor services, worker certifications, safety documents, compliance records
- **Advanced Notification Engine** — background rule evaluator with alerts for payroll due dates, attendance gaps and stock thresholds (Android WorkManager, Windows in-process timer)
- **Offline-First Sync** — local SQLite storage with Google sign-in and automatic Firebase Realtime Database mirroring plus latest-wins conflict resolution

---

## Platforms

| Platform | Target | Build |
|----------|--------|-------|
| Windows | Desktop (x64) | `flutter build windows --release` |
| Android | Phone / tablet | `flutter build apk --release` |

Responsive layout adapts across phone (<600dp), tablet (600–1023dp) and desktop (≥1024dp). Handheld form factors always use the compact phone layout; Windows uses the full responsive shell.

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter (Dart SDK >= 3.2.0) |
| State | `provider` |
| Local DB | `sqflite` (Android), `sqflite_common_ffi` (Windows) |
| Cloud | Firebase Auth (Google Sign-In), Firebase Realtime Database, FCM |
| Routing | `go_router` |
| Charts | `fl_chart` |
| Maps | `flutter_map` + `latlong2` + `geolocator` |
| Other | `pdf` report generation, `barcode_widget`, `simple_barcode_scanner`, `file_picker` |

---

## Architecture

- **Data layer** — single user-scoped SQLite database with foreign keys and covering indexes. Per-user row isolation via `user_id`. Encapsulated repositories: `DashboardRepository`, `WorkerRepository`, `InventoryRepository`, `SiteRepository`
- **Sync layer** — `FirebaseCloudService` mirrors business data and notification metadata to Firebase Realtime Database keyed by Google `uid`. Conflict resolution is latest-wins per record; offline edits are queued and retried with exponential backoff
- **Notification framework** — self-contained pipeline: `NotificationRule` → `NotificationRuleEvaluator` → dedupe via `NotificationHistoryRepository` → `NotificationScheduler`. Background delivery via Android WorkManager (15-min floor) and a Windows in-process timer
- **State** — `provider` for app-wide providers (`AuthProvider`, `SiteProvider`, `WorkerProvider`, `StoreProductProvider`, `UserServiceProvider`, `SyncService`, theme)

See [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) for the full component map.

---

## Getting Started

### Prerequisites

- Flutter SDK >= 3.2.0
- Android SDK (Android builds) or Visual Studio with Desktop C++ workload (Windows builds)
- A Firebase project with Auth (Google) and Realtime Database enabled

### Run Locally

```bash
git clone https://github.com/AshbornDV/Worklist.git
cd Worklist
flutter pub get

flutter run -d windows              # desktop
flutter run -d <android-device>     # Android
```

### Release Builds

```bash
flutter build apk --release         # Android APK
flutter build windows --release     # Windows desktop
```

---

## Project Layout

```
lib/
├── core/
│   ├── database/      # SQLite helper, migrations, tests
│   ├── firebase/      # Auth, cloud sync, App Check, FCM
│   ├── models/        # Site, worker, attendance, payroll, product...
│   ├── notifications/ # Rule engine, actions, insights, platform services
│   ├── providers/     # AuthProvider, WorkerProvider, ...
│   ├── repositories/  # Per-domain data access
│   └── services/      # PDF reports, helpers
├── features/          # UI screens grouped by domain
│   ├── account/ ai_assistant/ auth/ dashboard/ documents/
│   ├── leave/ notifications/ payroll/ products/ reports/
│   └── services/ shifts/ sites/ stock/ sync/ workers/
└── shared/widgets/    # Reusable UI components
```

---

## Release Artifacts

Releases are published under the repository **Releases** tab. Local build outputs:

- `build/app/outputs/apk/release/app-release.apk` — Android release
- `build/windows/x64/runner/Release/` — Windows release folder

---

## Documentation

- [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) — overall system design and component map
- [NOTIFICATIONS_ARCHITECTURE.md](NOTIFICATIONS_ARCHITECTURE.md) — notification subsystem design
- [CHANGELOG.md](CHANGELOG.md) — chronological change log
- [RELEASE_NOTES.md](RELEASE_NOTES.md) — per-version highlights and known limitations

---

## License

Proprietary — Parash Newar. All rights reserved.