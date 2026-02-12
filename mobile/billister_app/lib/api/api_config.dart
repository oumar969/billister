class ApiConfig {
  // Override at build/run time with:
  // flutter run --dart-define=API_BASE_URL=http://localhost:5072
  // Android emulator uses 10.0.2.2 to reach host machine localhost.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5072',
  );
}
