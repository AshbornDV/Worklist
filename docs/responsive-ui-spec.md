# Worklist — Responsive UI Design Specification (Mobile / Tablet / Desktop)

**Scope:** UI-only design specification for the Worklist construction site & workforce
management platform (CMS/ERP). Three device targets derived directly from the supplied
reference screenshots (mobile portrait, tablet landscape/hybrid, desktop with sidebar).

**Authoritative source of truth:** the three attached reference images. This document
describes the **target** design. Sections marked *[GAP]* are not yet implemented in
`lib/features/dashboard/*` and must be built to match.

---

## 0. Design System (shared across all three)

### 0.1 Color palette
| Token | Value (approx) | Usage |
|---|---|---|
| Background | `#FFFFFF` (app) / `#F5F6F8` (content area on tablet/desktop) | Page & content surfaces |
| Surface / Card | `#FFFFFF` | Cards, raised panels |
| Card border | `#ECEEF1` 1px | Subtle separation (no heavy shadow) |
| Primary / Accent | `#2563EB` (blue) | Active states, icons, links, "View All" |
| Primary soft fill | `#E8F0FE` (light blue) | Selected bottom-nav / sidebar item bg |
| Positive | `#16A34A` (green) | Upward trend arrows, present counts |
| Negative / Alert | `#DC2626` (red) | Downward trends, out-of-stock, logout, badge |
| Warning | `#F59E0B` (amber) | Stock-alert triangle, "Pending Payments" wallet icon |
| Purple | `#7C3AED` | Total Products box icon |
| Pink | `#EC4899` | Today's Expenses card icon |
| Teal | `#0D9488` | Workers Present check icon |
| Text primary | `#1F2937` | Headlines, values |
| Text secondary | `#6B7280` | Subtext, labels, trends |

### 0.2 Typography
- Family: system sans-serif (Roboto / Segoe UI / San Francisco per platform).
- Greeting: bold, ~22–26 sp, `#1F2937`.
- Card value: bold, ~22–28 sp, `#1F2937`.
- Card label: medium, ~13 sp, `#6B7280`.
- Section title: bold, ~18 sp, `#1F2937`.
- Section subtext: regular, ~13 sp, `#6B7280`.

### 0.3 Shape & elevation
- Card radius: **16 px**. Icon chips: **12 px**. Buttons: **10–12 px**.
- Elevation: 1px hairline border `#ECEEF1` + soft shadow
  `0 1px 2px rgba(16,24,40,0.04), 0 1px 3px rgba(16,24,40,0.06)`. No heavy drop shadows.

### 0.4 Icon style
- Outlined Material icons for idle state; rounded/solid for active (`_NavItem`
  already carries `icon` + `activeIcon`).
- Stat-card icons sit in a 40px rounded chip tinted with the icon's brand color at ~12% alpha.
- Notification bell carries a **red circular badge with white "3"** in the top-right.

### 0.5 Core dashboard elements (must appear on ALL three devices)
1. Header: greeting **"Good Morning, {first_name} 👋"** + subtext
   *"Here's what's happening on your projects today."* + date-range chip
   *(21 May – 21 May, 2024)* on tablet/desktop.
2. **8 metric cards**: Active Sites, Total Workers, Workers Present Today,
   Workers Absent Today, Total Products, Materials Issued Today,
   Pending Payments (Rs.), Today's Expenses (Rs.) — each with a colored icon chip,
   a big value, and a trend line (*↑ / ↓ N vs yesterday* or *Rs. N vs yesterday*).
3. **Stock Alerts** card (warning triangle, "N product(s) need attention",
   out-of-stock/critical/low breakdown, item row with red qty, "Open" button).
4. **Recent Activity** list (timestamped events). *[GAP] — not in current `home_content`.*
5. **Analytics & Charts**: Attendance Overview (bar), Sites Overview (donut),
   Top Material Issued (horizontal bar). *[GAP] — only chart widgets exist in
   `dashboard_charts.dart`; not composed into `home_content` yet.*
6. **Notification badge (3)** + personalized greeting.

---

## 1. MOBILE (portrait, < 600 dp)

### 1.1 Layout & grid
- Single scroll column, max content padding **16 px**.
- Status bar + app header (hamburger left, logo+**Worklist** center, bell w/ badge right).
- Greeting block (left-aligned).
- **Metric cards: 2 columns**, equal-width, gap **12 px**. 8 cards → 4 rows.
- Stock Alerts, Recent Activity, Analytics & Charts stack full-width, gap **16 px**.
- Analytics: charts stack **vertically** (each ~full width, height ~200 px).

### 1.2 Navigation
- **Bottom navigation bar**, 5 items, fixed, height **64 px**, top hairline border:
  `Dashboard (grid)`, `Sites (building)`, `Workers (person)`,
  `Attendance (clipboard)`, `More (three-dot)`.
- Active item: light-blue rounded background + blue icon/label.
- **Hamburger → left Drawer** for everything else (Remaining, Account, Settings, Logout).
- Tap targets ≥ **48×48 px**. Bottom-nav icon hit area ≥ 56 px wide.

### 1.3 Card / spacing rules
- Card padding **16 px**. Icon chip **40 px**. Value line height tight.
- Trend text **12 sp**, green/red, with arrow glyph.
- Vertical rhythm between sections **16 px**.

### 1.4 Interactions
- Pull-to-scroll only. No hover. Ripple on tap.
- "View All" = text button (blue, no background).
- Bottom-nav tap → route push; back press closes drawer, not app (drawer only).

---

## 2. TABLET (600–1199 dp, landscape/hybrid)

### 2.1 Layout & grid
- **Left sidebar** (persistent, ~240 px) + main content area on `#F5F6F8`.
- Top app bar inside content: **"Dashboard"** title + hamburger (collapses sidebar),
  date-range chip right, bell w/ badge, refresh icon.
- **Metric cards: 4 columns** on ≥900 dp, **2–3 columns** 600–899 dp, gap **16 px**.
- Middle row: **2 columns** → Stock Alerts (left) | Recent Activity (right).
- Analytics: **3 columns** (Attendance bar | Sites donut | Top Material horizontal),
  each card ~equal width, height ~240 px. Collapse to 1 column < 820 dp.

### 2.2 Navigation (sidebar)
- Vertical list, icon + label, **13 items** (per reference):
  Dashboard, Sites, Workers, Attendance, Payroll, Products, Stock, Services,
  Reports, Payments, Notifications, Account, Settings.
- Active: light-blue rounded bg + blue icon/label. Hover: subtle `#F0F2F5` fill.
- Bottom: user profile chip (**avatar + name + role + chevron**) and **Logout**
  (red text + exit icon).
- *[GAP] current `_navItems` has only 6 (Dashboard, Remaining, Sites, Workers,
  Attendance, Account) — extend to match reference.*

### 2.3 Spacing & touch
- Content padding **24 px**. Cards **16–20 px** padding.
- Hybrid input: touch + stylus; tap targets ≥ 44 px; sidebar rows 44 px tall.

### 2.4 Interactions
- Sidebar item hover/focus states. Date chip opens range picker.
- Charts gain tooltips on long-press/tap (no hover on tablet).

---

## 3. DESKTOP (≥ 1200 dp, full sidebar)

### 3.1 Layout & grid
- **Fixed left sidebar** (~260 px) with logo, full 13-item nav, profile + logout
  (same as tablet sidebar, always expanded).
- Top header bar (content area): hamburger (toggles sidebar collapse),
  **search field** *"Search anything…  Ctrl /"*, bell w/ badge, **theme/sun toggle**,
  user avatar.
- **Metric cards: 4 columns** (gap 16–20 px). 8 cards in 2 rows.
- Middle: **2 columns** Stock Alerts | Recent Activity.
- Analytics: **3 columns** (Attendance | Sites donut | Top Material), height ~260 px.
- Max content width optionally capped (~1600 px) and centered on ultra-wide.

### 3.2 Navigation (sidebar) + collapse
- Sidebar collapsible to **icon-rail (~72 px)** via hamburger/chevron; labels hide,
  active item shows blue icon + soft indicator. State persists per session.
- *[GAP] current desktop uses a non-collapsible 220 px sidebar (≥840 dp); reference
  shows a toggle. Add animated collapse (AnimatedContainer 260↔72).*

### 3.3 Desktop interactions
- **Hover states**: nav rows `#F0F2F5`, cards lift (shadow + 1px translateY),
  "View All" underline.
- **Focus states**: 2 px blue focus ring for keyboard users (sidebar, search, buttons).
- Search field: `Ctrl /` focuses; Esc clears. Bell → notifications panel/drawer.
- Sun icon → light/dark theme toggle (theme already exists in `app_theme.dart`).

---

## 4. Responsive breakpoints & transitions

| Breakpoint | Nav model | Metric cols | Middle | Analytics |
|---|---|---|---|---|
| **< 600** (phone) | Drawer + bottom nav (5) | 2 | stacked | stacked |
| **600–899** (tablet sm) | Sidebar (labels) | 2–3 | stacked/2 | 1–2 col |
| **900–1199** (tablet lg) | Sidebar (labels) | 4 | 2 col | 3 col |
| **≥ 1200** (desktop) | Sidebar (collapsible) + top search | 4 | 2 col | 3 col |

- Transition rule: layout switches are **snap** (no animated reflow); only the
  sidebar collapse animates (280 ms ease). Cards use `LayoutBuilder`/`GridView`
  with `crossAxisCount` derived from `MediaQuery().size.width` so heights stay natural.
- Single source of nav truth: one `AdaptiveNavigation` selector in
  `DashboardScreen.build` switching `_MobileLayout` / `_TabletRail` / `_CollapsibleSidebar`
  by width.

---

## 5. Implementation gaps vs current code (action list)

| # | Gap | Current | Target (reference) |
|---|---|---|---|
| 1 | Bottom nav items | 6 (Dashboard, Remaining, Sites, Workers, Attendance, Account) | **5**: Dashboard, Sites, Workers, Attendance, **More** |
| 2 | Sidebar items | 6 | **13** (add Payroll, Products, Stock, Services, Reports, Payments, Notifications, Settings) |
| 3 | Stock Alerts section | absent in `home_content` | build from `StoreProduct` low-stock query |
| 4 | Recent Activity section | absent | build from activity log / recent inserts |
| 5 | Analytics composition | chart widgets exist, not composed | compose Attendance + Sites + Top Material into `home_content` |
| 6 | Desktop sidebar collapse | fixed 220 px ≥840 dp | animated collapsible 260↔72, toggle, persist |
| 7 | Desktop top bar | none | add search (`Ctrl /`), theme toggle, avatar |
| 8 | Tablet/desktop greeting + date chip | mobile-only greeting | show on all; date-range chip on tablet/desktop |
| 9 | Notification badge "3" | bell exists in some screens | consistent red badge across all three headers |

**Constraint:** UI-only. Do not alter providers/models/repos/services/sync/Firebase.
Charts already implemented in `lib/features/dashboard/dashboard_charts.dart`
(`AttendanceChart`, `SiteProgressChart`, `MaterialUsageChart`, `ExpensesChart`,
`PaymentsChart`) — reuse, do not rewrite.

---

## 6. Acceptance checklist
- [ ] `flutter analyze` clean (0 errors/warnings).
- [ ] Mobile < 600 dp: drawer + 5-item bottom nav; 2-col metric grid; stacked sections.
- [ ] Tablet 600–1199 dp: persistent labeled sidebar (13 items); 4-col metrics ≥900;
      2-col middle; 3-col analytics.
- [ ] Desktop ≥ 1200 dp: collapsible sidebar (260↔72) + top search/theme/avatar;
      same grids; hover + focus states.
- [ ] All core elements present on all three (metrics, Stock Alerts, Recent Activity,
      Analytics, notification badge, personalized greeting).
- [ ] Release builds (APK + Windows) succeed; `dist/` updated.
