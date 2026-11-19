# Graph Report - Site and worker management app  (2026-11-19)

## Corpus Check
- 287 files · ~166,023 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 38 file(s) not represented in the graph (top: (none) 10, .xml 9, .bak-2026-11-17 5)

## Summary
- 4736 nodes · 8010 edges · 234 communities (142 shown, 92 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 34 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `eabc3b3d`
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
- dashboard_repository.dart
- document_model.dart
- dashboard_screen.dart
- payroll_screen.dart
- StatelessWidget
- notification_history_repository.dart
- document_provider.dart
- app.dart
- PayrollRecord
- ServiceRecord
- firebase_diagnostics.dart
- Notification
- site_model.dart
- dependencies
- worker_detail_screen.dart
- notification_model.dart
- document_detail_screen.dart
- inventory_audit_reminder_rule.dart
- notification_center_provider.dart
- android_notification_service.dart
- Company
- notification_settings.dart
- worker_repository.dart
- worker_form_screen.dart
- User
- notification_engine.dart
- sync_service.dart
- site_repository.dart
- documents_screen.dart
- payroll_model.dart
- Payment
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
- StockMovement
- windows_background_scheduler.dart
- SiteFormScreen.kt
- notification_rules_registry.dart
- store_product_model.dart
- business_insight_provider.dart
- package:flutter/foundation.dart
- CompanyMembership
- firebase_config.dart
- Attendance
- business_insight_engine.dart
- notification_cloud_sync_service.dart
- DateTime
- Design System
- app_check_service.dart
- FlutterWindow
- worker_model.dart
- CollectionRepository
- customPatterns
- document_file_service.dart
- PaymentDao
- StockMovementDao
- notification_scheduler.dart
- document_storage_service.dart
- payslip_service.dart
- Product
- bool get
- WorkerFormScreen.kt
- advance_payment_model.dart
- store_product_provider.dart
- document_permissions.dart
- AttendanceRepository
- products_screen.dart
- services_screen.dart
- site_product_model.dart
- CompanySession
- smart_summary_rule.dart
- worker_lifecycle_rule.dart
- ../models/notification_model.dart
- payroll_reminder_rule.dart
- notification_logger.dart
- notification_action_handler.dart
- int get
- worker_performance_model.dart
- Dashboard Content
- inventory_repository.dart
- collection_reminder_service.dart
- document_repository.dart
- String get
- notification_action_catalog.dart
- firebase_auth_listener.dart
- string
- Worker
- construction_payment_model.dart
- product_model.dart
- document_thumbnail.dart
- Win32Window
- ProductDao
- site_service_model.dart
- worker_document_model.dart
- google_services_config.dart
- Site
- AttendanceDao
- WorklistDestination
- win32_window.cpp
- StockMovementScreen.kt
- notification_settings_repository.dart
- .Create
- reminder_window.dart
- package:material_ui/material_ui.dart
- Worklist — Native Kotlin Port Design
- skill_gate.py
- System Architecture — Worklist
- SitesViewModel
- harness.dart
- SiteDao
- generated_plugin_registrant.cc
- MainActivity
- package:flutter_test/flutter_test.dart
- Worklist — Site & Worker Management
- ScreenSize
- CollectionDao
- payroll_repository.dart
- Bottom Navigation
- Changelog — Worklist
- Release Notes — Worklist
- ProductRepository
- site_lifecycle_rule.dart
- DashboardScreen.kt
- ThemeContractTest.kt
- ViewModelFactories.kt
- AGENTS.md
- Map
- Sidebar
- Review Focus
- AG-UI for all local AI tools — design
- user_service_provider.dart
- WorklistDatabase
- WorklistTab
- DashboardViewModel.kt
- AttendanceViewModel
- WorklistNavHost.kt
- dart:io
- ProductsViewModel
- WorkersScreen.kt
- StockViewModel
- theme_contract_test.dart
- MessageHandler
- RepositoryModule
- background_task_coordinator.dart
- Collection
- Notifications Architecture — Worklist
- notifications_contract_test.dart
- static const
- analysis_options.yaml
- WorklistTheme.kt
- MainActivity
- SitesScreen.kt
- .aider.conf.yml
- _MapPickerDialog
- _SiteFormScreenState
- Token-efficient working rules
- CLAUDE.md
- copilot-instructions.md
- RTK.md
- PaymentRecordScreen.kt

## God Nodes (most connected - your core abstractions)
1. `Product` - 92 edges
2. `_` - 83 edges
3. `Worker` - 83 edges
4. `Attendance` - 68 edges
5. `Site` - 68 edges
6. `PayrollRecord` - 58 edges
7. `User` - 57 edges
8. `ServiceRecord` - 55 edges
9. `WorkerProvider` - 51 edges
10. `Notification` - 50 edges

## Surprising Connections (you probably didn't know these)
- `Key types` --references--> `evaluate()`  [INFERRED]
  NOTIFICATIONS_ARCHITECTURE.md → .codex/hooks/skill_gate.py
- `Task 9: App shell and route placeholders` --references--> `Home`  [INFERRED]
  docs/superpowers/plans/2026-11-17-kotlin-port-m0-m1.md → native/app/src/main/kotlin/com/example/worklist/ui/navigation/WorklistDestination.kt
- `Task 9: App shell and route placeholders` --references--> `Sites`  [INFERRED]
  docs/superpowers/plans/2026-11-17-kotlin-port-m0-m1.md → native/app/src/main/kotlin/com/example/worklist/ui/navigation/WorklistDestination.kt
- `Task 9: App shell and route placeholders` --references--> `Workers`  [INFERRED]
  docs/superpowers/plans/2026-11-17-kotlin-port-m0-m1.md → native/app/src/main/kotlin/com/example/worklist/ui/navigation/WorklistDestination.kt
- `Task 9: App shell and route placeholders` --references--> `Payroll`  [INFERRED]
  docs/superpowers/plans/2026-11-17-kotlin-port-m0-m1.md → native/app/src/main/kotlin/com/example/worklist/ui/navigation/WorklistDestination.kt

## Import Cycles
- None detected.

## Communities (234 total, 92 thin omitted)

### Community 0 - "database_helper.dart"
Cohesion: 0.01
Nodes (129): _activeUserId, _addColumnIfMissing, addStock, approveAdvance, assignWorkerToSite, authenticate, countUserRecords, createAccount (+121 more)

### Community 1 - "responsive.dart"
Cohesion: 0.03
Nodes (61): _, all, base, baseFontSize, build, centeredForm, child, childAspectRatio (+53 more)

### Community 2 - "firebase_cloud_service.dart"
Cohesion: 0.03
Nodes (59): applySession, _auth, _authenticate, _authMessage, _backoffDelay, _cleanAccount, _clearPendingSync, clearSession (+51 more)

### Community 3 - "worker_provider.dart"
Cohesion: 0.03
Nodes (58): activeWorkerCount, addWorker, addWorkerDocument, addWorkerPerformance, _advances, approveAdvance, _attendanceRecords, calculatePaycheck (+50 more)

### Community 4 - "calendar_screen.dart"
Cohesion: 0.04
Nodes (57): active, _activeFilters, _allCategories, _attendanceLabel, _attendanceSubtitle, build, _buildBody, _buildEvents (+49 more)

### Community 5 - "site_detail_screen.dart"
Cohesion: 0.04
Nodes (64): SiteProvider, amount, bold, build, color, _ConstructionPaymentsSection, createState, _delete (+56 more)

### Community 6 - "site_provider.dart"
Cohesion: 0.04
Nodes (50): activeSiteCount, addConstructionPayment, addProduct, addSite, addSiteService, assignWorker, clear, clearError (+42 more)

### Community 7 - "site_form_screen.dart"
Cohesion: 0.04
Nodes (44): _advance, _area, _areaUnits, _budget, _cost, createState, dispose, _effectiveLastPaidDate (+36 more)

### Community 8 - "auth_provider.dart"
Cohesion: 0.04
Nodes (41): _auth, _autoPull, _autoPullInterval, _autoPullTimer, clearError, _cloud, _cloudDataVersion, cloudEmail (+33 more)

### Community 9 - "notification_metrics.dart"
Cohesion: 0.04
Nodes (47): _avgExecutionMs, _daily, _dailyRetentionDays, _dayKey, devLog, DiagnosticLogEntry, ensureLoaded, _executionCount (+39 more)

### Community 10 - "dashboard_repository.dart"
Cohesion: 0.15
Nodes (12): countUserRecords, DashboardRepository, _db, exportUserData, getAttendanceChartData, getDashboardStats, getExpensesChartData, getMaterialUsageChartData (+4 more)

### Community 11 - "document_model.dart"
Cohesion: 0.04
Nodes (39): apiValue, category, copyWith, createdAt, deletedAt, DocumentKind, DocumentSyncStatus, entityId (+31 more)

### Community 12 - "dashboard_screen.dart"
Cohesion: 0.03
Nodes (76): _buildRouter, navigate, AuthProvider, AccountScreen, _AccountScreenState, build, color, createState (+68 more)

### Community 13 - "payroll_screen.dart"
Cohesion: 0.04
Nodes (52): _DebugTokenCard, _DebugTokenCardState, AnalyticsScreen, _AnalyticsScreenState, _AmountColumn, _baseWage, bold, _bonus (+44 more)

### Community 14 - "StatelessWidget"
Cohesion: 0.03
Nodes (76): AdaptiveGrid, ResponsiveBuilder, ResponsiveLayout, ResponsivePadding, ResponsiveSpacing, ResponsiveText, _AgendaCard, _DayView (+68 more)

### Community 15 - "notification_history_repository.dart"
Cohesion: 0.05
Nodes (43): archive, archivedAt, body, copyWith, create, createdAt, delete, deleteAll (+35 more)

### Community 16 - "document_provider.dart"
Cohesion: 0.05
Nodes (35): _applyView, availableCategories, captureFromCamera, _docs, ensureLocal, _error, _files, _filterCategory (+27 more)

### Community 17 - "app.dart"
Cohesion: 0.03
Nodes (32): build, createState, didChangeDependencies, _handlerWired, _router, SiteWorkerManagerApp, _SiteWorkerManagerAppState, _wireActionHandler (+24 more)

### Community 18 - "PayrollRecord"
Cohesion: 0.06
Nodes (4): PayrollDao, PayrollRecord, PayrollRepository, PayrollRepositoryImpl

### Community 19 - "ServiceRecord"
Cohesion: 0.06
Nodes (5): ServiceDao, ServiceRecord, ServiceRepository, ServiceRepositoryImpl, ServicesViewModel

### Community 20 - "firebase_diagnostics.dart"
Cohesion: 0.12
Nodes (11): _checkAppCheck, _checkAuthentication, _checkConfig, _checkConnectivity, _checkFirebaseInitialization, _checkPlatform, _checkRealtimeDatabase, _checkRealtimeDatabaseRest (+3 more)

### Community 21 - "Notification"
Cohesion: 0.07
Nodes (5): NotificationDao, Notification, NotificationRepository, NotificationRepositoryImpl, NotificationsViewModel

### Community 22 - "site_model.dart"
Cohesion: 0.05
Nodes (36): advanceReceived, area, balance, budget, collectionReminderDays, completionPercentage, constructionPaid, copyWith (+28 more)

### Community 23 - "dependencies"
Cohesion: 0.04
Nodes (48): dependencies, barcode_widget, crypto, file_picker, firebase_app_check, firebase_auth, firebase_core, firebase_database (+40 more)

### Community 24 - "worker_detail_screen.dart"
Cohesion: 0.03
Nodes (87): WorkerPaycheck, WorkerProvider, _delete, _generateOrEdit, _load, _markPaid, _save, advance (+79 more)

### Community 25 - "notification_model.dart"
Cohesion: 0.06
Nodes (33): actions, AppNotification, body, copyWith, createdAt, deliveredAt, dismissedAt, entityId (+25 more)

### Community 26 - "document_detail_screen.dart"
Cohesion: 0.08
Nodes (32): DocumentProvider, _Actions, build, _busy, createState, _delete, doc, DocumentDetailScreen (+24 more)

### Community 27 - "inventory_audit_reminder_rule.dart"
Cohesion: 0.07
Nodes (27): buildEngineWithAllRules, engine, evaluate, FrequentlyUsedLowRule, _inventoryRepository, thresholds, _cycleBucket, evaluate (+19 more)

### Community 28 - "notification_center_provider.dart"
Cohesion: 0.06
Nodes (29): _all, archive, _category, categoryFilter, _compare, delete, deleteAll, dismiss (+21 more)

### Community 29 - "android_notification_service.dart"
Cohesion: 0.07
Nodes (25): actionHandler, cancel, cancelAll, _importance, initialize, _initialized, instance, _onResponse (+17 more)

### Community 30 - "Company"
Cohesion: 0.09
Nodes (4): CompanyDao, Company, CompanyRepository, CompanyRepositoryImpl

### Community 31 - "notification_settings.dart"
Cohesion: 0.06
Nodes (32): attendance, copyWith, dailyBriefingTime, dailySummary, _decodeTime, _encodeTime, fromJson, inventory (+24 more)

### Community 32 - "worker_repository.dart"
Cohesion: 0.06
Nodes (30): approveAdvance, _db, deleteWorker, deleteWorkerDocument, deleteWorkerDocumentsByWorker, deleteWorkerPerformance, deleteWorkerPerformanceByWorker, getAdvancesByWorker (+22 more)

### Community 33 - "worker_form_screen.dart"
Cohesion: 0.07
Nodes (30): _address, createState, _dailyRate, dispose, _formKey, _initialLoad, initState, _isEditing (+22 more)

### Community 34 - "User"
Cohesion: 0.07
Nodes (4): UserDao, User, UserRepository, UserRepositoryImpl

### Community 35 - "notification_engine.dart"
Cohesion: 0.08
Nodes (19): create, _history, refresh, registerRule, registerRules, _rules, _scheduler, _settings (+11 more)

### Community 36 - "sync_service.dart"
Cohesion: 0.06
Nodes (27): _auth, _authenticateBody, _busy, defaultPort, _handleRequest, isBusy, isRunning, loadServerAddress (+19 more)

### Community 37 - "site_repository.dart"
Cohesion: 0.06
Nodes (27): assignWorkerToSite, _db, deleteConstructionPayment, deleteProduct, deleteSite, deleteSiteProduct, deleteSiteService, getAllSites (+19 more)

### Community 38 - "documents_screen.dart"
Cohesion: 0.07
Nodes (26): DocumentEntityType, DocumentSort, build, _categoryDialog, _confirm, createState, doc, DocumentsScreen (+18 more)

### Community 39 - "payroll_model.dart"
Cohesion: 0.07
Nodes (28): advanceAmount, baseWage, bonus, copyWith, createdAt, dailyRate, deductions, fromMap (+20 more)

### Community 40 - "Payment"
Cohesion: 0.12
Nodes (3): Payment, PaymentRepository, PaymentRepositoryImpl

### Community 42 - "notification_settings_screen.dart"
Cohesion: 0.05
Nodes (35): NotificationSettingsRepository, _key, _load, _mode, setMode, toggle, AppTheme, attendanceColor (+27 more)

### Community 43 - "notification_center_screen.dart"
Cohesion: 0.06
Nodes (29): BusinessInsightProvider, NotificationCenterProvider, NotificationGroupBy, NotificationSort, NotificationRecord, build, _buildBody, _categories (+21 more)

### Community 44 - "app_constants.dart"
Cohesion: 0.08
Nodes (24): advanceApproved, advancePending, advanceRejected, AppConstants, appName, appVersion, attendanceAbsent, attendanceFull (+16 more)

### Community 45 - "sync_screen.dart"
Cohesion: 0.06
Nodes (29): SyncService, _addressCtrl, build, child, _cloudWorking, createState, dispose, initState (+21 more)

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
Cohesion: 0.06
Nodes (31): SiteModel, build, CollectionsScreen, _CollectionsScreenState, createState, _db, initState, _load (+23 more)

### Community 50 - "business_insight_models.dart"
Cohesion: 0.05
Nodes (39): body, BusinessInsight, copyWith, deepLink, deepLinkArgs, domain, entityId, entityType (+31 more)

### Community 51 - "analytics_screen.dart"
Cohesion: 0.08
Nodes (21): _attendance, build, _buildBody, createState, _db, _error, _ErrorState, _expenses (+13 more)

### Community 52 - "StockMovement"
Cohesion: 0.14
Nodes (3): StockMovement, StockMovementRepository, StockMovementRepositoryImpl

### Community 53 - "windows_background_scheduler.dart"
Cohesion: 0.09
Nodes (14): initializeBackgroundScheduling, kNotificationTaskName, kNotificationWorkUniqueName, notificationBackgroundCallbackDispatcher, interval, isBackgroundSupported, isRunning, registerStartup (+6 more)

### Community 54 - "SiteFormScreen.kt"
Cohesion: 0.11
Nodes (3): FormField(), SectionCard(), SiteFormScreen()

### Community 55 - "notification_rules_registry.dart"
Cohesion: 0.09
Nodes (6): buildNotificationRules, buildPhase2Rules, inventoryThresholds, settings, siteThresholds, workerThresholds

### Community 56 - "store_product_model.dart"
Cohesion: 0.09
Nodes (22): barcode, category, colorLabel, copyWith, createdAt, criticalStockThreshold, fromMap, id (+14 more)

### Community 57 - "business_insight_provider.dart"
Cohesion: 0.14
Nodes (11): BusinessInsightEngine, _engine, _error, forDomain, _insights, isLoading, load, _loading (+3 more)

### Community 58 - "package:flutter/foundation.dart"
Cohesion: 0.11
Nodes (11): clientId, configureFirebaseAuth, ensureLoaded, initializeApp, initializeFirebase, _initializeGoogleSignIn, register, android (+3 more)

### Community 60 - "firebase_config.dart"
Cohesion: 0.09
Nodes (19): androidAppId, androidPackageName, apiKey, ensureLoaded, FirebaseConfig, googleDesktopClientId, GoogleSignInPlatform, googleSignInStatusLabel (+11 more)

### Community 62 - "business_insight_engine.dart"
Cohesion: 0.10
Nodes (19): finance, _fmt, generateAll, generateSummary, inventory, inventoryRepository, _materialShortagePrediction, payments (+11 more)

### Community 63 - "notification_cloud_sync_service.dart"
Cohesion: 0.10
Nodes (17): _clearPending, downloadAndMerge, initForSession, _instance, _isPending, _markPending, NotificationCloudSyncService, _path (+9 more)

### Community 64 - "DateTime"
Cohesion: 0.10
Nodes (17): createdAt, fromMap, id, passwordHash, role, toMap, UserModel, username (+9 more)

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

### Community 70 - "customPatterns"
Cohesion: 0.06
Nodes (32): includeDiffs, includeLogs, includeLogsCount, sortByChanges, sortByChangesMaxCommits, ignore, customPatterns, useDefaultPatterns (+24 more)

### Community 71 - "document_file_service.dart"
Cohesion: 0.10
Nodes (15): deleteFiles, _dirName, DocumentFileService, DocumentFormatException, existsLocally, hashFile, ingest, ingestVersion (+7 more)

### Community 74 - "notification_scheduler.dart"
Cohesion: 0.14
Nodes (11): AndroidNotificationService, cancel, cancelAll, initialize, PlatformNotificationService, show, WindowsNotificationService, NotificationScheduler (+3 more)

### Community 75 - "document_storage_service.dart"
Cohesion: 0.13
Nodes (11): deleteFromStorage, DocumentStorageException, DocumentStorageService, download, _files, instance, message, processQueue (+3 more)

### Community 76 - "payslip_service.dart"
Cohesion: 0.12
Nodes (12): _buildHeader, _buildNetSalaryBanner, _buildSalaryTable, _buildWorkerInfo, _currency, _formatDate, generatePayslip, _infoRow (+4 more)

### Community 78 - "bool get"
Cohesion: 0.12
Nodes (15): AttendanceModel, copyWith, createdAt, date, fromMap, id, isAbsent, isFull (+7 more)

### Community 79 - "WorkerFormScreen.kt"
Cohesion: 0.19
Nodes (3): FormField(), SectionCard(), WorkerFormScreen()

### Community 80 - "advance_payment_model.dart"
Cohesion: 0.12
Nodes (16): AdvancePaymentModel, amount, approvedDate, copyWith, createdAt, fromMap, id, isApproved (+8 more)

### Community 81 - "store_product_provider.dart"
Cohesion: 0.12
Nodes (16): addProduct, addStock, clear, _cloud, deleteProduct, _error, findByBarcode, _generation (+8 more)

### Community 82 - "document_permissions.dart"
Cohesion: 0.12
Nodes (14): body, _Copy, DocumentPermissions, _ensure, _explain, instance, _PermUse, requestCamera (+6 more)

### Community 84 - "products_screen.dart"
Cohesion: 0.03
Nodes (68): StoreProductProvider, _load, activeFilters, _activeFiltersLabel, _applyFilters, build, _cleanOrNull, _clearFilters (+60 more)

### Community 85 - "services_screen.dart"
Cohesion: 0.17
Nodes (12): UserServiceProvider, build, createState, _deleteService, initState, onDelete, service, _ServiceCard (+4 more)

### Community 86 - "site_product_model.dart"
Cohesion: 0.12
Nodes (13): copyWith, createdAt, fromMap, id, productId, productName, productRate, productUnit (+5 more)

### Community 88 - "smart_summary_rule.dart"
Cohesion: 0.12
Nodes (14): BriefingMode, briefingTime, evaluate, inventoryRepository, isEnabled, mode, monthlyDay, payrollRepository (+6 more)

### Community 89 - "worker_lifecycle_rule.dart"
Cohesion: 0.14
Nodes (11): _anniversaryThisYear, _consecutiveAbsences, evaluate, _fmt, _midnight, _monthsBetween, _pad, _payrollRepository (+3 more)

### Community 90 - "../models/notification_model.dart"
Cohesion: 0.07
Nodes (24): build, now, NotificationRule, ConstructionPaymentRule, evaluate, _siteRepository, CustomerPaymentRule, evaluate (+16 more)

### Community 91 - "payroll_reminder_rule.dart"
Cohesion: 0.17
Nodes (9): _, _build, evaluate, month, monthEnd, Optimistic, _payrollRepository, evaluate (+1 more)

### Community 92 - "notification_logger.dart"
Cohesion: 0.14
Nodes (12): error, info, instance, Level, LevelX, _log, minLevel, name (+4 more)

### Community 93 - "notification_action_handler.dart"
Cohesion: 0.12
Nodes (15): GoRouterNotificationRouter, deepLinkRouteFor, handle, history, navigate, NotificationActionHandler, notificationFromRecord, NotificationRouter (+7 more)

### Community 94 - "int get"
Cohesion: 0.14
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
Cohesion: 0.17
Nodes (7): _authStateSubscription, FirebaseAuthListener, FirebaseAuthUserHandler, _idTokenSubscription, instance, start, stop

### Community 103 - "string"
Cohesion: 0.16
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 104 - "Worker"
Cohesion: 0.05
Nodes (5): WorkerDao, Worker, WorkerRepository, WorkerRepositoryImpl, WorkersViewModel

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
Cohesion: 0.18
Nodes (7): FlutterWindow::OnCreate(), Win32Window::GetClientArea(), Win32Window::OnCreate(), Win32Window, child_content_, quit_on_close_, window_handle_

### Community 110 - "site_service_model.dart"
Cohesion: 0.18
Nodes (10): copyWith, createdAt, fromMap, id, rate, serviceName, siteId, SiteService (+2 more)

### Community 111 - "worker_document_model.dart"
Cohesion: 0.18
Nodes (10): copyWith, documentType, fileName, filePath, fromMap, id, toMap, uploadedAt (+2 more)

### Community 112 - "google_services_config.dart"
Cohesion: 0.18
Nodes (5): _extractWebClientId, GoogleServicesConfig, load, _loaded, _webClientId

### Community 113 - "Site"
Cohesion: 0.09
Nodes (3): Site, SiteRepository, SiteRepositoryImpl

### Community 115 - "WorklistDestination"
Cohesion: 0.09
Nodes (25): Task 9: App shell and route placeholders, WorklistDestination, Account, Analytics, Attendance, Calendar, Collections, Documents (+17 more)

### Community 116 - "win32_window.cpp"
Cohesion: 0.14
Nodes (6): Win32Window::Destroy(), Win32Window::Show(), EnableNonClientDpiScaling, WindowClassRegistrar, class_registered_, instance_

### Community 117 - "StockMovementScreen.kt"
Cohesion: 0.26
Nodes (5): FormField(), MovementTypeChips(), ProductDropdown(), SectionCard(), StockMovementScreen()

### Community 118 - "notification_settings_repository.dart"
Cohesion: 0.25
Nodes (5): create, _key, load, _prefs, save

### Community 119 - ".Create"
Cohesion: 0.14
Nodes (8): Scale(), Point, x, y, Size, height, width, Win32Window::Win32Window()

### Community 120 - "reminder_window.dart"
Cohesion: 0.22
Nodes (8): days, due, isOverdueWindow, PaymentReminderWindow, priorityForWindow, today, windowForDueDate, windowLabel

### Community 121 - "package:material_ui/material_ui.dart"
Cohesion: 0.14
Nodes (11): build, createState, _fmt, initState, label, NotificationDiagnosticsScreen, _NotificationDiagnosticsScreenState, _Row (+3 more)

### Community 122 - "Worklist — Native Kotlin Port Design"
Cohesion: 0.06
Nodes (25): BootReceiver, WorklistApplication, 10. Milestones, 11. Deletion plan, 12. Risks, 13. Settled decisions, 14. Approval, 1. Goal (+17 more)

### Community 123 - "skill_gate.py"
Cohesion: 0.09
Nodes (19): derive_name(), frontmatter_name(), is_remote(), main(), record_exception(), stage(), baseline_for(), _deny() (+11 more)

### Community 124 - "System Architecture — Worklist"
Cohesion: 0.22
Nodes (8): Data model (per user_id), Firebase sync (verified), High-level layers, Performance characteristics (stress-tested), Security posture, SQLite integrity (verified), System Architecture — Worklist, UI / responsiveness

### Community 127 - "harness.dart"
Cohesion: 0.09
Nodes (20): DatabaseHelper, countRows, db, dbPath, deleteDatabase, encoded, existing, expectGolden (+12 more)

### Community 131 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.15
Nodes (6): main, main, main, observedProduct, main, main

### Community 132 - "Worklist — Site & Worker Management"
Cohesion: 0.25
Nodes (7): Architecture (summary), Documentation, License, Platforms, Quick start, Release artifacts, Worklist — Site & Worker Management

### Community 135 - "payroll_repository.dart"
Cohesion: 0.11
Nodes (15): _db, deletePayroll, getPayroll, getPayrollForMonth, insertPayroll, PayrollRepository, setPayrollStatus, updatePayroll (+7 more)

### Community 142 - "Changelog — Worklist"
Cohesion: 0.40
Nodes (4): 1.0.0 — Initial, 1.4.0 — Notification framework (Phases 1–12, prior sprints), 1.4.1+8 — 2026-07-13 (FINAL RELEASE), Changelog — Worklist

### Community 143 - "Release Notes — Worklist"
Cohesion: 0.40
Nodes (4): Known Limitations, Release Highlights, Release Notes — Worklist, What Was Verified

### Community 146 - "site_lifecycle_rule.dart"
Cohesion: 0.12
Nodes (13): evaluate, _fmt, _midnight, _pad, _siteRepository, thresholds, _workerRepository, _ymd (+5 more)

### Community 147 - "DashboardScreen.kt"
Cohesion: 0.21
Nodes (5): ActivityFeed(), DashboardScreen(), StatCard(), StatsGrid(), StockAlertsCard()

### Community 148 - "ThemeContractTest.kt"
Cohesion: 0.07
Nodes (18): Global Constraints, Kotlin Port — Milestone 0 & 1 Implementation Plan, Milestone exit criteria, Review Focus, Self-review notes, Task 1: Characterization harness + replayable seed, Task 2: Dashboard, site and worker contracts, Task 3: Payroll and advance-payment contracts (+10 more)

### Community 149 - "ViewModelFactories.kt"
Cohesion: 0.12
Nodes (21): applicationFrom(), attendanceViewModelFactory(), Factory, collectionsViewModelFactory(), Factory, dashboardViewModelFactory(), Factory, notificationsViewModelFactory() (+13 more)

### Community 150 - "AGENTS.md"
Cohesion: 0.50
Nodes (3): AG-UI, graphify, Token efficiency

### Community 151 - "Map"
Cohesion: 0.20
Nodes (8): advanceMonthlyLimit, anniversaryReminderDays, consecutiveAbsenceLimit, documentValidityMonths, longUnpaidMonths, performanceAttendanceWarning, performanceRatingWarning, WorkerThresholds

### Community 154 - "Review Focus"
Cohesion: 0.14
Nodes (13): AG-UI for All Local AI Tools — Implementation Plan, Global Constraints, Review Focus, Task 10: End-to-end verification and report, Task 1: Stage the monorepo and source material, Task 2: Write the canonical SKILL.md, Task 3: Write `references/protocol.md`, Task 4: Write `references/sdks.md` and `references/integrations.md` (+5 more)

### Community 155 - "AG-UI for all local AI tools — design"
Cohesion: 0.14
Nodes (13): AG-UI for all local AI tools — design, Approaches considered, Canonical skill, Constraints, Design, Goals, Intent, Left to the builder (+5 more)

### Community 156 - "user_service_provider.dart"
Cohesion: 0.14
Nodes (11): addService, clear, _cloud, deleteService, _generation, _loading, loadServices, reloadAll (+3 more)

### Community 159 - "WorklistTab"
Cohesion: 0.29
Nodes (11): BottomTabs(), NavRail(), ResponsiveShell(), TabIcon(), WorklistApp(), WorklistTab, Home, More (+3 more)

### Community 160 - "DashboardViewModel.kt"
Cohesion: 0.43
Nodes (3): DashboardStats, DashboardViewModel, DashboardActivity

### Community 162 - "WorklistNavHost.kt"
Cohesion: 0.12
Nodes (9): PlaceholderScreen(), WorklistNavHost(), AccountScreen(), AnalyticsScreen(), MetricRow(), CollectionCard(), CollectionsScreen(), StockCard() (+1 more)

### Community 163 - "dart:io"
Cohesion: 0.18
Nodes (4): _create, _instance, PlatformNotificationServiceFactory, scheduler

### Community 165 - "WorkersScreen.kt"
Cohesion: 0.12
Nodes (15): CalendarScreen(), NotificationCard(), NotificationsScreen(), PayrollCard(), PayrollScreen(), ProductCard(), ProductsScreen(), ServiceCard() (+7 more)

### Community 167 - "theme_contract_test.dart"
Cohesion: 0.20
Nodes (7): argb, _attendanceToJson, _hex, main, _schemeToJson, _shapeToJson, _statusToJson

### Community 170 - "background_task_coordinator.dart"
Cohesion: 0.22
Nodes (7): BackgroundTaskCoordinator, dispose, engine, prepare, _prepared, runInBackground, NotificationEngine

### Community 172 - "Notifications Architecture — Worklist"
Cohesion: 0.20
Nodes (9): NotificationSettings, Background scheduling, Cross-device sync (Phase 12), Diagnostics (Phase 10), Interactive actions (Phase 9), Key types, Notifications Architecture — Worklist, Pipeline (+1 more)

### Community 174 - "static const"
Cohesion: 0.29
Nodes (5): clearActiveUsername, loadActiveUsername, saveActiveUsername, SessionStorage, _usernameKey

### Community 175 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 178 - "SitesScreen.kt"
Cohesion: 0.18
Nodes (3): SiteCard(), SitesScreen(), StatusChip()

### Community 180 - ".aider.conf.yml"
Cohesion: 0.50
Nodes (3): cache-prompts, map-tokens, read

### Community 200 - "PaymentRecordScreen.kt"
Cohesion: 0.14
Nodes (10): FormField(), PaymentRecordScreen(), RateBasisChips(), SectionCard(), SiteDropdown(), WorkerDropdown(), AttendanceRecordScreen(), AttendanceTypeChips() (+2 more)

## Knowledge Gaps
- **2148 isolated node(s):** `_router`, `_handlerWired`, `createState`, `didChangeDependencies`, `_wireActionHandler` (+2143 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2812 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **92 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `responsive.dart` to `DateTime`, `ScreenSize`, `notification_settings_screen.dart`, `sync_screen.dart`, `StatelessWidget`, `bool get`, `WorkerFormScreen.kt`, `sites_list_screen.dart`, `site_product_model.dart`, `int get`?**
  _High betweenness centrality (0.388) - this node is a cross-community bridge._
- **What connects `_router`, `_handlerWired`, `createState` to the rest of the system?**
  _2148 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `database_helper.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.014814814814814815 - nodes in this community are weakly interconnected._
- **Why does `DashboardViewModel` connect `DashboardViewModel.kt` to `WorklistNavHost.kt`, `WorkersScreen.kt`, `CollectionRepository`, `Worker`, `Product`, `ProductRepository`, `Site`, `PayrollRecord`, `DashboardScreen.kt`, `AttendanceRepository`, `ViewModelFactories.kt`, `Attendance`?**
  _High betweenness centrality (0.101) - this node is a cross-community bridge._
- **Should `responsive.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03076923076923077 - nodes in this community are weakly interconnected._
- **Why does `Site` connect `Site` to `SiteDao`, `DashboardViewModel.kt`, `PaymentRecordScreen.kt`, `SitesScreen.kt`, `SitesViewModel`, `SiteFormScreen.kt`, `CompanySession`, `WorklistDatabase`?**
  _High betweenness centrality (0.084) - this node is a cross-community bridge._
- **Should `firebase_cloud_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.030303030303030304 - nodes in this community are weakly interconnected._