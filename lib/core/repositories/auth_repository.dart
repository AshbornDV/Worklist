import '../database/database_helper.dart';
import '../models/user_model.dart';

/// Repository layer for authentication and user-account access.
///
/// All SQLite access for users goes through here; providers/services must not
/// touch [DatabaseHelper] directly for auth concerns.
class AuthRepository {
  final _db = DatabaseHelper();

  String hashPassword(String password) => _db.hashPassword(password);

  Future<UserModel?> authenticate(String username, String password) {
    return _db.authenticate(username, password);
  }

  Future<UserModel?> getUserByUsername(String username) {
    return _db.getUserByUsername(username);
  }

  Future<UserModel> createAccount(String username, String password) {
    return _db.createAccount(username, password);
  }

  Future<int> createUser(UserModel user) => _db.createUser(user);

  Future<UserModel> ensureGoogleLocalAccount(String username) {
    return _db.ensureGoogleLocalAccount(username);
  }

  Future<UserModel> ensureLocalAccount(String username, String password) {
    return _db.ensureLocalAccount(username, password);
  }

  void setActiveUser(UserModel? user) => _db.setActiveUser(user);

  /// The id of the currently signed-in local Worklist user. Auth state lives
  /// in [DatabaseHelper] (set via [setActiveUser]); exposed here so services
  /// and providers resolve the active user without touching [DatabaseHelper].
  int? get activeUserId => _db.activeUserId;
}
