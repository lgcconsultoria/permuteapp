import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  // Build-time override (e.g. flutter run --dart-define=API_BASE_URL=...).
  static const String _override = String.fromEnvironment('API_BASE_URL');

  // On web the API is served from the same origin under /api/v1.
  // On Android emulator, host machine is reachable at 10.0.2.2.
  static const String _webDefault = '/api/v1';
  static const String _mobileDefault = 'http://10.0.2.2:3000/api/v1';

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return kIsWeb ? _webDefault : _mobileDefault;
  }
}
