import '../../repositories/inventory_repository.dart';
import '../../repositories/payroll_repository.dart';
import '../../repositories/site_repository.dart';
import '../../repositories/worker_repository.dart';
import '../models/notification_settings.dart';
import 'notification_rule.dart';
import 'inventory/frequently_used_low_rule.dart';
import 'inventory/inventory_audit_reminder_rule.dart';
import 'inventory/inventory_thresholds.dart';
import 'inventory/material_not_updated_rule.dart';
import 'inventory/stock_state_inventory_rule.dart';
import 'payment/construction_payment_rule.dart';
import 'payment/customer_payment_rule.dart';
import 'payroll/payroll_reminder_rule.dart';
import 'payroll/worker_advance_rule.dart';
import 'payroll/worker_salary_rule.dart';
import 'site/site_lifecycle_rule.dart';
import 'site/site_thresholds.dart';
import 'smart/smart_summary_rule.dart';
import 'worker/worker_lifecycle_rule.dart';
import 'worker/worker_thresholds.dart';

/// Wires the full set of notification rules (Phase 2 Payment/Payroll + Phase 3
/// Inventory) to the app's existing repositories. This is the single
/// integration seam between the Phase 1 engine and the concrete rules —
/// callers register the returned rules with the [NotificationEngine] without
/// touching the engine, framework, schema, providers, services, or UI.
///
/// Rules are read-only and rely on the engine for dedupe, settings filtering,
/// and delivery. Inventory thresholds are configurable via [inventoryThresholds].
List<NotificationRule> buildNotificationRules({
  required SiteRepository siteRepository,
  required PayrollRepository payrollRepository,
  required WorkerRepository workerRepository,
  required InventoryRepository inventoryRepository,
  InventoryThresholds inventoryThresholds = const InventoryThresholds(),
  SiteThresholds siteThresholds = const SiteThresholds(),
  WorkerThresholds workerThresholds = const WorkerThresholds(),
  NotificationSettings settings = const NotificationSettings(),
}) =>
    [
      // ── Phase 2: Payments ──
      CustomerPaymentRule(siteRepository: siteRepository),
      ConstructionPaymentRule(siteRepository: siteRepository),
      // ── Phase 2: Payroll ──
      PayrollReminderRule(payrollRepository: payrollRepository),
      WorkerSalaryRule(payrollRepository: payrollRepository),
      WorkerAdvanceRule(workerRepository: workerRepository),
      // ── Phase 3: Inventory ──
      StockStateInventoryRule(
        inventoryRepository: inventoryRepository,
        thresholds: inventoryThresholds,
      ),
      FrequentlyUsedLowRule(
        inventoryRepository: inventoryRepository,
        thresholds: inventoryThresholds,
      ),
      MaterialNotUpdatedRule(
        inventoryRepository: inventoryRepository,
        thresholds: inventoryThresholds,
      ),
      InventoryAuditReminderRule(
        inventoryRepository: inventoryRepository,
        thresholds: inventoryThresholds,
      ),
      // ── Phase 4: Sites ──
      SiteLifecycleRule(
        siteRepository: siteRepository,
        workerRepository: workerRepository,
        thresholds: siteThresholds,
      ),
      // ── Phase 5: Workers ──
      WorkerLifecycleRule(
        workerRepository: workerRepository,
        payrollRepository: payrollRepository,
        thresholds: workerThresholds,
      ),
      // ── Phase 8: Smart notifications (briefings / summaries) ──
      BriefingRule(
        mode: BriefingMode.daily,
        siteRepository: siteRepository,
        payrollRepository: payrollRepository,
        workerRepository: workerRepository,
        inventoryRepository: inventoryRepository,
        briefingTime: settings.dailyBriefingTime,
      ),
      BriefingRule(
        mode: BriefingMode.weekly,
        siteRepository: siteRepository,
        payrollRepository: payrollRepository,
        workerRepository: workerRepository,
        inventoryRepository: inventoryRepository,
        briefingTime: settings.weeklyReportTime,
        weeklyWeekday: settings.weeklyReportWeekday,
      ),
      BriefingRule(
        mode: BriefingMode.monthly,
        siteRepository: siteRepository,
        payrollRepository: payrollRepository,
        workerRepository: workerRepository,
        inventoryRepository: inventoryRepository,
        briefingTime: settings.monthlyReportTime,
        monthlyDay: settings.monthlyReportDay,
      ),
    ];

/// Phase 2-only subset (Payment + Payroll). Kept for callers that do not yet
/// wire inventory.
List<NotificationRule> buildPhase2Rules({
  required SiteRepository siteRepository,
  required PayrollRepository payrollRepository,
  required WorkerRepository workerRepository,
}) =>
    [
      CustomerPaymentRule(siteRepository: siteRepository),
      ConstructionPaymentRule(siteRepository: siteRepository),
      PayrollReminderRule(payrollRepository: payrollRepository),
      WorkerSalaryRule(payrollRepository: payrollRepository),
      WorkerAdvanceRule(workerRepository: workerRepository),
    ];
