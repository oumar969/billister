import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'screens/listing_details_screen.dart';
import 'screens/main_tabs_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  AppConfig.setInstance(AppConfig.prod);
  runApp(BillisterApp(sharedPreferences: prefs));
}

class BillisterApp extends StatefulWidget {
  final SharedPreferences sharedPreferences;

  const BillisterApp({super.key, required this.sharedPreferences});

  @override
  State<BillisterApp> createState() => _BillisterAppState();
}

class _BillisterAppState extends State<BillisterApp> {
  late final ApiClient _api;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(
      baseUrl: ApiConfig.baseUrl,
      prefs: widget.sharedPreferences,
    );
    _initDeepLinks();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await _api.restoreSession();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initDeepLinks() async {
    // Handle initial link when the app is launched from a deep link.
    // Deferred until after the first frame so the navigator is ready.
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeepLink(initial);
      });
    }
    // Listen for links while the app is running.
    _linkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'billister' &&
        uri.host == 'listings' &&
        uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first;
      if (id.isNotEmpty) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ListingDetailsScreen(api: _api, listingId: id),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
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
      navigatorKey: _navigatorKey,
      title: 'Billister',
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
      home: MainTabsScreen(api: _api),
    );
  }
}
