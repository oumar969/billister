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
      seedColor: const Color(0xFF3E6AE1), // Tesla Electric Blue
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
          scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Tesla White
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFFFFFFFF),
            foregroundColor: const Color(0xFF171A20), // Tesla Carbon Dark
            surfaceTintColor: const Color(0xFFFFFFFF),
            scrolledUnderElevation: 0,
            elevation: 0,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF3E6AE1), // Tesla Blue
            foregroundColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF4F4F4), // Tesla Light Ash
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4), // Tesla 4px radius
              borderSide: const BorderSide(
                color: Color(0xFFD0D1D2),
              ), // Pale Silver
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFD0D1D2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF3E6AE1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFEE0000)),
            ),
            hintStyle: const TextStyle(
              color: Color(0xFF8E8E8E), // Silver Fog
              fontWeight: FontWeight.w400,
            ),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w500,
              color: Color(0xFF171A20),
            ),
            headlineSmall: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Color(0xFF171A20),
            ),
            bodyLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF393C41), // Graphite
              height: 1.43,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF5C5E62), // Pewter
            ),
            labelMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF171A20),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E6AE1), // Tesla Blue
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // 4px Tesla style
              ),
              elevation: 0,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF171A20),
              side: const BorderSide(color: Color(0xFFD0D1D2)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF5C5E62), // Pewter
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          dividerColor: const Color(0xFFEEEEEE), // Cloud Gray
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
            ),
          ),
        ),
        home: FlavorBanner(child: MainTabsScreen(api: _api)),
      ),
    );
  }
}
