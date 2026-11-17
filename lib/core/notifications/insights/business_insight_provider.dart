import 'package:flutter/foundation.dart';

import '../../repositories/inventory_repository.dart';
import '../../repositories/payroll_repository.dart';
import '../../repositories/site_repository.dart';
import '../../repositories/worker_repository.dart';
import './business_insight_engine.dart';
import './business_insight_models.dart';

/// Phase 11 — UI state for the Business Insight screen.
///
/// Owns a [BusinessInsightEngine] wired to the app's existing repositories and
/// exposes the generated [BusinessInsight]s plus the four [InsightSummary]
/// kinds. Loading is read-only; no business data is mutated.
class BusinessInsightProvider extends ChangeNotifier {
  BusinessInsightProvider({
    SiteRepository? siteRepository,
    PayrollRepository? payrollRepository,
    WorkerRepository? workerRepository,
    InventoryRepository? inventoryRepository,
  })  : _engine = BusinessInsightEngine(
          siteRepository: siteRepository ?? SiteRepository(),
          payrollRepository: payrollRepository ?? PayrollRepository(),
          workerRepository: workerRepository ?? WorkerRepository(),
          inventoryRepository: inventoryRepository ?? InventoryRepository(),
        );

  final BusinessInsightEngine _engine;

  List<BusinessInsight> _insights = const [];
  final Map<InsightSummaryKind, InsightSummary?> _summaries = {
    for (final k in InsightSummaryKind.values) k: null,
  };
  bool _loading = false;
  String? _error;

  List<BusinessInsight> get insights => List.unmodifiable(_insights);
  InsightSummary? summary(InsightSummaryKind kind) => _summaries[kind];
  bool get isLoading => _loading;
  String? get error => _error;

  List<BusinessInsight> forDomain(InsightDomain domain) =>
      _insights.where((i) => i.domain == domain).toList();

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _insights = await _engine.generateAll();
      for (final kind in InsightSummaryKind.values) {
        _summaries[kind] = await _engine.generateSummary(kind);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Convenience: the most urgent summary headline for a home/overview card.
  String summaryHeadline(InsightSummaryKind kind) =>
      _summaries[kind]?.headline ?? '${kind.title}: —';
}
