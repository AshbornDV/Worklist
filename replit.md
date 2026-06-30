# Worklist

A cross-platform Flutter application for construction site and worker management. Supports Android, iOS, and Windows desktop.

## Stack

- **Framework**: Flutter (Dart)
- **Database**: SQLite via `sqflite` (mobile) + `sqflite_common_ffi` (Windows/Linux/macOS)
- **State management**: Provider (`ChangeNotifier`)
- **Navigation**: go_router
- **Cloud sync**: Firebase (Firestore via `firebase_core`)
- **Auth**: Firebase Auth + local SQLite fallback

## Project structure

```
lib/
  main.dart              — Entry point; initialises SQLite FFI on desktop
  app.dart               — GoRouter config + MaterialApp.router
  core/
    database/            — DatabaseHelper singleton (SQLite)
    models/              — Data classes (Site, Worker, Attendance, etc.)
    providers/           — AuthProvider, SiteProvider, WorkerProvider
    firebase/            — FirebaseCloudService
    sync/                — SyncService
    theme/               — AppTheme (Material 3, light + dark)
  features/
    auth/                — LoginScreen
    dashboard/           — DashboardScreen (adaptive sidebar/bottom-nav)
    sites/               — SitesListScreen, SiteDetailScreen, SiteFormScreen
    workers/             — WorkersListScreen, WorkerDetailScreen, AttendanceScreen
    account/             — AccountScreen
  shared/
    widgets/             — Shared UI components
```

## Running locally

This project targets mobile (Android/iOS) and Windows desktop. It cannot be run as a Flutter web app on Replit due to Firebase App Check and SQLite FFI requirements.

To build:
```
flutter pub get
flutter run -d windows   # Windows desktop
flutter run              # connected Android/iOS device
```

## Database

- SQLite, version 5
- 6 tables: `users`, `sites`, `workers`, `products`, `site_workers`, `attendance`, `advance_payments`
- All business tables are scoped by `user_id` (multi-user isolation)
- 9 explicit indexes on high-frequency query columns (added v5 migration)

## Key optimisations applied

- **DB indexes** (v5 migration): 9 indexes covering all heavy `WHERE`/`JOIN`/`ORDER BY` patterns
- **Dashboard stats**: consolidated from 6 queries → 3 using conditional aggregation
- **Advance date filter**: fixed to use `strftime('%Y-%m', approved_date)` instead of fragile string bounds
- **Provider loading flags**: split into per-resource flags (`_sitesLoading`, `_productsLoading`, `_siteWorkersLoading`) to prevent cross-feature spinner flicker
- **Logout cache flush**: `SiteProvider.clear()` and `WorkerProvider.clear()` called on logout to prevent stale data leaking to next user
- **Deprecated API**: all `withOpacity()` calls replaced with `withValues(alpha:)` (Flutter 3.x)
- **Desktop cursor**: `SystemMouseCursors.click` on site and worker card InkWells

## User preferences

- Keep project structure as-is (feature-based folders under lib/)
- Focus on mobile + Windows desktop smoothness and database performance
