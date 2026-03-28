import '../config/app_config.dart';

class ApiConfig {
  // Deprecated: use AppConfig.current.apiBaseUrl instead.
  // Kept for backward compatibility; reads from the active AppConfig.
  static String get baseUrl => AppConfig.current.apiBaseUrl;
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Override at build/run time with:
  // flutter run --dart-define=API_BASE_URL=http://localhost:5012
  // Android emulator uses 10.0.2.2 to reach host machine localhost.
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;
    if (kIsWeb) return 'http://localhost:5012';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5012';
    }
    return 'http://localhost:5012';
  }
}
