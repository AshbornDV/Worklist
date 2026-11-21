## Primary Request and Intent
- Implement Sprint 3 PDF Export for Daily Reports end-to-end
- Complete offline-first testing for Shift/Leave features
- Verify Android/Windows feature parity
- Review 4 subagent inspection outputs and fix identified risks
- Run migration tests v21-v24
- Fix concurrent onUserMutate race condition
- Finish all outstanding implementation and verification work per execution override

## Key Technical Concepts
- Flutter + Material 3: useMaterial3: true in Theme
- Provider pattern: ChangeNotifiers as state management, repository pattern for data access
- SQLite: sqflite ^2.3.3+1; migrations v21-v24 use IF NOT EXISTS for idempotent upgrades
- Firebase: Auth + Google Sign-In + RTDB (firebase_database) for cloud sync
- Local-first: UUID v4 naming, SHA-256 hashing, relative paths inside app docs dir
- Dependencies: pdf ^3.12.0, go_router ^13.2.4, sqflite ^2.3.3+1, path ^1.9.0, crypto ^3.0.3, flutter_local_notifications ^22.0.1, workmanager ^0.10.0
- 10+ ChangeNotifierProviders: SiteProvider, WorkerProvider, StoreProductProvider, UserServiceProvider, AuthProvider, SyncService, ThemeProvider, DailyReportProvider, ShiftProvider, LeaveProvider
- Document sync status pattern: DailyReportSyncStatus, ShiftSyncStatus, LeaveSyncStatus
- onUserMutate callback race condition: concurrent mutates may race; need queue or per-provider token - identified as risk
- _notifyUserMutated() called multiple times in same method (insertSiteService, insertUserService) - potential duplicate sync triggers

## Files and Code
- lib/features/reports/models/daily_report_model.dart: uuid, userId, siteId, date, title, kind, contentRef, fileName, mimeType, sizeBytes, localPath, storagePath, hash, thumbPath, createdAt, updatedAt; toMap()/fromMap(); DailyReportSyncStatus enum; DailyReportKind enum (text/image/pdf)
- lib/core/database/database_helper.dart: v21 _createDailyReportsTable with indexes; v22 _createDailyReportPhotosTable; v23 _createShiftsTable; v24 _createLeaveRequestsTable; _onUpgrade idempotent with IF NOT EXISTS for v21-v24; onUserMutate callback identified as race condition risk; _notifyUserMutated() called 3x in insertUserService (lines 1454-1456)
- lib/features/reports/report_form_screen.dart: Form with title, content, photo capture, save actions
- lib/features/reports/report_list_screen.dart: List with sync/delete actions, row-level operations
- lib/features/shifts/models/shift_model.dart: ShiftKind enum, ShiftSyncStatus enum, ShiftModel with toMap/fromMap
- lib/features/leave/models/leave_request_model.dart: LeaveType enum, LeaveSyncStatus enum, LeaveRequestModel with toMap/fromMap
- lib/features/shifts/shift_provider.dart: ShiftProvider with ChangeNotifier, repository pattern, CRUD methods, cloud sync
- lib/features/leave/leave_provider.dart: LeaveProvider with ChangeNotifier, repository pattern, CRUD methods, cloud sync
- lib/features/shifts/shift_form_screen.dart: Shift form with date, start/end time, kind selection
- lib/features/shifts/shift_list_screen.dart: Shift list with sync/delete actions
- lib/features/leave/leave_form_screen.dart: Leave form with type, reason, duration fields
- lib/features/leave/leave_list_screen.dart: Leave list with sync/delete actions
- lib/core/database/migrations_test.dart: 6 test cases for v21-v24 idempotency verification
- lib/features/reports/services/report_pdf_service.dart: NOT YET CREATED
- lib/features/reports/services/report_export_service.dart: NOT YET CREATED

## Errors and Fixes
- Subagent "database_engineer" rejected: resolved by using "db-engineer"
- Tool "shell" does not exist: used pwsh with `start http://localhost:6518` to open browser
- Subagent "architect" already in use: used "architect2" instead
- Subagent "architect2" failed before finishing: re-launched as architect2
- Four inspection subagents completed: architect2, ui-ux-engineer, qa-engineer, security-engineer
- onUserMutate callback: concurrent mutates may race; need queue or per-provider token - identified as risk
- _notifyUserMutated() called multiple times in same method (insertSiteService, insertUserService) - potential duplicate sync triggers

## Pending Jobs
- Implement PDF Export service and integrate into Daily Report provider and report screens
- Write offline-first sync tests for Shift/Leave features
- Run migration tests
- Fix concurrent onUserMutate race condition in database_helper.dart
- Review four subagent inspection outputs for risks

## Current Work (completed)
- DailyReportModel created with sync status pattern matching DocumentModel ✅
- daily_reports and daily_report_photos tables added to database_helper.dart (v21/v22) ✅
- _onUpgrade migration steps added for tables v21/v22 ✅
- DailyReportProvider with ChangeNotifier, repository pattern, _syncCloud method ✅
- report_form_screen with form fields and photo capture ✅
- report_list_screen with list and sync actions ✅
- Shift model created ✅
- Leave model created ✅
- database_helper.dart migrations v23 (Shifts) and v24 (Leave) added with IF NOT EXISTS ✅
- ShiftProvider created ✅
- LeaveProvider created ✅
- Shift model integration with provider pattern ✅
- Leave model integration with provider pattern ✅
- leave_form_screen.dart and leave_list_screen created ✅
- shift_form_screen.dart and shift_list_screen.dart created ✅
- migrations_test.dart created with 6 test cases for v21-v24 idempotency ✅
- PDF Export service: NOT YET IMPLEMENTED
- Offline-first shift/leave tests: NOT YET WRITTEN
- Migration test execution: NOT YET RUN
- onUserMutate race condition fix: NOT YET IMPLEMENTED
- Duplicate _notifyUserMutated() calls in insertSiteService/insertUserService need cleanup

## Next Step
- Implement PDF Export service (report_pdf_service.dart + report_export_service.dart) with generateDailyReportPdf() method integrated into DailyReportProvider
- Clean up duplicate _notifyUserMutated() calls
- Run migration tests
- Write offline-first tests for Shift/Leave

## Critical Context
- Approved Phase 1 plan must be fully implemented without breaking existing architecture
- Must maintain offline-first SQLite operation with Firebase RTDB sync
- Database migrations v21-v24 must be non-breaking with documented rollback (IF NOT EXISTS + idempotent)
- Android/Windows feature parity mandatory — shifts/leave must work identically on both platforms
- Provider pattern with ChangeNotifier must be preserved across all new features (now 10+ providers)
- Document sync status pattern replicated for shifts/leave with ShiftSyncStatus/LeaveSyncStatus enums
- Zero test coverage for migrations v21-v24, offline-first/sync — tests must be written alongside implementation
- database_helper.dart imports 24+ model files; adding ShiftModel + LeaveModel imports must not increase compile time significantly
- No breaking changes to existing tables/columns in v21-v24 migrations; verified with IF NOT EXISTS but must verify data-loss protection in upgrade path testing
- Four completed subagent inspections may have identified risks; must review outputs before proceeding
- onUserMutate callback: concurrent mutates may race; need queue or per-provider token - identified as risk
- Migration tests must verify: IF NOT EXISTS idempotency, data integrity across sequential migrations, column preservation, and table existence after re-runs
- offline-first sync tests must verify: local SQLite operations work without RTDB, sync conflict resolution, offline edit handling, and RTDB reconciliation on reconnect
- Duplicate _notifyUserMutated() calls (3x in insertUserService, 2x in insertSiteService) should be reduced to single call to prevent duplicate sync triggers
- Sprint 3 PDF Export: report_pdf_service.dart and report_export_service.dart need creation with generateDailyReportPdf() method