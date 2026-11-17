-- Characterization seed for the Worklist database (schema v20).
-- Plain SQLite only: the Kotlin port replays this file verbatim.
-- The account row is created by DatabaseHelper.createAccount before this runs,
-- so user_id is 1 on a fresh database. Semicolons are statement delimiters, so
-- no comment or string literal may contain one.

-- Sites: created_at/updated_at are fixed so contracts never leak wall-clock time.
INSERT INTO sites (user_id, name, area, rate, status, estimated_cost, site_size, created_at, updated_at)
VALUES (1, 'Maple Tower', 'Baneshwor, Kathmandu', 1200, 'active', 480000, 'small', '2026-01-15T09:00:00.000', '2026-01-15T09:00:00.000');
INSERT INTO sites (user_id, name, area, rate, status, estimated_cost, site_size, created_at, updated_at)
VALUES (1, 'Birch Villa', 'Jhamsikhel, Lalitpur', 1500, 'completed', 900000, 'large', '2026-01-15T10:00:00.000', '2026-01-15T10:00:00.000');
INSERT INTO sites (user_id, name, area, rate, status, estimated_cost, site_size, created_at, updated_at)
VALUES (1, 'Cedar Depot', 'Suryabinayak, Bhaktapur', 900, 'on_hold', 150000, 'small', '2026-01-15T11:00:00.000', '2026-01-15T11:00:00.000');

-- Workers: Anil Kumar carries 1.5x overtime (950 * 1.5 = 1425), the rest 0.0.
INSERT INTO workers (user_id, name, phone, trade, daily_rate, overtime_rate, status, created_at)
VALUES (1, 'Anil Kumar', '', 'mason', 950, 1425, 'active', '2026-01-15T09:00:00.000');
INSERT INTO workers (user_id, name, phone, trade, daily_rate, overtime_rate, status, created_at)
VALUES (1, 'Bina Shrestha', '', 'carpenter', 1100, 0, 'active', '2026-01-15T09:00:00.000');
INSERT INTO workers (user_id, name, phone, trade, daily_rate, overtime_rate, status, created_at)
VALUES (1, 'Chandra Rai', '', 'electrician', 1250, 0, 'active', '2026-01-15T09:00:00.000');
INSERT INTO workers (user_id, name, phone, trade, daily_rate, overtime_rate, status, created_at)
VALUES (1, 'Deepak Yadav', '', 'labour', 700, 0, 'active', '2026-01-15T09:00:00.000');

-- Site assignments: Anil + Bina on Maple Tower, Chandra on Birch Villa,
-- Deepak on Cedar Depot.
INSERT INTO site_workers (user_id, site_id, worker_id, assigned_date)
VALUES (1, 1, 1, '2026-01-15T09:00:00.000');
INSERT INTO site_workers (user_id, site_id, worker_id, assigned_date)
VALUES (1, 1, 2, '2026-01-15T09:00:00.000');
INSERT INTO site_workers (user_id, site_id, worker_id, assigned_date)
VALUES (1, 2, 3, '2026-01-15T09:00:00.000');
INSERT INTO site_workers (user_id, site_id, worker_id, assigned_date)
VALUES (1, 3, 4, '2026-01-15T09:00:00.000');

-- Attendance (March 2026, all in the past relative to the contract run).
-- Anil and Bina are on Maple Tower (site 1). Chandra is on Birch Villa (site 2).
-- Anil: full 03-02, 03, 04 and half 03-05.
INSERT INTO attendance (user_id, worker_id, site_id, date, type, created_at)
VALUES (1, 1, 1, '2026-03-02', 'full', '2026-03-02T09:00:00.000');
INSERT INTO attendance (user_id, worker_id, site_id, date, type, created_at)
VALUES (1, 1, 1, '2026-03-03', 'full', '2026-03-03T09:00:00.000');
INSERT INTO attendance (user_id, worker_id, site_id, date, type, created_at)
VALUES (1, 1, 1, '2026-03-04', 'full', '2026-03-04T09:00:00.000');
INSERT INTO attendance (user_id, worker_id, site_id, date, type, created_at)
VALUES (1, 1, 1, '2026-03-05', 'half', '2026-03-05T09:00:00.000');
-- Bina: full 03-02, 03-03 and absent 03-04.
INSERT INTO attendance (user_id, worker_id, site_id, date, type, created_at)
VALUES (1, 2, 1, '2026-03-02', 'full', '2026-03-02T09:00:00.000');
INSERT INTO attendance (user_id, worker_id, site_id, date, type, created_at)
VALUES (1, 2, 1, '2026-03-03', 'full', '2026-03-03T09:00:00.000');
INSERT INTO attendance (user_id, worker_id, site_id, date, type, created_at)
VALUES (1, 2, 1, '2026-03-04', 'absent', '2026-03-04T09:00:00.000');
-- Chandra: full 03-02 only.
INSERT INTO attendance (user_id, worker_id, site_id, date, type, created_at)
VALUES (1, 3, 2, '2026-03-02', 'full', '2026-03-02T09:00:00.000');

-- Approved advances. approved_date is in March 2026 because
-- getApprovedAdvancesTotal filters strftime('%Y-%m', approved_date).
INSERT INTO advance_payments (user_id, worker_id, amount, request_date, status, approved_date, notes, created_at)
VALUES (1, 1, 1850, '2026-03-10', 'approved', '2026-03-10T10:00:00.000', NULL, '2026-03-10T10:00:00.000');
INSERT INTO advance_payments (user_id, worker_id, amount, request_date, status, approved_date, notes, created_at)
VALUES (1, 2, 2500, '2026-03-12', 'approved', '2026-03-12T10:00:00.000', NULL, '2026-03-12T10:00:00.000');
-- Pending advance for Chandra. Excluded from approved advance totals.
INSERT INTO advance_payments (user_id, worker_id, amount, request_date, status, approved_date, notes, created_at)
VALUES (1, 3, 3000, '2026-03-13', 'pending', NULL, NULL, '2026-03-13T10:00:00.000');

-- Stored draft payroll for Anil. The month literal must be exactly 2026-03-01
-- so getPayrollForMonth can find it, even though toMap emits an ISO timestamp.
INSERT INTO payroll (user_id, worker_id, month, full_days, half_days, daily_rate, overtime_hours, overtime_rate, advance_amount, bonus, deductions, net_salary, status, notes, created_at, updated_at)
VALUES (1, 1, '2026-03-01', 3, 1, 950, 0, 0, 1850, 0, 0, 1475, 'draft', NULL, '2026-03-15T12:00:00.000', '2026-03-15T12:00:00.000');
