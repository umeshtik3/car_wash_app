import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';

/// Core payment service that handles payment processing logic
/// This service is decoupled from Firebase and can be used with any backend
class PaymentService {
  static const String _razorpayKeyId = 'rzp_test_1234567890'; // Replace with your actual key
  // Note: Secret key is used server-side for order creation, not in client app
  
  Razorpay? _razorpay;
  
  PaymentService() {
    // Only initialize Razorpay on mobile platforms
    if (!kIsWeb) {
      _razorpay = Razorpay();
    }
  }

  /// Initialize Razorpay with configuration
  void initializeRazorpay() {
    if (_razorpay != null) {
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  /// Clean up Razorpay listeners
  void dispose() {
    _razorpay?.clear();
  }

  /// Process online payment using Razorpay
  /// Returns payment options for Razorpay
  Map<String, dynamic> createOnlinePaymentOptions({
    required String orderId,
    required double amount,
    required String currency,
    required String description,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? prefillEmail,
    String? prefillContact,
  }) {
    final options = {
      'key': _razorpayKeyId,
      'amount': (amount * 100).toInt(), // Convert to paise
      'name': 'Car Wash App',
      'description': description,
      'order_id': orderId,
      'prefill': {
        'contact': customerPhone,
        'email': customerEmail,
        'name': customerName,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    return options;
  }

  /// Open Razorpay payment gateway
  void openPaymentGateway(Map<String, dynamic> options) {
    if (kIsWeb) {
      throw PaymentException('Razorpay is not supported on web platform. Please use mobile app for payments.');
    }
    
    if (_razorpay == null) {
      throw PaymentException('Razorpay is not initialized');
    }
    
    try {
      _razorpay!.open(options);
    } catch (e) {
      throw PaymentException('Failed to open payment gateway: $e');
    }
  }

  /// Set up payment success callback
  void setPaymentSuccessCallback(Function(RazorpayPaymentSuccessResponse) callback) {
    if (_razorpay != null) {
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, callback);
    }
  }

  /// Set up payment error callback
  void setPaymentErrorCallback(Function(RazorpayPaymentFailureResponse) callback) {
    if (_razorpay != null) {
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, callback);
    }
  }

  /// Set up external wallet callback
  void setExternalWalletCallback(Function(RazorpayExternalWalletResponse) callback) {
    if (_razorpay != null) {
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, callback);
    }
  }

  /// Process cash payment (COD)
  /// Returns payment result for cash payment
  PaymentResult processCashPayment({
    required String bookingId,
    required double amount,
    required String currency,
  }) {
    // Simulate cash payment processing
    return PaymentResult(
      success: true,
      paymentId: 'CASH_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      currency: currency,
      paymentMethod: PaymentMethod.cash,
      status: PaymentStatus.pending,
      message: 'Payment will be collected at service time',
    );
  }

  /// Validate payment amount
  bool validatePaymentAmount(double amount) {
    return amount > 0 && amount <= 100000; // Max 1 lakh
  }

  /// Generate unique order ID for Razorpay
  String generateOrderId() {
    return 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // This will be handled by the calling widget
    // The response contains payment details
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    // This will be handled by the calling widget
    // The response contains error details
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    // This will be handled by the calling widget
    // The response contains wallet details
  }

  /// Get supported payment methods
  List<PaymentMethod> getSupportedPaymentMethods() {
    return [
      PaymentMethod.upi,
      PaymentMethod.card,
      PaymentMethod.wallet,
      PaymentMethod.cash,
    ];
  }

  /// Check if payment method is online
  bool isOnlinePaymentMethod(PaymentMethod method) {
    return method != PaymentMethod.cash;
  }

  /// Check if online payments are supported on current platform
  bool isOnlinePaymentSupported() {
    return !kIsWeb;
  }

  /// Get payment method display name
  String getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.cash:
        return 'Cash on Delivery';
    }
  }

  /// Get payment method description
  String getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return 'Pay via UPI apps';
      case PaymentMethod.card:
        return 'Visa/Mastercard';
      case PaymentMethod.wallet:
        return 'Popular wallets';
      case PaymentMethod.cash:
        return 'Pay at service time';
    }
  }
}

/// Payment result model
class PaymentResult {
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

  PaymentResult({
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

  factory PaymentResult.fromMap(Map<String, dynamic> map) {
    return PaymentResult(
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
enum PaymentMethod {
  upi,
  card,
  wallet,
  cash,
}

/// Payment status enum
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

/// Payment exception class
class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => 'PaymentException: $message';
}

/// Payment success response from Razorpay
class RazorpayPaymentSuccessResponse {
  final String paymentId;
  final String orderId;
  final String signature;

  RazorpayPaymentSuccessResponse({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
}

/// Payment failure response from Razorpay
class RazorpayPaymentFailureResponse {
  final String code;
  final String description;
  final String source;
  final String step;
  final String reason;

  RazorpayPaymentFailureResponse({
    required this.code,
    required this.description,
    required this.source,
    required this.step,
    required this.reason,
  });
}

/// External wallet response from Razorpay
class RazorpayExternalWalletResponse {
  final String walletName;

  RazorpayExternalWalletResponse({
    required this.walletName,
  });
}
