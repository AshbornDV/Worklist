import '../../../repositories/site_repository.dart';
import '../../../repositories/worker_repository.dart';
import '../../models/notification_model.dart';
import 'site_rule_base.dart';
import 'site_thresholds.dart';

/// Site lifecycle reminders. Scans the site list once and emits candidates for
/// each of the eight site-specific conditions:
///
///  • **Site nearing completion** — `completionPercentage` crosses the
///    configurable 90% / 95% tiers (and is not yet 100%).
///  • **Site deadline approaching** — `endDate` is within
///    [SiteThresholds.deadlineWarningDays] (upcoming, not passed).
///  • **Site overdue** — `endDate` is in the past and the site is not archived.
///  • **Site inactive** — `updatedAt` older than [SiteThresholds.inactiveDays].
///  • **No workers assigned** — `getWorkersBySite` returns empty.
///  • **No attendance recorded** — no worker has attendance for the latest
///    working day on this site.
///  • **Budget exceeded** — `totalCost > budget` (when a budget is set).
///  • **Site archived reminder** — a site with `status == 'archived'` is a
///    periodic nudge to review/clean it up.
///
/// "Payment overdue" is intentionally NOT re-implemented here — it is already
/// covered by the Phase 2 Customer Payment rule (same engine, shared dedupe), so
/// adding it again would duplicate both logic and reminders.
///
/// Read-only rule — the engine deduplicates/delivers.
class SiteLifecycleRule extends SiteRuleBase {
  SiteLifecycleRule({
    required SiteRepository siteRepository,
    required WorkerRepository workerRepository,
    this.thresholds = const SiteThresholds(),
    super.now,
  })  : _siteRepository = siteRepository,
        _workerRepository = workerRepository,
        super(id: 'site_lifecycle');

  final SiteRepository _siteRepository;
  final WorkerRepository _workerRepository;
  final SiteThresholds thresholds;

  @override
  Future<List<AppNotification>> evaluate() async {
    final sites = await _siteRepository.getAllSites();
    final out = <AppNotification>[];

    for (final site in sites) {
      if (site.id == null) continue;
      final id = site.id!;
      final name = site.name;
      final isArchived = site.status == 'archived';

      // ── Site nearing completion (90% / 95% tiers) ──
      final pct = site.completionPercentage;
      if (pct >= thresholds.completionNear2 && pct < 100) {
        out.add(
          build(
            siteId: id,
            siteName: name,
            subKey: 'near_complete_95',
            title: 'Site nearly complete · $name',
            body:
                '$name is at ${pct.toStringAsFixed(0)}% completion. Final wrap-up approaching.',
            priority: NotificationPriority.high,
            extra: {'completion': pct},
          ),
        );
      } else if (pct >= thresholds.completionNear1 && pct < 100) {
        out.add(
          build(
            siteId: id,
            siteName: name,
            subKey: 'near_complete_90',
            title: 'Site nearing completion · $name',
            body:
                '$name is at ${pct.toStringAsFixed(0)}% completion. Plan the finishing work.',
            priority: NotificationPriority.normal,
            extra: {'completion': pct},
          ),
        );
      }

      // ── Site deadline approaching / overdue ──
      if (site.endDate != null && !isArchived) {
        final days = site.endDate!.difference(_midnight(now)).inDays;
        if (days > 0 && days <= thresholds.deadlineWarningDays) {
          out.add(
            build(
              siteId: id,
              siteName: name,
              subKey: 'deadline_approaching',
              title: 'Deadline approaching · $name',
              body:
                  '$name is due in $days day(s) (${_fmt(site.endDate!)}).',
              priority: NotificationPriority.high,
              scheduledFor: site.endDate,
              extra: {'daysToDeadline': days},
            ),
          );
        } else if (days < 0) {
          out.add(
            build(
              siteId: id,
              siteName: name,
              subKey: 'overdue',
              title: 'Site overdue · $name',
              body:
                  '$name was due on ${_fmt(site.endDate!)} (${(-days)} day(s) overdue).',
              priority: NotificationPriority.critical,
              scheduledFor: site.endDate,
              extra: {'daysOverdue': -days},
            ),
          );
        }
      }

      // ── Site inactive ──
      final cutoff = now.subtract(Duration(days: thresholds.inactiveDays));
      if (site.updatedAt.isBefore(cutoff) && !isArchived) {
        final d = now.difference(site.updatedAt).inDays;
        out.add(
          build(
            siteId: id,
            siteName: name,
            subKey: 'inactive',
            title: 'Site inactive · $name',
            body:
                'No updates on $name for $d days. Confirm it is still active.',
            priority: NotificationPriority.normal,
            extra: {'daysInactive': d},
          ),
        );
      }

      // ── No workers assigned ──
      final workers = await _siteRepository.getWorkersBySite(id);
      if (workers.isEmpty && !isArchived) {
        out.add(
          build(
            siteId: id,
            siteName: name,
            subKey: 'no_workers',
            title: 'No workers assigned · $name',
            body: '$name has no workers assigned. Assign a team to proceed.',
            priority: NotificationPriority.normal,
          ),
        );
      }

      // ── No attendance recorded (latest working day) ──
      if (workers.isNotEmpty && !isArchived) {
        final today = _ymd(now);
        final recorded =
            await _workerRepository.getSiteAttendanceForDate(id, today);
        if (recorded.isEmpty) {
          out.add(
            build(
              siteId: id,
              siteName: name,
              subKey: 'no_attendance',
              title: 'No attendance recorded · $name',
              body:
                  'No attendance has been marked for $name today (${_fmt(now)}).',
              priority: NotificationPriority.normal,
              extra: {'date': today},
            ),
          );
        }
      }

      // ── Budget exceeded ──
      if (site.budget != null && site.totalCost > site.budget!) {
        final over = site.totalCost - site.budget!;
        out.add(
          build(
            siteId: id,
            siteName: name,
            subKey: 'budget_exceeded',
            title: 'Budget exceeded · $name',
            body:
                '$name has exceeded its budget by ${over.toStringAsFixed(0)} (cost ${site.totalCost.toStringAsFixed(0)} / budget ${site.budget!.toStringAsFixed(0)}).',
            priority: NotificationPriority.high,
            extra: {'overBy': over},
          ),
        );
      }

      // ── Site archived reminder ──
      if (isArchived) {
        out.add(
          build(
            siteId: id,
            siteName: name,
            subKey: 'archived',
            title: 'Archived site · $name',
            body:
                '$name is archived. Review whether it can be closed out or removed.',
            priority: NotificationPriority.low,
          ),
        );
      }
    }
    return out;
  }

  DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
  String _ymd(DateTime d) =>
      '${d.year}-${_pad(d.month)}-${_pad(d.day)}';
  String _fmt(DateTime d) => '${_pad(d.day)}/${_pad(d.month)}/${d.year}';
  String _pad(int n) => n.toString().padLeft(2, '0');
}
