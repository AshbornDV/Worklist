-- Characterization seed for the Worklist database (schema v20).
-- Plain SQLite only: the Kotlin port replays this file verbatim.
-- The account row is created by DatabaseHelper.createAccount before this runs,
-- so user_id is 1 on a fresh database. Semicolons are statement delimiters, so
-- no comment or string literal may contain one.

-- Sites: created_at/updated_at are fixed so contracts never leak wall-clock time.
INSERT INTO sites (user_id, name, area, rate, status, estimated_cost, site_size, created_at, updated_at)
VALUES (1, 'Maple Tower', 'Baneshwor, Kathmandu', 1200, 'active', 480000, 'small', '2026-01-15T09:00:00.000', '2026-01-15T09:00:00.000');
INSERT INTO sites (user_id, name, area, rate, status, estimated_cost, site_size, created_at, updated_at)
VALUES (1, 'Birch Villa', 'Jhamsikhel, Lalitpur', 1500, 'completed', 900000, 'large', '2026-01-15T09:00:00.000', '2026-01-15T09:00:00.000');
INSERT INTO sites (user_id, name, area, rate, status, estimated_cost, site_size, created_at, updated_at)
VALUES (1, 'Cedar Depot', 'Suryabinayak, Bhaktapur', 900, 'on_hold', 150000, 'small', '2026-01-15T09:00:00.000', '2026-01-15T09:00:00.000');

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
