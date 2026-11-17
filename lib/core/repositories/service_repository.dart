import '../database/database_helper.dart';
import '../models/user_service_model.dart';

/// Repository layer for the global user service catalog.
///
/// Providers access user services only through this repository.
class ServiceRepository {
  final _db = DatabaseHelper();

  Future<List<UserService>> getAllUserServices() => _db.getAllUserServices();

  Future<UserService?> getUserServiceById(int id) =>
      _db.getUserServiceById(id);

  Future<int> insertUserService(UserService service) =>
      _db.insertUserService(service);

  Future<int> updateUserService(UserService service) =>
      _db.updateUserService(service);

  Future<int> deleteUserService(int id) => _db.deleteUserService(id);
}
