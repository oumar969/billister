import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'config/app_config.dart';
import 'screens/main_tabs_screen.dart';
import 'services/signalr_chat_service.dart';
import 'widgets/flavor_banner.dart';

class BillisterApp extends StatefulWidget {
  final SharedPreferences sharedPreferences;

  const BillisterApp({super.key, required this.sharedPreferences});

  @override
  State<BillisterApp> createState() => _BillisterAppState();
}

class _BillisterAppState extends State<BillisterApp> {
  late final ApiClient _api;
  late final SignalRChatService _signalRService;
  bool _signalRInitialized = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(
      baseUrl: AppConfig.current.apiBaseUrl,
      prefs: widget.sharedPreferences,
    );
    _signalRService = SignalRChatService();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await _api.restoreSession();

    // Initialize SignalR if user is authenticated
    if (mounted && _api.token != null && _api.currentUser != null) {
      await _initializeSignalR();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeSignalR() async {
    if (_signalRInitialized || _api.token == null) return;

    try {
      await _signalRService.connect(
        baseUrl: AppConfig.current.apiBaseUrl,
        userId: _api.currentUser?.id ?? '',
        authToken: _api.token,
      );
      _signalRInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize SignalR: $e');
    }
  }

  @override
  void dispose() {
    _api.dispose();
    _signalRService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SignalRChatService>.value(
          value: _signalRService,
        ),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
