# 1. ARCHITECTURAL AUDIT REPORT

## Primary Request and Intent
- **Audit the architecture** of Flutter "Site and worker management app"
- **Create report at**: project-audit/01_architectural_audit.md
- **Read-only investigation**: do not modify source code

---

## Architecture Overview

### Technology Stack
| Layer | Technology | Version/Notes |
|-------|------------|---------------|
| Framework | Flutter | Dart >=3.2.0 <4.0.0 |
| State Management | Provider + ChangeNotifier | MultiProvider pattern |
| Database | SQLite (sqflite) | Version 20 confirmed |
| Cloud | Firebase | Auth, Firestore, FCM, Storage |
| Navigation | GoRouter | ShellRoute pattern |
| Desktop Support | sqflite_common_ffi | Windows/FFI initialized |

### Project Structure
```
lib/
├── main.dart                 # Application entry point
├── app.dart                  # GoRouter configuration, MultiProvider setup
├── core/
│   ├── database/
│   │   └── database_helper.dart  # 2873 lines, SQLite CRUD, migrations
│   ├── models/               # 20+ model classes
│   ├── repositories/         # 5 repositories
│   ├── providers/            # 7 ChangeNotifiers
│   └── services/             # Business logic services
└── features/                 # 16 feature modules
```

### Data Flow Pattern
```
Models → Providers → Repositories → SQLite/Firebase → UI
                ↓
           Cloud Sync via onUserMutate hook
```

---

## Key Architectural Patterns

### 1. Repository Pattern ✓
- **5 Repositories** properly implemented:
  - `site_repository.dart` — Site CRUD, products per site, worker assignments
  - `payroll_repository.dart` — Payroll per worker per month, status management
  - `auth_repository.dart` — Password hashing, authentication, user creation
  - `service_repository.dart` — User service catalog (global, not site-scoped)
  - `document_repository.dart` — Document CRUD operations

### 2. Provider Pattern ✓
- **7 ChangeNotifiers** in MultiProvider:
  1. AuthProvider — Authentication state, auto-pull
  2. ThemeProvider — Theme management
  3. SiteProvider — Site data and operations
  4. WorkerProvider — Worker data, payroll calculations
  5. StoreProductProvider — Products/stock management
  6. UserServiceProvider — Global service catalog
  7. SyncService — Cloud sync orchestration

### 3. Navigation Pattern ✓
- **GoRouter with ShellRoute** pattern
- 15+ route definitions covering all features
- Auth state redirects: `/login` ↔ `/`
- Deep linking support for Firebase Auth email links

### 4. Database Layer ✓
- **SQLite with sqflite 2.0+**
- **Version 20** with `onCreate` and `onUpgrade` methods
- FFI support for Windows desktop
- Raw SQL queries for performance

---

## Architectural Strengths

1. **Clean Separation of Concerns**
   - Models: Data schemas
   - Repositories: Data access layer
   - Providers: State management
   - Features: UI/UX

2. **Hybrid Persistence Strategy**
   - Local SQLite cache for offline support
   - Firebase cloud sync for multi-device access
   - `onUserMutate` callback for change notifications

3. **Testability**
   - Characterization test suite exists
   - Contract-based testing with golden files
   - Database harness for test isolation

4. **Platform Support**
   - Android (primary development)
   - Windows desktop build configured
   - FFI for non-mobile platforms

---

## Architectural Weaknesses

### 1. iOS Platform Missing
- No iOS directory structure in project
- Android is primary platform
- Firebase iOS config (`GoogleService-Info.plist`) referenced but may not exist

### 2. Deprecated Dependencies
- `provider_pattern` package referenced in code:
  - `lib/features/leave/leave_form_screen.dart` line 2
  - Not declared in `pubspec.yaml`

### 3. Tight Coupling in Notification System
- Background processing tied to platform-specific implementations
- WorkManager integration Android-only

### 4. Limited Error Boundaries
- No centralized error handling architecture
- Errors often handled per-provider

---

## Module Completeness

| Module | Status | Key Components |
|--------|--------|----------------|
| Sites | ✓ Complete | `site_provider.dart`, `sites_list.dart`, `site_detail.dart`, `site_form.dart` |
| Workers | ✓ Complete | `worker_provider.dart`, `workers_list.dart`, `worker_detail.dart`, `payroll_view.dart` |
| Payroll | ✓ Present | Integration with worker feature, payroll calculation logic |
| Products | ✓ Complete | `product_provider.dart`, products CRUD |
| Services | ✓ Complete | Global service catalog, not site-scoped |
| Documents | ✓ Present | Firebase Storage integration |
| Dashboard | ✓ Complete | Charts, home content (calendar removed) |
| Notifications | ✓ Complete | Rules engine, FCM, background processing |
| Account | ✓ Present | User profile, settings |
| Calendar | ⚠ Removed | 1254 lines deleted, replaced by dashboard |
| Shifts | ✓ Present | Shift management |
| Leave | ✗ Issues | `leave_form_screen.dart` has 908 analyze issues |
| Reports | ✓ Present | Reporting dashboard |
| Stock | ✓ Present | Inventory management |
| Inventory | ✓ Complete | Stock tracking, alerts |
| Settings | ✓ Present | Theme, app configuration |

---

## Dependency Graph

```
main.dart
  └─> MultiProvider (7 providers)
       ├─> AuthProvider ─> AuthRepository ─> DatabaseHelper
       ├─> SiteProvider ─> SiteRepository ─> DatabaseHelper
       ├─> WorkerProvider ─> PayrollRepository ─> DatabaseHelper
       ├─> StoreProductProvider ─> ? (implicit)
       ├─> UserServiceProvider ─> ServiceRepository ─> DatabaseHelper
       └─> SyncService ─> Firebase services
```

---

## Database Schema Summary

### Core Tables
1. **users** — Authentication, roles, session management
2. **sites** — Project sites, cost tracking, completion %
3. **workers** — Worker profiles, payroll info
4. **products** — Products per site, stock levels
5. **services** — Global service catalog
6. **documents** — File references, Firebase paths
7. **payroll** — Monthly payroll records
8. **attendance** — Worker attendance records
9. **advances** — Advance payments tracking
10. **leave_requests** — Leave application system

---

## Conclusion

### Architecture Score: 8/10

The architecture demonstrates:
- ✅ Proper separation of concerns
- ✅ Standard Flutter patterns (Provider, Repository)
- ✅ Hybrid local/cloud persistence
- ✅ Comprehensive test infrastructure

**Areas for Improvement:**
1. Add iOS platform support
2. Fix missing `provider_pattern` dependency
3. Resolve 908 flutter analyze issues (primarily in leave module)
4. Implement iOS Firebase configuration

---

## Files Analyzed

| File | Lines | Purpose |
|------|-------|---------|
| `lib/main.dart` | ~150 | App entry, Firebase init, MultiProvider |
| `lib/app.dart` | ~200 | Router, provider setup |
| `lib/core/database/database_helper.dart` | 2873 | SQLite layer, migrations |
| `lib/core/repositories/*.dart` | Various | Data access |
| `lib/core/providers/*.dart` | Various | State management |
| `pubspec.yaml` | ~100 | Dependencies |

---

*Report generated by architectural audit*  
*Audit Date: 2026-11-21*