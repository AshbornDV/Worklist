# Structured Checkpoint

## Primary Request and Intent
- Comprehensive audit of Flutter project named "Worklist"
- Cross-platform site and worker management for construction projects
- Explore project structure to understand codebase organization
- Initial investigation of architecture, models, providers, and feature modules

## Key Technical Concepts
- Flutter/Dart framework with multi-module architecture (core/ + features/)
- Provider-based state management with ChangeNotifier + MultiProvider
- GoRouter navigation with ShellRoute pattern and auth state redirects
- Firebase integration (Auth, Messaging, Database, Cloud Storage)
- SQLite local persistence with sqflite + sqflite_common_ffi
- Hybrid local+cloud data strategy (local DB + Firebase sync)
- Model serialization with toMap/fromMap patterns
- Notification system with rules engine and background processing
- Construction industry domain: sites, workers, payroll, products, services, documents

## Files and Code Examined (Expanded)
- **pubspec.yaml**: 60+ dependencies (sqflite, firebase packages, go_router, material_ui, barcode scanners, pdf, geolocator, fl_chart, etc.)
- **lib/main.dart**: Entry point - initializes Firebase, WorkManager, notification handlers, database cloud-sync hook, email link handler; MultiProvider with 7 ChangeNotifiers (AuthProvider, ThemeProvider, SiteProvider, WorkerProvider, StoreProductProvider, UserServiceProvider, SyncService)
- **lib/app.dart**: GoRouter configuration with 15+ route definitions covering: login, dashboard home, collections, analytics, calendar, documents, sites (list/detail/form), workers (list/detail/form), payroll, products, services, stock
- **lib/core/models/user_model.dart**: UserModel with id, username, passwordHash, role, createdAt; toMap/fromMap serialization with password hashing
- **lib/core/models/product_model.dart**: ProductModel with siteId, name, quantity, unit, deliveryDate, createdAt; copyWith pattern, toMap/fromMap
- **lib/core/models/site_model.dart**: Comprehensive SiteModel with 25+ fields including cost tracking (estimatedCost, advanceReceived, constructionPaid), completionPercentage, isPaid/isOverpaid calculations, collection reminder logic based on site size
- **lib/core/providers/auth_provider.dart**: 708-line AuthProvider with auto-pull machinery (30s timer), cloud sync, Google sign-in status, session management, logout, error handling, lifecycle listening
- **lib/features/**: 16+ feature modules: account, auth, dashboard (home/collections/analytics/calendar), documents, payroll, products, services, sites (list/detail/form), stock, workers (list/detail/form), notifications (center/diagnostics/business_insight/settings)

## Patterns Identified
- Data Flow: Models → Providers → Repositories → Firebase/SQLite → UI
- Authentication: Firebase Auth with Google sign-in, email-link passwordless flow, session storage
- Navigation: GoRouter with ShellRoute pattern, auth state redirects (/login ↔ /)
- Persistence: Local SQLite + Firebase cloud sync hybrid
- Notifications: Background processing, FCM, WorkManager periodic tasks, platform-specific services (Android/iOS/Windows)
- Cost Tracking: Site model with running totals, overpayment detection, completion percentages
- Rules Engine: Notification rules categorized by inventory, payment, payroll, site, worker, smart types

## Errors and Fixes
- (none encountered during initial exploration)

## Pending Jobs
- (none)

## Current Work Status
- Phase 1 complete: Project structure and core module exploration
- Phase 2 in progress: Feature module deep dive and data flow analysis
- Focus areas: notification architecture, provider synchronization, repository patterns

## Next Step
- Continue feature module examination (payroll, workers, documents, notifications)
- Investigate repository implementations and their cloud/local sync strategies
- Analyze notification rules engine and business insight calculations
- Check for security considerations in auth and data handling

## Critical Context
- Project: Construction site + worker management application
- Architecture: Local SQLite persistence + Firebase cloud sync hybrid
- Multi-role system serving construction industry workflows
- 16+ feature modules organized under lib/features/
- Active development with regular model/provider updates
- Key patterns: Provider state management, GoRouter navigation, Firebase/Auth, SQLite local storage