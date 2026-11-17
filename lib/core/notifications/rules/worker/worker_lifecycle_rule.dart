import '../../../repositories/payroll_repository.dart';
import '../../../repositories/worker_repository.dart';
import '../../models/notification_model.dart';
import 'worker_rule_base.dart';
import 'worker_thresholds.dart';

/// Worker lifecycle reminders. Scans workers and emits candidates for each of
/// the nine worker conditions:
///
///  • **Birthday** — derived from `joinDate` as a work anniversary (the only
///    per-worker calendar date in the schema; no DOB field exists, so we
///    celebrate the work anniversary instead of inventing a birthday column).
///  • **Missing attendance** — no attendance record for the worker today.
///  • **Consecutive absences** — `consecutiveAbsenceLimit` successive 'absent'
///    days up to today.
///  • **Worker document expiry** — `uploadedAt + validityMonths` passed.
///  • **Contract expiry** — the `contract` document's derived expiry passed.
///  • **Worker performance warning** — latest monthly rating/attendance below
///    the configured thresholds.
///  • **Missing profile information** — blank address / skills / joinDate.
///  • **Long unpaid salary** — a draft payroll older than [longUnpaidMonths]
///    (duration-gated extension of the Phase 2 unpaid-salary rule; distinct key
///    so it never duplicates that rule's per-month reminder).
///  • **Advance limit exceeded** — approved advances this month exceed
///    [advanceMonthlyLimit].
///
/// Read-only rule — the engine deduplicates/delivers. No scheduling logic is
/// duplicated here; the Phase 1 engine owns dispatch.
class WorkerLifecycleRule extends WorkerRuleBase {
  WorkerLifecycleRule({
    required WorkerRepository workerRepository,
    required PayrollRepository payrollRepository,
    this.thresholds = const WorkerThresholds(),
    super.now,
  })  : _workerRepository = workerRepository,
        _payrollRepository = payrollRepository,
        super(id: 'worker_lifecycle');

  final WorkerRepository _workerRepository;
  final PayrollRepository _payrollRepository;
  final WorkerThresholds thresholds;

  @override
  Future<List<AppNotification>> evaluate() async {
    final workers = await _workerRepository.getAllWorkers();
    final out = <AppNotification>[];

    for (final w in workers) {
      if (w.id == null) continue;
      final id = w.id!;
      final name = w.name;
      if (w.status == 'inactive') continue; // skip offboarded workers

      // ── Birthday (work anniversary) ──
      if (w.joinDate != null) {
        final next = _anniversaryThisYear(w.joinDate!, now);
        final days = next.difference(_midnight(now)).inDays;
        if (days >= 0 && days <= thresholds.anniversaryReminderDays) {
          out.add(
            build(
              workerId: id,
              workerName: name,
              subKey: 'anniversary',
              title: 'Work anniversary · $name',
              body:
                  '$name completes another year today (joined ${_fmt(w.joinDate!)}).',
              priority: NotificationPriority.normal,
              extra: {'joinDate': w.joinDate!.toIso8601String()},
            ),
          );
        }
      }

      // ── Missing attendance (today) ──
      final today = _ymd(now);
      final todayAtt =
          await _workerRepository.getAttendance(id, today);
      if (todayAtt == null) {
        out.add(
          build(
            workerId: id,
            workerName: name,
            subKey: 'missing_attendance',
            title: 'Attendance missing · $name',
            body: 'No attendance marked for $name on $today.',
            priority: NotificationPriority.normal,
            extra: {'date': today},
          ),
        );
      }

      // ── Consecutive absences ──
      final consec = await _consecutiveAbsences(id, now);
      if (consec >= thresholds.consecutiveAbsenceLimit) {
        out.add(
          build(
            workerId: id,
            workerName: name,
            subKey: 'consecutive_absences',
            title: 'Consecutive absences · $name',
            body:
                '$name has been absent $consec days in a row. Check in with them.',
            priority: NotificationPriority.high,
            extra: {'consecutive': consec},
          ),
        );
      }

      // ── Document / Contract expiry ──
      final docs = await _workerRepository.getWorkerDocuments(id);
      for (final d in docs) {
        final months = thresholds.documentValidityMonths[d.documentType];
        if (months == null) continue;
        final expiry = DateTime(
          d.uploadedAt.year,
          d.uploadedAt.month + months,
          d.uploadedAt.day,
        );
        if (!now.isAfter(expiry)) continue;
        final isContract = d.documentType == 'contract';
        out.add(
          build(
            workerId: id,
            workerName: name,
            subKey: isContract ? 'contract_expiry' : 'document_expiry',
            title:
                '${isContract ? 'Contract' : d.displayName} expired · $name',
            body:
                '${d.displayName} for $name expired on ${_fmt(expiry)}. Renew it.',
            priority: NotificationPriority.high,
            extra: {
              'documentType': d.documentType,
              'expiry': expiry.toIso8601String(),
            },
          ),
        );
      }

      // ── Performance warning ──
      final perf = await _workerRepository.getWorkerPerformance(id);
      if (perf.isNotEmpty) {
        final latest = perf.reduce((a, b) => a.month.isAfter(b.month) ? a : b);
        final ratingBad = latest.rating <= thresholds.performanceRatingWarning;
        final attBad = latest.attendancePercentage <=
            thresholds.performanceAttendanceWarning;
        if (ratingBad || attBad) {
          out.add(
            build(
              workerId: id,
              workerName: name,
              subKey: 'performance_warning',
              title: 'Performance warning · $name',
              body: [
                if (ratingBad)
                  'Rating ${latest.rating.toStringAsFixed(1)}/5',
                if (attBad)
                  'Attendance ${latest.attendancePercentage.toStringAsFixed(0)}%',
              ].join(' · '),
              priority: NotificationPriority.normal,
              extra: {
                'rating': latest.rating,
                'attendance': latest.attendancePercentage,
              },
            ),
          );
        }
      }

      // ── Missing profile information ──
      final missing = <String>[];
      if (w.address == null || w.address!.isEmpty) missing.add('address');
      if (w.skills == null || w.skills!.isEmpty) missing.add('skills');
      if (w.joinDate == null) missing.add('join date');
      if (w.photoPath == null || w.photoPath!.isEmpty) {
        missing.add('photo');
      }
      if (missing.isNotEmpty) {
        out.add(
          build(
            workerId: id,
            workerName: name,
            subKey: 'missing_profile',
            title: 'Incomplete profile · $name',
            body:
                'Missing profile info for $name: ${missing.join(', ')}.',
            priority: NotificationPriority.low,
            extra: {'missing': missing},
          ),
        );
      }

      // ── Long unpaid salary (duration-gated) ──
      final month = DateTime(now.year, now.month, 1);
      final records =
          await _payrollRepository.getPayrollForMonth(month);
      final draft = records.where((p) => p.workerId == id && !p.isPaid);
      for (final p in draft) {
        final ageMonths = _monthsBetween(p.month, now);
        if (ageMonths >= thresholds.longUnpaidMonths) {
          out.add(
            build(
              workerId: id,
              workerName: name,
              subKey: 'long_unpaid',
              title: 'Long unpaid salary · $name',
              body:
                  '${p.monthLabel} salary (Rs. ${p.netSalary.toStringAsFixed(0)}) has been unpaid for $ageMonths month(s).',
              priority: NotificationPriority.high,
              extra: {'months': ageMonths, 'payrollId': p.id},
            ),
          );
        }
      }

      // ── Advance limit exceeded (this month) ──
      final approvedThisMonth = await _workerRepository.getApprovedAdvancesTotal(
        id,
        year: now.year,
        month: now.month,
      );
      final advances = await _workerRepository.getAdvancesByWorker(id);
      final countThisMonth = advances
          .where((a) =>
              a.isApproved &&
              a.requestDate.year == now.year &&
              a.requestDate.month == now.month)
          .length;
      if (countThisMonth > thresholds.advanceMonthlyLimit) {
        out.add(
          build(
            workerId: id,
            workerName: name,
            subKey: 'advance_limit',
            title: 'Advance limit exceeded · $name',
            body:
                '$name has $countThisMonth approved advance(s) this month (limit ${thresholds.advanceMonthlyLimit}); total Rs. ${approvedThisMonth.toStringAsFixed(0)}.',
            priority: NotificationPriority.normal,
            extra: {
              'count': countThisMonth,
              'total': approvedThisMonth,
            },
          ),
        );
      }
    }
    return out;
  }

  /// Counts consecutive 'absent' days ending today (walking backwards).
  Future<int> _consecutiveAbsences(int workerId, DateTime now) async {
    var count = 0;
    var cursor = _midnight(now);
    // Guard the loop so a long gap can never spin forever.
    for (var i = 0; i < 365; i++) {
      final date = _ymd(cursor);
      final att = await _workerRepository.getAttendance(workerId, date);
      if (att == null || att.isAbsent) {
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  }

  DateTime _anniversaryThisYear(DateTime join, DateTime now) =>
      DateTime(now.year, join.month, join.day);

  int _monthsBetween(DateTime a, DateTime b) =>
      (b.year - a.year) * 12 + (b.month - a.month);

  DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
  String _ymd(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';
  String _fmt(DateTime d) => '${_pad(d.day)}/${_pad(d.month)}/${d.year}';
  String _pad(int n) => n.toString().padLeft(2, '0');
}
