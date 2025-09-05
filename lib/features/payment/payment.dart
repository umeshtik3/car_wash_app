import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';
import 'package:car_wash_app/services/payment_service.dart';
import 'package:car_wash_app/services/payment_firebase_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;
  
  final PaymentService _paymentService = PaymentService();
  final PaymentFirebaseService _paymentFirebaseService = PaymentFirebaseService();

  @override
  void initState() {
    super.initState();
    _paymentService.initializeRazorpay();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _select(PaymentMethod method) {
    setState(() { _selectedMethod = method; });
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() { _isProcessing = true; });

    try {
      if (_selectedMethod == PaymentMethod.cash) {
        await _processCashPayment();
      } else {
        await _processOnlinePayment();
      }
    } catch (e) {
      _showErrorDialog('Payment failed: $e');
    } finally {
      setState(() { _isProcessing = false; });
    }
  }

  Future<void> _processCashPayment() async {
    // Mock booking data - in real app, this would come from navigation parameters
    const String bookingId = 'BOOKING_123';
    const double amount = 69.98;
    const String currency = 'INR';

    final paymentResult = _paymentService.processCashPayment(
      bookingId: bookingId,
      amount: amount,
      currency: currency,
    );

    // Save payment details to Firestore
    await _paymentFirebaseService.savePaymentDetails(
      bookingId: bookingId,
      paymentResult: paymentResult,
    );

    // Update booking payment status
    await _paymentFirebaseService.updateBookingPaymentStatus(
      bookingId: bookingId,
      paymentStatus: PaymentStatus.pending,
    );

    await _paymentFirebaseService.updateBookingPaymentMethod(
      bookingId: bookingId,
      paymentMethod: PaymentMethod.cash,
    );

    _showSuccessDialog('Cash payment confirmed! You will pay at service time.');
  }

  Future<void> _processOnlinePayment() async {
    // Check if online payments are supported
    if (!_paymentService.isOnlinePaymentSupported()) {
      _showErrorDialog('Online payments are not supported on web platform. Please use the mobile app or select cash payment.');
      return;
    }

    // Mock booking data - in real app, this would come from navigation parameters
    const String bookingId = 'BOOKING_123';
    const double amount = 69.98;
    const String currency = 'INR';

    final orderId = _paymentService.generateOrderId();
    
    final options = _paymentService.createOnlinePaymentOptions(
      orderId: orderId,
      amount: amount,
      currency: currency,
      description: 'Car Wash Service Payment',
      customerName: 'John Doe', // In real app, get from user profile
      customerEmail: 'john@example.com', // In real app, get from user profile
      customerPhone: '+919876543210', // In real app, get from user profile
    );

    // Set up payment callbacks
    _paymentService.setPaymentSuccessCallback((RazorpayPaymentSuccessResponse response) async {
      await _handlePaymentSuccess(response, bookingId, amount, currency, orderId);
    });

    _paymentService.setPaymentErrorCallback((RazorpayPaymentFailureResponse response) {
      _handlePaymentError(response);
    });

    _paymentService.openPaymentGateway(options);
  }

  Future<void> _handlePaymentSuccess(
    RazorpayPaymentSuccessResponse response,
    String bookingId,
    double amount,
    String currency,
    String orderId,
  ) async {
    try {
      final paymentResult = PaymentResult(
        success: true,
        paymentId: response.paymentId,
        amount: amount,
        currency: currency,
        paymentMethod: _selectedMethod!,
        status: PaymentStatus.completed,
        message: 'Payment successful',
        razorpayOrderId: orderId,
        razorpayPaymentId: response.paymentId,
        razorpaySignature: response.signature,
      );

      // Save payment details to Firestore
      await _paymentFirebaseService.savePaymentDetails(
        bookingId: bookingId,
        paymentResult: paymentResult,
      );

      // Update booking payment status
      await _paymentFirebaseService.updateBookingPaymentStatus(
        bookingId: bookingId,
        paymentStatus: PaymentStatus.completed,
      );

      await _paymentFirebaseService.updateBookingPaymentMethod(
        bookingId: bookingId,
        paymentMethod: _selectedMethod!,
      );

      _showSuccessDialog('Payment successful! Your booking is confirmed.');
    } catch (e) {
      _showErrorDialog('Failed to process payment: $e');
    }
  }

  void _handlePaymentError(RazorpayPaymentFailureResponse response) {
    _showErrorDialog('Payment failed: ${response.description}');
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/confirmation');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final List<_SummaryRow> services = const <_SummaryRow>[
      _SummaryRow(label: 'Basic Wash', value: '\$49.99'),
      _SummaryRow(label: 'Interior Clean', value: '\$19.99'),
    ];
    const String dateStr = '—';
    const String timeStr = '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final _SummaryRow row in services)
          Row(children: [Text(row.label), const Spacer(), Text(row.value)]),
        Row(children: const [Text('Date'), Spacer(), Text(dateStr)]),
        Row(children: const [Text('Time'), Spacer(), Text(timeStr)]),
        Row(children: const [
          Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
          Spacer(),
          Text('\$69.98', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text('Payment', style: context.text.titleLarge),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Booking summary', style: context.text.headlineSmall),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.border)),
                        ),
                        child: _buildSummary(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Choose payment method', style: context.text.bodySmall),
                      if (!_paymentService.isOnlinePaymentSupported()) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: AppRadii.small,
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange, size: 16),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Online payments are only available on mobile app. Use cash payment for web.',
                                  style: context.text.bodySmall?.copyWith(color: Colors.orange.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Column(children: [
                        _PayMethodTile(
                          label: _paymentService.getPaymentMethodDisplayName(PaymentMethod.upi),
                          subtitle: _paymentService.isOnlinePaymentSupported() 
                              ? _paymentService.getPaymentMethodDescription(PaymentMethod.upi)
                              : 'Not available on web - use mobile app',
                          selected: _selectedMethod == PaymentMethod.upi,
                          enabled: _paymentService.isOnlinePaymentSupported(),
                          onTap: _paymentService.isOnlinePaymentSupported() 
                              ? () => _select(PaymentMethod.upi) 
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PayMethodTile(
                          label: _paymentService.getPaymentMethodDisplayName(PaymentMethod.card),
                          subtitle: _paymentService.isOnlinePaymentSupported() 
                              ? _paymentService.getPaymentMethodDescription(PaymentMethod.card)
                              : 'Not available on web - use mobile app',
                          selected: _selectedMethod == PaymentMethod.card,
                          enabled: _paymentService.isOnlinePaymentSupported(),
                          onTap: _paymentService.isOnlinePaymentSupported() 
                              ? () => _select(PaymentMethod.card) 
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PayMethodTile(
                          label: _paymentService.getPaymentMethodDisplayName(PaymentMethod.wallet),
                          subtitle: _paymentService.isOnlinePaymentSupported() 
                              ? _paymentService.getPaymentMethodDescription(PaymentMethod.wallet)
                              : 'Not available on web - use mobile app',
                          selected: _selectedMethod == PaymentMethod.wallet,
                          enabled: _paymentService.isOnlinePaymentSupported(),
                          onTap: _paymentService.isOnlinePaymentSupported() 
                              ? () => _select(PaymentMethod.wallet) 
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PayMethodTile(
                          label: _paymentService.getPaymentMethodDisplayName(PaymentMethod.cash),
                          subtitle: _paymentService.getPaymentMethodDescription(PaymentMethod.cash),
                          selected: _selectedMethod == PaymentMethod.cash,
                          enabled: true,
                          onTap: () => _select(PaymentMethod.cash),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppButton(label: 'Back', primary: false, onPressed: () => Navigator.of(context).pop()),
                          AppButton(
                            label: _isProcessing ? 'Processing...' : 'Pay now',
                            primary: true,
                            onPressed: (_selectedMethod == null || _isProcessing) ? null : _processPayment,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PayMethodTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _PayMethodTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadii.medium,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: enabled 
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: AppRadii.medium,
          border: Border.all(
            color: selected 
                ? AppColors.primary 
                : enabled 
                    ? Theme.of(context).dividerColor
                    : Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
          boxShadow: selected ? <BoxShadow>[BoxShadow(color: AppColors.primary.withValues(alpha:0.06), spreadRadius: 2)] : AppShadows.small,
        ),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                label, 
                style: context.text.titleMedium?.copyWith(
                  color: enabled 
                      ? null 
                      : Theme.of(context).textTheme.titleMedium?.color?.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle, 
                style: context.text.bodySmall?.copyWith(
                  color: enabled 
                      ? null 
                      : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ),
            ])),
            if (selected) Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});
}


