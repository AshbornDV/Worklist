---
name: Master-detail layout pattern
description: How the wide-screen master-detail split is implemented for Sites and Workers screens
---

## Rule
Sites and Workers list screens switch to master-detail at **1100px** (`_kWideBreakpoint`). Below that they fall back to the existing desktop grid (840px+) or mobile list.

## Structure
- **Master panel**: fixed-width side list (`340px` sites, `300px` workers) with animated selection state.
- **Detail panel**: `SiteDetailPanel` / `WorkerSummaryPanel` — embeddable widgets that live in the **same file** as their full-screen counterparts so they can access private sub-widgets (`_FinancialCard`, `_ProductsSection`, `_WorkersSection`, etc.).
- Both panels use `didUpdateWidget` to reload when the id changes, and `ValueKey(selectedId)` on the panel widget for clean state disposal.

## Stale-selection guard
`_filtered()` in each list screen clears the selected id via `addPostFrameCallback` if the filtered results no longer contain it. This avoids showing a detail panel for a hidden/deleted item.

**Why:** Embedding the panel in the same file avoids making private layout widgets public and keeps the API surface minimal. The `ValueKey` ensures Flutter disposes the old state completely when switching between two items.

**How to apply:** Any new list screen that needs master-detail should follow this same file co-location pattern, use `ValueKey(id)` on the panel, and add the stale-selection guard in `_filtered()`.
