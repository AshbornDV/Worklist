# Claude Code Master Prompt: Improve Worklist Using Construction-App Research

**Research snapshot:** 20 November 2026  
**Project:** Worklist - existing construction site and workforce management app  
**Mode:** Audit first, preserve architecture, implement in small verified phases

You are working inside the existing Worklist repository. This is NOT a greenfield application and NOT permission to rewrite it. Your first responsibility is to understand the current implementation and preserve working functionality.

## 1. Product context and current baseline

Worklist already has functional areas for:
- Sites and site details
- Worker profiles, assignments, documents and performance
- Attendance
- Payroll, payslips, wage calculations and advances
- Products, inventory and stock management
- Site materials and site services
- Payments and business records
- Analytics, calendar and notifications

The known architecture is Flutter + Material 3, Provider ChangeNotifiers, repositories, SQLite (`sqflite` / `sqflite_common_ffi`) as the offline source of truth, and Firebase Authentication / Google Sign-In with Realtime Database synchronization under `users/{uid}`. Android and Windows support are both important. Verify all of this against the actual repository before relying on it; the repository and its tests are the source of truth.

## 2. Competitor research findings to use as design references

Use these as workflow references, not as requirements to copy wholesale:

1. **HajariBook by Fiveone Digital** - site/worker attendance, multiple attendance modes, QR and geofenced/self-attendance options, shift attendance, leave, overtime, advances, incentives, attendance locking, weekly payroll, payslips, site-wise material balances and petty cash/site cashbooks. Its Google Play listing showed a 10 November 2026 update and lists features including leave categories, multi-site self-attendance, loan ledger, incentives, QR attendance and email-enabled salary slip/report templates. Treat location/face verification as optional and privacy-sensitive.
   Source: https://play.google.com/store/apps/details?id=com.fiveone.labour

2. **HajriBook by Jagati Apps** - a separate app with a similar name, focused on offline worker attendance, muster rolls, daily wage calculation, advances and salary slips shared through WhatsApp. The listing states offline operation and a September 2026 update. Do not conflate it with Fiveone Digital's HajariBook.
   Source: https://play.google.com/store/apps/details?id=com.hajribook.hajribook

3. **Sitora (Nepal)** - daily site reports, photos, attendance, progress, inventory by project/store, purchase orders, goods receipts, stock issues/transfers, measurement book and RA billing, BOQ quantity/certification/deductions, project budgets/payments/advances, VAT/TDS, attendance/overtime/payroll and activity history. Its website states Nepali and English support and offline entry for supported site tasks.
   Source: https://sitora.cc/

4. **GharNaksa (Nepal)** - material, labour and payment tracking; quantity/rate/supplier details; daily logs, weather and notes; issue tracking; stage photos; floor-by-floor work breakdown/checklists; drawings/documents; schedules/milestones; collaborator access; client-facing PDF reports.
   Source: https://app.gharnaksa.com/

5. **Raken** - daily field reports with work logs, notes, photos/videos, timestamps, timecards, safety notes, materials/equipment and cost-code details; PDF/CSV/XLS reports and scheduled report delivery; AI daily-report summaries are advertised. Its Help Center describes daily, manpower, project-summary and tasks exports.
   Sources: https://www.rakenapp.com/features/daily-reports and https://help.rakenapp.com/en/articles/14465432-raken-reports-overview

6. **Fieldwire by Hilti** - drawing/plan viewing and versioning, plan markups, tasks pinned to drawings, punch lists, inspections, checklists, photos/videos and forms. Android/iOS can work offline with previously downloaded project content and sync later; offline behavior has constraints and must be designed carefully.
   Sources: https://www.fieldwire.com/ and https://help.fieldwire.com/hc/en-us/articles/202631944-Q-A-Can-I-use-Fieldwire-while-offline

7. **busybusy** - construction timecards, GPS employee/equipment tracking, signed timecards, budgets, daily reports, GPS/time-stamped progress photos, safety/time sign-off, budget-versus-actual tracking and offline time-clock mode.
   Source: https://busybusy.com/

8. **builDx - Construction Reporter** - Nepal-developed, offline-first project cost and site reporting reference: material purchases, labour charges, advances, service charges, daily photo/note updates, estimates, planned-versus-actual comparison and expense reports. Its listing describes optional Google Drive backup. The store listing describes an early release; treat this as a workflow reference, not proof of mature scale.
   Source: https://play.google.com/store/apps/details?id=com.softcrunch.buildx

## 3. Product direction

Make Worklist a practical, offline-capable construction operations app that connects:
- What happened on each site today
- Which workers were present and what labour cost accrued
- Which materials were received, issued, consumed, returned or wasted
- Which tasks progressed or became blocked
- What was spent, paid, committed and left in the budget
- Who entered, changed, submitted and approved each record

Do not expand the app by adding disconnected screens. Reuse existing site, worker, attendance, payroll, inventory, service, payment, document and notification data wherever possible.

## 4. Phase 0 - mandatory repository audit before coding

Before changing code:
1. Map the app's folder structure, routes, screens, providers/ChangeNotifiers, repositories, SQLite tables, migrations, Firebase RTDB paths, background jobs and notification services.
2. Identify the existing site, worker, attendance, payroll, advance, product/stock, service/payment, document and reporting models. Find where each is read/written.
3. Trace the full offline write -> local persistence -> sync queue/change detection -> Firebase synchronization -> conflict/error handling -> UI refresh flow.
4. Inspect Android and Windows platform-specific differences, especially SQLite initialization, file/photo storage, PDF generation, notifications and permissions.
5. Read current implementation plans, architecture docs, tests and TODOs. Check whether daily reports, tasks, audit history, material movements or costing already exist in partial form.
6. Build a feature-to-existing-code map. Mark each proposed capability as `already exists`, `partial`, `missing` or `unclear` with file paths and evidence.
7. Run existing tests and record the baseline. Do not silently fix unrelated defects during the audit.

Deliver a concise audit summary and implementation plan before the first substantial change. If the repository differs from the context above, follow the repository and document the difference.

## 5. Phase 1 - Daily Site Report (highest-value first feature)

Implement a daily report for each site and local calendar date, integrated with current Worklist records.

### Report contents
- Site and report date
- Supervisor/author and report status (`draft`, `submitted`, `approved`, `rejected` if the app's existing approval convention supports it)
- Work completed, work in progress and blockers/delays
- Worker attendance/headcount derived from existing attendance records; avoid re-entering the same attendance
- Labour hours/cost when reliable data already exists
- Materials received/issued/consumed/returned/wasted, linked to the movement ledger where present
- Services/equipment notes where relevant
- Progress photos and attachments with timestamps and site association
- Optional weather, safety/quality observations and general notes
- Submitted/approved timestamps and actor identity

### UX requirements
- A clear `Today's Work` entry point from the main dashboard and from each site.
- Fast supervisor workflow: prefill data already held in Worklist; allow the supervisor to add only the missing narrative, photos and exceptions.
- Draft autosave; explicit submit; prevent accidental duplicate report for the same site/date unless the product has a supported multi-shift/report policy.
- Show missing sections without forcing users to enter irrelevant information.
- Generate a clean, shareable PDF using existing document/PDF conventions; do not add a second PDF stack if one already exists.
- Use existing navigation and Material 3 components; remain responsive on Android and Windows.

### Data/engineering requirements
- Follow the existing Provider -> repository -> SQLite architecture.
- SQLite remains the offline source of truth. Implement safe schema migrations and backward compatibility.
- Sync reports and attachments using existing Firebase conventions. Do not upload local file paths as if they were remote URLs.
- Use stable IDs, idempotent sync and clear retry/error states. Handle records created offline and later synced.
- Preserve actor, created/updated time and approval metadata.
- Add validation and tests for same-site/same-date uniqueness, draft editing, submit/approve permissions, offline creation, reconnect sync, duplicate retry and report export.

## 6. Phase 2 - Site cost overview (after Phase 1 is stable)

Create one project financial view by combining existing records rather than duplicating them.

Show separately:
- Labour cost accrued from attendance/payroll for the selected period
- Material cost, with a clearly defined basis (purchase cost, issue cost or consumed cost)
- Service/contractor cost
- Other approved site expenses
- Cash paid versus cost accrued (these are not always the same)
- Committed cost from approved purchase orders, only if Worklist supports those records
- Original budget, actual cost, committed cost and remaining budget
- Planned-versus-actual trend and cost breakdown

Critical accounting rule: prevent double counting. A stock purchase, transfer, issue and consumption are different events. A site transfer must not create a second company-wide expense. Paying a wage or supplier bill must not add the same cost a second time if the underlying accrual is already counted. Document the calculation rules and test them.

## 7. Phase 3 - Material movement ledger

If not already implemented, introduce traceable movements:
- Purchase/receipt into a store
- Issue to a site
- Consumption/use
- Return from site
- Transfer between stores/sites
- Wastage/damage/adjustment

Each movement should have a stable ID, product, quantity/unit, source, destination, date, actor, optional bill/challan/photo, reason and link to an originating record. Maintain immutable movement history; corrections should be reversal/adjustment records rather than destructive edits where feasible. Keep stock balances derived from movements or reconcile them safely with current stock tables.

## 8. Phase 4 - Tasks and work milestones

If absent, implement a lightweight work breakdown:
- Site stages and tasks
- Assignee/team, start and due dates
- Status and progress
- Priority and blocker/issue notes
- Checklists and photos
- Optional links to drawings/documents
- Timeline or simple Kanban presentation

Do not attempt a full BIM/CAD or heavyweight Gantt platform in the first iteration. Keep task updates usable offline and sync them safely.

## 9. Phase 5 - workforce and approval improvements

Audit what is already present before adding anything. Candidate improvements:
- Attendance locking before payroll finalization
- Leave and shift handling
- Supervisor permissions scoped to assigned sites
- Optional QR or GPS check-in where justified by the workflow
- Worker-facing payslip delivery/access
- Clear advance/loan and deduction ledgers
- Approval history and audit trail

Treat GPS and biometrics as optional, explicit-permission, privacy-sensitive features. Do not introduce continuous location tracking or face recognition as a default. Provide a non-GPS supervisor attendance path and explain permission use. Never expose workers' sensitive information to unauthorized site users.

## 10. Nepal-specific usability

Evaluate and implement only where it fits the existing localization architecture:
- Nepali and English labels
- BS and AD date display/input without corrupting stored canonical dates
- Nepal timezone defaults (`Asia/Kathmandu`)
- NPR currency formatting
- VAT/TDS and RA-bill workflows only with clearly defined business rules and configurable rates; do not hard-code legal/tax assumptions without verification.

Keep dates stored in a stable canonical format and convert for display. Add tests around BS/AD conversion, month boundaries and timezone handling if supported.

## 11. Non-negotiable engineering constraints

- No rewrite or migration to a new state-management framework.
- No removal of working screens, routes, database fields or sync behavior without proof and explicit migration strategy.
- No direct SQLite/Firebase access from UI widgets if repository conventions exist.
- Do not make cloud availability mandatory for core site work.
- Do not break Android/Windows parity; test both where applicable.
- Respect existing code style, naming, dependency versions and architecture.
- Keep dependencies minimal. Explain every new dependency and Windows compatibility.
- Add migrations, repository/provider tests and UI tests for meaningful changes.
- Test failure paths: offline, repeated sync, duplicate submit, partial attachment upload, permission denial and app restart.
- Protect user data. Never log credentials, tokens or sensitive worker information.
- Do not claim a feature is complete until implementation, tests and manual verification evidence exist.

## 12. Implementation workflow and deliverables

Work in small vertical slices:
1. Audit repository and baseline tests.
2. Produce a feature gap matrix and file-level implementation plan.
3. Implement Phase 1 (Daily Site Report) only, unless an equivalent feature already exists; if it exists, improve the gaps rather than creating a duplicate.
4. Add migrations, sync, permissions, UI, PDF export and tests.
5. Run formatter, analyzer/linter, unit tests and relevant integration tests.
6. Verify Android and Windows builds if toolchain is available. If not, say exactly what could not be verified.
7. Update implementation documentation and changelog.
8. Summarize changed files, schema changes, sync implications, test results, known limitations and next phase.

Do not implement all phases blindly in one enormous change. Complete Phase 1 cleanly, then present Phase 2-5 as the next prioritized backlog. Keep existing data safe. If a required behavior is ambiguous, choose the least destructive option and document the assumption rather than silently inventing business rules.

## 13. Final acceptance criteria

The change is acceptable only when:
- Existing app behavior continues to work.
- A supervisor can create and submit a site's daily report without a network connection.
- Existing attendance/material/payment data is reused rather than duplicated.
- Offline records sync without duplicate creation or data loss.
- A report can be exported/shared in a clean PDF.
- Permissions and approval history are respected.
- Automated tests cover core data, migration and sync behavior.
- Android and Windows compatibility has been verified or limitations clearly recorded.

Begin with Phase 0: inspect the actual Worklist repository and report the evidence-based feature gap matrix. Do not start by rewriting code.
