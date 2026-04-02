import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../api/api_client.dart';

class StripePaymentService extends ChangeNotifier {
  final ApiClient apiClient;

  String? _clientSecret;
  String? _stripePaymentIntentId;
  bool _isProcessing = false;
  String? _error;

  // Getters
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  bool get hasPaymentIntent =>
      _clientSecret != null && _stripePaymentIntentId != null;

  StripePaymentService({required this.apiClient});

  /// Initialize Stripe with publishable key
  static Future<void> initialize(String publishableKey) async {
    try {
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
    } catch (e) {
      debugPrint('Error initializing Stripe: $e');
    }
  }

  /// Initiate a payment and get clientSecret
  Future<bool> initiatePayment({
    required String orderId,
    required double amount,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final payment = await apiClient.initiatePayment(
        orderId: orderId,
        amount: amount,
      );

      _clientSecret = payment.stripe_clientSecret;
      _stripePaymentIntentId = payment.stripe_paymentIntentId;

      if (_clientSecret == null || _stripePaymentIntentId == null) {
        _error = 'Failed to get Stripe payment details';
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to initiate payment: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Confirm payment with Stripe
  Future<bool> confirmPayment() async {
    if (_clientSecret == null || _stripePaymentIntentId == null) {
      _error = 'Payment not initialized';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Present card payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Confirm with backend
      await apiClient.confirmPayment(
        paymentId: _stripePaymentIntentId!,
        stripeSessionId: _stripePaymentIntentId!,
      );

      _clientSecret = null;
      _stripePaymentIntentId = null;

      notifyListeners();
      return true;
    } on StripeException catch (e) {
      _error = 'Stripe error: ${e.error.message}';
      debugPrint(_error);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Payment confirmation failed: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Setup payment sheet
  Future<bool> setupPaymentSheet({
    required String merchantDisplayName,
    required String customerId,
    required String ephemeralKeySecret,
  }) async {
    try {
      if (_clientSecret == null) {
        _error = 'Client secret not set';
        return false;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: _clientSecret,
          merchantDisplayName: merchantDisplayName,
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKeySecret,
          style: ThemeMode.system,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFF4F46E5),
            ),
          ),
        ),
      );

      return true;
    } catch (e) {
      _error = 'Failed to setup payment sheet: $e';
      debugPrint(_error);
      return false;
    }
  }

  /// Clear payment state
  void clearPayment() {
    _clientSecret = null;
    _stripePaymentIntentId = null;
    _error = null;
    _isProcessing = false;
    notifyListeners();
  }
}
