# CHECKPOINT: PDF Export for Daily Reports - Context Condensed

## Primary Request and Intent
- **Implement Sprint 3 PDF Export for Daily Reports end-to-end in Flutter Worklist app**
- Create PDF export service with `generateDailyReportPdf()` method using `pdf` package (^3.12.0)
- Integrate into DailyReportProvider with `exportReportPdf(String reportUuid)` method
- Add PDF export button/action to `report_list_screen.dart`
- Run `flutter pub get`, `flutter analyze`, `flutter test` for reports feature

## Key Technical Concepts
- Flutter + Material 3, `pdf` package ^3.12.0 in pubspec.yaml
- Provider pattern: ChangeNotifiers as state management, repository pattern
- SQLite: sqflite ^2.3.3+1; IF NOT EXISTS migrations v21-v24 idempotent
- Firebase: Auth + Google Sign-In + RTDB (firebase_database) for cloud sync
- Local-first: UUID v4 naming, SHA-256 hashing, relative paths inside app docs dir
- 10+ ChangeNotifierProviders: SiteProvider, WorkerProvider, StoreProductProvider, UserServiceProvider, AuthProvider, SyncService, ThemeProvider, DailyReportProvider, ShiftProvider, LeaveProvider
- Document sync status pattern: DailyReportSyncStatus, ShiftSyncStatus, LeaveSyncStatus
- `_notifyUserMutated()` called multiple times (3x in insertUserService, 2x in insertSiteService) — needs reduction to single call
- Flutter pub get completed: 110 packages newer than constraints; pdf package ^3.12.0 resolved

## Files and Code (Status)
- `lib/core/services/report_pdf_service.dart`: Created with `generateDailyReportPdf()` — returns `Uint8List` with title, date, site info, photo placeholders ✅
- `lib/features/reports/services/report_export_service.dart`: Created; `DailyReportProvider.exportReportPdf()` added ✅
- `lib/features/reports/report_list_screen.dart`: PDF export IconButton added to actions list; `_exportReportPdf` method implemented calling `provider.exportReportPdf(report.uuid)`; `_isLoading` state managed around export ✅
- `lib/features/reports/daily_report_provider.dart`: **HAS ERRORS** — 80 analysis issues, mostly `uri_does_not_exist` from incomplete imports

## Errors and Fixes (Pending)
- **`flutter analyze` shows 80 issues** in `daily_report_provider.dart`:
  - Missing `cloud_firestore` dependency → add to pubspec.yaml
  - Missing files referenced by URI:
    - `package:cloud_firestore/cloud_firestore.dart`
    - `../../../core/services/firebase_service.dart`
    - `../../../core/services/pdf_export_service.dart`
    - `../../../core/services/sync_service.dart`
    - `../../sites/models/site_model.dart`
    - `package:worklist/features/reports/daily_report_provider.generated.dart`
  - Undefined classes: `FirebaseService`, `SyncService`, `DailyReportModel`
  - `Uint8List` not type in `report_export_service.dart`
  - Class name `DynamikReportProvider` should be `DailyReportProvider` in `report_export_service.dart`
  - `ReportPdfService` undefined in `report_export_service.dart`

## Pending Jobs
- Run `flutter analyze` to fix `uri_does_not_exist` errors in `daily_report_provider.dart`
- Run `flutter test` for reports feature tests
- Fix `report_export_service.dart`: rename `DynamikReportProvider` → `DailyReportProvider`, add `ReportPdfService` import
- Clean up duplicate `_notifyUserMutated()` calls (3x in insertUserService, 2x in insertSiteService)
- Execute migration tests v21-v24: 6 test cases pending

## Current Work Summary
- `report_pdf_service.dart` created with `generateDailyReportPdf()` returning bytes including title, date, site info, photo placeholders
- `report_export_service.dart` created; `DailyReportProvider.exportReportPdf()` added
- PDF export IconButton added to `report_list_screen.dart` actions list; `_exportReportPdf` method implemented calling `provider.exportReportPdf(report.uuid)`; `_isLoading` state managed around export
- Migration tests v21-v24: 6 test cases pending execution
- Offline-first shift/leave tests: pending

## Next Step (Immediate)
- **Fix `daily_report_provider.dart` import errors**: Add missing package dependencies and create/relocate referenced service files
- After analyze passes, run `flutter test` for reports feature

## Critical Context
- Phase 1 plan must be fully implemented without breaking existing architecture
- Maintain offline-first SQLite operation with Firebase RTDB sync
- Database migrations v21-v24: non-breaking with documented rollback (`IF NOT EXISTS` + idempotent)
- Android/Windows feature parity mandatory — shifts/leave must work identically on both platforms
- Provider pattern with ChangeNotifier preserved across all new features (now 10+ providers)
- Document sync status pattern replicated for shifts/leave with ShiftSyncStatus/LeaveSyncStatus enums
- Zero test coverage for migrations v21-v24, offline-first/sync — tests must be written alongside implementation
- `database_helper.dart` imports 24+ model files; adding ShiftModel + LeaveModel imports must not increase compile time significantly
- No breaking changes to existing tables/columns in v21-v24 migrations; verified with IF NOT EXISTS; must verify data-loss protection in upgrade path testing
- `onUserMutate` callback: concurrent mutates may race; need queue or per-provider token — identified as risk
- Duplicate `_notifyUserMutated()` calls (3x in insertUserService, 2x in insertSiteService) should be reduced to single call to prevent duplicate sync triggers