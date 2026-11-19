import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads OAuth client IDs from the bundled [google-services.json] on Android.
class GoogleServicesConfig {
  GoogleServicesConfig._();

  static String? _webClientId;
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded || !Platform.isAndroid) return;
    _loaded = true;

    try {
      final raw = await rootBundle.loadString('assets/google-services.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _webClientId = _extractWebClientId(json);
    } catch (e) {
      debugPrint('[GoogleServices] Failed to load google-services.json: $e');
      _webClientId = null;
    }
  }

  static String? get webClientId => _webClientId;

  static String? _extractWebClientId(Map<String, dynamic> json) {
    final clients = json['client'] as List<dynamic>? ?? const [];
    for (final client in clients) {
      final oauthClients =
          (client as Map<String, dynamic>)['oauth_client'] as List<dynamic>? ??
              const [];
      for (final oauthClient in oauthClients) {
        final entry = oauthClient as Map<String, dynamic>;
        final type = entry['client_type'];
        if (type == 3) {
          final clientId = entry['client_id'] as String?;
          if (clientId != null && clientId.isNotEmpty) {
            return clientId;
          }
        }
      }
    }
    return null;
  }
}
