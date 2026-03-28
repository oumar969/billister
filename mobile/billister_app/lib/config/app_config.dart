enum AppFlavor { dev, prod }

class AppConfig {
  final AppFlavor flavor;
  final String appName;
  final String apiBaseUrl;

  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
  });

  bool get isDev => flavor == AppFlavor.dev;
  bool get isProd => flavor == AppFlavor.prod;

  static const AppConfig dev = AppConfig(
    flavor: AppFlavor.dev,
    appName: 'Billister Dev',
    apiBaseUrl: 'http://10.0.2.2:5072',
  );

  static const AppConfig prod = AppConfig(
    flavor: AppFlavor.prod,
    appName: 'Billister',
    apiBaseUrl: 'https://api.billister.no',
  );

  static AppConfig get current {
    assert(_initialized, 'AppConfig.setInstance() must be called in main() before runApp().');
    return _instance;
  }

  static AppConfig _instance = prod;
  static bool _initialized = false;

  /// Call once in `main()`, before `runApp()`, to select the active flavor.
  static void setInstance(AppConfig config) {
    _instance = config;
    _initialized = true;
  }
}
