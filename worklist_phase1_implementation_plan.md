# Worklist Phase 1 Implementation Plan

**Date:** 20 Nov 2026  
**Purpose:** Bridge feature gaps identified in Phase 0 audit  
**Scope:** Implement missing core features to achieve feature parity with top competitors

---

## Executive Summary

Based on the feature gap matrix analysis, 8 critical gaps need addressing. This plan prioritizes features that:
1. Have no existing implementation
2. Are core to workforce site management
3. Are required for offline-first operation

---

## Phase 1 Priority: Core Workforce Management (MVP)

### Milestone 1: Daily Site Reporting Workflow (Sprint 1)

**Goal:** Enable supervisors to capture and submit daily site reports with photo documentation

**Features to Implement:**

1. **Daily Report Creation**
   - [ ] Create `DailyReportModel` extending existing `ReportModel` pattern
   - [ ] Add `siteId`, `date`, `photos[]`, `notes`, `workCompleted` fields
   - [ ] Create `DailyReportProvider` (ChangeNotifier pattern)

2. **Supervisor Submission Flow**
   - [ ] Add "Submit Report" button to site detail view
   - [ ] Implement draft saving (auto-save every 30 seconds)
   - [ ] Add supervisor approval workflow

3. **Scheduled Delivery**
   - [ ] Add `scheduledDeliveryTime` to `SiteModel`
   - [ ] Implement background notification for report deadline

**Repository Changes:**
- `lib/features/reports/models/daily_report_model.dart` (NEW)
- `lib/features/reports/providers/daily_report_provider.dart` (NEW)
- `lib/features/reports/screens/report_form_screen.dart` (NEW)
- `lib/features/reports/screens/report_list_screen.dart` (NEW)

---

### Milestone 2: Enhanced Attendance & Payroll (Sprint 2)

**Goal:** Add shift handling, leave management, attendance types

**Features to Implement:**

1. **Shift Management**
   - [ ] Create `ShiftModel` - defines shift patterns per site
   - [ ] Add `ShiftProvider` for CRUD operations
   - [ ] Modify `AttendanceModel` to reference `shiftId`

2. **Leave Management**
   - [ ] Create `LeaveRequestModel` with approval workflow
   - [ ] Add leave balance tracking in `WorkerModel`
   - [ ] Add `LeaveProvider`

3. **Enhanced Attendance Types**
   - [ ] Extend `AttendanceType` enum: `late`, `early_departure`, `half_day`
   - [ ] Update `AttendanceProvider` to validate attendance rules

**Repository Changes:**
- `lib/features/workforce/models/shift_model.dart` (NEW)
- `lib/features/workforce/models/leave_request_model.dart` (NEW)
- `lib/features/workforce/providers/shift_provider.dart` (NEW)
- `lib/features/workforce/providers/leave_provider.dart` (NEW)
- `lib/core/models/attendance_model.dart` (MODIFY)
- `lib/core/models/worker_model.dart` (MODIFY)

---

### Milestone 3: Offline-First Report Generation (Sprint 3)

**Goal:** Generate PDF reports for daily reports without server dependency

**Features to Implement:**

1. **PDF Export for Daily Reports**
   - [ ] Add `generateDailyReportPdf()` method to `DailyReportProvider`
   - [ ] Create PDF template with site details, worker attendance, photos
   - [ ] Add share/export button to report detail screen

2. **Offline Schedule Delivery**
   - [ ] Add `scheduledDeliveryEnabled` flag to `SiteModel`
   - [ ] Implement local notification scheduler
   - [ ] Add retry logic for failed deliveries

**Repository Changes:**
- `lib/core/services/report_pdf_service.dart` (NEW)
- `lib/features/reports/services/report_export_service.dart` (NEW)

---

## Phase 2: Advanced Features (Post-MVP)

### Future Features (Not in Phase 1 Scope)

1. **GPS/Time Tracking** - Requires device location permissions, external API integration
2. **Facial Liveness Recognition** - Requires camera + ML model integration
3. **QR/Geofenced Attendance** - Requires QR code generation + geolocation services
4. **Advanced Inventory** - Beyond basic product tracking

---

## Technical Architecture Notes

### Database Schema Updates Required

**v21 - Daily Reports Table**
```sql
CREATE TABLE daily_reports (
  id TEXT PRIMARY KEY,
  siteId TEXT NOT NULL,
  date TEXT NOT NULL,
  title TEXT,
  notes TEXT,
  workCompleted TEXT,
  status TEXT, -- draft, submitted, approved
  supervisorId TEXT,
  createdAt TEXT,
  updatedAt TEXT,
  FOREIGN KEY(siteId) REFERENCES sites(id)
);
```

**v22 - Daily Report Photos Junction**
```sql
CREATE TABLE daily_report_photos (
  id TEXT PRIMARY KEY,
  reportId TEXT NOT NULL,
  documentId TEXT NOT NULL,
  orderIndex INTEGER,
  FOREIGN KEY(reportId) REFERENCES daily_reports(id) ON DELETE CASCADE,
  FOREIGN KEY(documentId) REFERENCES documents(id)
);
```

**v23 - Shifts Table**
```sql
CREATE TABLE shifts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  startTime TEXT NOT NULL,
  endTime TEXT NOT NULL,
  breakDurationMinutes INTEGER,
  siteId TEXT,
  FOREIGN KEY(siteId) REFERENCES sites(id) ON DELETE SET NULL
);
```

**v24 - Leave Requests Table**
```sql
CREATE TABLE leave_requests (
  id TEXT PRIMARY KEY,
  workerId TEXT NOT NULL,
  startDate TEXT NOT NULL,
  endDate TEXT NOT NULL,
  type TEXT NOT NULL, -- annual, sick, emergency
  reason TEXT,
  status TEXT, -- pending, approved, rejected
  supervisorId TEXT,
  createdAt TEXT,
  updatedAt TEXT,
  FOREIGN KEY(workerId) REFERENCES workers(id),
  FOREIGN KEY(supervisorId) REFERENCES users(id)
);
```

---

## Development Order

| Sprint | Feature | Files to Create | Files to Modify |
|--------|---------|-----------------|-----------------|
| Sprint 1 | Daily Reports | 4 new files | None |
| Sprint 2 | Shifts & Leave | 6 new files, modify 2 | |
| Sprint 3 | PDF Export | 2 new files | |

---

## Dependencies

- Existing `DocumentModel` for photo storage (already implemented)
- `DatabaseHelper` for schema migrations
- `SyncService` for report synchronization
- `pdf` package (already in pubspec.yaml v3.12.0)

---

## Acceptance Criteria

1. Supervisor can create daily report from site screen
2. Report drafts auto-save offline
3. Report submission triggers approval workflow
4. Scheduled delivery notifies supervisor
5. Workers can request leave with supervisor approval
6. Attendance supports shift references
7. PDF reports can be generated offline
8. All new data persists through app restarts (SQLite)

---

## Verification Checklist

- [ ] Unit tests for new models (80% coverage minimum)
- [ ] Integration tests for providers
- [ ] UI tests for report workflows
- [ ] Manual testing on Android emulator
- [ ] Manual testing on Windows
- [ ] Offline scenario testing
- [ ] Sync conflict resolution testing

---

## Next Steps

1. Review this plan with stakeholder
2. Confirm sprint duration (suggested: 2 weeks each)
3. Allocate development resources
4. Set up CI/CD pipeline for new features
5. Begin Sprint 1 implementation

---

*Plan generated from Phase 0 audit findings. Uses existing Flutter provider patterns and SQLite schema conventions.*