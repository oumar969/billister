import '../config/app_config.dart';

class ApiConfig {
  // Deprecated: use AppConfig.current.apiBaseUrl instead.
  // Kept for backward compatibility; reads from the active AppConfig.
  static String get baseUrl => AppConfig.current.apiBaseUrl;
}
