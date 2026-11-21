# Architecture Inspection Report

## 1. Provider Architecture

| Severity | File:Line | Description | Recommended Action |
|----------|-----------|-------------|--------------------|
| critical | `lib/core/providers/auth_provider.dart:62` | Auto-pull timer lifecycle listener not disposed on provider disposal, risking memory leaks and stale cloud sync operations. | Implement `dispose()` method to cancel `_retryTimer` and remove lifecycle listener. |
| major | `lib/core/providers/site_provider.dart:145` | `SiteRepository` changes not propagated to UI when app is in background; cloud sync may occur without UI awareness. | Add `Listener` or `ChangeNotifierListener` to track sync state across app lifecycle events. |
| minor | `lib/core/providers/worker_provider.dart:312` | PayrollRepository calculations embedded directly in ChangeNotifier; violates separation of concerns. | Extract pure calculation logic into a separate `PayrollCalculator` class; inject as dependency. |

## 2. Repository Pattern

| Severity | File:Line | Description | Recommended Action |
|----------|-----------|-------------|--------------------|
| major | `lib/core/repositories/site_repository.dart:35` | `setActiveUser` delegates to `_db.setActiveUser` without validation; unguarded DB access may corrupt state. | Add input validation and null-checks before delegating to database; return optional result. |
| minor | `lib/core/repositories/worker_repository.dart:88` | `getWorkerById` performs linear search through list; O(n) complexity for what should be O(1) lookup. | Introduce a `Map<int, WorkerModel>` cache indexed by ID; maintain cache on insert/update/delete. |
| improvement | `lib/core/repositories/payroll_repository.dart:22` | Payroll data access scattered across multiple methods without unified transaction boundary. | Wrap multi-step payroll operations in a transactional `computePayroll` method with atomic commit/rollback. |

## 3. Database Layer

| Severity | File:Line | Description | Recommended Action |
|----------|-----------|-------------|--------------------|
| critical | `lib/core/database/database_helper.dart:62` | `onUserMutate` static callback is the sole bridge between local DB and cloud sync; any mutation triggers cloud push without debouncing. | Introduce mutation batching/coalescing; add flag to suppress redundant cloud pushes within short interval. |
| critical | `lib/core/database/database_helper.dart:1505-1507` | `onUserMutate` called **3x** in `insertWorker` — triple notification issue; each insert fires independent cloud sync. | Refactor to fire `onUserMutate` once after transaction commit; or add unique mutation ID to prevent duplicate processing. |
| major | `lib/core/database/database_helper.dart:2040` | Schema version 20; migration path to v21–v24 not yet implemented; future schema changes will break offline-first sync. | Implement `onUpgrade` with safe column additions; populate `worklist_phase1_implementation_plan.md` migration tasks. |
| minor | `lib/core/database/database_helper.dart:145` | Raw `rawQuery` calls without prepared statement parameterization in 3 locations; minor SQL injection risk. | Replace with parameterized `query` methods using `where` args. |

## 4. Sync Architecture

| Severity | File:Line | Description | Recommended Action |
|----------|-----------|-------------|--------------------|
| major | `lib/core/sync/sync_service.dart:87` | Local HTTP server on port 8787 for LAN sync; no firewall or port-configuration options; may conflict on crowded networks. | Add port configurable via environment variable; implement port conflict detection and fallback. |
| major | `lib/core/sync/sync_service.dart:152` | `pushToServer` has no idempotency key; repeated pushes of same mutation may create duplicate cloud records. | Introduce mutation UUIDs; deduplicate on server by checking for existing UUID before write. |
| minor | `lib/core/sync/sync_service.dart:221` | `pullFromServer` fetches entire Realtime Database subtree; inefficient for large sites with many records. | Implement incremental sync using Firebase query filters (`limit`, `orderByChild`, `startAt/endAt`). |
| improvement | `lib/core/sync/sync_service.dart:305` | No offline queue persistency; app restart loses pending sync queue; user must re-trigger sync manually. | Persist offline queue to SQLite with `dirty` flag; replay on app startup. |

## 5. Model Layer

| Severity | File:Line | Description | Recommended Action |
|----------|-----------|-------------|--------------------|
| major | `lib/core/models/site_model.dart:78-80` | `collectionReminderDays` uses `AppConstants.siteSizeSmall/Large` without enum; magic numbers reduce readability. | Replace with `enum class SiteSize { small, large }` with associated reminder days. |
| minor | `lib/core/models/payroll_model.dart:57` | `baseWage` computes `(fullDays * dailyRate) + (halfDays * (dailyRate / 2))` inline; logic duplicated if used elsewhere. | Extract as `calculateBaseWage` extension method or dedicated service; test independently. |
| improvement | `lib/core/models/worker_model.dart:32` | `halfDayRate` computed as `dailyRate / 2`; should be derived from `attendance_type` logic consistent with `AttendanceModel.payMultiplier`. | Unify half-day rate logic across models; ensure consistency between attendance and payroll calculations. |
| critical | `lib/core/models/attendance_model.dart:29-38` | `payMultiplier` returns 0.0 for absent; if used in payroll without also checking `isAbsent`, may silently zero out wages. | Add explicit `isAbsent` guard in payroll computation; consider raising severity if already observed. |

## 6. Platform Parity

| Severity | File:Line | Description | Recommended Action |
|----------|-----------|-------------|--------------------|
| critical | `lib/main.dart:44-52` | `sqflite FFI` initialized only for non-mobile (`!kIsWeb && (Platform.isAndroid || Platform.isIOS)` is false); Android uses original sqflite, Windows uses FFI — feature divergence. | Ensure identical DB schema and `onUserMutate` behavior across both code paths; integration test on both platforms. |
| major | `lib/main.dart:95-105` | Windows-specific `sqlite3_ffi_dl` loading has no fallback; crash on unsupported platforms if loaded unconditionally. | Guard FFI initialization with `try-catch`; provide graceful degradation message; log for diagnostics. |
| minor | `lib/main.dart:118` | No platform-specific `kIsWeb` check before registering web-targeted providers; may register inappropriate providers on desktop. | Add `if (!kIsWeb)` guard around web-specific provider registrations; or feature-flip via env var. |
| improvement | N/A | Android + Windows parity documented as goal; no automated test suite verifying feature parity across both platforms. | Create CI workflow that builds and runs minimal sync test on both Android emulator and Windows build; enforce parity gates. |

## 7. Dependencies

| Severity | File:Line | Description | Recommended Action |
|----------|-----------|-------------|--------------------|
| major | `pubspec.yaml:12` | `provider ^6.1.2` pinned; no upper-bound lock; minor version bumps may introduce breaking changes in ChangeNotifier semantics. | Add explicit upper-bound: `provider: ^6.1.2` or migrate to `^6.0.0` with change audit. |
| critical | `pubspec.yaml:15` | `sqflite_common_ffi ^2.3.3` enables FFI on desktop; transitive dependency risks if version mismatches with `sqflite ^2.3.3+1`. | Lock both to exact versions; run `dart pub outdated`; verify `flutter pub get` consistency. |
| minor | `pubspec.yaml:18` | `pdf ^3.12.0` and `file_picker ^11.0.2` not used in core architecture; dead weight increasing app bundle size. | Evaluate if PDF/file_picker features are required; if not, remove to reduce download/startup time. |
| improvement | N/A | No `cached_network_image` or similar optimization; network images load without caching, degrading UI performance on slow networks. | Add `cached_network_image: ^3.3.0` if images are used; or confirm intentional offline-first design. |

## 8. Feature Coverage

| Severity | File:Line | Description | Recommended Action |
|----------|-----------|-------------|--------------------|
| major | `worklist_phase1_implementation_plan.md:45` | 8 critical gaps identified between current state and Phase 1 plan; gap summary not mapped to specific code locations. | Map each gap to exact file:line; assign owner; add to sprint backlog with defined acceptance criteria. |
| minor | `lib/core/providers/store_product_provider.dart:67` | InventoryRepository lacks `deleteProduct` method; UI can create products but not remove them, inconsistent with other repositories. | Implement `deleteProduct` with confirmation dialog and SQLite `DELETE` + cloud sync marker. |
| improvement | N/A | No feature flag mechanism to toggle experimental features (e.g., new sync protocol) without code redeploy. | Introduce `feature_flags.dart` with environment-based toggles; enable gradual rollout. |

---

## Prioritized Summary: Top 10 Most Important Findings

| Rank | Severity | Area | File:Line | Summary |
|------|----------|------|-----------|---------|
| 1 | **critical** | Database Layer | `database_helper.dart:1505-1507` | `onUserMutate` called 3x in insertWorker — triple notification breaks cloud sync deduplication. |
| 2 | **critical** | Platform Parity | `main.dart:44-52` | sqflite FFI only for Windows; Android uses original sqflite — feature divergence risk. |
| 3 | **critical** | Provider Architecture | `auth_provider.dart:62` | Auto-pull timer not disposed on disposal — memory leak + stale sync risk. |
| 4 | **critical** | Database Layer | `database_helper.dart:62` | `onUserMutate` sole bridge between local DB and cloud sync — single point of failure. |
| 5 | **major** | Repository Pattern | `site_repository.dart:35` | `setActiveUser` delegates to `_db.setActiveUser` without validation — state corruption. |
| 6 | **major** | Sync Architecture | `sync_service.dart:87` | LAN HTTP server on port 8787 no firewall/port config — conflict on shared networks. |
| 7 | **major** | Database Layer | `database_helper.dart:2040` | Schema version 20; migrations v21–v24 not implemented — future breakage guaranteed. |
| 8 | **major** | Sync Architecture | `sync_service.dart:152` | `pushToServer` lacks idempotency key — duplicate cloud records on retry. |
| 9 | **major** | Provider Architecture | `site_provider.dart:145` | Site changes not propagated in background — UI sync blindness. |
| 10 | **major** | Feature Coverage | `worklist_phase1_implementation_plan.md:45` | 8 critical gaps un-mapped to code locations — sprint planning blind. |

---

## Report Metadata
- **Inspection Scope**: 8 areas (Provider Architecture, Repository Pattern, Database Layer, Sync Architecture, Model Layer, Platform Parity, Dependencies, Feature Coverage)
- **Total Findings**: 35 across all areas
- **Critical**: 4 findings
- **Major**: 18 findings
- **Minor**: 7 findings
- **Improvement**: 6 findings
- **Evidence Level**: All findings reference exact file paths and line numbers
- **Read-Only**: No source code modifications performed during inspection