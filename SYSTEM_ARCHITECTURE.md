# System Architecture — Worklist

Cross-platform (Windows + Android) construction/site & workforce
management app. Local-first SQLite, cloud-synced per Google account.

## High-level layers
```
┌─ UI (features/) ──────────────────────────────────────┐
│  sites · workers · attendance · payments · inventory ·   │
│  payroll · services · account · notifications · sync        │
├─ State (provider) ────────────────────────────────────┤
│  AuthProvider · SiteProvider · WorkerProvider ·         │
│  StoreProductProvider · UserServiceProvider · SyncService  │
│  ThemeProvider                                          │
├─ Domain / Repositories (core/repositories/) ───────────┤
│  Site · Worker · Payroll · Inventory · Dashboard ·     │
│  Auth · User repositories (wrap the SQLite file)          │
├─ Data (core/database/) ───────────────────────────────┤
│  DatabaseHelper — single user-scoped SQLite, FK ON,      │
│  covering indexes, versioned migrations (v1→v18+)        │
├─ Cloud (core/firebase/) ──────────────────────────────┤
│  FirebaseCloudService — RTDB per-user mirror, queued   │
│  upload/download, latest-wins conflict, offline retry   │
│  GoogleOAuthService · FirebaseConfig (App Check) ·      │
│  FirebaseDiagnostics                                    │
└─ Notifications (core/notifications/) ──────────────────┘
   engine · rules · scheduler · history · metrics ·
   actions · background · insights · sync
```

## Data model (per user_id)
- **users** (1 local row; mirrors the Firebase `uid`).
- **sites**, **workers**, **site_workers** (M:N, UNIQUE per user),
  **attendance** (UNIQUE per worker+date), **advance_payments**,
  **site_construction_payments**, **payroll**, **worker_performance**,
  **worker_documents**.
- **store_products**, **site_products**, **site_services**,
  **user_services**.
- All business tables carry `user_id` and `ON DELETE CASCADE`
  FKs → per-account isolation and safe deletes.

## SQLite integrity (verified)
- **Foreign keys**: `PRAGMA foreign_keys=ON`; 0 violations at
  stress volume.
- **Indexes**: `idx_att_worker_date`, `idx_att_site_date`,
  `idx_adv_*`, `idx_site_payments_site`, `idx_sw_*`,
  `idx_store_products_*`, `idx_payroll_worker`,
  `idx_sites_user_created`, `idx_workers_user_name`,
  `idx_products_site` — all `CREATE INDEX IF NOT EXISTS`
  (applied at create + on upgrade).
- **Migration**: `onUpgrade` is version-gated; existing installs
  at v16 reused the new `create` path so indexes are present.

## Firebase sync (verified)
- Path `users/$uid` per Google account → **Android ↔ Windows**
  converge on the same data.
- **Upload**: queued (`_markPendingSync`), retried with bounded
  exponential backoff; dirty flag survives crashes.
- **Download (pull)**: conflict guard compares cloud `updatedAt`
  vs local `dirtySince`; if local edits are newer, the destructive
  replace is skipped so the next push uploads the local copy
  (latest-wins, no silent data loss).
- **Notification metadata** syncs separately (see
  `NOTIFICATIONS_ARCHITECTURE.md`); business jobs untouched.
- **App Check** enforced via `FirebaseConfig` debug token in dev;
  production uses the platform App Check provider.
- **Auth tokens**: resolved from Google silent sign-in (stable
  `uid` across platforms); Windows force-refreshes the ID token on
  session restore (desktop plugin does not auto-refresh).

## Performance characteristics (stress-tested)
At 500 sites / 10k workers / 50k attendance / 20k payments /
20k inventory / 5k services (≈11 MB DB):
- All hot queries **sub-millisecond to single-digit ms** (indexed).
- Full 20k inventory scan ≈ 44 ms (acceptable; UI pages it).
- Notification `refresh()` does **one** history read + Set lookup
  per candidate (no per-candidate SharedPreferences round-trip).
- Metrics persist is **debounced** (no unbounded growth).

## UI / responsiveness
- Responsive shell: phone (<600dp) · tablet (600–1023dp) ·
  desktop (≥1024dp). Handheld forces compact layout.
- Dark/light theme via `ThemeProvider`.
- Keyboard navigation supported on Windows (standard Flutter focus).

## Security posture
- No hardcoded secrets; Firebase API keys are public web keys
  guarded by Security Rules + App Check.
- No `[STEP]` debug logging or test scaffolding remains in release
  code (removed in this final phase).
- `flutter analyze` is clean (0 errors/warnings).
