import '../database/database_helper.dart';
import '../models/product_model.dart';
import '../models/store_product_model.dart';

/// Repository layer for the global store inventory: store products, stock
/// operations, barcode lookup and stock alerts.
///
/// Providers and screens access inventory data only through this repository.
class InventoryRepository {
  final _db = DatabaseHelper();

  // ─────────────── STORE PRODUCTS ───────────────

  Future<List<StoreProduct>> getAllStoreProducts() =>
      _db.getAllStoreProducts();

  Future<StoreProduct?> getStoreProductById(int id) =>
      _db.getStoreProductById(id);

  Future<StoreProduct?> getStoreProductByBarcode(String barcode) =>
      _db.getStoreProductByBarcode(barcode);

  Future<int> insertStoreProduct(StoreProduct product) =>
      _db.insertStoreProduct(product);

  Future<int> updateStoreProduct(StoreProduct product) =>
      _db.updateStoreProduct(product);

  Future<int> deleteStoreProduct(int id) => _db.deleteStoreProduct(id);

  // ─────────────── STOCK OPERATIONS ───────────────

  Future<void> deductStoreStock(int productId, double quantity) =>
      _db.deductStoreStock(productId, quantity);

  Future<void> restoreStoreStock(int productId, double quantity) =>
      _db.restoreStoreStock(productId, quantity);

  Future<void> addStock(int productId, double quantity) =>
      _db.addStock(productId, quantity);

  Future<void> setStock(int productId, double quantity) =>
      _db.setStock(productId, quantity);

  Future<double> getTotalSentToSites(int productId) =>
      _db.getTotalSentToSites(productId);

  Future<List<StoreProduct>> getStockAlertProducts({int limit = 5}) =>
      _db.getStockAlertProducts(limit: limit);

  // ─────────────── PRODUCTS (site delivery) ───────────────

  /// Read-only: all products across the current user's sites.
  /// Returns ProductModel list (NOT StoreProduct).
  /// Used by Calendar to surface material delivery reminders.
  Future<List<ProductModel>> getAllProducts() => _db.getAllProducts();
}
