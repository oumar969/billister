import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'api/api_config.dart';
import 'screens/main_tabs_screen.dart';
import 'screens/onboarding_screen.dart';

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

  /// null while loading from SharedPreferences, true/false afterwards.
  bool? _onboardingSeen;

  static const String _tokenKey = 'auth_token';
  static const String _onboardingKey = 'onboarding_seen';

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: ApiConfig.baseUrl);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final seen = prefs.getBool(_onboardingKey) ?? false;
    if (token != null && token.isNotEmpty) {
      _api.token = token;
    }
    if (mounted) setState(() => _onboardingSeen = seen);
  }

  /// Called whenever the authentication state changes (login / logout).
  void _handleAuthChanged() {
    _saveToken();
    if (mounted) setState(() {});
  }

  Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = _api.token;
    if (t != null && t.isNotEmpty) {
      await prefs.setString(_tokenKey, t);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  /// Called when the user completes (or skips) onboarding.
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    if (mounted) setState(() => _onboardingSeen = true);
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingSeen == null) {
      return MaterialApp(
        title: 'Billister',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Billister',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: _onboardingSeen!
          ? MainTabsScreen(
              api: _api,
              onAuthChanged: _handleAuthChanged,
            )
          : OnboardingScreen(
              api: _api,
              onComplete: _completeOnboarding,
              onAuthChanged: _handleAuthChanged,
            ),
    );
  }
}

