import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'screens/listing_details_screen.dart';
import 'screens/main_tabs_screen.dart';

void main() {
  AppConfig.setInstance(AppConfig.prod);
  runApp(const BillisterApp());
}

class BillisterApp extends StatefulWidget {
  const BillisterApp({super.key});

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
    _api = ApiClient(baseUrl: ApiConfig.baseUrl);
    _initDeepLinks();
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
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Billister',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: MainTabsScreen(api: _api),
    );
  }
}