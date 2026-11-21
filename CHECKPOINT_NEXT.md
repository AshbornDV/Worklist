## Primary Request and Intent
- Implement Sprint 3 PDF Export end-to-end in Flutter Worklist app
- Create PDF export service with `generateDailyReportPdf()` using `pdf` package (^3.12.0)
- Integrate into DailyReportProvider with `exportReportPdf(String reportUuid)` 
- Add PDF export button/action to report_list_screen.dart
- Run flutter pub get, flutter analyze, flutter test for reports feature

## Key Technical Concepts
- Flutter + Material 3, `pdf` ^3.12.0 in pubspec.yaml
- Provider pattern: ChangeNotifiers + repository pattern
- SQLite: sqflite ^2.3.3+1; IF NOT EXISTS migrations v21-v24 idempotent
- Firebase: Auth + Google Sign-In + RTDB for cloud sync
- Local-first: UUID v4, SHA-256 hashing, relative paths in app docs dir
- 10+ ChangeNotifierProviders: SiteProvider, WorkerProvider, StoreProductProvider, UserServiceProvider, AuthProvider, SyncService, ThemeProvider, DailyReportProvider, ShiftProvider, LeaveProvider
- Document sync status: DailyReportSyncStatus, ShiftSyncStatus, LeaveSyncStatus
- onUserMutate callback: concurrent mutates may race; need queue/per-provider token
- _notifyUserMutated(): 3x in insertUserService, 2x in insertSiteService — duplicate sync triggers

## Files and Code
- lib/core/services/report_pdf_service.dart: `generateDailyReportPdf(dailyReportModel)` → Uint8List with title, date, site info, photo placeholders
- lib/features/reports/services/report_export_service.dart: `ReportExportService.exportReportPdf()` mediates between provider and PDF service
- lib/features/reports/daily_report_provider.dart: Added import, `exportReportPdf(String reportUuid)`, `_getSiteName` helper, `_notifyUserMutated()` pattern
- lib/features/reports/report_list_screen.dart: PDF export IconButton in actions; `_exportReportPdf` calling `provider.exportReportPdf(report.uuid)`; `_isLoading` managed around export

## Errors and Fixes
- subagent name conflicts (architect2) resolved
- missing shell tool → pwsh resolved
- database_engineer → db-engineer resolved
- 78 analyze issues: mostly uri_does_not_exist from incomplete imports in daily_report_provider.dart
- Duplicate `_notifyUserMutated()` calls: 3x in insertUserService, 2x in insertSiteService — reduce to single call

## Pending Jobs
- Run `flutter analyze` to fix uri_does_not_exist errors in daily_report_provider.dart
- Run `flutter test` for reports feature tests
- Clean up duplicate `_notifyUserMutated()` calls (3x insertUserService, 2x insertSiteService)

## Current Work
- `report_pdf_service.dart` created with `generateDailyReportPdf()` — returns bytes with title, date, site info, photo placeholders
- `report_export_service.dart` created; `DailyReportProvider.exportReportPdf()` added
- PDF export IconButton added to report_list_screen.dart actions; `_exportReportPdf` method; `_isLoading` managed
- Migration tests v21-v24: 6 test cases; pending execution
- Offline-first shift/leave tests: pending

## Next Step
- Run `flutter analyze` to fix uri_does_not_exist errors; then run `flutter test` for reports feature

## Critical Context
- Phase 1 plan must be fully implemented without breaking existing architecture
- Maintain offline-first SQLite operation with Firebase RTDB sync
- Database migrations v21-v24: non-breaking with documented rollback (IF NOT EXISTS + idempotent)
- Android/Windows feature parity mandatory — shifts/leave must work identically on both platforms
- Provider pattern with ChangeNotifier preserved across all new features (now 10+ providers)
- Document sync status pattern replicated for shifts/leave with ShiftSyncStatus/LeaveSyncStatus enums
- Zero test coverage for migrations v21-v24, offline-first/sync — tests must be written alongside implementation
- database_helper.dart imports 24+ model files; adding ShiftModel + LeaveModel must not increase compile time significantly
- No breaking changes to existing tables/columns in v21-v24 migrations; verified with IF NOT EXISTS; must verify data-loss protection in upgrade path testing
- onUserMutate callback: concurrent mutates may race; need queue or per-provider token — identified as risk
- Duplicate `_notifyUserMutated()` calls (3x in insertUserService, 2x in insertSiteService) should be reduced to single call to prevent duplicate sync triggers
- Flutter pub get completed: 110 packages newer than constraints; pdf package ^3.12.0 resolved