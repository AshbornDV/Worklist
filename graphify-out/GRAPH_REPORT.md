# Graph Report - Site and worker management app  (2026-11-16)

## Corpus Check
- 172 files · ~107,880 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 20 file(s) not represented in the graph (top: .xml 7, (none) 4, .properties 3)

## Summary
- 3228 nodes · 4405 edges · 145 communities (126 shown, 19 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 15 edges (avg confidence: 0.86)
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
- dependencies
- products_screen.dart
- firebase_diagnostics.dart
- StatelessWidget
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
- build
- windows_background_scheduler.dart
- WorkerProvider
- notification_rules_registry.dart
- store_product_model.dart
- business_insight_provider.dart
- firebase_bootstrap.dart
- home_content.dart
- firebase_config.dart
- collections_screen.dart
- business_insight_engine.dart
- notification_cloud_sync_service.dart
- DateTime
- Design System
- app_check_service.dart
- FlutterWindow
- worker_model.dart
- FlutterWindow::OnCreate
- State
- document_file_service.dart
- login_screen.dart
- attendance_screen.dart
- notification_scheduler.dart
- document_storage_service.dart
- payslip_service.dart
- WindowClassRegistrar
- bool get
- static const
- advance_payment_model.dart
- List
- document_permissions.dart
- main.dart
- stock_screen.dart
- services_screen.dart
- site_product_model.dart
- NotificationRule
- smart_summary_rule.dart
- worker_lifecycle_rule.dart
- ../notification_rule.dart
- ../models/notification_model.dart
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
- utils.cpp
- analysis_options.yaml
- construction_payment_model.dart
- product_model.dart
- document_thumbnail.dart
- Win32Window
- int?
- site_service_model.dart
- worker_document_model.dart
- google_services_config.dart
- AI token baseline — captured 2026-11-16
- _MapPickerDialog
- Map
- win32_window.cpp
- Point
- notification_settings_repository.dart
- _SiteFormScreenState
- ../models/notification_model.dart
- package:flutter/material.dart
- package:go_router/go_router.dart
- skill_gate.py
- System Architecture — Worklist
- package:flutter/foundation.dart
- BootReceiver.kt
- NotificationPriority
- MainActivity
- widget_test.dart
- Worklist — Site & Worker Management
- ScreenSize
- Bottom Navigation
- Changelog — Worklist
- Release Notes — Worklist
- AGENTS.md
- Sidebar

## God Nodes (most connected - your core abstractions)
1. `_` - 83 edges
2. `WorkerProvider` - 51 edges
3. `SiteProvider` - 46 edges
4. `AuthProvider` - 34 edges
5. `dependencies` - 33 edges
6. `Win32Window` - 27 edges
7. `StoreProductProvider` - 21 edges
8. `DocumentProvider` - 18 edges
9. `_` - 15 edges
10. `_` - 13 edges

## Surprising Connections (you probably didn't know these)
- `Key types` --references--> `evaluate()`  [INFERRED]
  NOTIFICATIONS_ARCHITECTURE.md → .codex/hooks/skill_gate.py
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `_deleteDocument` --references--> `WorkerProvider`  [EXTRACTED]
  lib/features/workers/worker_documents_screen.dart → lib/core/providers/worker_provider.dart
- `_loadDocuments` --references--> `WorkerProvider`  [EXTRACTED]
  lib/features/workers/worker_documents_screen.dart → lib/core/providers/worker_provider.dart
- `_uploadDocument` --references--> `WorkerProvider`  [EXTRACTED]
  lib/features/workers/worker_documents_screen.dart → lib/core/providers/worker_provider.dart

## Import Cycles
- None detected.

## Communities (145 total, 19 thin omitted)

### Community 0 - "database_helper.dart"
Cohesion: 0.01
Nodes (128): _activeUserId, _addColumnIfMissing, addStock, approveAdvance, assignWorkerToSite, authenticate, countUserRecords, createAccount (+120 more)

### Community 1 - "responsive.dart"
Cohesion: 0.03
Nodes (67): _, AdaptiveGrid, all, base, baseFontSize, build, centeredForm, child (+59 more)

### Community 2 - "firebase_cloud_service.dart"
Cohesion: 0.03
Nodes (59): applySession, _auth, _authenticate, _authMessage, _backoffDelay, _cleanAccount, _clearPendingSync, clearSession (+51 more)

### Community 3 - "worker_provider.dart"
Cohesion: 0.03
Nodes (58): activeWorkerCount, addWorker, addWorkerDocument, addWorkerPerformance, _advances, approveAdvance, _attendanceRecords, calculatePaycheck (+50 more)

### Community 4 - "calendar_screen.dart"
Cohesion: 0.03
Nodes (66): active, _activeFilters, _AgendaCard, _allCategories, _attendanceLabel, _attendanceSubtitle, build, _buildBody (+58 more)

### Community 5 - "site_detail_screen.dart"
Cohesion: 0.05
Nodes (45): SiteProvider, _TabletRailShell, amount, bold, build, color, createState, _delete (+37 more)

### Community 6 - "site_provider.dart"
Cohesion: 0.04
Nodes (50): activeSiteCount, addConstructionPayment, addProduct, addSite, addSiteService, assignWorker, clear, clearError (+42 more)

### Community 7 - "site_form_screen.dart"
Cohesion: 0.04
Nodes (45): _advance, _area, _areaUnits, _budget, _cost, createState, dispose, _effectiveLastPaidDate (+37 more)

### Community 8 - "auth_provider.dart"
Cohesion: 0.04
Nodes (41): _auth, _autoPull, _autoPullInterval, _autoPullTimer, clearError, _cloud, _cloudDataVersion, cloudEmail (+33 more)

### Community 9 - "notification_metrics.dart"
Cohesion: 0.04
Nodes (47): _avgExecutionMs, _daily, _dailyRetentionDays, _dayKey, devLog, DiagnosticLogEntry, ensureLoaded, _executionCount (+39 more)

### Community 10 - "user_service_provider.dart"
Cohesion: 0.09
Nodes (19): countUserRecords, DashboardRepository, _db, exportUserData, getAttendanceChartData, getDashboardStats, getExpensesChartData, getMaterialUsageChartData (+11 more)

### Community 11 - "document_model.dart"
Cohesion: 0.04
Nodes (39): apiValue, category, copyWith, createdAt, deletedAt, DocumentKind, DocumentSyncStatus, entityId (+31 more)

### Community 12 - "dashboard_screen.dart"
Cohesion: 0.06
Nodes (28): 0, activeIcon, _bottomNavItems, build, child, createState, cs, expanded (+20 more)

### Community 13 - "payroll_screen.dart"
Cohesion: 0.04
Nodes (46): _AmountColumn, _baseWage, bold, _bonus, _bonusAmt, build, _buildActions, _changeMonth (+38 more)

### Community 14 - "StatelessWidget"
Cohesion: 0.07
Nodes (28): AttendanceChart, build, color, data, dateStr, _EmptyChart, ExpensesChart, _formatChartCurrency (+20 more)

### Community 15 - "notification_history_repository.dart"
Cohesion: 0.05
Nodes (43): archive, archivedAt, body, copyWith, create, createdAt, delete, deleteAll (+35 more)

### Community 16 - "document_provider.dart"
Cohesion: 0.05
Nodes (35): _applyView, availableCategories, captureFromCamera, _docs, ensureLocal, _error, _files, _filterCategory (+27 more)

### Community 17 - "app.dart"
Cohesion: 0.06
Nodes (5): createState, didChangeDependencies, _handlerWired, _router, _wireActionHandler

### Community 18 - "dependencies"
Cohesion: 0.04
Nodes (47): dependencies, barcode_widget, crypto, file_picker, firebase_app_check, firebase_auth, firebase_core, firebase_database (+39 more)

### Community 19 - "products_screen.dart"
Cohesion: 0.05
Nodes (33): activeFilters, _activeFiltersLabel, _applyFilters, _cleanOrNull, _clearFilters, controller, createState, _criticalStockThreshold (+25 more)

### Community 20 - "firebase_diagnostics.dart"
Cohesion: 0.12
Nodes (11): _checkAppCheck, _checkAuthentication, _checkConfig, _checkConnectivity, _checkFirebaseInitialization, _checkPlatform, _checkRealtimeDatabase, _checkRealtimeDatabaseRest (+3 more)

### Community 21 - "StatelessWidget"
Cohesion: 0.12
Nodes (15): _AppLogo, _BottomBarItem, DashboardScreen, _MobileLayout, _SidebarTile, _SidebarToggle, _ConstructionPaymentsSection, _FinancialCard (+7 more)

### Community 22 - "site_model.dart"
Cohesion: 0.05
Nodes (36): advanceReceived, area, balance, budget, collectionReminderDays, completionPercentage, constructionPaid, copyWith (+28 more)

### Community 23 - "shared_widgets.dart"
Cohesion: 0.06
Nodes (29): action, amount, bgColor, build, compact, confirmText, destructive, false (+21 more)

### Community 24 - "worker_detail_screen.dart"
Cohesion: 0.05
Nodes (36): WorkerPaycheck, advance, _AdvanceTile, amount, bold, _changeMonth, color, createState (+28 more)

### Community 25 - "notification_model.dart"
Cohesion: 0.07
Nodes (31): actions, AppNotification, body, copyWith, createdAt, deliveredAt, dismissedAt, entityId (+23 more)

### Community 26 - "document_detail_screen.dart"
Cohesion: 0.08
Nodes (32): DocumentProvider, _Actions, build, _busy, createState, _delete, doc, DocumentDetailScreen (+24 more)

### Community 27 - "inventory_audit_reminder_rule.dart"
Cohesion: 0.09
Nodes (25): evaluate, FrequentlyUsedLowRule, _inventoryRepository, thresholds, _cycleBucket, evaluate, InventoryAuditReminderRule, _inventoryRepository (+17 more)

### Community 28 - "notification_center_provider.dart"
Cohesion: 0.06
Nodes (29): _all, archive, _category, categoryFilter, _compare, delete, deleteAll, dismiss (+21 more)

### Community 29 - "android_notification_service.dart"
Cohesion: 0.07
Nodes (25): actionHandler, cancel, cancelAll, _importance, initialize, _initialized, instance, _onResponse (+17 more)

### Community 30 - "worker_performance_screen.dart"
Cohesion: 0.06
Nodes (31): _attendancePercentage, _buildPerformanceList, color, _completedWorkDays, createState, dispose, _editPerformance, _EmptyState (+23 more)

### Community 31 - "notification_settings.dart"
Cohesion: 0.06
Nodes (31): attendance, copyWith, dailyBriefingTime, dailySummary, _decodeTime, _encodeTime, fromJson, inventory (+23 more)

### Community 32 - "worker_repository.dart"
Cohesion: 0.06
Nodes (29): approveAdvance, _db, deleteWorker, deleteWorkerDocument, deleteWorkerDocumentsByWorker, deleteWorkerPerformance, deleteWorkerPerformanceByWorker, getAdvancesByWorker (+21 more)

### Community 33 - "worker_form_screen.dart"
Cohesion: 0.06
Nodes (30): _address, createState, _dailyRate, dispose, _formKey, _initialLoad, initState, _isEditing (+22 more)

### Community 34 - "Architecture Refactor — Layered Repository Plan"
Cohesion: 0.09
Nodes (21): 1. `auth_repository.dart` — `AuthRepository`, 2. `site_repository.dart` — `SiteRepository`, 3. `worker_repository.dart` — `WorkerRepository`, 4. `payroll_repository.dart` — `PayrollRepository`, 5. `inventory_repository.dart` — `InventoryRepository`, 6. `service_repository.dart` — `ServiceRepository`, 7. `dashboard_repository.dart` — `DashboardRepository`, Architecture (before → after) (+13 more)

### Community 35 - "notification_engine.dart"
Cohesion: 0.07
Nodes (23): BackgroundTaskCoordinator, dispose, engine, prepare, _prepared, runInBackground, create, _history (+15 more)

### Community 36 - "sync_service.dart"
Cohesion: 0.06
Nodes (27): _auth, _authenticateBody, _busy, defaultPort, _handleRequest, isBusy, isRunning, loadServerAddress (+19 more)

### Community 37 - "site_repository.dart"
Cohesion: 0.07
Nodes (26): assignWorkerToSite, _db, deleteConstructionPayment, deleteProduct, deleteSite, deleteSiteProduct, deleteSiteService, getAllSites (+18 more)

### Community 38 - "documents_screen.dart"
Cohesion: 0.07
Nodes (26): DocumentEntityType, DocumentSort, build, _categoryDialog, _confirm, createState, doc, DocumentsScreen (+18 more)

### Community 39 - "payroll_model.dart"
Cohesion: 0.07
Nodes (28): advanceAmount, baseWage, bonus, copyWith, createdAt, dailyRate, deductions, fromMap (+20 more)

### Community 40 - "AuthProvider"
Cohesion: 0.10
Nodes (25): _buildRouter, AuthProvider, AccountScreen, _AccountScreenState, build, color, createState, _formatTime (+17 more)

### Community 41 - "notifications.dart"
Cohesion: 0.06
Nodes (5): worklist_notifications, _create, _instance, PlatformNotificationServiceFactory, scheduler

### Community 42 - "notification_settings_screen.dart"
Cohesion: 0.08
Nodes (23): NotificationSettingsRepository, build, _CategoryToggle, createState, _days, _fmt, initState, label (+15 more)

### Community 43 - "notification_center_screen.dart"
Cohesion: 0.07
Nodes (27): NotificationCenterProvider, NotificationGroupBy, NotificationSort, NotificationRecord, _buildBody, _categories, _categoryLabel, _confirm (+19 more)

### Community 44 - "app_constants.dart"
Cohesion: 0.08
Nodes (24): advanceApproved, advancePending, advanceRejected, AppConstants, appName, appVersion, attendanceAbsent, attendanceFull (+16 more)

### Community 45 - "sync_screen.dart"
Cohesion: 0.09
Nodes (25): BusinessInsightProvider, SyncService, _addressCtrl, build, child, _cloudWorking, createState, dispose (+17 more)

### Community 46 - "worker_documents_screen.dart"
Cohesion: 0.08
Nodes (21): _buildDocumentList, createState, _deleteDocument, document, _documents, _DocumentTile, documentType, _DocumentTypeCard (+13 more)

### Community 47 - "workers_list_screen.dart"
Cohesion: 0.08
Nodes (21): build, _buildSearchFilter, createState, _DesktopGrid, dispose, _filtered, initState, isSelected (+13 more)

### Community 48 - "google_oauth_service.dart"
Cohesion: 0.08
Nodes (21): displayName, email, _ensureConfigured, _ensureSupported, FirebaseAuthSession, firebaseUid, GoogleOAuthService, _googleSignIn (+13 more)

### Community 49 - "sites_list_screen.dart"
Cohesion: 0.08
Nodes (22): SiteModel, build, _buildSearchFilter, createState, _DesktopGrid, dispose, _filter, _filtered (+14 more)

### Community 50 - "business_insight_models.dart"
Cohesion: 0.05
Nodes (39): body, BusinessInsight, copyWith, deepLink, deepLinkArgs, domain, entityId, entityType (+31 more)

### Community 51 - "analytics_screen.dart"
Cohesion: 0.08
Nodes (23): AnalyticsScreen, _AnalyticsScreenState, _attendance, build, _buildBody, createState, _db, _error (+15 more)

### Community 53 - "windows_background_scheduler.dart"
Cohesion: 0.09
Nodes (14): initializeBackgroundScheduling, kNotificationTaskName, kNotificationWorkUniqueName, notificationBackgroundCallbackDispatcher, interval, isBackgroundSupported, isRunning, registerStartup (+6 more)

### Community 54 - "WorkerProvider"
Cohesion: 0.10
Nodes (20): WorkerProvider, _delete, _generateOrEdit, _load, _markPaid, _save, _AdvancesTab, _AttendanceTab (+12 more)

### Community 55 - "notification_rules_registry.dart"
Cohesion: 0.07
Nodes (11): buildNotificationRules, buildPhase2Rules, inventoryThresholds, settings, siteThresholds, workerThresholds, completionNear1, completionNear2 (+3 more)

### Community 56 - "store_product_model.dart"
Cohesion: 0.09
Nodes (22): barcode, category, colorLabel, copyWith, createdAt, criticalStockThreshold, fromMap, id (+14 more)

### Community 57 - "business_insight_provider.dart"
Cohesion: 0.14
Nodes (11): BusinessInsightEngine, _engine, _error, forDomain, _insights, isLoading, load, _loading (+3 more)

### Community 58 - "firebase_bootstrap.dart"
Cohesion: 0.15
Nodes (7): clientId, configureFirebaseAuth, ensureLoaded, initializeApp, initializeFirebase, _initializeGoogleSignIn, register

### Community 59 - "home_content.dart"
Cohesion: 0.07
Nodes (23): build, ThemeProvider, _activity, _attendance, _bell, build, createState, _db (+15 more)

### Community 60 - "firebase_config.dart"
Cohesion: 0.09
Nodes (19): androidAppId, androidPackageName, apiKey, ensureLoaded, FirebaseConfig, googleDesktopClientId, GoogleSignInPlatform, googleSignInStatusLabel (+11 more)

### Community 61 - "collections_screen.dart"
Cohesion: 0.17
Nodes (9): build, CollectionsScreen, _CollectionsScreenState, createState, _db, initState, _load, _loading (+1 more)

### Community 62 - "business_insight_engine.dart"
Cohesion: 0.10
Nodes (19): finance, _fmt, generateAll, generateSummary, inventory, inventoryRepository, _materialShortagePrediction, payments (+11 more)

### Community 63 - "notification_cloud_sync_service.dart"
Cohesion: 0.10
Nodes (17): _clearPending, downloadAndMerge, initForSession, _instance, _isPending, _markPending, NotificationCloudSyncService, _path (+9 more)

### Community 64 - "DateTime"
Cohesion: 0.20
Nodes (8): createdAt, fromMap, id, passwordHash, role, toMap, UserModel, username

### Community 65 - "Design System"
Cohesion: 0.40
Nodes (5): Color Palette, Design System, Responsive UI Design Specification, Spacing, Typography

### Community 66 - "app_check_service.dart"
Cohesion: 0.10
Nodes (17): activate, _activateAndroidDebug, _activateAndroidRelease, _activated, _activateDesktop, _activateWeb, _androidDebugTokenKey, AppCheckService (+9 more)

### Community 67 - "FlutterWindow"
Cohesion: 0.11
Nodes (6): FlutterWindow::OnDestroy(), FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_, Win32Window::OnDestroy()

### Community 68 - "worker_model.dart"
Cohesion: 0.11
Nodes (18): address, copyWith, createdAt, dailyRate, fromMap, halfDayRate, id, joinDate (+10 more)

### Community 69 - "FlutterWindow::OnCreate"
Cohesion: 0.40
Nodes (3): RegisterPlugins(), FlutterWindow::OnCreate(), Win32Window::OnCreate()

### Community 70 - "State"
Cohesion: 0.23
Nodes (10): SiteWorkerManagerApp, _SiteWorkerManagerAppState, _DebugTokenCard, _DebugTokenCardState, _CollapsibleSidebarShell, _CollapsibleSidebarShellState, _WorkerPayrollTile, _WorkerPayrollTileState (+2 more)

### Community 71 - "document_file_service.dart"
Cohesion: 0.10
Nodes (15): deleteFiles, _dirName, DocumentFileService, DocumentFormatException, existsLocally, hashFile, ingest, ingestVersion (+7 more)

### Community 72 - "login_screen.dart"
Cohesion: 0.12
Nodes (12): build, _confirmCtrl, createState, _creatingAccount, dispose, _formKey, LoginScreen, _LoginScreenState (+4 more)

### Community 73 - "attendance_screen.dart"
Cohesion: 0.12
Nodes (15): AttendanceScreen, _AttendanceScreenState, build, _buildList, createState, _date, _dateKey, initState (+7 more)

### Community 74 - "notification_scheduler.dart"
Cohesion: 0.14
Nodes (11): AndroidNotificationService, cancel, cancelAll, initialize, PlatformNotificationService, show, WindowsNotificationService, NotificationScheduler (+3 more)

### Community 75 - "document_storage_service.dart"
Cohesion: 0.13
Nodes (11): deleteFromStorage, DocumentStorageException, DocumentStorageService, download, _files, instance, message, processQueue (+3 more)

### Community 76 - "payslip_service.dart"
Cohesion: 0.11
Nodes (12): _buildHeader, _buildNetSalaryBanner, _buildSalaryTable, _buildWorkerInfo, _currency, _formatDate, generatePayslip, _infoRow (+4 more)

### Community 77 - "WindowClassRegistrar"
Cohesion: 0.25
Nodes (3): WindowClassRegistrar, class_registered_, instance_

### Community 78 - "bool get"
Cohesion: 0.12
Nodes (15): AttendanceModel, copyWith, createdAt, date, fromMap, id, isAbsent, isFull (+7 more)

### Community 79 - "static const"
Cohesion: 0.12
Nodes (10): clearActiveUsername, loadActiveUsername, saveActiveUsername, SessionStorage, _usernameKey, _key, _load, _mode (+2 more)

### Community 80 - "advance_payment_model.dart"
Cohesion: 0.12
Nodes (16): AdvancePaymentModel, amount, approvedDate, copyWith, createdAt, fromMap, id, isApproved (+8 more)

### Community 81 - "List"
Cohesion: 0.05
Nodes (38): addProduct, addStock, clear, _cloud, deleteProduct, _error, findByBarcode, _generation (+30 more)

### Community 82 - "document_permissions.dart"
Cohesion: 0.12
Nodes (14): body, _Copy, DocumentPermissions, _ensure, _explain, instance, _PermUse, requestCamera (+6 more)

### Community 83 - "main.dart"
Cohesion: 0.12
Nodes (5): authProvider, initialize, initializeFirebase, main, _requestPermissions

### Community 84 - "stock_screen.dart"
Cohesion: 0.07
Nodes (33): StoreProductProvider, _load, build, initState, _showAddDialog, _showEditDialog, build, createState (+25 more)

### Community 85 - "services_screen.dart"
Cohesion: 0.15
Nodes (13): UserService, UserServiceProvider, build, createState, _deleteService, initState, onDelete, service (+5 more)

### Community 86 - "site_product_model.dart"
Cohesion: 0.12
Nodes (13): copyWith, createdAt, fromMap, id, productId, productName, productRate, productUnit (+5 more)

### Community 87 - "NotificationRule"
Cohesion: 0.08
Nodes (24): NotificationRule, ConstructionPaymentRule, evaluate, _siteRepository, CustomerPaymentRule, evaluate, _siteRepository, PayrollReminderRule (+16 more)

### Community 88 - "smart_summary_rule.dart"
Cohesion: 0.12
Nodes (14): BriefingMode, briefingTime, evaluate, inventoryRepository, isEnabled, mode, monthlyDay, payrollRepository (+6 more)

### Community 89 - "worker_lifecycle_rule.dart"
Cohesion: 0.08
Nodes (17): buildEngineWithAllRules, engine, evaluate, _fmt, _workerRepository, _anniversaryThisYear, _consecutiveAbsences, evaluate (+9 more)

### Community 90 - "../notification_rule.dart"
Cohesion: 0.29
Nodes (4): build, now, build, now

### Community 91 - "../models/notification_model.dart"
Cohesion: 0.10
Nodes (17): _, _build, evaluate, month, monthEnd, Optimistic, _payrollRepository, evaluate (+9 more)

### Community 92 - "notification_logger.dart"
Cohesion: 0.13
Nodes (12): error, info, instance, Level, LevelX, _log, minLevel, name (+4 more)

### Community 93 - "notification_action_handler.dart"
Cohesion: 0.13
Nodes (13): deepLinkRouteFor, handle, history, navigate, NotificationActionHandler, notificationFromRecord, openExternal, _performRoute (+5 more)

### Community 94 - "auth_repository.dart"
Cohesion: 0.15
Nodes (11): activeUserId, authenticate, AuthRepository, createAccount, createUser, _db, ensureGoogleLocalAccount, ensureLocalAccount (+3 more)

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
Nodes (8): CollectionReminderService, initialize, _initialized, instance, _notifications, requestPermissions, _showNotification, syncReminders

### Community 99 - "document_repository.dart"
Cohesion: 0.15
Nodes (11): byUuid, _db, DocumentRepository, hardDelete, insert, list, needingSync, restore (+3 more)

### Community 100 - "String get"
Cohesion: 0.15
Nodes (11): actionId, category, fromMap, hashCode, icon, label, NotificationAction, NotificationActionCategory (+3 more)

### Community 101 - "notification_action_catalog.dart"
Cohesion: 0.18
Nodes (9): _, actionsFor, _general, _inventory, NotificationActionCatalog, _payment, _service, _site (+1 more)

### Community 102 - "firebase_auth_listener.dart"
Cohesion: 0.18
Nodes (7): _authStateSubscription, FirebaseAuthListener, FirebaseAuthUserHandler, _idTokenSubscription, instance, start, stop

### Community 103 - "utils.cpp"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 104 - "analysis_options.yaml"
Cohesion: 0.50
Nodes (3): include, linter, rules

### Community 105 - "construction_payment_model.dart"
Cohesion: 0.17
Nodes (11): amount, ConstructionPaymentModel, copyWith, createdAt, fromMap, id, notes, paymentDate (+3 more)

### Community 106 - "product_model.dart"
Cohesion: 0.17
Nodes (11): copyWith, createdAt, deliveryDate, fromMap, id, name, ProductModel, quantity (+3 more)

### Community 107 - "document_thumbnail.dart"
Cohesion: 0.17
Nodes (9): DocumentModel, _AsyncImage, build, doc, DocumentThumbnail, _iconFor, _resolve, size (+1 more)

### Community 108 - "Win32Window"
Cohesion: 0.12
Nodes (9): Win32Window::Destroy(), Win32Window::GetClientArea(), Win32Window, child_content_, quit_on_close_, Size, height, width (+1 more)

### Community 109 - "int?"
Cohesion: 0.20
Nodes (8): copyWith, createdAt, fromMap, id, name, rate, toMap, updatedAt

### Community 110 - "site_service_model.dart"
Cohesion: 0.18
Nodes (10): copyWith, createdAt, fromMap, id, rate, serviceName, siteId, SiteService (+2 more)

### Community 111 - "worker_document_model.dart"
Cohesion: 0.18
Nodes (10): copyWith, documentType, fileName, filePath, fromMap, id, toMap, uploadedAt (+2 more)

### Community 112 - "google_services_config.dart"
Cohesion: 0.18
Nodes (5): _extractWebClientId, GoogleServicesConfig, load, _loaded, _webClientId

### Community 113 - "AI token baseline — captured 2026-11-16"
Cohesion: 0.33
Nodes (5): AI token baseline — captured 2026-11-16, Baseline numbers, How to compare after a week, How to read the result honestly, What is in here

### Community 115 - "Map"
Cohesion: 0.20
Nodes (8): advanceMonthlyLimit, anniversaryReminderDays, consecutiveAbsenceLimit, documentValidityMonths, longUnpaidMonths, performanceAttendanceWarning, performanceRatingWarning, WorkerThresholds

### Community 116 - "win32_window.cpp"
Cohesion: 0.16
Nodes (6): Win32Window::GetHandle(), Win32Window::Show(), EnableFullDpiSupportIfAvailable(), EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window()

### Community 117 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 118 - "notification_settings_repository.dart"
Cohesion: 0.22
Nodes (5): create, _key, load, _prefs, save

### Community 120 - "../models/notification_model.dart"
Cohesion: 0.11
Nodes (14): evaluate, id, isEnabled, type, days, due, isOverdueWindow, PaymentReminderWindow (+6 more)

### Community 121 - "package:flutter/material.dart"
Cohesion: 0.22
Nodes (7): AppTheme, attendanceColor, darkTheme, lightTheme, _secondary, _seed, statusColor

### Community 122 - "package:go_router/go_router.dart"
Cohesion: 0.18
Nodes (5): GoRouterNotificationRouter, navigate, openExternal, _router, NotificationRouter

### Community 123 - "skill_gate.py"
Cohesion: 0.07
Nodes (24): derive_name(), frontmatter_name(), is_remote(), main(), stage(), _deny(), evaluate(), find_scanner() (+16 more)

### Community 124 - "System Architecture — Worklist"
Cohesion: 0.22
Nodes (8): Data model (per user_id), Firebase sync (verified), High-level layers, Performance characteristics (stress-tested), Security posture, SQLite integrity (verified), System Architecture — Worklist, UI / responsiveness

### Community 125 - "package:flutter/foundation.dart"
Cohesion: 0.25
Nodes (4): android, DefaultFirebaseOptions, web, windows

### Community 132 - "Worklist — Site & Worker Management"
Cohesion: 0.25
Nodes (7): Architecture (summary), Documentation, License, Platforms, Quick start, Release artifacts, Worklist — Site & Worker Management

### Community 142 - "Changelog — Worklist"
Cohesion: 0.40
Nodes (4): 1.0.0 — Initial, 1.4.0 — Notification framework (Phases 1–12, prior sprints), 1.4.1+8 — 2026-07-13 (FINAL RELEASE), Changelog — Worklist

### Community 143 - "Release Notes — Worklist"
Cohesion: 0.40
Nodes (4): Known Limitations, Release Highlights, Release Notes — Worklist, What Was Verified

## Knowledge Gaps
- **2087 isolated node(s):** `_activeUserId`, `_addColumnIfMissing`, `addStock`, `approveAdvance`, `assignWorkerToSite` (+2082 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2469 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **19 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `responsive.dart` to `DateTime`, `String get`, `ScreenSize`, `sync_screen.dart`, `bool get`, `static const`, `List`, `site_product_model.dart`, `shared_widgets.dart`?**
  _High betweenness centrality (0.027) - this node is a cross-community bridge._
- **What connects `_activeUserId`, `_addColumnIfMissing`, `addStock` to the rest of the system?**
  _2087 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `database_helper.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.014925373134328358 - nodes in this community are weakly interconnected._
- **Why does `WorkerProvider` connect `WorkerProvider` to `worker_form_screen.dart`, `worker_provider.dart`, `site_detail_screen.dart`, `State`, `attendance_screen.dart`, `dashboard_screen.dart`, `sync_screen.dart`, `payroll_screen.dart`, `worker_documents_screen.dart`, `workers_list_screen.dart`, `StatelessWidget`, `worker_detail_screen.dart`, `worker_performance_screen.dart`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Should `responsive.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.027777777777777776 - nodes in this community are weakly interconnected._
- **Why does `_` connect `../models/notification_model.dart` to `../models/notification_model.dart`, `../notification_rule.dart`, `NotificationRule`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Should `firebase_cloud_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.030303030303030304 - nodes in this community are weakly interconnected._