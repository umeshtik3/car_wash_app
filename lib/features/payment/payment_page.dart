import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/services/booking_firebase_service.dart';
import 'package:car_wash_app/services/payment_firebase_service.dart';
import 'package:car_wash_app/services/service_firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentPage extends StatefulWidget {
  final String bookingId;
  const PaymentPage({super.key, required this.bookingId});
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  // Booking data
  Map<String, dynamic>? _bookingData;
  List<Map<String, dynamic>> _selectedServices = [];
  double _totalAmount = 0.0;
  final BookingFirebaseService _bookingFirebaseService =
      BookingFirebaseService();
  final ServiceFirebaseService _serviceFirebaseService =
      ServiceFirebaseService();
  final PaymentFirebaseService _paymentFirebaseService = PaymentFirebaseService();
  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadBookingData();
  }

  void _openCheckout() {
    var options = {
      'key': 'rzp_test_RGLuZjK3v0cTGI', // your key_id
      'amount': _totalAmount * 100, // in paise (₹500)
      'name': 'Car Wash App',
      'description': 'Test Payment',
      'prefill': {'contact': '9876543210', 'email': 'test@razorpay.com'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadBookingData() async {
    try {
      setState(() {
      });

      // Load booking details using the bookingId from widget
      _bookingData = await _bookingFirebaseService.getBookingDetails(
        widget.bookingId,
      );
      if (_bookingData == null) {
        throw Exception('Booking not found with ID: ${widget.bookingId}');
      }

      // Load selected services
      final selectedServiceIds = List<String>.from(
        _bookingData!['selectedServices'] ?? [],
      );
      _selectedServices = [];
      for (String serviceId in selectedServiceIds) {
        final serviceData = await _serviceFirebaseService.getServiceDetails(
          serviceId,
        );
        if (serviceData != null) {
          _selectedServices.add(serviceData);
        }
      }

      // Load car details
      final carId = _bookingData!['carId'] as String?;
      final userId = _bookingData!['userId'] as String?;
      if (carId != null && userId != null) {
      }

      // Calculate total amount
      _totalAmount = _bookingData!['totalPrice']?.toDouble() ?? 0.0;

      setState(() {
      });
    } catch (e) {
      setState(() {
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
  }

  void _handlePaymentError(PaymentFailureResponse response) {
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
    Future<void> _processCashPayment() async {
    if (_bookingData == null) {
      _showErrorDialog('Booking data not available');
      return;
    }

    final String bookingId = _bookingData!['id'];
    final double amount = _totalAmount;
    const String currency = 'INR';

    final paymentResult = PaymentBookingResult(
      success: true,
      paymentId: 'CASH_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      currency: currency,
      paymentMethod: PaymentMethod.cash,
      status: PaymentStatus.pending,
      message: 'Payment will be collected at service time',
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: [
            ElevatedButton.icon(
                                  onPressed: () => _processCashPayment(),
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text('Pay Later'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
            ElevatedButton(
              onPressed: _openCheckout,
              child: Text("Pay with Razorpay"),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentBookingResult {
  final bool success;
  final String paymentId;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final String message;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;

  PaymentBookingResult({
    required this.success,
    required this.paymentId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.message,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'paymentId': paymentId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'message': message,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  factory PaymentBookingResult.fromMap(Map<String, dynamic> map) {
    return PaymentBookingResult(
      success: map['success'] ?? false,
      paymentId: map['paymentId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'INR',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      message: map['message'] ?? '',
      razorpayOrderId: map['razorpayOrderId'],
      razorpayPaymentId: map['razorpayPaymentId'],
      razorpaySignature: map['razorpaySignature'],
    );
  }
}

/// Payment method enum
enum PaymentMethod { upi, card, wallet, cash }

/// Payment status enum
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}
