import '../database/database_helper.dart';
import '../models/construction_payment_model.dart';
import '../models/product_model.dart';
import '../models/site_model.dart';
import '../models/site_product_model.dart';
import '../models/site_service_model.dart';
import '../models/worker_model.dart';

/// Repository layer for everything site-scoped: sites, per-site products,
/// construction payments, site↔worker assignments, site products and services.
///
/// Providers and screens access site data only through this repository.
class SiteRepository {
  final _db = DatabaseHelper();

  // ─────────────── SITES ───────────────

  Future<List<SiteModel>> getAllSites() => _db.getAllSites();

  Future<SiteModel?> getSiteById(int id) => _db.getSiteById(id);

  Future<int> insertSite(SiteModel site) => _db.insertSite(site);

  Future<int> updateSite(SiteModel site) => _db.updateSite(site);

  Future<int> deleteSite(int id) => _db.deleteSite(id);

  // ─────────────── PRODUCTS (per site) ───────────────

  Future<List<ProductModel>> getProductsBySite(int siteId) =>
      _db.getProductsBySite(siteId);

  Future<int> insertProduct(ProductModel product) => _db.insertProduct(product);

  Future<int> updateProduct(ProductModel product) => _db.updateProduct(product);

  Future<int> deleteProduct(int id) => _db.deleteProduct(id);

  // ─────────────── CONSTRUCTION PAYMENTS ───────────────

  Future<List<ConstructionPaymentModel>> getConstructionPaymentsBySite(
          int siteId) =>
      _db.getConstructionPaymentsBySite(siteId);

  Future<int> insertConstructionPayment(ConstructionPaymentModel payment) =>
      _db.insertConstructionPayment(payment);

  Future<int> deleteConstructionPayment(
          int paymentId, int siteId, double amount) =>
      _db.deleteConstructionPayment(paymentId, siteId, amount);

  Future<int> updateConstructionPayment(
    int paymentId,
    double oldAmount,
    ConstructionPaymentModel payment,
  ) =>
      _db.updateConstructionPayment(paymentId, oldAmount, payment);

  // ─────────────── SITE ↔ WORKER ASSIGNMENTS ───────────────

  Future<List<WorkerModel>> getWorkersBySite(int siteId) =>
      _db.getWorkersBySite(siteId);

  Future<List<WorkerModel>> getWorkersNotOnSite(int siteId) =>
      _db.getWorkersNotOnSite(siteId);

  Future<void> assignWorkerToSite(int workerId, int siteId) =>
      _db.assignWorkerToSite(workerId, siteId);

  Future<void> removeWorkerFromSite(int workerId, int siteId) =>
      _db.removeWorkerFromSite(workerId, siteId);

  Future<List<SiteModel>> getSitesByWorker(int workerId) =>
      _db.getSitesByWorker(workerId);

  // ─────────────── SITE PRODUCTS (store → site) ───────────────

  Future<List<SiteProduct>> getSiteProducts(int siteId) =>
      _db.getSiteProducts(siteId);

  Future<SiteProduct> sendProductToSite(
          int siteId, int productId, double quantity) =>
      _db.sendProductToSite(siteId, productId, quantity);

  Future<int> deleteSiteProduct(int id) => _db.deleteSiteProduct(id);

  // ─────────────── SITE SERVICES ───────────────

  Future<List<SiteService>> getSiteServices(int siteId) =>
      _db.getSiteServices(siteId);

  Future<int> insertSiteService(SiteService service) =>
      _db.insertSiteService(service);

  Future<int> updateSiteService(SiteService service) =>
      _db.updateSiteService(service);

  Future<int> deleteSiteService(int id) => _db.deleteSiteService(id);
}
