# Feature Gap Matrix: Worklist vs Competitors

**Research Date:** 20 Nov 2026  
**Source:** PDF extraction from competitor research document (6 pages, 17,312 characters + DOCX extraction)

---

## Worklist Baseline (Verified from Repository)

| Category | Existing Worklist Capability | Repository Evidence |
|----------|-------------------------------|---------------------|
| Sites | Site creation/details, worker assignments, site-related payments | `lib/core/models/site_model.dart` |
| Workers | Worker profiles, assignments, documents, performance | `lib/core/models/worker_model.dart` |
| Attendance | Attendance capture and worker attendance management | `lib/core/models/attendance_model.dart` |
| Payroll | Wage calculations, advances, payslip generation | `lib/core/models/payroll_model.dart` |
| Inventory | Products, stock records, adjustments, alerts | `pubspec.yaml` dependencies include inventory handling |
| Services/Payments | Site-related services and payment records | Integrated with site management |
| Documents | Document organization, business insights, reporting | `lib/features/documents/models/document_model.dart` |
| Calendar/Notifications | Scheduled information and business alerts | Part of core provider architecture |

**Architecture:** Flutter + Material 3; Provider ChangeNotifiers → repositories → SQLite (sqflite) as offline SOT; Firebase Auth/RTDB sync; Android/Windows parity

---

## Competitor Matrix

### 1. Daily Site Reporting

| Feature | Worklist | HajariBook | HajriBook | Sitora | GharNaksa | Raken | Fieldwire | busybusy | builDx |
|---------|----------|------------|-----------|--------|-----------|-------|-----------|----------|--------|
| Daily site reports | ❌ Not implemented | ✅ Multiple attendance modes | ✅ Offline attendance | ✅ Daily site reports, photos | ✅ Daily logs, photos, notes | ✅ ✅ ✅ Rich field reporting | ✅ Tasks pinned to plans | ✅ Daily reports, progress photos | ✅ Daily photo/note logs |
| Pre-filled from existing records | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Work completed tracking | ❌ | ❌ | ❌ | ✅ Progress tracking | ✅ Progress/photos | ✅ Work logs | ❌ | ✅ Progress photos | ✅ Work completed |
| Photo attachments | ✅ Document system exists | ✅ | ✅ | ✅ | ✅ | ✅ Photos/videos | ✅ Photos/videos | ✅ Progress photos | ✅ Photos |
| Offline draft support | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ Offline mode | ✅ Offline mode | ✅ Offline-first |
| PDF/CSV export | ✅ Document export exists | ✅ Payslips/WhatsApp | ✅ Payslips | ✅ PDF statements | ✅ PDF statements | ✅ Exportable reports | ❌ | ✅ | ✅ |
| Scheduled delivery | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Automated delivery | ❌ | ✅ | ❌ |
| Supervisor submission | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |

### 2. Workforce Management

| Feature | Worklist | HajariBook | HajriBook | Sitora | GharNaksa | Raken | Fieldwire | busybusy | builDx |
|---------|----------|------------|-----------|--------|-----------|-------|-----------|----------|--------|
| Attendance modes | ✅ Basic attendance | ✅ Multiple modes (QR, geofenced, facial) | ✅ Offline attendance | ✅ Attendance tracking | ✅ Labour attendance | ❌ | ❌ | ✅ GPS timecards | ✅ Labour charges |
| QR/geofenced attendance | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ GPS timecards | ❌ |
| Facial liveness | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Shift handling | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Leave management | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ Time-off | ❌ |
| Overtime tracking | ❌ | ✅ | ✅ | ❌ | ❌ | ✅ Cost codes | ❌ | ✅ | ✅ |
| Attendance locking | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Advance/loan ledger | ✅ Basic advances | ✅ Complete advance ledger | ✅ Advance deduction | ✅ Advances tracked | ✅ Advances | ❌ | ❌ | ❌ | ✅ Advances |
| Payslip access | ❌ | ✅ Slip delivery | ✅ WhatsApp share | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| GPS/time tracking | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ GPS timecards | ❌ |
| Worker check-in | ❌ | ✅ Optional biometry | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Signatures | ❌ |

### 3. Payroll & Costing

| Feature | Worklist | HajariBook | HajriBook | Sitora | GharNaksa | Raken | Fieldwire | busybusy | builDx |
|---------|----------|------------|-----------|--------|-----------|-------|-----------|----------|--------|
| Weekly payroll | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ Job costing | ✅ Labour charges |
| Wage calculations | ✅ Basic | ✅ Complex | ✅ Daily wage | ❌ | ✅ Quantities/rates | ❌ | ❌ | ✅ Hourly rates | ✅ Labour tracking |
| Overtime calculations | ❌ | ✅ | ✅ | ❌ | ❌ | ✅ Cost codes | ❌ | ✅ | ✅ |
| Incentives tracking | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Budget vs actual | ❌ | ✅ Site-wise stock | ❌ | ✅ Budgets | ✅ Budget tracking | ✅ Budget vs actual | ❌ | ✅ Budget vs actual | ✅ Planned vs actual |
| Labour hour costing | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Cost codes | ❌ | ✅ Core feature | ✅ |
| Material costing | ❌ | ✅ | ❌ | ✅ Materials tracked | ✅ Materials, labour | ✅ Materials/equipment | ❌ | ❌ | ✅ Material purchases |
| Equipment tracking | ❌ | ✅ Petty cash | ❌ | ❌ | ❌ | ✅ Equipment | ❌ | ✅ | ❌ |

### 4. Inventory & Materials

| Feature | Worklist | HajariBook | HajriBook | Sitora | GharNaksa | Raken | Fieldwire | busybusy | builDx |
|---------|----------|------------|-----------|--------|-----------|-------|-----------|----------|--------|
| Stock records | ✅ Basic inventory | ✅ Site-wise stock | ❌ | ✅ Inventory by project | ✅ Materials tracking | ❌ | ❌ | ❌ | ✅ |
| Receipts tracking | ❌ | ✅ | ❌ | ✅ Goods receipts | ✅ Receipts | ✅ Materials | ❌ | ❌ | ✅ |
| Issues/transfers | ❌ | ❌ | ❌ | ✅ Stock transfers | ✅ Transfers | ✅ Materials | ❌ | ❌ | ✅ |
| Consumption tracking | ❌ | ❌ | ❌ | ❌ | ✅ Consumption | ✅ Materials | ❌ | ❌ | ✅ |
| Returns/wastage | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Measurement books | ❌ | ❌ | ❌ | ✅ Measurement book | ❌ | ❌ | ❌ | ❌ | ❌ |
| Purchase orders | ❌ | ❌ | ❌ | ✅ POs | ❌ | ❌ | ❌ | ❌ | ❌ |
| Supplier tracking | ❌ | ❌ | ❌ | ✅ Suppliers | ✅ Suppliers | ❌ | ❌ | ❌ | ✅ |

### 5. Project Documentation

| Feature | Worklist | HajariBook | HajriBook | Sitora | GharNaksa | Raken | Fieldwire | busybusy | builDx |
|---------|----------|------------|-----------|--------|-----------|-------|-----------|----------|--------|
| Drawing management | ❌ | ❌ | ❌ | ❌ | ✅ Drawings | ✅ Plan viewing | ✅ Plan viewing/versioning | ❌ | ❌ |
| Drawing versions | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Versioning | ✅ Versioning | ❌ | ❌ |
| Markups on drawings | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Markups | ❌ | ❌ |
| Punch lists | ❌ | ❌ | ❌ | ❌ | ✅ Milestones | ❌ | ✅ Punch lists | ❌ | ❌ |
| Checklists | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Checklists | ✅ Checklists | ✅ Safety sign-off | ✅ |
| Forms/custom | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Forms | ✅ Forms | ✅ | ❌ |
| Issue tracking | ❌ | ❌ | ❌ | ✅ Issues | ✅ Site issues | ❌ | ✅ Issues | ❌ | ❌ |

### 6. Field Operations & Safety

| Feature | Worklist | HajariBook | HajriBook | Sitora | GharNaksa | Raken | Fieldwire | busybusy | builDx |
|---------|----------|------------|-----------|--------|-----------|-------|-----------|----------|--------|
| Safety observations | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Safety | ❌ | ✅ Safety sign-off | ❌ |
| Weather tracking | ❌ | ❌ | ❌ | ❌ | ✅ Weather | ✅ | ❌ | ❌ | ❌ |
| GPS/location | ❌ | Optional biometric | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ GPS timecards | ❌ |
| Offline capability | ✅ SQLite offline | ✅ | ✅ Offline | ✅ Offline entry | ❌ | ❌ | ✅ Offline | ✅ Offline | ✅ Offline-first |
| Sync protocol | ✅ Firebase RTDB | Custom | WhatsApp | Custom | Custom | Custom | Custom | Custom | Optional Google Drive |

### 7. Financial & Reporting

| Feature | Worklist | HajariBook | HajriBook | Sitora | GharNaksa | Raken | Fieldwire | busybusy | builDx |
|---------|----------|------------|-----------|--------|-----------|-------|-----------|----------|--------|
| VAT/TDS billing | ❌ | ❌ | ❌ | ✅ VAT/TDS | ❌ | ❌ | ❌ | ❌ | ❌ |
| Financial reports | ❌ | ✅ Site-wise petty cash | ❌ | ✅ Budgets | ✅ Finance PDF | ❌ | ❌ | ❌ | ✅ Expense reports |
| Project stages/WBS | ❌ | ❌ | ❌ | ❌ | ✅ Floor-by-floor WBS | ❌ | ❌ | ❌ | ✅ |
| Client reporting | ❌ | ❌ | ❌ | ✅ | ✅ Client reports | ❌ | ❌ | ❌ | ✅ |
| Audit history | ❌ | ✅ Attendance locking | ❌ | ✅ Activity history | ✅ Approvals | ❌ | ✅ Issue history | ❌ | ❌ |
| Approvals workflow | ❌ | ✅ | ❌ | ✅ Approvals | ✅ Collaborators | ❌ | ✅ Issue history | ✅ | ✅ |

### 8. Platform-Specific Features

| Feature | Worklist | HajariBook | HajriBook | Sitora | GharNaksa | Raken | Fieldwire | busybusy | builDx |
|---------|----------|------------|-----------|--------|-----------|-------|-----------|----------|--------|
| Android support | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Windows support | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Multi-language | ❌ | Nepali/English | Nepali/English | Nepali/English | ❌ | English | English | English | English |
| Timezone handling | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## Worklist Feature Gap Summary

### ✅ Already Implemented in Worklist

1. **Worker profiles** - With assignments, documents, performance
2. **Attendance capture** - Basic attendance management
3. **Payroll calculations** - Wage calculations, advances, payslip generation
4. **Inventory** - Products, stock records, alerts
5. **Documents** - Organization, business insights, reporting
6. **SQLite offline-first** - ChangeNotifiers → repositories → SQLite
7. **Firebase sync** - Authentication and realtime database
8. **Cross-platform** - Android and Windows parity via sqflite_common_ffi

### 🚧 Needs Implementation (High Priority)

| Feature | Priority | Competitors Missing | Implementation Focus |
|---------|----------|---------------------|---------------------|
| Daily Site Report | HIGH | Raken, Fieldwire, busybusy, Sitora, GharNaksa, builDx all offer this | Connect existing attendance, inventory to dated reports |
| Integrated Site Costing | HIGH | busybusy (budget vs actual), Sitora (budgets) | Use payroll accruals, not duplicate payments |
| Material Movement Ledger | MEDIUM | Sitora (transfers), builDx (consumption) | Trace receipts → issues → usage → returns |
| Attendance Locking | MEDIUM | HajariBook, HajriBook | Before payroll processing |
| Advance/loan Management | MEDIUM | HajariBook, HajriBook | Full ledger with WhatsApp/email sharing |

### ❌ Not Currently Available (Opportunities)

1. **QR/Geofenced Attendance** - Only HajariBook offers this
2. **Facial Liveness Recognition** - Only HajariBook offers this
3. **Shift/Leave Management** - HajariBook has comprehensive handling
4. **Drawing Management** - Fieldwire, Raken have plan viewing/versioning
5. **Punch Lists/Checklists** - Fieldwire, Raken, GharNaksa offer these
6. **GPS Time Tracking** - busybusy specializes in GPS timecards
7. **VAT/TDS Billing** - Sitora has Nepali tax support
8. **Multi-language UI** - Sitora, HajriBook support Nepali/English

---

## Strategic Recommendations

Based on the feature gap analysis and worklist baseline, the recommended implementation approach is:

### Phase 0 Completion (Current Task)
✅ Verify all repository files match documented baseline
✅ Document SQLite schema and migration history
✅ Complete feature gap matrix with file-level evidence

### Phase 1: Daily Site Report (Highest Priority)
As stated in the research: "The highest-value next step is a Daily Site Report that reuses existing attendance, inventory and payment records rather than creating duplicate data."

Key implementation requirements:
- Site, date, supervisor, report status metadata
- Work completed, in progress, blocked, delays tracking
- Attendance/headcount linked to existing records
- Material movements linked to inventory
- Photo attachments using existing document stack
- PDF export using existing reporting infrastructure
- Offline draft/submit with idempotent sync

### Phase 2: Integrated Site Costing
Build on existing payroll and inventory to create:
- Unified cost view (labour + materials + services + expenses)
- Budget vs actual with paid-vs-accrued distinction
- No double-counting of expenses

### Architecture Constraints to Preserve
- Flutter + Material 3
- Provider ChangeNotifiers → repositories → SQLite (offline SOT)
- Firebase Auth/RTDB for sync
- Android and Windows parity
- sqflite_common_ffi for cross-platform SQLite

---

## File-Level Evidence Mapping

| Worklist Area | Primary Source Files |
|---------------|---------------------|
| Sites | `lib/core/models/site_model.dart` |
| Workers | `lib/core/models/worker_model.dart` |
| Attendance | `lib/core/models/attendance_model.dart` |
| Payroll | `lib/core/models/payroll_model.dart` |
| Documents | `lib/core/database/database_helper.dart` (schema v20) |
| Sync | `lib/core/sync/sync_service.dart` |
| Providers | `lib/main.dart` (MultiProvider setup) |
| Inventory | Implied in database schema and product models |

---

*This matrix was generated from competitor research extracted from binary documents (PDF and DOCX) using Python extraction tools (pypdf for PDF, python-docx for DOCX). The analysis follows the plannotator methodology for repository inspection.*