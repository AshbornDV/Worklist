import 'package:flutter/foundation.dart';
import '../firebase/firebase_cloud_service.dart';
import '../models/product_model.dart';
import '../models/site_model.dart';
import '../models/worker_model.dart';
import '../services/collection_reminder_service.dart';
import '../models/construction_payment_model.dart';
import '../models/site_product_model.dart';
import '../models/site_service_model.dart';
import '../repositories/site_repository.dart';

class SiteProvider extends ChangeNotifier {
  final _repo = SiteRepository();
  final _cloud = FirebaseCloudService.instance;

  List<SiteModel> _sites = [];
  List<ProductModel> _products = [];
  List<WorkerModel> _siteWorkers = [];
  List<ConstructionPaymentModel> _constructionPayments = [];
  List<SiteProduct> _siteProducts = [];
  List<SiteService> _siteServices = [];
  bool _sitesLoading = false;
  bool _productsLoading = false;
  bool _siteWorkersLoading = false;
  bool _constructionPaymentsLoading = false;
  bool _siteProductsLoading = false;
  bool _siteServicesLoading = false;
  String? _error;

  /// Incremented by [clear] to invalidate all in-flight async loads,
  /// preventing stale previous-user data from being written back after logout.
  int _generation = 0;

  List<SiteModel> get sites => List.unmodifiable(_sites);
  List<ProductModel> get products => List.unmodifiable(_products);
  List<WorkerModel> get siteWorkers => List.unmodifiable(_siteWorkers);
  List<ConstructionPaymentModel> get constructionPayments =>
      List.unmodifiable(_constructionPayments);
  List<SiteProduct> get siteProducts => List.unmodifiable(_siteProducts);
  List<SiteService> get siteServices => List.unmodifiable(_siteServices);

  /// True while the sites list is loading (used by SitesListScreen).
  bool get isLoading => _sitesLoading;

  /// True while the products list for the current site is loading.
  bool get productsLoading => _productsLoading;

  /// True while the workers list for the current site is loading.
  bool get siteWorkersLoading => _siteWorkersLoading;

  bool get constructionPaymentsLoading => _constructionPaymentsLoading;
  bool get siteProductsLoading => _siteProductsLoading;
  bool get siteServicesLoading => _siteServicesLoading;

  String? get error => _error;

  // ── Stats for dashboard ──
  int get activeSiteCount => _sites.where((s) => s.status == 'active').length;
  double get totalEstimatedCost =>
      _sites.fold(0, (sum, s) => sum + s.estimatedCost);
  double get totalAdvanceReceived =>
      _sites.fold(0, (sum, s) => sum + s.advanceReceived);

  /// Clears all cached data and invalidates any in-flight loads.
  /// Call this on logout so stale previous-user data never appears.
  void clear() {
    _generation++;
    _sites = [];
    _products = [];
    _siteWorkers = [];
    _constructionPayments = [];
    _siteProducts = [];
    _siteServices = [];
    _sitesLoading = false;
    _productsLoading = false;
    _siteWorkersLoading = false;
    _constructionPaymentsLoading = false;
    _siteProductsLoading = false;
    _siteServicesLoading = false;
    _error = null;
    notifyListeners();
  }

  // ─────────────── SITES ───────────────

  Future<void> loadSites() async {
    final gen = _generation;
    _sitesLoading = true;
    notifyListeners();
    try {
      final result = await _repo.getAllSites();
      if (_generation != gen) return;
      _sites = result;
      CollectionReminderService.instance.syncReminders(_sites);
    } catch (e) {
      if (_generation != gen) return;
      _error = e.toString();
    } finally {
      if (_generation == gen) {
        _sitesLoading = false;
        notifyListeners();
      }
    }
  }

  Future<SiteModel?> getSite(int id) async {
    return _repo.getSiteById(id);
  }

  Future<bool> addSite(SiteModel site) async {
    try {
      final id = await _repo.insertSite(site);
      _sites.insert(0, site.copyWith(id: id));
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSite(SiteModel site) async {
    try {
      await _repo.updateSite(site);
      final idx = _sites.indexWhere((s) => s.id == site.id);
      if (idx != -1) _sites[idx] = site;
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSite(int id) async {
    try {
      await _repo.deleteSite(id);
      _sites.removeWhere((s) => s.id == id);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────── PRODUCTS ───────────────

  Future<void> loadProducts(int siteId) async {
    final gen = _generation;
    _productsLoading = true;
    notifyListeners();
    try {
      final result = await _repo.getProductsBySite(siteId);
      if (_generation != gen) return;
      _products = result;
    } catch (e) {
      if (_generation != gen) return;
      _error = e.toString();
    } finally {
      if (_generation == gen) {
        _productsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      final id = await _repo.insertProduct(product);
      _products.insert(0, product.copyWith(id: id));
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _repo.updateProduct(product);
      final idx = _products.indexWhere((p) => p.id == product.id);
      if (idx != -1) _products[idx] = product;
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _repo.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────── CONSTRUCTION PAYMENTS ───────────────

  Future<void> loadConstructionPayments(int siteId) async {
    final gen = _generation;
    _constructionPaymentsLoading = true;
    notifyListeners();
    try {
      final result = await _repo.getConstructionPaymentsBySite(siteId);
      if (_generation != gen) return;
      _constructionPayments = result;
    } catch (e) {
      if (_generation != gen) return;
      _error = e.toString();
    } finally {
      if (_generation == gen) {
        _constructionPaymentsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addConstructionPayment(ConstructionPaymentModel payment) async {
    try {
      final id = await _repo.insertConstructionPayment(payment);
      _constructionPayments.insert(0, payment.copyWith(id: id));
      
      // Update site in memory
      final idx = _sites.indexWhere((s) => s.id == payment.siteId);
      if (idx != -1) {
        final s = _sites[idx];
        _sites[idx] = s.copyWith(
          constructionPaid: s.constructionPaid + payment.amount,
          lastPaidDate: payment.paymentDate,
        );
      }
      
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteConstructionPayment(int paymentId, int siteId, double amount) async {
    try {
      await _repo.deleteConstructionPayment(paymentId, siteId, amount);
      _constructionPayments.removeWhere((p) => p.id == paymentId);
      
      // Update site in memory
      final idx = _sites.indexWhere((s) => s.id == siteId);
      if (idx != -1) {
        final s = _sites[idx];
        _sites[idx] = s.copyWith(
          constructionPaid: s.constructionPaid - amount,
        );
      }
      
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateConstructionPayment(
    int paymentId,
    double oldAmount,
    ConstructionPaymentModel payment,
  ) async {
    try {
      await _repo.updateConstructionPayment(paymentId, oldAmount, payment);
      final idx = _constructionPayments.indexWhere((p) => p.id == paymentId);
      if (idx != -1) {
        _constructionPayments[idx] = payment.copyWith(id: paymentId);
      }
      
      // Update site in memory
      final sIdx = _sites.indexWhere((s) => s.id == payment.siteId);
      if (sIdx != -1) {
        final s = _sites[sIdx];
        final diff = payment.amount - oldAmount;
        _sites[sIdx] = s.copyWith(
          constructionPaid: s.constructionPaid + diff,
          lastPaidDate: payment.paymentDate.isAfter(s.lastPaidDate ?? s.createdAt)
              ? payment.paymentDate
              : s.lastPaidDate,
        );
      }
      
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────── SITE WORKERS ───────────────

  Future<void> loadSiteWorkers(int siteId) async {
    final gen = _generation;
    _siteWorkersLoading = true;
    notifyListeners();
    try {
      final result = await _repo.getWorkersBySite(siteId);
      if (_generation != gen) return;
      _siteWorkers = result;
    } catch (e) {
      if (_generation != gen) return;
      _error = e.toString();
    } finally {
      if (_generation == gen) {
        _siteWorkersLoading = false;
        notifyListeners();
      }
    }
  }

  Future<List<WorkerModel>> getWorkersNotOnSite(int siteId) async {
    return _repo.getWorkersNotOnSite(siteId);
  }

  Future<bool> assignWorker(int workerId, int siteId) async {
    try {
      await _repo.assignWorkerToSite(workerId, siteId);
      await loadSiteWorkers(siteId);
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeWorker(int workerId, int siteId) async {
    try {
      await _repo.removeWorkerFromSite(workerId, siteId);
      _siteWorkers.removeWhere((w) => w.id == workerId);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────── SITE PRODUCTS ───────────────

  Future<void> loadSiteProducts(int siteId) async {
    final gen = _generation;
    _siteProductsLoading = true;
    notifyListeners();
    try {
      final result = await _repo.getSiteProducts(siteId);
      if (_generation != gen) return;
      _siteProducts = result;
    } catch (e) {
      if (_generation != gen) return;
      _error = e.toString();
    } finally {
      if (_generation == gen) {
        _siteProductsLoading = false;
        notifyListeners();
      }
    }
  }

  /// Sends a product from store inventory to this site.
  /// Deducts store stock and adds a site_product record in one transaction.
  Future<String?> sendProductToSite(int siteId, int productId, double quantity) async {
    try {
      final siteProduct = await _repo.sendProductToSite(siteId, productId, quantity);
      _siteProducts.insert(0, siteProduct);
      _error = null;
      notifyListeners();
      _syncCloud();
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  Future<bool> deleteSiteProduct(int id) async {
    try {
      await _repo.deleteSiteProduct(id);
      _siteProducts.removeWhere((p) => p.id == id);
      _error = null;
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────── SITE SERVICES ───────────────

  Future<void> loadSiteServices(int siteId) async {
    final gen = _generation;
    _siteServicesLoading = true;
    notifyListeners();
    try {
      final result = await _repo.getSiteServices(siteId);
      if (_generation != gen) return;
      _siteServices = result;
    } catch (e) {
      if (_generation != gen) return;
      _error = e.toString();
    } finally {
      if (_generation == gen) {
        _siteServicesLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addSiteService(SiteService service) async {
    try {
      final id = await _repo.insertSiteService(service);
      _siteServices.add(service.copyWith(id: id));
      _error = null;
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSiteService(SiteService service) async {
    try {
      await _repo.updateSiteService(service);
      final idx = _siteServices.indexWhere((s) => s.id == service.id);
      if (idx >= 0) _siteServices[idx] = service;
      _error = null;
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSiteService(int id) async {
    try {
      await _repo.deleteSiteService(id);
      _siteServices.removeWhere((s) => s.id == id);
      _error = null;
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────── TOTALS ───────────────

  double getSiteServiceTotal() =>
      _siteServices.fold(0.0, (sum, s) => sum + s.rate);

  double getSiteProductTotal() =>
      _siteProducts.fold(0.0, (sum, p) => sum + p.totalCost);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> reloadAll() async {
    await Future.wait([
      loadSites(),
      // Note: site-specific loads (products, workers, etc.) require a siteId
      // They will be reloaded when user navigates to a site
    ]);
  }

  void _syncCloud() {
    _cloud.uploadActiveUserInBackground(reason: 'site-data-changed');
  }
}
