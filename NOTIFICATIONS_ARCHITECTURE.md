# Notifications Architecture — Worklist

Self-contained notification subsystem. It never touches business logic,
auth, sync, schema, or the UI outside its own files.

## Pipeline
```
NotificationRule.evaluate()
        │  (each rule queries only its own data slice)
        ▼
NotificationRuleEvaluator.evaluateRules(rules)
        │  - runs enabled rules concurrently (Future.wait)
        │  - drops candidates silenced by quiet hours
        ▼
NotificationEngine.refresh()
        │  1. evaluate → candidates
        │  2. batch dedupe: one readAllPublic() → Set<id>
        │  3. for each candidate not in delivered set:
        │       scheduler.showNow(candidate)
        │       history.record(candidate, deliveredAt)
        │  4. metrics.record(delivered) / record(duplicatePrevented)
        │  5. history.prune() + metrics.recordTiming()
        ▼
NotificationScheduler → PlatformNotificationService
        (Android: flutter_local_notifications; Windows: same plugin, toasts)
```

## Key types
- **`NotificationRule`** — base; `id`, `isEnabled(settings)`,
  `evaluate()`. Rules are additive (payment, payroll, inventory,
  sites, workers, briefing/summary, insights).
- **`NotificationHistoryRepository`** — SharedPreferences-backed;
  `wasAlreadyDelivered`, `record`, `markRead/Unread/Archived/Snoozed`,
  `prune`, `readAllPublic`. De-dupe key = `NotificationModel.id`
  (rule-stable, e.g. `payment_overdue:siteId`).
- **`NotificationMetrics`** — diagnostics store (counters, daily
  buckets pruned to 14 days, rolling avg exec time, bounded log
  ring). Persistence is **debounced** (one write / 1.5 s burst) to
  avoid disk thrash on every event.
- **`NotificationSettings`** — per-type enable, quiet hours, reminder
  times, briefing/weekly/monthly report schedules, priority, sound,
  vibration.

## Background scheduling
| Platform | Mechanism | Survives app close? |
|---|---|---|
| Android | `Workmanager` periodic task, unique name `worklist.notifications.periodic`, `ExistingPeriodicWorkPolicy.update` (15-min floor) | **Yes** (reboot-safe) |
| Windows | in-process `Timer.periodic(15 min)` started from `main.dart`; optional Startup-folder registration | **No** (OS limitation) |

Both are **idempotent**: re-enqueuing reuses the same unique name
(no duplicate jobs); the Windows timer calls `stop()` before `start()`
(no duplicate timers).

## Cross-device sync (Phase 12)
`NotificationCloudSyncService` mirrors **notification metadata only** to
`users/$uid/notifications` on Firebase RTDB:
- read / unread / dismissed / archived / snoozed
- reminder history
- notification preferences

Conflict resolution: **latest update wins**, computed per record by
the most-recent of its timestamps. Offline edits are queued
(`notif_sync_pending_$uid`) and retried. Platform scheduled jobs
(WorkManager / Windows timers) are **intentionally not** synchronized.

## Interactive actions (Phase 9)
`NotificationActionHandler` routes tap/action intents:
- deep links (`/sites/:id`, `/workers/:id`, `/products`, `/services`)
- status updates (mark paid/read/attendance)
- snooze (in-process re-show; snooze *state* synced cross-device)
- `tel:` call worker

## Diagnostics (Phase 10)
`NotificationDiagnosticsScreen` (`/notifications/diagnostics`)
shows engine/scheduler status, delivered today, duplicates prevented,
avg exec time, memory, next scheduled run, last background exec, and
a bounded log tail — all read from `NotificationMetrics`.

## Security notes
- Firebase **apiKeys** in `firebase_options.dart` / `firebase_config.dart`
  are *public* web/API keys, not secrets. Protection is via Firebase
  Security Rules + App Check, not key secrecy.
- No notification payload contains business secrets; deep links are
  in-app routes resolved after auth.
