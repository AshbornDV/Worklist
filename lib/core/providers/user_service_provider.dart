import 'package:material_ui/material_ui.dart';
import '../firebase/firebase_cloud_service.dart';
import '../models/user_service_model.dart';
import '../repositories/service_repository.dart';

class UserServiceProvider extends ChangeNotifier {
  final _repo = ServiceRepository();
  final _cloud = FirebaseCloudService.instance;

  List<UserService> _services = [];
  bool _loading = false;
  int _generation = 0;

  List<UserService> get services => List.unmodifiable(_services);
  bool get loading => _loading;

  Future<void> loadServices() async {
    _loading = true;
    notifyListeners();
    final gen = ++_generation;
    try {
      final list = await _repo.getAllUserServices();
      if (gen != _generation) return;
      _services = list;
    } finally {
      if (gen == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> addService(UserService service) async {
    await _repo.insertUserService(service);
    _cloud.uploadActiveUserInBackground(reason: 'user-service-added');
    await loadServices();
  }

  Future<void> updateService(UserService service) async {
    await _repo.updateUserService(service);
    _cloud.uploadActiveUserInBackground(reason: 'user-service-updated');
    await loadServices();
  }

  Future<void> deleteService(int id) async {
    await _repo.deleteUserService(id);
    _cloud.uploadActiveUserInBackground(reason: 'user-service-deleted');
    await loadServices();
  }

  void clear() {
    _services = [];
    _generation++;
    _loading = false;
    notifyListeners();
  }

  Future<void> reloadAll() async {
    await loadServices();
  }
}
