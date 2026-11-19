import 'package:flutter/foundation.dart';

import '../firebase/firebase_cloud_service.dart';
import '../models/store_product_model.dart';
import '../repositories/inventory_repository.dart';

class StoreProductProvider extends ChangeNotifier {
  final _inventory = InventoryRepository();
  final _cloud = FirebaseCloudService.instance;

  List<StoreProduct> _products = [];
  bool _loading = false;
  String? _error;
  int _generation = 0;

  List<StoreProduct> get products => List.unmodifiable(_products);
  bool get loading => _loading;
  String? get error => _error;

  void clear() {
    _generation++;
    _products = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    final gen = _generation;
    _loading = true;
    notifyListeners();
    try {
      final result = await _inventory.getAllStoreProducts();
      if (_generation != gen) return;
      _products = result;
      _error = null;
    } catch (e) {
      if (_generation != gen) return;
      _error = e.toString();
    } finally {
      if (_generation == gen) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addProduct(StoreProduct product) async {
    try {
      final id = await _inventory.insertStoreProduct(product);
      _products.insert(0, product.copyWith(id: id));
      _error = null;
      notifyListeners();
      _cloud.uploadActiveUserInBackground(reason: 'store-product-added');
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(StoreProduct product) async {
    try {
      await _inventory.updateStoreProduct(product);
      final idx = _products.indexWhere((p) => p.id == product.id);
      if (idx >= 0) _products[idx] = product;
      _error = null;
      notifyListeners();
      _cloud.uploadActiveUserInBackground(reason: 'store-product-updated');
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _inventory.deleteStoreProduct(id);
      _products.removeWhere((p) => p.id == id);
      _error = null;
      notifyListeners();
      _cloud.uploadActiveUserInBackground(reason: 'store-product-deleted');
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<double> getSentToSiteTotal(int productId) async {
    return _inventory.getTotalSentToSites(productId);
  }

  Future<StoreProduct?> findByBarcode(String barcode) async {
    return _inventory.getStoreProductByBarcode(barcode);
  }

  Future<List<StoreProduct>> getStockAlertProducts({int limit = 5}) async {
    return _inventory.getStockAlertProducts(limit: limit);
  }

  Future<void> addStock(int productId, double quantity) async {
    await _inventory.addStock(productId, quantity);
    await loadProducts();
  }

  Future<void> reloadAll() async {
    await loadProducts();
  }
}
