import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../core/notifications/analytics/notification_metrics.dart';
import '../../core/notifications/background/windows_background_scheduler.dart';

/// Phase 10 — Notification Diagnostics screen.
///
/// Shows the live enterprise analytics captured by [NotificationMetrics]:
/// engine / scheduler / background-worker status, pending/delivered/failed
/// counts for today, duplicates prevented, average execution time, memory
/// usage, next scheduled run, and the last background execution. A structured
/// log tail is shown at the bottom for troubleshooting.
///
/// This is a read-only diagnostics view — it never mutates notifications or
/// business data.
class NotificationDiagnosticsScreen extends StatefulWidget {
  const NotificationDiagnosticsScreen({super.key});

  @override
  State<NotificationDiagnosticsScreen> createState() =>
      _NotificationDiagnosticsScreenState();
}

class _NotificationDiagnosticsScreenState
    extends State<NotificationDiagnosticsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationMetrics.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = NotificationMetrics.instance;
    final pending = (m.daily(NotificationEventType.created) -
            m.daily(NotificationEventType.delivered))
        .clamp(0, m.daily(NotificationEventType.created));
    final backgroundStatus = Platform.isAndroid
        ? 'WorkManager (periodic)'
        : (WindowsBackgroundScheduler().isRunning
            ? 'Timer running'
            : 'Inactive');
    final engineStatus =
        m.executionCount > 0 ? 'Active' : 'Idle';

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard([
            _Row('Engine Status', engineStatus),
            _Row('Scheduler Status',
                m.schedulerRegistered ? 'Registered' : 'Not registered'),
            _Row('Background Worker', backgroundStatus),
          ]),
          const SizedBox(height: 16),
          _StatusCard([
            _Row('Pending', '$pending'),
            _Row('Delivered Today',
                '${m.daily(NotificationEventType.delivered)}'),
            _Row('Failed Today', '${m.daily(NotificationEventType.failed)}'),
            _Row('Duplicates Prevented',
                '${m.total(NotificationEventType.duplicatePrevented)}'),
          ]),
          const SizedBox(height: 16),
          _StatusCard([
            _Row('Avg Execution Time',
                '${m.avgExecutionMs.toStringAsFixed(1)} ms'),
            _Row('Runs Executed', '${m.executionCount}'),
            _Row('Memory Usage',
                m.memoryUsageMb != null ? '${m.memoryUsageMb!.toStringAsFixed(1)} MB' : 'n/a'),
            _Row('Next Scheduled Run', _fmt(m.nextScheduledRun)),
            _Row('Last Foreground Run', _fmt(m.lastForegroundExecution)),
            _Row('Last Background Execution', _fmt(m.lastBackgroundExecution)),
          ]),
          const SizedBox(height: 16),
          _StatusCard([
            _Row('Created (total)', '${m.total(NotificationEventType.created)}'),
            _Row('Delivered (total)',
                '${m.total(NotificationEventType.delivered)}'),
            _Row('Opened (total)', '${m.total(NotificationEventType.opened)}'),
            _Row('Dismissed (total)',
                '${m.total(NotificationEventType.dismissed)}'),
            _Row('Archived (total)',
                '${m.total(NotificationEventType.archived)}'),
            _Row('Ignored Today', '${m.ignoredToday()}'),
            _Row('Failed (total)', '${m.total(NotificationEventType.failed)}'),
          ]),
          const SizedBox(height: 16),
          const Text('Structured Logs',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...m.recentLogs(limit: 50).map(
            (e) => ListTile(
              dense: true,
              leading: Text(e.type.label,
                  style: Theme.of(context).textTheme.labelSmall),
              title: Text(e.message),
              subtitle: Text(
                e.ts.toLocal().toString().substring(0, 19),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          if (m.recentLogs().isEmpty)
            const ListTile(
              dense: true,
              title: Text('No log entries yet — run a notification refresh.'),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime? d) =>
      d == null ? 'never' : d.toLocal().toString().substring(0, 19);
}

class _StatusCard extends StatelessWidget {
  const _StatusCard(this.rows);
  final List<Widget> rows;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: rows),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
