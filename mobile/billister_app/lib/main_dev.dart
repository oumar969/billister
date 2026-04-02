import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'app.dart';
import 'services/stripe_payment_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe with test publishable key (only on non-web platforms)
  if (!kIsWeb) {
    await StripePaymentService.initialize('pk_test_51234567890');
  }

  final prefs = await SharedPreferences.getInstance();
  AppConfig.setInstance(AppConfig.dev);
  runApp(BillisterApp(sharedPreferences: prefs));
}
