# Architecture Inspection Checkpoint

## Primary Request and Intent
- Produce comprehensive architecture inspection report as Markdown at `architecture_inspection_report.md`
- Strictly read-only inspection; no source code modifications
- Cover 8 areas: Provider architecture, Repository pattern, Database layer, Sync architecture, Model layer, Platform parity, Dependencies, Feature coverage
- Each finding: severity (critical/major/minor/improvement), location (file:line), description, recommended action
- End with prioritized summary table
- Return concise summary of top 10 most important findings
- App: Flutter + Material 3 construction site management; Provider ChangeNotifiers, repository pattern, SQLite (sqflite) offline source of truth, Firebase (Auth + Realtime Database) cloud sync; targets Android + Windows with feature parity

## Key Technical Concepts
- Flutter/Dart, Provider (ChangeNotifier), Repository pattern, sqflite (SQLite), Firebase Auth + Realtime Database, offline-first sync, conflict resolution, Material 3
- Platform-specific imports: `dart:io`, `kIsWeb`
- DB schema migrations via `onUpgrade` — currently version 20, planned v21–v24
- Dependencies: sqflite ^2.3.3+1, sqflite_common_ffi ^2.3.3, provider ^6.1.2, firebase_auth 6.5.4, firebase_database 12.4.4, pdf ^3.12.0, file_picker ^11.0.2
- Android + Windows parity with sqflite FFI initialization in main.dart
- DatabaseHelper.onUserMutate callback hook for cloud sync
- Sync service runs local HTTP server on port 8787 for LAN sync

## Files and Code (evidence-based)
- `pubspec.yaml`: 70 lines; dependencies: sqflite, firebase packages, pdf, file_picker
- `lib/main.dart`: 129 lines; initializes sqflite FFI on non-mobile platforms, MultiProvider registers 7 providers
- `worklist_phase1_implementation_plan.md`: 231 lines; defines migrations v21–24, identifies 8 critical gaps
- `lib/core/providers/site_provider.dart`: 518 lines; ChangeNotifier with SiteRepository, cloud sync via FirebaseCloudService
- `lib/core/providers/worker_provider.dart`: 549 lines; ChangeNotifier with WorkerRepository + PayrollRepository, payroll calculations
- `lib/core/providers/auth_provider.dart`: 708 lines; AuthChangeNotifier with auto-pull timer, lifecycle listener
- `lib/core/providers/store_product_provider.dart`: 114 lines; ChangeNotifier with InventoryRepository
- `lib/core/database/database_helper.dart`: 2791 lines; schema version 20, `onUserMutate` static callback at line 62, `_notifyUserMutated()` at lines 1505–1507 (called 3x in insertWorker)
- `lib/core/sync/sync_service.dart`: 273 lines; local HTTP server on port 8787, pushToServer/pullFromServer methods
- `lib/core/firebase/firebase_cloud_service.dart`: 903 lines; CloudPullResult enum, offline queue with dirty flag, _retryTimer 2-min interval, _clockSkewTolerance 2min
- `lib/core/repositories/*`: follow `_db = DatabaseHelper()` pattern; wrap database operations
- `lib/core/models/*.dart`: 15 model files read (worker, user, site, payroll, attendance, construction_payment, product, store_product, site_product, site_service, user_service, advance_payment, worker_document, worker_performance)

## Errors and Fixes
- (none resolved in this session)
- Potential issue: `onUserMutate` called 3x in database_helper.dart during insertWorker (lines 1505–1507) — potential triple notification issue

## Pending Jobs (explicitly requested work not completed)
- Inspect all ChangeNotifier providers (site_provider, worker_provider, auth_provider, store_product_provider reviewed)
- Inspect all repositories (auth, dashboard, site, worker, inventory, payroll, service reviewed)
- Inspect database_helper.dart schema and sync patterns (completed)
- Inspect remaining models in lib/core/models/ and lib/features/documents/models/ — completed: 15/15
- Assess Android/Windows parity
- Review pubspec.yaml dependencies against Phase 1 plan
- Map feature modules against approved plan to identify gaps

## Current Work
- Read 4 provider files: site_provider, worker_provider, auth_provider, store_product_provider
- Read sync_service.dart and firebase_cloud_service.dart
- Read all repository files: auth, dashboard, site, worker, inventory, payroll, service
- Read model files: worker, user, site, payroll, attendance, construction_payment, product, store_product, site_product, site_service, user_service, advance_payment, worker_document, worker_performance — all 15/15 completed
- Identified potential issue: `onUserMutate` called 3x in database_helper.dart during insertWorker (lines 1505–1507)

## Next Step
- Generate the prioritized summary table of top 10 most important findings
- Write the architecture_inspection_report.md with 8-area coverage and severity-ranked findings

## Critical Context
- Scope strictly read-only: no source code modifications allowed
- Permission scope fixed at delegation; operations requiring approval rejected automatically
- Final report must include evidence with exact file paths and line numbers
- Architecture concern: DatabaseHelper.onUserMutate is sole bridge between local DB and cloud sync
- sqflite FFI only initialized for Windows/Linux/MacOS in main.dart; Android uses original sqflite
- MultiProvider registration includes 7 providers
- auth_repository.dart line 35: setActiveUser delegates to _db.setActiveUser; line 40: activeUserId getter
- DashboardRepository lines 47–51: exportUserData/replaceUserData used by sync_service.dart
- onUserMutate called 3x in database_helper.dart during insertWorker — potential triple notification issue
- Feature parity target: Android + Windows with identical offline-first sync behavior
- DB schema version 20 with planned migrations v21–v24 adding new tables/columns