import 'package:car_wash_app/features/payment/payment_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase service for payment-related Firestore operations
/// Handles all database operations for payments, separate from core payment logic
class PaymentFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Save payment details to Firestore
  /// Creates document in separate payments collection and updates booking with paymentID
  Future<void> savePaymentDetails({
    required String bookingId,
    required PaymentBookingResult paymentResult,
  }) async {
    try {
      // Save payment in separate payments collection
      final paymentRef = _firestore.collection('payments').doc(paymentResult.paymentId);

      final paymentData = {
        ...paymentResult.toMap(),
        'bookingId': bookingId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await paymentRef.set(paymentData);

      // Update booking document with paymentID reference
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentId': paymentResult.paymentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save payment details: $e');
    }
  }

  /// Update payment status in Firestore
  /// Updates payment document in separate payments collection
  Future<void> updatePaymentStatus({
    required String bookingId,
    required String paymentId,
    required PaymentStatus status,
    String? message,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (message != null && message.isNotEmpty) {
        updateData['message'] = message;
      }

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// Get payment details from Firestore
  /// Retrieves payment document from separate payments collection
  Future<PaymentBookingResult?> getPaymentDetails({
    required String bookingId,
    required String paymentId,
  }) async {
    try {
      final doc = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return PaymentBookingResult.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get payment details: $e');
    }
  }

  /// Get all payments for a booking
  /// Returns list of payment documents from separate payments collection filtered by bookingId
  Future<List<PaymentBookingResult>> getBookingPayments(String bookingId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PaymentBookingResult.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get booking payments: $e');
    }
  }

  /// Stream all payments for a booking (real-time updates)
  /// Returns stream of payment documents from separate payments collection filtered by bookingId
  Stream<QuerySnapshot> getBookingPaymentsStream(String bookingId) {
    return _firestore
        .collection('payments')
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream specific payment details (real-time updates)
  /// Returns stream of payment document from separate payments collection
  Stream<DocumentSnapshot> getPaymentDetailsStream({
    required String bookingId,
    required String paymentId,
  }) {
    return _firestore
        .collection('payments')
        .doc(paymentId)
        .snapshots();
  }

  /// Update booking payment status
  /// Updates paymentStatus field in bookings/{bookingId} document
  Future<void> updateBookingPaymentStatus({
    required String bookingId,
    required PaymentStatus paymentStatus,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentStatus': paymentStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update booking payment status: $e');
    }
  }

  /// Update booking payment method
  /// Updates paymentMethod field in bookings/{bookingId} document
  Future<void> updateBookingPaymentMethod({
    required String bookingId,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentMethod': paymentMethod.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update booking payment method: $e');
    }
  }

  /// Get payments by status
  /// Returns list of payment documents with specific status
  Future<List<Map<String, dynamic>>> getPaymentsByStatus(PaymentStatus status) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collectionGroup('payment')
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get payments by status: $e');
    }
  }

  /// Get payments by method
  /// Returns list of payment documents with specific payment method
  Future<List<Map<String, dynamic>>> getPaymentsByMethod(PaymentMethod method) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collectionGroup('payment')
          .where('paymentMethod', isEqualTo: method.name)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get payments by method: $e');
    }
  }

  /// Get user payments
  /// Returns list of payment documents for a specific user from separate payments collection
  Future<List<Map<String, dynamic>>> getUserPayments(String userId) async {
    try {
      // First get all bookings for the user to get booking IDs
      QuerySnapshot bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      List<String> bookingIds = bookingsSnapshot.docs.map((doc) => doc.id).toList();

      if (bookingIds.isEmpty) {
        return [];
      }

      // Get all payments for these bookings
      QuerySnapshot paymentsSnapshot = await _firestore
          .collection('payments')
          .where('bookingId', whereIn: bookingIds)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> allPayments = [];
      for (QueryDocumentSnapshot paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data() as Map<String, dynamic>;
        allPayments.add(paymentData);
      }

      return allPayments;
    } catch (e) {
      throw Exception('Failed to get user payments: $e');
    }
  }

  /// Get user payments for current user
  Future<List<Map<String, dynamic>>> getCurrentUserPayments() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getUserPayments(currentUser!.uid);
  }

  /// Stream user payments (real-time updates)
  /// Returns stream of payment documents for a specific user from separate payments collection
  Stream<List<Map<String, dynamic>>> getUserPaymentsStream(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((bookingsSnapshot) async {
      List<String> bookingIds = bookingsSnapshot.docs.map((doc) => doc.id).toList();

      if (bookingIds.isEmpty) {
        return <Map<String, dynamic>>[];
      }

      // Get all payments for these bookings
      QuerySnapshot paymentsSnapshot = await _firestore
          .collection('payments')
          .where('bookingId', whereIn: bookingIds)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> allPayments = [];
      for (QueryDocumentSnapshot paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data() as Map<String, dynamic>;
        allPayments.add(paymentData);
      }

      return allPayments;
    });
  }

  /// Stream user payments for current user (real-time updates)
  Stream<List<Map<String, dynamic>>> getCurrentUserPaymentsStream() {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return getUserPaymentsStream(currentUser!.uid);
  }

  /// Delete payment details
  /// Removes payment document from separate payments collection and clears paymentId from booking
  Future<void> deletePaymentDetails({
    required String bookingId,
    required String paymentId,
  }) async {
    try {
      // Delete payment from payments collection
      await _firestore
          .collection('payments')
          .doc(paymentId)
          .delete();

      // Clear paymentId from booking document
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete payment details: $e');
    }
  }

  /// Check if payment exists
  /// Returns true if payment document exists in separate payments collection
  Future<bool> paymentExists({
    required String bookingId,
    required String paymentId,
  }) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check payment existence: $e');
    }
  }

  /// Get payment count for booking
  /// Returns number of payments for a specific booking from separate payments collection
  Future<int> getBookingPaymentCount(String bookingId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get booking payment count: $e');
    }
  }

  /// Get total payment amount for booking
  /// Returns sum of all successful payments for a booking from separate payments collection
  Future<double> getBookingTotalPaid(String bookingId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .where('status', isEqualTo: PaymentStatus.completed.name)
          .get();

      double total = 0.0;
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Failed to get booking total paid: $e');
    }
  }

  /// Get payment statistics for user
  /// Returns payment statistics for a specific user
  Future<Map<String, dynamic>> getUserPaymentStats(String userId) async {
    try {
      final payments = await getUserPayments(userId);
      
      int totalPayments = payments.length;
      int successfulPayments = payments.where((p) => p['status'] == PaymentStatus.completed.name).length;
      int failedPayments = payments.where((p) => p['status'] == PaymentStatus.failed.name).length;
      int pendingPayments = payments.where((p) => p['status'] == PaymentStatus.pending.name).length;
      
      double totalAmount = 0.0;
      double successfulAmount = 0.0;
      
      for (Map<String, dynamic> payment in payments) {
        double amount = (payment['amount'] ?? 0).toDouble();
        totalAmount += amount;
        
        if (payment['status'] == PaymentStatus.completed.name) {
          successfulAmount += amount;
        }
      }

      return {
        'totalPayments': totalPayments,
        'successfulPayments': successfulPayments,
        'failedPayments': failedPayments,
        'pendingPayments': pendingPayments,
        'totalAmount': totalAmount,
        'successfulAmount': successfulAmount,
        'successRate': totalPayments > 0 ? (successfulPayments / totalPayments) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get user payment stats: $e');
    }
  }

  /// Get payment statistics for current user
  Future<Map<String, dynamic>> getCurrentUserPaymentStats() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getUserPaymentStats(currentUser!.uid);
  }
}
