import '../../models/notification_model.dart';
import '../../../repositories/site_repository.dart';
import '../notification_rule.dart';
import 'reminder_window.dart';

/// Reminds the user to collect a customer's site payment when the site reaches
/// one of the eight reminder windows relative to its derived due date.
///
/// The due date is derived from live data (lastPaidDate + collectionReminderDays)
/// — no separate due-date column is added and no schema is touched. A site with
/// no remaining balance is skipped entirely.
///
/// Phase 2 only: this is a read-only rule; it queries [SiteRepository] and
/// returns candidates. The engine handles dedupe, settings, and delivery.
class CustomerPaymentRule extends NotificationRule {
  CustomerPaymentRule({
    required SiteRepository siteRepository,
    DateTime Function()? now,
  })  : _siteRepository = siteRepository,
        _now = now ?? DateTime.now,
        super(id: 'customer_payment', type: NotificationType.payment);

  final SiteRepository _siteRepository;
  final DateTime Function() _now;

  @override
  Future<List<AppNotification>> evaluate() async {
    final sites = await _siteRepository.getAllSites();
    final now = _now();
    final out = <AppNotification>[];

    for (final site in sites) {
      if (site.id == null) continue;
      if (!site.hasRemainingPayment) continue; // fully paid → no reminder

      final anchor = site.lastPaidDate ?? site.createdAt;
      final due = anchor.add(Duration(days: site.collectionReminderDays));
      final window = windowForDueDate(due, now);
      if (window == null) continue;

      final amount = site.balance.toStringAsFixed(0);
      final label = windowLabel(window);
      out.add(
        NotificationModel(
          id: 'customer_payment:${site.id}:${window.name}',
          title: 'Collect payment from ${site.name}',
          body:
              'Rs. $amount $label · ${site.name} (${site.area})${isOverdueWindow(window) ? ' — follow up needed' : ''}',
          type: NotificationType.payment,
          priority: priorityForWindow(window),
          status: NotificationStatus.pending,
          createdAt: now,
          scheduledFor: due,
          entityId: site.id.toString(),
          entityType: 'site',
          payload: {
            'rule': id,
            'window': window.name,
            'siteId': site.id,
            'siteName': site.name,
            'amount': site.balance,
            'deepLink': 'site_detail',
            'deepLinkArgs': {'siteId': site.id},
          },
        ),
      );
    }
    return out;
  }
}
