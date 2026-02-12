import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/api_config.dart';
import 'screens/main_tabs_screen.dart';

void main() {
  runApp(const BillisterApp());
}

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
    _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billister',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: MainTabsScreen(api: _api),
    );
  }
}
