# Graph Report - .  (2026-07-30)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 3149 nodes · 4271 edges · 154 communities (140 shown, 14 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 14 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `dc2971c3`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- database_helper.dart
- responsive.dart
- firebase_cloud_service.dart
- worker_provider.dart
- calendar_screen.dart
- site_detail_screen.dart
- site_provider.dart
- site_form_screen.dart
- auth_provider.dart
- notification_metrics.dart
- user_service_provider.dart
- document_model.dart
- dashboard_screen.dart
- payroll_screen.dart
- StatelessWidget
- notification_history_repository.dart
- document_provider.dart
- app.dart
- What You Must Do When Invoked
- products_screen.dart
- firebase_diagnostics.dart
- business_insight_provider.dart
- site_model.dart
- shared_widgets.dart
- worker_detail_screen.dart
- notification_model.dart
- document_detail_screen.dart
- inventory_audit_reminder_rule.dart
- notification_center_provider.dart
- android_notification_service.dart
- worker_performance_screen.dart
- notification_settings.dart
- worker_repository.dart
- worker_form_screen.dart
- Architecture Refactor — Layered Repository Plan
- notification_engine.dart
- sync_service.dart
- site_repository.dart
- documents_screen.dart
- payroll_model.dart
- AuthProvider
- notifications.dart
- notification_settings_screen.dart
- notification_center_screen.dart
- app_constants.dart
- sync_screen.dart
- worker_documents_screen.dart
- workers_list_screen.dart
- google_oauth_service.dart
- sites_list_screen.dart
- business_insight_models.dart
- analytics_screen.dart
- NotificationCenterProvider
- windows_background_scheduler.dart
- package:provider/provider.dart
- notification_rules_registry.dart
- store_product_model.dart
- worker_advance_rule.dart
- firebase_bootstrap.dart
- home_content.dart
- firebase_config.dart
- collections_screen.dart
- business_insight_engine.dart
- notification_cloud_sync_service.dart
- WorkerProvider
- Design System
- app_check_service.dart
- FlutterWindow
- worker_model.dart
- site_lifecycle_rule.dart
- State
- document_file_service.dart
- login_screen.dart
- attendance_screen.dart
- ../models/notification_model.dart
- document_storage_service.dart
- payslip_service.dart
- win32_window.cpp
- bool get
- static const
- advance_payment_model.dart
- store_product_provider.dart
- document_permissions.dart
- main.dart
- stock_screen.dart
- services_screen.dart
- site_product_model.dart
- NotificationRule
- smart_summary_rule.dart
- worker_lifecycle_rule.dart
- List
- payroll_reminder_rule.dart
- notification_logger.dart
- notification_action_handler.dart
- auth_repository.dart
- worker_performance_model.dart
- Dashboard Content
- inventory_repository.dart
- collection_reminder_service.dart
- document_repository.dart
- String get
- notification_action_catalog.dart
- firebase_auth_listener.dart
- wWinMain
- _MapPickerDialog
- construction_payment_model.dart
- product_model.dart
- document_thumbnail.dart
- Win32Window
- DateTime
- site_service_model.dart
- worker_document_model.dart
- google_services_config.dart
- _SiteFormScreenState
- dart:io
- Map
- MessageHandler
- graphify reference: extra exports and benchmark
- notification_settings_repository.dart
- background_task_coordinator.dart
- reminder_window.dart
- package:flutter/material.dart
- package:go_router/go_router.dart
- NOTIFICATIONS_ARCHITECTURE.md
- System Architecture — Worklist
- package:flutter/foundation.dart
- BootReceiver
- build
- WorklistApplication
- RegisterPlugins
- MainActivity
- widget_test.dart
- Worklist — Site & Worker Management
- ScreenSize
- package:shared_preferences/shared_preferences.dart
- graphify reference: query, path, explain
- String?
- Bottom Navigation
- Changelog — Worklist
- Release Notes — Worklist
- graphify reference: add a URL and watch a folder
- graphify reference: commit hook and native CLAUDE.md integration
- graphify reference: incremental update and cluster-only
- Exception
- graphify reference: GitHub clone and cross-repo merge
- graphify reference: transcribe video and audio
- AGENTS.md
- extraction-spec.md
- Sidebar

## God Nodes (most connected - your core abstractions)
1. `WorkerProvider` - 51 edges
2. `SiteProvider` - 46 edges
3. `AuthProvider` - 34 edges
4. `StoreProductProvider` - 21 edges
5. `Win32Window` - 19 edges
6. `DocumentProvider` - 18 edges
7. `MessageHandler` - 12 edges
8. `What You Must Do When Invoked` - 12 edges
9. `NotificationRule` - 10 edges
10. `UserServiceProvider` - 10 edges

## Surprising Connections (you probably didn't know these)
- `SiteProvider` --references--> `_loadSite`  [EXTRACTED]
  lib/core/providers/site_provider.dart → lib/features/sites/site_form_screen.dart
- `SiteProvider` --references--> `initState`  [EXTRACTED]
  lib/core/providers/site_provider.dart → lib/features/sites/sites_list_screen.dart
- `SiteProvider` --references--> `build`  [EXTRACTED]
  lib/core/providers/site_provider.dart → lib/features/workers/attendance_screen.dart
- `SiteProvider` --references--> `_loadInitial`  [EXTRACTED]
  lib/core/providers/site_provider.dart → lib/features/workers/attendance_screen.dart
- `StoreProductProvider` --references--> `build`  [EXTRACTED]
  lib/core/providers/store_product_provider.dart → lib/features/sites/product_select_dialog.dart

## Import Cycles
- None detected.

## Communities (154 total, 14 thin omitted)

### Community 0 - "database_helper.dart"
Cohesion: 0.02
Nodes (132): ../../features/documents/models/document_model.dart, _activeUserId, _addColumnIfMissing, addStock, approveAdvance, assignWorkerToSite, authenticate, countUserRecords (+124 more)

### Community 1 - "responsive.dart"
Cohesion: 0.03
Nodes (72): Axis, _, EdgeInsetsGeometry?, AdaptiveGrid, all, base, baseFontSize, build (+64 more)

### Community 2 - "firebase_cloud_service.dart"
Cohesion: 0.03
Nodes (65): firebase_diagnostics.dart, Future, google_oauth_service.dart, applySession, _auth, _authenticate, _authMessage, _backoffDelay (+57 more)

### Community 3 - "worker_provider.dart"
Cohesion: 0.03
Nodes (58): activeWorkerCount, addWorker, addWorkerDocument, addWorkerPerformance, _advances, approveAdvance, _attendanceRecords, calculatePaycheck (+50 more)

### Community 4 - "calendar_screen.dart"
Cohesion: 0.04
Nodes (58): active, _activeFilters, _allCategories, _attendanceLabel, _attendanceSubtitle, build, _buildBody, _buildEvents (+50 more)

### Community 5 - "site_detail_screen.dart"
Cohesion: 0.05
Nodes (53): ../../core/models/construction_payment_model.dart, ../../core/models/product_model.dart, ../../core/models/site_product_model.dart, ../../core/models/site_service_model.dart, SiteProvider, _MobileLayout, _TabletRailShell, amount (+45 more)

### Community 6 - "site_provider.dart"
Cohesion: 0.04
Nodes (51): activeSiteCount, addConstructionPayment, addProduct, addSite, addSiteService, assignWorker, clear, clearError (+43 more)

### Community 7 - "site_form_screen.dart"
Cohesion: 0.04
Nodes (49): LatLng, _advance, _area, _areaUnits, _budget, _cost, createState, dispose (+41 more)

### Community 8 - "auth_provider.dart"
Cohesion: 0.04
Nodes (48): AppLifecycleListener?, ../firebase/firebase_auth_listener.dart, ../firebase/firebase_config.dart, ../firebase/google_oauth_service.dart, ../firebase/session_storage.dart, _auth, _autoPull, _autoPullInterval (+40 more)

### Community 9 - "notification_metrics.dart"
Cohesion: 0.04
Nodes (46): _avgExecutionMs, _daily, _dailyRetentionDays, _dayKey, devLog, DiagnosticLogEntry, ensureLoaded, _executionCount (+38 more)

### Community 10 - "user_service_provider.dart"
Cohesion: 0.05
Nodes (34): ../database/database_helper.dart, ../firebase/firebase_cloud_service.dart, addService, clear, _cloud, deleteService, _generation, _loading (+26 more)

### Community 11 - "document_model.dart"
Cohesion: 0.04
Nodes (44): DocumentKind get, image,
  pdf,
  docx,
  xlsx,, apiValue, category, copyWith, createdAt, deletedAt, DocumentKind (+36 more)

### Community 12 - "dashboard_screen.dart"
Cohesion: 0.05
Nodes (39): ColorScheme, GlobalKey, InheritedWidget, navigate, 0, activeIcon, _AppLogo, _bottomNavItems (+31 more)

### Community 13 - "payroll_screen.dart"
Cohesion: 0.04
Nodes (44): ../../core/models/payroll_model.dart, ../../core/services/payslip_service.dart, _AmountColumn, _baseWage, bold, _bonus, _bonusAmt, build (+36 more)

### Community 14 - "StatelessWidget"
Cohesion: 0.05
Nodes (46): _AgendaCard, _DayView, _ErrorState, _EventTile, _FilterBar, _MonthView, _WeekdayHeader, _WeekStrip (+38 more)

### Community 15 - "notification_history_repository.dart"
Cohesion: 0.05
Nodes (42): archive, archivedAt, body, copyWith, create, createdAt, delete, deleteAll (+34 more)

### Community 16 - "document_provider.dart"
Cohesion: 0.05
Nodes (40): DocumentEntityType? get, DocumentSort get, _applyView, availableCategories, captureFromCamera, _docs, ensureLocal, _error (+32 more)

### Community 17 - "app.dart"
Cohesion: 0.06
Nodes (38): core/notifications/actions/app_notification_router.dart, core/notifications/actions/notification_action_handler.dart, core/notifications/platform/android_notification_service.dart, core/notifications/platform/platform_notification_service_factory.dart, core/notifications/platform/windows_notification_service.dart, ../../core/theme/app_theme.dart, features/account/account_screen.dart, features/auth/login_screen.dart (+30 more)

### Community 18 - "What You Must Do When Invoked"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 19 - "products_screen.dart"
Cohesion: 0.05
Nodes (38): activeFilters, _activeFiltersLabel, _applyFilters, _cleanOrNull, _clearFilters, controller, createState, _criticalStockThreshold (+30 more)

### Community 20 - "firebase_diagnostics.dart"
Cohesion: 0.12
Nodes (15): _checkAppCheck, _checkAuthentication, _checkConfig, _checkConnectivity, _checkFirebaseInitialization, _checkPlatform, _checkRealtimeDatabase, _checkRealtimeDatabaseRest (+7 more)

### Community 21 - "business_insight_provider.dart"
Cohesion: 0.14
Nodes (13): ./business_insight_engine.dart, ./business_insight_models.dart, BusinessInsightEngine, _engine, _error, forDomain, _insights, isLoading (+5 more)

### Community 22 - "site_model.dart"
Cohesion: 0.05
Nodes (36): advanceReceived, area, balance, budget, collectionReminderDays, completionPercentage, constructionPaid, copyWith (+28 more)

### Community 23 - "shared_widgets.dart"
Cohesion: 0.06
Nodes (35): action, amount, AttendanceBadge, bgColor, build, compact, confirmText, CurrencyText (+27 more)

### Community 24 - "worker_detail_screen.dart"
Cohesion: 0.06
Nodes (34): ../../core/models/advance_payment_model.dart, WorkerPaycheck, advance, _AdvanceTile, amount, bold, _changeMonth, color (+26 more)

### Community 25 - "notification_model.dart"
Cohesion: 0.06
Nodes (34): actions, AppNotification, body, copyWith, createdAt, deliveredAt, dismissedAt, entityId (+26 more)

### Community 26 - "document_detail_screen.dart"
Cohesion: 0.08
Nodes (34): DocumentProvider, _Actions, build, _busy, createState, _delete, doc, DocumentDetailScreen (+26 more)

### Community 27 - "inventory_audit_reminder_rule.dart"
Cohesion: 0.09
Nodes (29): inventory_rule_base.dart, inventory_thresholds.dart, evaluate, FrequentlyUsedLowRule, _inventoryRepository, thresholds, _cycleBucket, evaluate (+21 more)

### Community 28 - "notification_center_provider.dart"
Cohesion: 0.06
Nodes (33): _all, archive, _category, categoryFilter, _compare, delete, deleteAll, dismiss (+25 more)

### Community 29 - "android_notification_service.dart"
Cohesion: 0.06
Nodes (34): ../actions/notification_action_catalog.dart, FlutterLocalNotificationsPlugin, actionHandler, AndroidNotificationService, cancel, cancelAll, _importance, initialize (+26 more)

### Community 30 - "worker_performance_screen.dart"
Cohesion: 0.07
Nodes (29): ../../core/models/worker_performance_model.dart, _addPerformance, _attendancePercentage, _buildPerformanceList, color, _completedWorkDays, createState, dispose (+21 more)

### Community 31 - "notification_settings.dart"
Cohesion: 0.06
Nodes (32): attendance, copyWith, dailyBriefingTime, dailySummary, _decodeTime, _encodeTime, fromJson, inventory (+24 more)

### Community 32 - "worker_repository.dart"
Cohesion: 0.06
Nodes (32): approveAdvance, _db, deleteWorker, deleteWorkerDocument, deleteWorkerDocumentsByWorker, deleteWorkerPerformance, deleteWorkerPerformanceByWorker, getAdvancesByWorker (+24 more)

### Community 33 - "worker_form_screen.dart"
Cohesion: 0.06
Nodes (31): File?, _address, createState, _dailyRate, dispose, _formKey, _initialLoad, initState (+23 more)

### Community 34 - "Architecture Refactor — Layered Repository Plan"
Cohesion: 0.09
Nodes (21): 1. `auth_repository.dart` — `AuthRepository`, 2. `site_repository.dart` — `SiteRepository`, 3. `worker_repository.dart` — `WorkerRepository`, 4. `payroll_repository.dart` — `PayrollRepository`, 5. `inventory_repository.dart` — `InventoryRepository`, 6. `service_repository.dart` — `ServiceRepository`, 7. `dashboard_repository.dart` — `DashboardRepository`, Architecture (before → after) (+13 more)

### Community 35 - "notification_engine.dart"
Cohesion: 0.07
Nodes (27): @immutable, ../core/notification_logger.dart, create, _history, refresh, registerRule, registerRules, _rules (+19 more)

### Community 36 - "sync_service.dart"
Cohesion: 0.07
Nodes (29): HttpServer?, _auth, _authenticateBody, _busy, defaultPort, _handleRequest, isBusy, isRunning (+21 more)

### Community 37 - "site_repository.dart"
Cohesion: 0.07
Nodes (29): assignWorkerToSite, _db, deleteConstructionPayment, deleteProduct, deleteSite, deleteSiteProduct, deleteSiteService, getAllSites (+21 more)

### Community 38 - "documents_screen.dart"
Cohesion: 0.07
Nodes (28): document_detail_screen.dart, DocumentEntityType, DocumentSort, build, _categoryDialog, _confirm, createState, doc (+20 more)

### Community 39 - "payroll_model.dart"
Cohesion: 0.07
Nodes (28): advanceAmount, baseWage, bonus, copyWith, createdAt, dailyRate, deductions, fromMap (+20 more)

### Community 40 - "AuthProvider"
Cohesion: 0.08
Nodes (30): Color?, IconData, _buildRouter, AuthProvider, AccountScreen, _AccountScreenState, build, color (+22 more)

### Community 41 - "notifications.dart"
Cohesion: 0.07
Nodes (26): background/background_task_coordinator.dart, engine/notification_rule_evaluator.dart, insights/business_insight_engine.dart, insights/business_insight_models.dart, insights/business_insight_provider.dart, worklist_notifications, library, rules/inventory/frequently_used_low_rule.dart (+18 more)

### Community 42 - "notification_settings_screen.dart"
Cohesion: 0.08
Nodes (27): ../../core/notifications/models/notification_model.dart, ../../core/notifications/models/notification_settings.dart, ../../core/notifications/repositories/notification_settings_repository.dart, NotificationSettingsRepository, build, _CategoryToggle, createState, _days (+19 more)

### Community 43 - "notification_center_screen.dart"
Cohesion: 0.07
Nodes (26): ../../core/notifications/providers/notification_center_provider.dart, ../../core/notifications/repositories/notification_history_repository.dart, NotificationGroupBy, NotificationSort, NotificationRecord, _buildBody, _categories, _categoryLabel (+18 more)

### Community 44 - "app_constants.dart"
Cohesion: 0.08
Nodes (25): advanceApproved, advancePending, advanceRejected, AppConstants, appName, appVersion, attendanceAbsent, attendanceFull (+17 more)

### Community 45 - "sync_screen.dart"
Cohesion: 0.10
Nodes (23): SyncService, _addressCtrl, build, child, _cloudWorking, createState, dispose, initState (+15 more)

### Community 46 - "worker_documents_screen.dart"
Cohesion: 0.08
Nodes (24): ../../core/models/worker_document_model.dart, _buildDocumentList, createState, _deleteDocument, document, _documents, _DocumentTile, documentType (+16 more)

### Community 47 - "workers_list_screen.dart"
Cohesion: 0.08
Nodes (24): ../../core/models/worker_model.dart, build, _buildSearchFilter, createState, _DesktopGrid, dispose, _filtered, initState (+16 more)

### Community 48 - "google_oauth_service.dart"
Cohesion: 0.08
Nodes (24): GoogleSignIn?, displayName, email, _ensureConfigured, _ensureSupported, FirebaseAuthSession, firebaseUid, GoogleOAuthService (+16 more)

### Community 49 - "sites_list_screen.dart"
Cohesion: 0.08
Nodes (24): SiteModel, build, _buildSearchFilter, createState, _DesktopGrid, dispose, _filter, _filtered (+16 more)

### Community 50 - "business_insight_models.dart"
Cohesion: 0.05
Nodes (47): ChangeNotifier, ../../../core/notifications/insights/business_insight_models.dart, ../../../core/notifications/insights/business_insight_provider.dart, ../../../core/repositories/inventory_repository.dart, ../../../core/repositories/payroll_repository.dart, ../../../core/repositories/site_repository.dart, ../../../core/repositories/worker_repository.dart, body (+39 more)

### Community 51 - "analytics_screen.dart"
Cohesion: 0.08
Nodes (26): ../dashboard/dashboard_charts.dart, ../dashboard/dashboard_screen.dart, AnalyticsScreen, _AnalyticsScreenState, _attendance, build, _buildBody, createState (+18 more)

### Community 52 - "NotificationCenterProvider"
Cohesion: 0.25
Nodes (8): NotificationCenterProvider, build, initState, NotificationCenterScreen, _NotificationCenterScreenState, Route /notifications/diagnostics, Route /notifications/insights, Route /notifications/settings

### Community 53 - "windows_background_scheduler.dart"
Cohesion: 0.09
Nodes (21): ../analytics/notification_metrics.dart, @pragma, Duration, initializeBackgroundScheduling, kNotificationTaskName, kNotificationWorkUniqueName, notificationBackgroundCallbackDispatcher, interval (+13 more)

### Community 54 - "package:provider/provider.dart"
Cohesion: 0.15
Nodes (13): core/providers/site_provider.dart, build, createState, dispose, initState, ProductSelectDialog, _ProductSelectDialogState, _qtyControllers (+5 more)

### Community 55 - "notification_rules_registry.dart"
Cohesion: 0.09
Nodes (22): inventory/frequently_used_low_rule.dart, inventory/inventory_audit_reminder_rule.dart, inventory/inventory_thresholds.dart, inventory/material_not_updated_rule.dart, inventory/stock_state_inventory_rule.dart, buildNotificationRules, buildPhase2Rules, inventoryThresholds (+14 more)

### Community 56 - "store_product_model.dart"
Cohesion: 0.09
Nodes (22): barcode, category, colorLabel, copyWith, createdAt, criticalStockThreshold, fromMap, id (+14 more)

### Community 57 - "worker_advance_rule.dart"
Cohesion: 0.33
Nodes (5): evaluate, _fmt, _workerRepository, WorkerRepository, ../models/advance_payment_model.dart

### Community 58 - "firebase_bootstrap.dart"
Cohesion: 0.15
Nodes (12): app_check_service.dart, firebase_config.dart, ../../firebase_options.dart, clientId, configureFirebaseAuth, ensureLoaded, initializeApp, initializeFirebase (+4 more)

### Community 59 - "home_content.dart"
Cohesion: 0.10
Nodes (21): ../../core/services/collection_reminder_service.dart, ../../features/dashboard/dashboard_charts.dart, _activity, _attendance, _bell, createState, _db, HomeContent (+13 more)

### Community 60 - "firebase_config.dart"
Cohesion: 0.09
Nodes (21): google_services_config.dart, androidAppId, androidPackageName, apiKey, ensureLoaded, FirebaseConfig, googleDesktopClientId, GoogleSignInPlatform (+13 more)

### Community 61 - "collections_screen.dart"
Cohesion: 0.17
Nodes (12): ../../core/models/site_model.dart, ../../features/dashboard/dashboard_screen.dart, build, CollectionsScreen, _CollectionsScreenState, createState, _db, initState (+4 more)

### Community 62 - "business_insight_engine.dart"
Cohesion: 0.10
Nodes (20): finance, _fmt, generateAll, generateSummary, inventory, inventoryRepository, _materialShortagePrediction, payments (+12 more)

### Community 63 - "notification_cloud_sync_service.dart"
Cohesion: 0.10
Nodes (20): _clearPending, downloadAndMerge, initForSession, _instance, _isPending, _markPending, NotificationCloudSyncService, _path (+12 more)

### Community 64 - "WorkerProvider"
Cohesion: 0.11
Nodes (19): WorkerProvider, _delete, _generateOrEdit, _load, _markPaid, _save, _AdvancesTab, _AttendanceTab (+11 more)

### Community 65 - "Design System"
Cohesion: 0.40
Nodes (5): Color Palette, Design System, Responsive UI Design Specification, Spacing, Typography

### Community 66 - "app_check_service.dart"
Cohesion: 0.10
Nodes (19): dart:math, activate, _activateAndroidDebug, _activateAndroidRelease, _activated, _activateDesktop, _activateWeb, _androidDebugTokenKey (+11 more)

### Community 67 - "FlutterWindow"
Cohesion: 0.12
Nodes (16): FlutterViewController, unique_ptr, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM (+8 more)

### Community 68 - "worker_model.dart"
Cohesion: 0.11
Nodes (18): address, copyWith, createdAt, dailyRate, fromMap, halfDayRate, id, joinDate (+10 more)

### Community 69 - "site_lifecycle_rule.dart"
Cohesion: 0.11
Nodes (17): evaluate, _fmt, _midnight, _pad, SiteLifecycleRule, _siteRepository, thresholds, _workerRepository (+9 more)

### Community 70 - "State"
Cohesion: 0.15
Nodes (19): _CollapsibleSidebarShell, _CollapsibleSidebarShellState, _PayrollEditDialog, _PayrollEditDialogState, PayrollScreen, _PayrollScreenState, _WorkerPayrollTile, _WorkerPayrollTileState (+11 more)

### Community 71 - "document_file_service.dart"
Cohesion: 0.11
Nodes (18): deleteFiles, _dirName, DocumentFileService, existsLocally, hashFile, ingest, ingestVersion, instance (+10 more)

### Community 72 - "login_screen.dart"
Cohesion: 0.12
Nodes (17): ../../core/constants/app_constants.dart, ../../core/providers/auth_provider.dart, ../../core/theme/responsive.dart, FormState, build, _confirmCtrl, createState, _creatingAccount (+9 more)

### Community 73 - "attendance_screen.dart"
Cohesion: 0.12
Nodes (17): ../../core/models/attendance_model.dart, core/providers/worker_provider.dart, AttendanceScreen, _AttendanceScreenState, build, _buildList, createState, _date (+9 more)

### Community 74 - "../models/notification_model.dart"
Cohesion: 0.15
Nodes (13): DateTime get, cancel, cancelAll, initialize, show, build, now, build (+5 more)

### Community 75 - "document_storage_service.dart"
Cohesion: 0.14
Nodes (13): document_file_service.dart, deleteFromStorage, DocumentStorageService, download, _files, instance, message, processQueue (+5 more)

### Community 76 - "payslip_service.dart"
Cohesion: 0.11
Nodes (17): _buildHeader, _buildNetSalaryBanner, _buildSalaryTable, _buildWorkerInfo, _currency, _formatDate, generatePayslip, _infoRow (+9 more)

### Community 77 - "win32_window.cpp"
Cohesion: 0.18
Nodes (14): Point, Size, wchar_t, Scale(), Create, Destroy, UpdateTheme, Win32Window::Win32Window() (+6 more)

### Community 78 - "bool get"
Cohesion: 0.12
Nodes (16): bool get, AttendanceModel, copyWith, createdAt, date, fromMap, id, isAbsent (+8 more)

### Community 79 - "static const"
Cohesion: 0.22
Nodes (8): _key, _load, _mode, setMode, toggle, static const, ThemeMode, ThemeMode get

### Community 80 - "advance_payment_model.dart"
Cohesion: 0.12
Nodes (16): AdvancePaymentModel, amount, approvedDate, copyWith, createdAt, fromMap, id, isApproved (+8 more)

### Community 81 - "store_product_provider.dart"
Cohesion: 0.12
Nodes (16): addProduct, addStock, clear, _cloud, deleteProduct, _error, findByBarcode, _generation (+8 more)

### Community 82 - "document_permissions.dart"
Cohesion: 0.12
Nodes (16): body, _Copy, DocumentPermissions, _ensure, _explain, instance, _PermUse, requestCamera (+8 more)

### Community 83 - "main.dart"
Cohesion: 0.12
Nodes (15): app.dart, core/firebase/firebase_bootstrap.dart, core/firebase/firebase_cloud_service.dart, core/notifications/background/background_notification_callback.dart, core/providers/store_product_provider.dart, core/providers/theme_provider.dart, core/sync/sync_service.dart, features/documents/services/document_permissions.dart (+7 more)

### Community 84 - "stock_screen.dart"
Cohesion: 0.10
Nodes (23): ../../core/models/store_product_model.dart, StoreProductProvider, _load, build, initState, _showAddDialog, _showEditDialog, build (+15 more)

### Community 85 - "services_screen.dart"
Cohesion: 0.15
Nodes (16): ../../core/models/user_service_model.dart, core/providers/user_service_provider.dart, UserService, UserServiceProvider, build, createState, _deleteService, initState (+8 more)

### Community 86 - "site_product_model.dart"
Cohesion: 0.12
Nodes (15): double?, double get, copyWith, createdAt, fromMap, id, productId, productName (+7 more)

### Community 87 - "NotificationRule"
Cohesion: 0.13
Nodes (16): NotificationRule, ConstructionPaymentRule, evaluate, _siteRepository, CustomerPaymentRule, evaluate, _siteRepository, PayrollReminderRule (+8 more)

### Community 88 - "smart_summary_rule.dart"
Cohesion: 0.12
Nodes (15): BriefingMode, briefingTime, evaluate, inventoryRepository, isEnabled, mode, monthlyDay, payrollRepository (+7 more)

### Community 89 - "worker_lifecycle_rule.dart"
Cohesion: 0.10
Nodes (19): buildEngineWithAllRules, engine, _anniversaryThisYear, _consecutiveAbsences, evaluate, _fmt, _midnight, _monthsBetween (+11 more)

### Community 90 - "List"
Cohesion: 0.13
Nodes (15): class, ../../core/notifications/analytics/notification_metrics.dart, core/notifications/background/windows_background_scheduler.dart, build, createState, _fmt, initState, label (+7 more)

### Community 91 - "payroll_reminder_rule.dart"
Cohesion: 0.10
Nodes (19): _, _build, evaluate, month, monthEnd, Optimistic, _payrollRepository, evaluate (+11 more)

### Community 92 - "notification_logger.dart"
Cohesion: 0.14
Nodes (14): dart:developer, error, info, instance, Level, LevelX, _log, minLevel (+6 more)

### Community 93 - "notification_action_handler.dart"
Cohesion: 0.13
Nodes (14): deepLinkRouteFor, handle, history, navigate, NotificationActionHandler, notificationFromRecord, openExternal, _performRoute (+6 more)

### Community 94 - "auth_repository.dart"
Cohesion: 0.15
Nodes (12): activeUserId, authenticate, AuthRepository, createAccount, createUser, _db, ensureGoogleLocalAccount, ensureLocalAccount (+4 more)

### Community 95 - "worker_performance_model.dart"
Cohesion: 0.14
Nodes (13): attendancePercentage, completedWorkDays, copyWith, createdAt, fromMap, id, lateArrivals, month (+5 more)

### Community 96 - "Dashboard Content"
Cohesion: 0.67
Nodes (3): Dashboard Charts, Dashboard Content, Metric Grid

### Community 97 - "inventory_repository.dart"
Cohesion: 0.14
Nodes (13): addStock, _db, deductStoreStock, deleteStoreProduct, getAllStoreProducts, getStockAlertProducts, getStoreProductByBarcode, getStoreProductById (+5 more)

### Community 98 - "collection_reminder_service.dart"
Cohesion: 0.15
Nodes (12): ../constants/app_constants.dart, CollectionReminderService, initialize, _initialized, instance, _notifications, requestPermissions, _showNotification (+4 more)

### Community 99 - "document_repository.dart"
Cohesion: 0.15
Nodes (12): core/database/database_helper.dart, byUuid, _db, DocumentRepository, hardDelete, insert, list, needingSync (+4 more)

### Community 100 - "String get"
Cohesion: 0.14
Nodes (13): int get, actionId, category, fromMap, hashCode, icon, label, NotificationAction (+5 more)

### Community 101 - "notification_action_catalog.dart"
Cohesion: 0.17
Nodes (11): _, actionsFor, _general, _inventory, NotificationActionCatalog, _payment, _service, _site (+3 more)

### Community 102 - "firebase_auth_listener.dart"
Cohesion: 0.17
Nodes (11): dart:async, _authStateSubscription, FirebaseAuthListener, FirebaseAuthUserHandler, _idTokenSubscription, instance, start, stop (+3 more)

### Community 103 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 105 - "construction_payment_model.dart"
Cohesion: 0.17
Nodes (11): amount, ConstructionPaymentModel, copyWith, createdAt, fromMap, id, notes, paymentDate (+3 more)

### Community 106 - "product_model.dart"
Cohesion: 0.17
Nodes (11): copyWith, createdAt, deliveryDate, fromMap, id, name, ProductModel, quantity (+3 more)

### Community 107 - "document_thumbnail.dart"
Cohesion: 0.17
Nodes (11): DocumentModel, _AsyncImage, build, doc, DocumentThumbnail, _iconFor, _resolve, size (+3 more)

### Community 108 - "Win32Window"
Cohesion: 0.21
Nodes (12): RECT, OnCreate, HWND, Win32Window, child_content_, GetClientArea, OnCreate, quit_on_close_ (+4 more)

### Community 109 - "DateTime"
Cohesion: 0.11
Nodes (18): DateTime, int?, createdAt, fromMap, id, passwordHash, role, toMap (+10 more)

### Community 110 - "site_service_model.dart"
Cohesion: 0.18
Nodes (10): copyWith, createdAt, fromMap, id, rate, serviceName, siteId, SiteService (+2 more)

### Community 111 - "worker_document_model.dart"
Cohesion: 0.18
Nodes (10): copyWith, documentType, fileName, filePath, fromMap, id, toMap, uploadedAt (+2 more)

### Community 112 - "google_services_config.dart"
Cohesion: 0.18
Nodes (10): dart:convert, _extractWebClientId, GoogleServicesConfig, load, _loaded, _webClientId, package:flutter/services.dart, static bool (+2 more)

### Community 114 - "dart:io"
Cohesion: 0.12
Nodes (15): dart:io, _create, _instance, PlatformNotificationServiceFactory, scheduler, NotificationScheduler, platform, prepareBackground (+7 more)

### Community 115 - "Map"
Cohesion: 0.20
Nodes (9): advanceMonthlyLimit, anniversaryReminderDays, consecutiveAbsenceLimit, documentValidityMonths, longUnpaidMonths, performanceAttendanceWarning, performanceRatingWarning, WorkerThresholds (+1 more)

### Community 116 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 117 - "graphify reference: extra exports and benchmark"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 118 - "notification_settings_repository.dart"
Cohesion: 0.25
Nodes (7): create, _key, load, _prefs, save, SharedPreferences, static const String

### Community 119 - "background_task_coordinator.dart"
Cohesion: 0.22
Nodes (8): engine/notification_engine.dart, BackgroundTaskCoordinator, dispose, engine, prepare, _prepared, runInBackground, NotificationEngine

### Community 120 - "reminder_window.dart"
Cohesion: 0.22
Nodes (8): days, due, isOverdueWindow, PaymentReminderWindow, priorityForWindow, today, windowForDueDate, windowLabel

### Community 121 - "package:flutter/material.dart"
Cohesion: 0.20
Nodes (9): AppTheme, attendanceColor, darkTheme, lightTheme, _secondary, _seed, statusColor, package:flutter/material.dart (+1 more)

### Community 122 - "package:go_router/go_router.dart"
Cohesion: 0.22
Nodes (8): ../actions/notification_action_handler.dart, GoRouter, GoRouterNotificationRouter, openExternal, _router, NotificationRouter, package:go_router/go_router.dart, package:url_launcher/url_launcher.dart

### Community 123 - "NOTIFICATIONS_ARCHITECTURE.md"
Cohesion: 0.25
Nodes (7): Background scheduling, Cross-device sync (Phase 12), Diagnostics (Phase 10), Interactive actions (Phase 9), Key types, Pipeline, Security notes

### Community 124 - "System Architecture — Worklist"
Cohesion: 0.22
Nodes (8): Data model (per user_id), Firebase sync (verified), High-level layers, Performance characteristics (stress-tested), Security posture, SQLite integrity (verified), System Architecture — Worklist, UI / responsiveness

### Community 125 - "package:flutter/foundation.dart"
Cohesion: 0.25
Nodes (7): android, DefaultFirebaseOptions, web, windows, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions

### Community 126 - "BootReceiver"
Cohesion: 0.33
Nodes (4): BootReceiver, BroadcastReceiver, Context, Intent

### Community 127 - "build"
Cohesion: 0.40
Nodes (5): build, Route /attendance, Route /collections, Route /products, Route /stock

### Community 132 - "Worklist — Site & Worker Management"
Cohesion: 0.25
Nodes (7): Architecture (summary), Documentation, License, Platforms, Quick start, Release artifacts, Worklist — Site & Worker Management

### Community 134 - "package:shared_preferences/shared_preferences.dart"
Cohesion: 0.29
Nodes (6): clearActiveUsername, loadActiveUsername, saveActiveUsername, SessionStorage, _usernameKey, package:shared_preferences/shared_preferences.dart

### Community 135 - "graphify reference: query, path, explain"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 142 - "Changelog — Worklist"
Cohesion: 0.40
Nodes (4): 1.0.0 — Initial, 1.4.0 — Notification framework (Phases 1–12, prior sprints), 1.4.1+8 — 2026-07-13 (FINAL RELEASE), Changelog — Worklist

### Community 143 - "Release Notes — Worklist"
Cohesion: 0.40
Nodes (4): Known Limitations, Release Highlights, Release Notes — Worklist, What Was Verified

### Community 144 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 145 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 146 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

### Community 147 - "Exception"
Cohesion: 0.50
Nodes (4): Exception, _SyncHttpException, DocumentFormatException, DocumentStorageException

## Knowledge Gaps
- **2165 isolated node(s):** `_router`, `_handlerWired`, `createState`, `didChangeDependencies`, `_wireActionHandler` (+2160 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WorkerProvider` connect `WorkerProvider` to `worker_form_screen.dart`, `worker_provider.dart`, `site_detail_screen.dart`, `State`, `attendance_screen.dart`, `dashboard_screen.dart`, `payroll_screen.dart`, `sync_screen.dart`, `worker_documents_screen.dart`, `workers_list_screen.dart`, `business_insight_models.dart`, `worker_detail_screen.dart`, `worker_performance_screen.dart`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `AuthProvider` connect `AuthProvider` to `site_detail_screen.dart`, `State`, `auth_provider.dart`, `login_screen.dart`, `dashboard_screen.dart`, `sync_screen.dart`, `app.dart`, `business_insight_models.dart`, `shared_widgets.dart`, `home_content.dart`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `SiteProvider` connect `site_detail_screen.dart` to `State`, `site_provider.dart`, `site_form_screen.dart`, `attendance_screen.dart`, `dashboard_screen.dart`, `sync_screen.dart`, `StatelessWidget`, `_SiteFormScreenState`, `business_insight_models.dart`, `sites_list_screen.dart`, `package:provider/provider.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `_router`, `_handlerWired`, `createState` to the rest of the system?**
  _2165 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `database_helper.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.015037593984962405 - nodes in this community are weakly interconnected._
- **Should `responsive.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0273972602739726 - nodes in this community are weakly interconnected._
- **Should `firebase_cloud_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.030303030303030304 - nodes in this community are weakly interconnected._