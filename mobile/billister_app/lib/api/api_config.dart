import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class ApiConfig {
  // Override at build/run time with:
  // flutter run --dart-define=API_BASE_URL=http://localhost:5012
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;

    final configured = AppConfig.current.apiBaseUrl;
    final adapted = _adaptConfiguredUrl(configured);
    if (adapted != null) return adapted;

    // Fallback defaults (should rarely be needed).
    if (kIsWeb) return 'http://localhost:5012';
    if (defaultTargetPlatform == TargetPlatform.android)
      return 'http://10.0.2.2:5012';
    return 'http://localhost:5012';
  }

  static String? _adaptConfiguredUrl(String configured) {
    if (configured.isEmpty) return null;
    final uri = Uri.tryParse(configured);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty)
      return configured;

    // Android emulator can't reach host localhost directly.
    if (defaultTargetPlatform == TargetPlatform.android &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return uri.replace(host: '10.0.2.2').toString();
    }

    // Web/desktop should not use emulator host.
    if (kIsWeb && uri.host == '10.0.2.2') {
      return uri.replace(host: 'localhost').toString();
    }

    return configured;
  }
}
