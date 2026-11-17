import '../../repositories/inventory_repository.dart';
import '../../repositories/payroll_repository.dart';
import '../../repositories/site_repository.dart';
import '../../repositories/worker_repository.dart';
import '../engine/notification_engine.dart';
import '../rules/notification_rules_registry.dart';

/// Composition root that wires the concrete repositories to the notification
/// engine. Used both by the foreground app and by the background isolate so
/// the rules can be evaluated without the UI process being alive.
///
/// All four repositories are parameterless (they wrap the shared SQLite file),
/// so reconstructing them in a background isolate is safe and reads the same
/// data the user sees in the app.
Future<NotificationEngine> buildEngineWithAllRules() async {
  final engine = await NotificationEngine.create();
  engine.registerRules(
    buildNotificationRules(
      siteRepository: SiteRepository(),
      payrollRepository: PayrollRepository(),
      workerRepository: WorkerRepository(),
      inventoryRepository: InventoryRepository(),
    ),
  );
  return engine;
}
