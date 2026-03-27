import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'config/app_config.dart';
import 'screens/main_tabs_screen.dart';
import 'widgets/flavor_banner.dart';

class BillisterApp extends StatefulWidget {
  const BillisterApp({super.key});

  @override
  State<BillisterApp> createState() => _BillisterAppState();
}

class _BillisterAppState extends State<BillisterApp> {
  late final ApiClient _api;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: AppConfig.current.apiBaseUrl);
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.current.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: FlavorBanner(child: MainTabsScreen(api: _api)),
    );
  }
}
