import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../api/models.dart';
import '../services/stripe_payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final ApiClient api;
  final Order order;

  const PaymentScreen({Key? key, required this.api, required this.order})
    : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late StripePaymentService _stripeService;
  bool _isInitiating = false;
  bool _isConfirming = false;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _stripeService = StripePaymentService(apiClient: widget.api);
    _stripeService.addListener(_onStripeStateChanged);
  }

  @override
  void dispose() {
    _stripeService.removeListener(_onStripeStateChanged);
    _stripeService.dispose();
    super.dispose();
  }

  void _onStripeStateChanged() {
    if (mounted) {
      setState(() {
        _error = _stripeService.error;
      });
    }
  }

  Future<void> _payWithStripe() async {
    if (!_stripeService.isProcessing) {
      setState(() => _isInitiating = true);

      // Step 1: Initiate payment
      final initiated = await _stripeService.initiatePayment(
        orderId: widget.order.id,
        amount: widget.order.amount,
      );

      if (!initiated) {
        setState(() => _isInitiating = false);
        return;
      }

      if (!mounted) return;

      // Step 2: Setup payment sheet
      final setupSuccess = await _stripeService.setupPaymentSheet(
        merchantDisplayName: 'Billister',
        customerId: widget.api.currentUser?.id ?? '',
        ephemeralKeySecret: '', // Optional - for customer saved cards
      );

      if (!setupSuccess) {
        setState(() => _isInitiating = false);
        return;
      }

      if (!mounted) return;

      setState(() {
        _isInitiating = false;
        _isConfirming = true;
      });

      // Step 3: Confirm payment
      final confirmed = await _stripeService.confirmPayment();

      if (!mounted) return;

      setState(() => _isConfirming = false);

      if (confirmed) {
        setState(() => _successMessage = 'Betaling gennemført!');
        if (mounted) {
          await Future.delayed(const Duration(seconds: 2));
          Navigator.of(context).pop(true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_stripeService.isProcessing) {
          return false; // Prevent navigation during payment
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Betaling'),
          elevation: 0,
          automaticallyImplyLeading: !_stripeService.isProcessing,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderSummary(),
              const Divider(height: 32),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_error != null && _successMessage == null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_successMessage == null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildPaymentInfo(),
                ),
              const SizedBox(height: 24),
              if (_successMessage == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPayButton(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ordre opsummering',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _summaryRow('Ordre-ID', widget.order.id.substring(0, 8)),
          _summaryRow(
            'Beløb',
            '${widget.order.amount.toStringAsFixed(0)} DKK',
            bold: true,
          ),
          _summaryRow(
            'Status',
            widget.order.statusDanish,
            color: _getStatusColor(widget.order.status),
          ),
          _summaryRow('Valuta', 'DKK'),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sikker betaling gennem Stripe',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Du kan betale med:',
            style: TextStyle(
              color: Colors.blue[900],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Visa, Mastercard, American Express\n• Apple Pay, Google Pay\n• Lokale betalingsmetoder',
            style: TextStyle(color: Colors.blue[800], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    final isProcessing = _isInitiating || _isConfirming;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledBackgroundColor: Colors.grey[300],
        ),
        onPressed: isProcessing ? null : _payWithStripe,
        child: isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isConfirming
                        ? 'Bekræfter betaling...'
                        : 'Initierer betaling...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                'Betal ${widget.order.amount.toStringAsFixed(0)} DKK',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
