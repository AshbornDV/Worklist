import '../../models/notification_model.dart';
import '../../../repositories/site_repository.dart';
import '../notification_rule.dart';
import 'reminder_window.dart';

/// Reminds the user about an upcoming or overdue construction payment scheduled
/// for a site. The scheduled date is the model's `paymentDate`; we scan only the
/// sites that actually have scheduled future/overdue payments (no full-table
/// sweep beyond what [SiteRepository.getConstructionPaymentsBySite] returns).
///
/// Phase 2 only: read-only rule returning candidates; engine dedupe/deliver.
class ConstructionPaymentRule extends NotificationRule {
  ConstructionPaymentRule({
    required SiteRepository siteRepository,
    DateTime Function()? now,
  })  : _siteRepository = siteRepository,
        _now = now ?? DateTime.now,
        super(id: 'construction_payment', type: NotificationType.payment);

  final SiteRepository _siteRepository;
  final DateTime Function() _now;

  @override
  Future<List<AppNotification>> evaluate() async {
    final sites = await _siteRepository.getAllSites();
    final now = _now();
    final out = <AppNotification>[];

    for (final site in sites) {
      if (site.id == null) continue;
      final payments = await _siteRepository.getConstructionPaymentsBySite(site.id!);
      for (final p in payments) {
        final window = windowForDueDate(p.paymentDate, now);
        if (window == null) continue;

        final amount = p.amount.toStringAsFixed(0);
        final label = windowLabel(window);
        out.add(
          NotificationModel(
            id: 'construction_payment:${p.id}:${window.name}',
            title: 'Construction payment ${isOverdueWindow(window) ? 'overdue' : 'scheduled'} · ${site.name}',
            body:
                'Rs. $amount $label for ${site.name}${p.notes?.isNotEmpty == true ? ' · ${p.notes}' : ''}',
            type: NotificationType.payment,
            priority: priorityForWindow(window),
            status: NotificationStatus.pending,
            createdAt: now,
            scheduledFor: p.paymentDate,
            entityId: p.id?.toString() ?? '${site.id}',
            entityType: 'construction_payment',
            payload: {
              'rule': id,
              'window': window.name,
              'paymentId': p.id,
              'siteId': site.id,
              'siteName': site.name,
              'amount': p.amount,
              'deepLink': 'site_detail',
              'deepLinkArgs': {'siteId': site.id},
            },
          ),
        );
      }
    }
    return out;
  }
}
