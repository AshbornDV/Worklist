import 'package:flutter_test/flutter_test.dart';
import 'package:worklist/core/notifications/models/notification_settings.dart';
import 'package:worklist/core/notifications/rules/notification_rules_registry.dart';
import 'package:worklist/core/repositories/inventory_repository.dart';
import 'package:worklist/core/repositories/payroll_repository.dart';
import 'package:worklist/core/repositories/site_repository.dart';
import 'package:worklist/core/repositories/worker_repository.dart';

import 'harness.dart';

/// A settings profile with every toggle set to [enabled]. Quiet hours stay off
/// because `isEnabled` never consults the clock.
NotificationSettings _profile({required bool enabled}) => NotificationSettings(
      masterEnabled: enabled,
      payments: enabled,
      payroll: enabled,
      inventory: enabled,
      workers: enabled,
      attendance: enabled,
      sites: enabled,
      services: enabled,
      dailySummary: enabled,
      weeklySummary: enabled,
      monthlySummary: enabled,
      quietHoursEnabled: false,
    );

void main() {
  test('notification rule catalogue: stable ids, types and enabled-ness under two settings profiles',
      () {
    // buildNotificationRules registers the full rule set. It only constructs
    // rules (no queries); each rule's isEnabled consults settings alone, so the
    // whole contract is deterministic. Candidate output is deliberately NOT
    // frozen — rules derive dates from real DateTime.now() — so it stays out.
    final rules = buildNotificationRules(
      siteRepository: SiteRepository(),
      payrollRepository: PayrollRepository(),
      workerRepository: WorkerRepository(),
      inventoryRepository: InventoryRepository(),
    );

    final catalogue = rules
        .map((r) => <String, String>{'id': r.id, 'type': r.type.name})
        .toList()
      ..sort((a, b) => a['id']!.compareTo(b['id']!));

    List<String> enabledIds(NotificationSettings profile) {
      final ids = rules
          .where((r) => r.isEnabled(profile))
          .map((r) => r.id)
          .toList();
      ids.sort();
      return ids;
    }

    expectGolden('notifications.catalogue', {
      'rules': catalogue,
      'allOn': enabledIds(_profile(enabled: true)),
      'allOff': enabledIds(_profile(enabled: false)),
      'defaultSettings': const NotificationSettings().toJson(),
    });
  });
}
