import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../firebase/firebase_cloud_service.dart';
import '../models/product_model.dart';
import '../models/site_model.dart';
import '../models/worker_model.dart';

class SiteProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  final _cloud = FirebaseCloudService.instance;

  List<SiteModel> _sites = [];
  List<ProductModel> _products = [];
  List<WorkerModel> _siteWorkers = [];
  bool _sitesLoading = false;
  bool _productsLoading = false;
  bool _siteWorkersLoading = false;
  String? _error;

  /// Incremented by [clear] to invalidate all in-flight async loads,
  /// preventing stale previous-user data from being written back after logout.
  int _generation = 0;

  List<SiteModel> get sites => List.unmodifiable(_sites);
  List<ProductModel> get products => List.unmodifiable(_products);
  List<WorkerModel> get siteWorkers => List.unmodifiable(_siteWorkers);

  /// True while the sites list is loading (used by SitesListScreen).
  bool get isLoading => _sitesLoading;

  /// True while the products list for the current site is loading.
  bool get productsLoading => _productsLoading;

  /// True while the workers list for the current site is loading.
  bool get siteWorkersLoading => _siteWorkersLoading;

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
    _sitesLoading = false;
    _productsLoading = false;
    _siteWorkersLoading = false;
    _error = null;
    notifyListeners();
  }

  // ─────────────── SITES ───────────────

  Future<void> loadSites() async {
    final gen = _generation;
    _sitesLoading = true;
    notifyListeners();
    try {
      final result = await _db.getAllSites();
      if (_generation != gen) return;
      _sites = result;
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
    return _db.getSiteById(id);
  }

  Future<bool> addSite(SiteModel site) async {
    try {
      final id = await _db.insertSite(site);
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
      await _db.updateSite(site);
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
      await _db.deleteSite(id);
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
      final result = await _db.getProductsBySite(siteId);
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
      final id = await _db.insertProduct(product);
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
      await _db.updateProduct(product);
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
      await _db.deleteProduct(id);
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

  // ─────────────── SITE WORKERS ───────────────

  Future<void> loadSiteWorkers(int siteId) async {
    final gen = _generation;
    _siteWorkersLoading = true;
    notifyListeners();
    try {
      final result = await _db.getWorkersBySite(siteId);
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
    return _db.getWorkersNotOnSite(siteId);
  }

  Future<bool> assignWorker(int workerId, int siteId) async {
    try {
      await _db.assignWorkerToSite(workerId, siteId);
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
      await _db.removeWorkerFromSite(workerId, siteId);
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _syncCloud() {
    _cloud.uploadActiveUserInBackground();
  }
}
