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

## Professional UI Showcase

![Worklist Dashboard](https://i.imgur.com/placeholder1.png)  
*Dashboard with real-time analytics, worker assignments, and site overview*

![Worklist Site Detail](https://i.imgur.com/placeholder2.png)  
*Site detail view showing active workers, tasks, and resource allocation*

![Worklist Payroll](https://i.imgur.com/placeholder3.png)  
*Payroll management interface with advance payment tracking and salary calculations*

> **Note**: Replace the placeholder images with actual screenshots from your device. Screenshots should be taken from real device usage to showcase the responsive layout across phone, tablet, and desktop platforms. The UI maintains consistent styling using Material Design components with custom branding.

## Key Features

- **Site & Worker Management** — track multiple construction sites, assign workers, monitor active status, maintain contact and role records
- **Attendance & Payroll** — daily attendance logging, advance payment tracking, construction payment milestones, automated salary and payroll calculations
- **Inventory & Stock Control** — store product tracking, material allocation per site, consumption analytics
- **Services & Documents** — site-specific subcontractor services, worker certifications, safety documents, compliance records
- **Advanced Notification Engine** — background rule evaluator with alerts for payroll due dates, attendance gaps and stock thresholds (Android WorkManager, Windows in-process timer)
- **Offline-First Sync** — local SQLite storage with Google sign-in and automatic Firebase Realtime Database mirroring plus latest-wins conflict resolution

## Platforms

| Platform | Target | Build Command |
|----------|--------|---------------|
| Windows | Desktop (x64) | `flutter build windows --release` |
| Android | Phone / tablet | `flutter build apk --release` |

> **Windows Note**: Requires Visual Studio 2022 with "Desktop development with C++" workload. See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) for detailed installation steps.

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

## Architecture

- **Data layer** — single user-scoped SQLite database with foreign keys and covering indexes. Per-user row isolation via `user_id`. Encapsulated repositories: `DashboardRepository`, `WorkerRepository`, `InventoryRepository`, `SiteRepository`
- **Sync layer** — `FirebaseCloudService` mirrors business data and notification metadata to Firebase Realtime Database keyed by Google `uid`. Conflict resolution is latest-wins per record; offline edits are queued and retried with exponential backoff
- **Notification framework** — self-contained pipeline: `NotificationRule` → `NotificationRuleEvaluator` → dedupe via `NotificationHistoryRepository` → `NotificationScheduler`. Background delivery via Android WorkManager (15-min floor) and a Windows in-process timer
- **State** — `provider` for app-wide providers (`AuthProvider`, `SiteProvider`, `WorkerProvider`, `StoreProductProvider`, `UserServiceProvider`, `SyncService`, theme)

See [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) for the full component map.

## Getting Started

### Prerequisites

- Flutter SDK >= 3.2.0
- Android SDK (Android builds) or Visual Studio 2022 with C++ workload (Windows builds)
- A Firebase project with Auth (Google) and Realtime Database enabled

### Run Locally

```bash
git clone https://github.com/AshbornDV/Worklist.git
cd Worklist
flutter pub get

flutter run -d windows              # desktop (requires Windows setup)
flutter run -d <android-device>     # Android
```

### Release Builds

```bash
flutter build apk --release         # Android APK
flutter build windows --release     # Windows desktop (requires setup)
```

Release assets are published under the repository **Releases** tab. APK asset is available at `build/app/outputs/apk/release/app-release.apk`; Windows build output is in `build/windows/x64/runner/Release/` (when build environment is configured).

## Documentation

- [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) — overall system design and component map
- [NOTIFICATIONS_ARCHITECTURE.md](NOTIFICATIONS_ARCHITECTURE.md) — notification subsystem design
- [CHANGELOG.md](CHANGELOG.md) — chronological change log
- [RELEASE_NOTES.md](RELEASE_NOTES.md) — per-version highlights and known limitations

---

## License

Proprietary — Parash Newar. All rights reserved.