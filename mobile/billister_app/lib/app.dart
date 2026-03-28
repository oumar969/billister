import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'config/app_config.dart';
import 'screens/main_tabs_screen.dart';
import 'widgets/flavor_banner.dart';

class BillisterApp extends StatefulWidget {
  final SharedPreferences sharedPreferences;

  const BillisterApp({super.key, required this.sharedPreferences});

  @override
  State<BillisterApp> createState() => _BillisterAppState();
}

class _BillisterAppState extends State<BillisterApp> {
  late final ApiClient _api;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(
      baseUrl: AppConfig.current.apiBaseUrl,
      prefs: widget.sharedPreferences,
    );
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await _api.restoreSession();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: AppConfig.current.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          surfaceTintColor: scheme.surface,
          scrolledUnderElevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      home: FlavorBanner(child: MainTabsScreen(api: _api)),
    );
  }
}
