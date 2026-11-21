# QA / Test Inspection Report
**App:** Site and Worker Management (Flutter + Material 3, cross-platform Android + Windows)  
**Scope:** Read-only inspection of test inventory, quality, coverage, and gaps  
**Report Date:** 2026-11-21  
**Phase 1 Scope:** v21 (daily_reports), v22 (daily_report_photos), v23 (shifts), v24 (leave_requests), PDF export  
**All migrations must be reversible with documented rollback; no data loss; no breaking sync behavior changes**

---

## 1. Test Inventory Summary

| Category | Files | Lines | Coverage Focus |
|---|---|---|---|
| Characterization (DB contract) | 7 files | ~430 | SQLite schema, model behavior, mutations |
| Widget | 1 file | 7 | Basic widget scaffold |
| **Total** | **8 files** | **~437** | |

### Test Files Under `test/`:

| File | Purpose | Key Tests |
|---|---|---|
| `widget_test.dart` | Scaffold test | `project test harness is available` |
| `harness.dart` | Test infrastructure | `initCharacterizationEnvironment`, `openSeeded`, `expectGolden`, `countRows` |
| `harness_test.dart` | Minimal harness test | 3 sites visible, names match |
| `dashboard_contract_test.dart` | Dashboard contracts | `getDashboardStats()`, `getAllSites()`, `getWorkersBySite()`, attendance cascade on worker delete |
| `inventory_contract_test.dart` | Inventory mutations | `deductStoreStock`, `restoreStoreStock`, barcode lookup, duplicate product rejection, stock alerts |
| `notifications_contract_test.dart` | Notification rules catalogue | Rules catalogue under two settings profiles (all-on / all-off) |
| `payroll_contract_test.dart` | Payroll calculations | `calculatePaycheck`, `generatePayroll`, monthly summaries, payroll-for-month queries |
| `theme_contract_test.dart` | Theme color scheme | Light/dark color schemes, status/attendance color resolution, shape constants |

### Test Files **Not Found** (but referenced in plan):
- `test_driver/` — no Flutter driver / e2e infrastructure
- `integration_test/` — `integration_test` SDK line **commented out** in `pubspec.yaml` (line 65)
- `.github/workflows/` — **no CI config exists**

---

## 2. Coverage Analysis vs. Phase 1 Plan

### Phase 1 Feature Coverage by Test Category

| Phase 1 Milestone | Feature | Test Coverage | Gap |
|---|---|---|---|
| **Sprint 1** — Daily Site Reporting | Daily report creation, supervisor submission, draft auto-save, scheduled delivery, approval workflow | **0%** | No tests for DailyReportModel, DailyReportProvider, report form screens |
| **Sprint 2** — Attendance & Payroll | Shift management, leave management, attendance types, payroll calculation | **Partial** — payroll_contract_test.dart covers formulas; attendance tested via dashboard_contract_test.dart only |
| **Sprint 3** — PDF Export | PDF generation for daily reports, offline schedule delivery | **0%** | No PDF export tests; no offline/qeuing tests |
| **Migrations v21–v24** | daily_reports, daily_report_photos, shifts, leave_requests tables | **0%** | **No migration tests exist**; no rollback/reversibility tests |
| **Offline-First / Sync** | Offline queuing, retry, conflict resolution, SQLite ↔ Firebase RTDB sync | **0%** | No sync/offline tests; no Firebase mocks; no queuing tests |
| **Infrastructure** | Build/test commands, CI config | **0%** | No `.github/workflows/`; `integration_test` SDK line commented out |

### Critical Untested Paths (from earlier checkpoint)

| Path | Status | Risk |
|---|---|---|
| Payroll calculation | Partially covered (payroll_contract_test.dart runs formulas against seeded DB) | ⚠ Formula logic frozen in contracts; edge cases unexplored |
| Attendance validation | Covered only via `dashboard_contract_test.dart` attendance cascade | ⚠ No validation rules tested beyond seed data |
| Site / Worker CRUD | Not tested as separate contract | ⚠ Cascade/delete behavior only tested indirectly |
| Inventory document handling | Not tested beyond stock mutations in `inventory_contract_test.dart` | ⚠ Document-sync gaps |
| Offline queuing / conflict resolution | **Completely untested** | ⚠ Sync integrity risk if offline behavior changes |
| Migration v21–v24 reversible rollback | **No tests exist** | ⚠ Data loss risk if migration introduces breaking change |

---

## 3. Mock / Fake Usage Assessment

### Dependency Status (`pubspec.yaml`)

```yaml
dev_deps:
  flutter_test:
  flutter_lints: ^3.0.0
# integration_test: ^2.0.0  # ← commented out (line 65)
```

**No mock frameworks declared:** `mockito`, `mocktail`, `mockito_generator` are **absent**.

### Test Reality

- **All 7 characterization tests use real SQLite** via `DatabaseHelper` and `sqflite_common_ffi`.
- The `harness.dart` file initializes FFI (`sqfliteFfiInit()`), opens `worklist.db`, and loads `seed.sql`.
- `expectGolden` compares runtime output against frozen JSON contracts under `contracts/expectations/`.
- **No unit tests use mocks/stubs** — every test hits the real database.
- **No widget tests interact with real UI** beyond the basic scaffold test.

### Risk

- Tests are **fragile** — any schema or logic change breaks golden contracts.
- **No test isolation** beyond `--concurrency=1` (shared `worklist.db`).
- **No test doubles** means adding fake APIs or cloud behavior requires real infrastructure.

---

## 4. Migration Test Coverage & Rollback Status

### Current Schema

- Database version: **20** (`database_helper.dart` line 98: `version: 20`)
- `seed.sql` documents schema **up to v20** (the latest seeded migration).
- `onUpgrade` in `database_helper.dart` handles v1 → v20 transitions (20 upgrade blocks).
- **No upgrade path beyond v20** exists in the codebase.

### Planned Migrations (Phase 1, from `worklist_phase1_implementation_plan.md`)

| Migration | Table | SQL Definition | Test Coverage | Rollback Documented |
|---|---|---|---|---|
| **v21** | `daily_reports` | id, siteId, date, title, notes, workCompleted, status, supervisorId, createdAt, updatedAt, FK→sites | **0%** | **No** |
| **v22** | `daily_report_photos` | id, reportId, documentId, orderIndex, FK→daily_reports ON DELETE CASCADE, FK→documents | **0%** | **No** |
| **v23** | `shifts` | id, name, startTime, endTime, breakDurationMinutes, siteId, FK→sites ON DELETE SET NULL | **0%** | **No** |
| **v24** | `leave_requests` | id, workerId, startDate, endDate, type, reason, status, supervisorId, createdAt, updatedAt, FK→workers, FK→users | **0%** | **No** |

### Rollback / Reversibility Status

- **Zero rollback tests exist** in the repository.
- The `onUpgrade` method only migrates **forward** (v1 → v20); there is **no `onDowngrade`**.
- **No migration test** verifies that data can be round-tripped (upgrade then downgrade) without loss.
- **No documentation** of rollback procedures for v21–v24.
- **Risk:** If a migration introduces a breaking change, there is no automated way to revert zero-data-loss.

### Required Actions (before Phase 1 implementation)

1. **Write reversible migration scripts** for v21–v24 with documented `ROLLBACK` statements.
2. **Add migration tests** that:
   - Upgrade schema from v20 → v21 → v22 → v23 → v24
   - Populate new tables with sample data
   - Downgrade v24 → v23 → v22 → v21 → v20
   - Verify zero data loss at each step
3. **Freeze golden contracts** after each migration so `expectGolden` comparisons remain stable.
4. **Record rollback procedures** in `worklist_phase1_implementation_plan.md` or a separate ADR.

---

## 5. Offline-First / Sync Test Coverage

### What the App Supports (from architecture)

- **SQLite** as local offline-first store (`sqflite`, `sqflite_common_ffi`).
- **Firebase Auth + Realtime Database** (`firebase_auth`, `firebase_database`) for cloud sync.
- **SyncService** (`lib/core/sync/sync_service.dart`) — local HTTP server for peer-to-peer sync, plus `pullFromServer` / `pushToServer` cloud sync hooks.
- **Offline queuing** — changes are queued locally and pushed when connectivity restores.
- **Conflict resolution** — implied by the sync architecture but untested.

### Test Gaps (all 0%)

| Gap | Status | Risk |
|---|---|---|
| **Offline change queuing** | No tests | ⚠ Queuing logic could break under real offline conditions |
| **Retry on failed sync** | No tests | ⚠ Retry may loop or drop changes |
| **Conflict resolution** (last-write-wins, server-wins, user-resolve) | No tests | ⚠ Data corruption if conflicts aren't resolved correctly |
| **SQLite ↔ Firebase RTDB sync** | No tests (no Firebase mocks) | ⚠ Sync integrity unproven |
| **Push/pull commands from pubspec** | `pdf ^3.12.0`, `uuid ^4.5.3` listed but no sync test coverage | ⚠ New deps may have untested interactions |
| **Build/test commands** | Only `flutter test` available; no CI config | ⚠ No regression guard on every commit |

### Required Actions

1. **Write offline-first tests** that:
   - Simulate offline change, verify it's queued locally
   - Restore connectivity, verify push succeeds
   - Verify no duplicate entries after retry
2. **Write conflict-resolution tests** that:
   - Simulate two devices editing same record offline
   - Reconcile on reconnection with documented strategy
3. **Add Firebase mocks** (or integration tests with emulator) for sync behavior.
4. **Document build/test commands** and consider adding a minimal `.github/workflows/` CI config.

---

## 6. Build / Test Commands

| Command | Source | Notes |
|---|---|---|
| `flutter test` | `pubspec.yaml` dev_deps | Runs all `test/` and `test_widget` tests |
| `flutter test --dart-define=UPDATE_GOLDENS=true` | Characterization test helper | Regenerate frozen contracts when behavior changes |
| `flutter test --concurrency=1` | Required for shared `worklist.db` | Prevents concurrent DB writes |
| **CI / CD** | **None exists** | No `.github/workflows/` directory |
| **Build artifacts** | Not inspected | No APK/IPA build config inspected |

**Recommendation:** Add a minimal CI config that runs `flutter test --concurrency=1` on every commit. Consider enabling `integration_test` once the SDK dependency is uncommented and a driver is written.

---

## 7. Quality Gaps & Recommendations

### Must-Write Tests Before/Alongside Phase 1 Implementation

| Priority | Test Category | Rationale |
|---|---|---|
| **P0** | **Migration tests v21–v24** with rollback | Phase 1 mandate: all migrations reversible, zero data loss. No current coverage. |
| **P0** | **Offline queuing + retry tests** | Critical for construction-site usage where connectivity is intermittent. |
| **P0** | **Sync conflict resolution tests** | Ensures SQLite ↔ Firebase RTDB integrity across devices. |
| **P1** | **DailyReportModel / DailyReportProvider contracts** | Frozen `expectGolden` contracts for new v21 tables; without these, migrations cannot be verified. |
| **P1** | **PDF export test** (happy path + error path) | `pdf ^3.12.0` is a Phase 1 dependency; must verify offline PDF generation works. |
| **P1** | **ShiftModel / LeaveRequestModel contracts** | Phase 2 features; testing now prevents drift later. |
| **P2** | **Full CRUD tests for sites, workers** | Currently only indirect coverage via attendance cascade. |
| **P2** | **Firebase mock-based sync tests** | Replaces need for real RTDB in CI; enables regression guards. |
| **P3** | **Widget tests for new screens** (report form, shift detail, leave request) | Basic UI regression guard. |

### Recommended Test Additions (not yet in repo)

1. **`test/migration_v21_test.dart`** — upgrade to v21, verify `daily_reports` table, downgrade with zero data loss.
2. **`test/offline_queuing_test.dart`** — simulate offline change, verify queue, verify push on reconnect.
3. **`test/sync_conflict_test.dart`** — two-device scenario, reconcile conflicts.
4. **`test/pdf_export_test.dart`** — generate PDF from DailyReportProvider, verify file output.
5. **`test/daily_report_contract_test.dart`** — frozen contract for v21 daily_reports, like other `*_contract_test.dart` files.
6. **`test/worker_crud_test.dart`** — create/update/delete workers, verify cascade to site_workers/attendance.
7. **`test/payroll_edge_cases_test.dart`** — edge cases: zero attendance, multiple advances, half-day + overtime combos.

### Suggested CI Configuration (minimal)

```yaml
# .github/workflows/flutter_test.yml
name: Flutter Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: windows-latest
    flutter:
      channel: stable
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-setup@v2
      - run: flutter pub get
      - run: flutter test --concurrency=1
```

---

## 8. Summary of Findings

| Area | coverage | Grade | Comment |
|---|---|---|---|
| **Test inventory** | 8 files, ~437 lines | **F** | Sparse; no integration/e2e; no CI |
| **Phase 1 feature coverage** | 0% for v21–v24, offline/sync, PDF | **F** | Critical gaps vs. plan requirements |
| **Migration reversibility** | 0% | **F** | No rollback tests; no downgrade path; mandate unmet |
| **Mock / fake usage** | 0 frameworks | **D** | All tests use real SQLite; fragile but deterministic |
| **Offline-first / sync** | 0% | **F** | Untested; data integrity at risk |
| **Payroll / attendance** | ~30% (partial contract) | **C** | Formulas frozen in contracts; edge cases missing |
| **Theme / dashboard** | ~80% (contracts frozen) | **B** | Good coverage for existing v20 schema |
| **Build / CI** | 0% | **F** | No workflows; `integration_test` commented out |

### Overall Grade: **F**

The test suite is **insufficient for Phase 1 implementation**. The most critical gaps are:

1. **Zero migration test coverage** for v21–v24 with documented rollback — the Phase 1 mandate.
2. **Zero offline-first/sync testing** — risky for a construction-site app where connectivity is intermittent.
3. **No CI/CD configuration** — no regression guard on every commit.
4. **`integration_test` SDK dependency commented out** — no e2e testing infrastructure.

### Path Forward

- **Immediate:** Write migration tests v21–v24 with rollback, freeze golden contracts.
- **Short-term:** Add offline queuing + sync conflict resolution tests; uncomment `integration_test` and write minimal driver.
- **Medium-term:** Establish CI pipeline (`flutter test --concurrency=1`); add mock frameworks if test doubles are needed.
- **Long-term:** Reach 80%+ test coverage across all Phase 1 features before marking Phase 1 complete.

---
*Report generated from read-only inspection of `test/`, `lib/`, and `pubspec.yaml`. No source code was modified.*