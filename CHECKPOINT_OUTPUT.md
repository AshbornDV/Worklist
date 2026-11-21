## Primary Request and Intent
- "continue with the plan and dont stop until every thing in the plan is done"
- 3-sprint plan: Sprint 1 (Daily Reports v21-v22), Sprint 2 (Shifts & Leave v23-v24), Sprint 3 (PDF Export)
- Constraints: no data loss, preserve offline-first and Android/Windows parity, no breaking DB migrations without documented migration/rollback
- All 3 sprints must execute without stopping

## Key Technical Concepts
- Flutter + Material 3: `useMaterial3: true` in Theme
- Provider: ChangeNotifiers as state management, repository pattern for data access
- SQLite: sqflite v20, v21-v22 migrations for daily_reports/daily_report_photos tables
- Firebase: Auth + Google Sign-In + RTDB (firebase_database) for cloud sync
- Android/Windows parity requirement
- 8+ ChangeNotifierProviders: SiteProvider, WorkerProvider, StoreProductProvider, UserServiceProvider, AuthProvider, SyncService, ThemeProvider, DailyReportProvider
- Document model pattern: DocumentModel, DocumentSyncStatus replicated as DailyReportSyncStatus
- Local-first: UUID naming, SHA-256 hashing, relative paths
- Dependencies: pdf ^3.12.0, go_router ^13.2.4, sqflite ^2.3.3+1, path ^1.9.0, crypto ^3.0.3, flutter_local_notifications ^22.0.1, workmanager ^0.10.0

## Files and Code
- `lib/features/reports/models/daily_report_model.dart` — NEW: DailyReportModel (uuid, entityType, entityId, fileName, mimeType, sizeBytes, localPath, syncStatus DailyReportSyncStatus, hash); toMap()/fromMap() for cloud sync
- `lib/core/database/database_helper.dart` — EDITED:
  - `_onCreate`: added `_createDailyReportsTable(db)` (v21), `_createDailyReportPhotosTable(db)` (v22) before `_createIndexes(db)`
  - `_onUpgrade`: idempotent IF NOT EXISTS migrations v21 (CREATE daily_reports), v22 (CREATE daily_report_photos)
  - `_createDailyReportsTable`: id, uuid, userId, siteId, date, title, kind, contentRef, fileName, mimeType, sizeBytes, localPath, storagePath, hash, thumbPath, syncStatus, isDeleted, createdAt, updatedAt; indexes userId+siteId, userId+syncStatus, uuid
  - `_createDailyReportPhotosTable`: id, uuid, userId, reportId, photoPath, fileName, mimeType, sizeBytes, hash, thumbPath, syncStatus, createdAt, updatedAt; indexes userId+reportId, uuid
  - `onUserMutate` callback wired to Firebase sync; `_notifyUserMutated()` at line 68-71
- `lib/features/reports/` — TO BE CREATED: daily_report_provider.dart, report_form_screen.dart, report_list_screen.dart

## Errors and Fixes
- Subagent "database_engineer" rejected: fixed by using "db-engineer"
- Tool "shell" does not exist: used pwsh with `start http://localhost:6518` to open browser
- Subagent "architect" already in use: used "architect2" instead
- Subagent "architect2" failed before finishing: re-launched as architect2
- Four inspection subagents completed: architect2, ui-ux-engineer, qa-engineer, security-engineer

## Pending Jobs
- Write migration tests for v21/v22 upgrades
- Write offline-first sync tests
- Create DailyReportProvider with ChangeNotifier pattern
- Create report_form_screen with form fields and photo capture
- Create report_list_screen with list and sync actions

## Current Work
- DailyReportModel created with sync status pattern matching DocumentModel
- daily_reports and daily_report_photos tables added to database_helper.dart (v21/v22)
- _onUpgrade migration steps added for tables v21/v22
- Ready to create DailyReportProvider following SiteProvider/WorkerProvider patterns
- Ready to create report_form_screen and report_list_screen UI

## Next Step
- Create DailyReportProvider (ChangeNotifier, repository pattern, _syncCloud method)

## Critical Context
- Approved Phase 1 plan must be fully implemented without breaking existing architecture
- Must maintain offline-first SQLite operation with Firebase RTDB sync
- Database migrations v21/v22 must be non-breaking with documented rollback (IF NOT EXISTS + idempotent)
- Android/Windows feature parity mandatory — daily reports same on both platforms
- Provider pattern with ChangeNotifier must be preserved across new features
- Document sync status pattern replicated for daily reports with DailyReportSyncStatus enum
- User explicitly approved the 3-sprint plan and wants full execution without stopping
- All new code must integrate with existing Firebase RTDB sync via onUserMutate hook
- Zero test coverage for Daily Reports, migrations v21-v24, offline-first/sync — tests must be written alongside implementation