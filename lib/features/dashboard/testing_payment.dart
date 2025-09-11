import 'package:car_wash_app/services/booking_firebase_service.dart';
import 'package:car_wash_app/services/car_firebase_service.dart';
import 'package:car_wash_app/services/service_firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class TestingPaymentPage extends StatefulWidget {
   final String bookingId;
  TestingPaymentPage({super.key, required this.bookingId});
  @override
  _TestingPaymentPageState createState() => _TestingPaymentPageState();
}

class _TestingPaymentPageState extends State<TestingPaymentPage> {
  late Razorpay _razorpay;
  // Booking data
  Map<String, dynamic>? _bookingData;
  List<Map<String, dynamic>> _selectedServices = [];
  Map<String, dynamic>? _carData;
  double _totalAmount = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
   final BookingFirebaseService _bookingFirebaseService =
      BookingFirebaseService();
  final ServiceFirebaseService _serviceFirebaseService =
      ServiceFirebaseService();
  final CarFirebaseService _carFirebaseService = CarFirebaseService();
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
      'amount': 50000, // in paise (₹500)
      'name': 'Car Wash App',
      'description': 'Test Payment',
      'prefill': {
        'contact': '9876543210',
        'email': 'test@razorpay.com',
      }
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
        _isLoading = true;
        _errorMessage = null;
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
        final carData = await _carFirebaseService.getCarDetails(userId, carId);
        _carData = carData;
      }

      // Calculate total amount
      _totalAmount = _bookingData!['totalPrice']?.toDouble() ?? 0.0;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load booking data: $e';
      });
    }
  }


  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("SUCCESS: ${response.paymentId}");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("ERROR: ${response.code} - ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("EXTERNAL WALLET: ${response.walletName}");
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _openCheckout,
          child: Text("Pay with Razorpay"),
        ),
      ),
    );
  }
}
