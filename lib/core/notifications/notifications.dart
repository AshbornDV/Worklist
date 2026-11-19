/// Public surface of the Worklist notification framework (Phase 1).
///
/// Future feature modules import from this barrel and interact only with
/// [NotificationEngine] (register rules) and the model enums. No feature should
/// schedule or display notifications directly.
library worklist_notifications;

export 'core/notification_logger.dart';
export 'models/notification_model.dart';
export 'models/notification_settings.dart';
export 'models/notification_action.dart';
export 'actions/notification_action_catalog.dart';
export 'actions/notification_action_handler.dart';
export 'analytics/notification_metrics.dart';
export 'insights/business_insight_models.dart';
export 'insights/business_insight_engine.dart';
export 'insights/business_insight_provider.dart';
export 'sync/notification_cloud_sync_service.dart';
export 'rules/notification_rule.dart';
export 'rules/notification_rules_registry.dart';
export 'rules/payment/reminder_window.dart';
export 'rules/payment/customer_payment_rule.dart';
export 'rules/payment/construction_payment_rule.dart';
export 'rules/payroll/payroll_reminder_rule.dart';
export 'rules/payroll/worker_salary_rule.dart';
export 'rules/payroll/worker_advance_rule.dart';
export 'rules/inventory/inventory_thresholds.dart';
export 'rules/inventory/inventory_rule_base.dart';
export 'rules/inventory/stock_state_inventory_rule.dart';
export 'rules/inventory/frequently_used_low_rule.dart';
export 'rules/inventory/material_not_updated_rule.dart';
export 'rules/inventory/inventory_audit_reminder_rule.dart';
export 'rules/site/site_thresholds.dart';
export 'rules/site/site_rule_base.dart';
export 'rules/site/site_lifecycle_rule.dart';
export 'rules/worker/worker_thresholds.dart';
export 'rules/worker/worker_rule_base.dart';
export 'rules/worker/worker_lifecycle_rule.dart';
export 'repositories/notification_history_repository.dart';
export 'repositories/notification_settings_repository.dart';
export 'engine/notification_rule_evaluator.dart';
export 'engine/notification_engine.dart';
export 'scheduler/notification_scheduler.dart';
export 'platform/platform_notification_service.dart';
export 'platform/android_notification_service.dart';
export 'platform/windows_notification_service.dart';
export 'platform/platform_notification_service_factory.dart';
export 'background/background_task_coordinator.dart';
