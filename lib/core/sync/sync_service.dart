import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/dashboard_repository.dart';

class SyncService extends ChangeNotifier {
  static const defaultPort = 8787;
  static const _serverAddressKey = 'sync_server_address';

  final _auth = AuthRepository();
  final _sync = DashboardRepository();
  HttpServer? _server;
  StreamSubscription<HttpRequest>? _subscription;
  bool _busy = false;
  String? _message;

  bool get isRunning => _server != null;
  bool get isBusy => _busy;
  String? get message => _message;
  int get port => _server?.port ?? defaultPort;

  Future<String?> loadServerAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverAddressKey);
  }

  Future<void> saveServerAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverAddressKey, address.trim());
  }

  Future<void> startServer({int port = defaultPort}) async {
    if (_server != null) return;
    _setBusy(true);
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _subscription = _server!.listen(_handleRequest);
      _message = 'Sharing server is running on port ${_server!.port}.';
    } catch (e) {
      _message = 'Could not start sharing server: $e';
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> stopServer() async {
    _setBusy(true);
    try {
      await _subscription?.cancel();
      await _server?.close(force: true);
      _subscription = null;
      _server = null;
      _message = 'Sharing server stopped.';
    } finally {
      _setBusy(false);
    }
  }

  Future<List<String>> localAddresses() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    final addresses = <String>[];
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        addresses.add('${address.address}:$port');
      }
    }
    return addresses;
  }

  Future<String> pullFromServer({
    required String address,
    required String username,
    required String password,
    required int currentUserId,
  }) async {
    final response = await _postJson(
      address,
      '/sync/export',
      {
        'username': username,
        'password': password,
      },
    );
    await _sync.replaceUserData(
      currentUserId,
      Map<String, dynamic>.from(response['data'] as Map),
    );
    await saveServerAddress(address);
    _message = 'Data pulled from server.';
    notifyListeners();
    return _message!;
  }

  Future<String> pushToServer({
    required String address,
    required String username,
    required String password,
    required int currentUserId,
  }) async {
    final data = await _sync.exportUserData(currentUserId);
    await _postJson(
      address,
      '/sync/import',
      {
        'username': username,
        'password': password,
        'data': data,
      },
    );
    await saveServerAddress(address);
    _message = 'Data pushed to server.';
    notifyListeners();
    return _message!;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    request.response.headers
      ..set(HttpHeaders.accessControlAllowOriginHeader, '*')
      ..set(HttpHeaders.accessControlAllowMethodsHeader, 'GET, POST, OPTIONS')
      ..set(HttpHeaders.accessControlAllowHeadersHeader, 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    try {
      if (request.method == 'GET' && request.uri.path == '/sync/status') {
        await _writeJson(request, {
          'ok': true,
          'app': 'Worklist',
          'serverTime': DateTime.now().toIso8601String(),
        });
        return;
      }

      if (request.method == 'POST' && request.uri.path == '/sync/export') {
        final body = await _readJson(request);
        final user = await _authenticateBody(body);
        final data = await _sync.exportUserData(user.id!);
        await _writeJson(request, {'ok': true, 'data': data});
        return;
      }

      if (request.method == 'POST' && request.uri.path == '/sync/import') {
        final body = await _readJson(request);
        final user = await _authenticateBody(body);
        final data = Map<String, dynamic>.from(body['data'] as Map);
        await _sync.replaceUserData(user.id!, data);
        await _writeJson(request, {'ok': true});
        return;
      }

      throw const _SyncHttpException(HttpStatus.notFound, 'Route not found.');
    } on _SyncHttpException catch (e) {
      await _writeJson(
        request,
        {'ok': false, 'message': e.message},
        statusCode: e.statusCode,
      );
    } catch (e) {
      await _writeJson(
        request,
        {'ok': false, 'message': 'Sync failed: $e'},
        statusCode: HttpStatus.internalServerError,
      );
    }
  }

  Future<UserModel> _authenticateBody(Map<String, dynamic> body) async {
    final username = (body['username'] as String?)?.trim() ?? '';
    final password = body['password'] as String? ?? '';
    if (username.isEmpty || password.isEmpty) {
      throw const _SyncHttpException(
        HttpStatus.badRequest,
        'Username and password are required.',
      );
    }
    final user = await _auth.authenticate(username, password);
    if (user == null) {
      throw const _SyncHttpException(
        HttpStatus.unauthorized,
        'The account was not accepted by this Worklist server.',
      );
    }
    return user;
  }

  Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    if (body.trim().isEmpty) return {};
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const _SyncHttpException(
        HttpStatus.badRequest,
        'Expected a JSON object.',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _writeJson(
    HttpRequest request,
    Map<String, dynamic> body, {
    int statusCode = HttpStatus.ok,
  }) async {
    request.response.statusCode = statusCode;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }

  Future<Map<String, dynamic>> _postJson(
    String address,
    String path,
    Map<String, dynamic> payload,
  ) async {
    final client = HttpClient();
    try {
      final uri = _uri(address, path);
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));

      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      final decoded = body.trim().isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(body) as Map);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(decoded['message'] ?? 'Server refused the sync.');
      }

      return decoded;
    } finally {
      client.close(force: true);
    }
  }

  Uri _uri(String address, String path) {
    final trimmed = address.trim();
    final withScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed
            : 'http://$trimmed';
    final uri = Uri.parse(withScheme);
    return uri.replace(path: path);
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}

class _SyncHttpException implements Exception {
  final int statusCode;
  final String message;

  const _SyncHttpException(this.statusCode, this.message);
}
