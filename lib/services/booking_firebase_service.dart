import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Create a new booking in Firestore
  /// Creates document in standalone bookings collection and adds bookingId to user's temp_booking
  Future<String> createBooking({
    required String userId,
    required String carId,
    required List<String> selectedServices,
    required double totalPrice,
    required String bookingDate, // YYYY-MM-DD format
    required String timeSlot, // HH:MM-HH:MM format
    String? specialInstructions,
    String? paymentMethod,
    String? location,
  }) async {
    try {
      final bookingRef = _firestore.collection('bookings').doc();
      final bookingId = bookingRef.id;

      final bookingData = {
        'id': bookingId,
        'userId': userId,
        'carId': carId,
        'selectedServices': selectedServices,
        'totalPrice': totalPrice,
        'bookingDate': bookingDate,
        'timeSlot': timeSlot,
        'status': 'pending',
        'paymentStatus': 'pending',
        'specialInstructions': specialInstructions ?? '',
        'paymentMethod': paymentMethod ?? '',
        'location': location ?? '',
        'assignedStaff': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create booking in standalone collection
      await bookingRef.set(bookingData);

      // Add bookingId to user's temp_booking collection
      await _addBookingIdToUserTempBooking(userId, bookingId);

      return bookingId;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Create booking for current user
  Future<String> createCurrentUserBooking({
    required String carId,
    required List<String> selectedServices,
    required double totalPrice,
    required String bookingDate,
    required String timeSlot,
    String? specialInstructions,
    String? paymentMethod,
    String? location,
  }) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await createBooking(
      userId: currentUser!.uid,
      carId: carId,
      selectedServices: selectedServices,
      totalPrice: totalPrice,
      bookingDate: bookingDate,
      timeSlot: timeSlot,
      specialInstructions: specialInstructions,
      paymentMethod: paymentMethod,
      location: location,
    );
  }

  /// Update booking details in Firestore
  Future<void> updateBooking({
    required String bookingId,
    String? carId,
    List<String>? selectedServices,
    double? totalPrice,
    String? bookingDate,
    String? timeSlot,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    String? specialInstructions,
    String? assignedStaff,
    String? location,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update fields that are provided
      if (carId != null && carId.isNotEmpty) updateData['carId'] = carId;
      if (selectedServices != null) updateData['selectedServices'] = selectedServices;
      if (totalPrice != null) updateData['totalPrice'] = totalPrice;
      if (bookingDate != null && bookingDate.isNotEmpty) updateData['bookingDate'] = bookingDate;
      if (timeSlot != null && timeSlot.isNotEmpty) updateData['timeSlot'] = timeSlot;
      if (status != null && status.isNotEmpty) updateData['status'] = status;
      if (paymentStatus != null && paymentStatus.isNotEmpty) updateData['paymentStatus'] = paymentStatus;
      if (paymentMethod != null) updateData['paymentMethod'] = paymentMethod;
      if (specialInstructions != null) updateData['specialInstructions'] = specialInstructions;
      if (assignedStaff != null) updateData['assignedStaff'] = assignedStaff;
      if (location != null) updateData['location'] = location;

      if (updateData.length > 1) { // More than just updatedAt
        await _firestore.collection('bookings').doc(bookingId).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update booking: $e');
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add completion timestamp if status is completed
      if (status == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus(String bookingId, String paymentStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// Get all bookings for a user
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('bookingDate', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get user bookings: $e');
    }
  }

  /// Get all bookings for current user
  Future<List<Map<String, dynamic>>> getCurrentUserBookings() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getUserBookings(currentUser!.uid);
  }

  /// Get bookings by status
  Future<List<Map<String, dynamic>>> getBookingsByStatus(String status) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: status)
          .orderBy('bookingDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get bookings by status: $e');
    }
  }

  /// Get bookings by date
  Future<List<Map<String, dynamic>>> getBookingsByDate(String date) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bookings')
          .where('bookingDate', isEqualTo: date)
          .orderBy('timeSlot')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get bookings by date: $e');
    }
  }

  /// Get specific booking details
  Future<Map<String, dynamic>?> getBookingDetails(String bookingId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get booking details: $e');
    }
  }

  /// Stream all bookings for a user (real-time updates)
  Stream<QuerySnapshot> getUserBookingsStream(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('bookingDate', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream all bookings for current user (real-time updates)
  Stream<QuerySnapshot> getCurrentUserBookingsStream() {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return getUserBookingsStream(currentUser!.uid);
  }

  /// Stream bookings by status (real-time updates)
  Stream<QuerySnapshot> getBookingsByStatusStream(String status) {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: status)
        .orderBy('bookingDate', descending: true)
        .snapshots();
  }

  /// Stream bookings by date (real-time updates)
  Stream<QuerySnapshot> getBookingsByDateStream(String date) {
    return _firestore
        .collection('bookings')
        .where('bookingDate', isEqualTo: date)
        .orderBy('timeSlot')
        .snapshots();
  }

  /// Stream specific booking details (real-time updates)
  Stream<DocumentSnapshot> getBookingDetailsStream(String bookingId) {
    return _firestore.collection('bookings').doc(bookingId).snapshots();
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      // Get booking details to find userId
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }
      
      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final userId = bookingData['userId'] as String;

      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove bookingId from user's temp_booking collection
      await _removeBookingIdFromUserTempBooking(userId, bookingId);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Delete booking (permanent deletion)
  Future<void> deleteBooking(String bookingId) async {
    try {
      // Get booking details to find userId
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }
      
      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final userId = bookingData['userId'] as String;

      // Delete booking from standalone collection
      await _firestore.collection('bookings').doc(bookingId).delete();

      // Remove bookingId from user's temp_booking collection
      await _removeBookingIdFromUserTempBooking(userId, bookingId);
    } catch (e) {
      throw Exception('Failed to delete booking: $e');
    }
  }

  /// Get booking count for user
  Future<int> getUserBookingCount(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get user booking count: $e');
    }
  }

  /// Get booking count for current user
  Future<int> getCurrentUserBookingCount() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getUserBookingCount(currentUser!.uid);
  }

  /// Check if booking exists
  Future<bool> bookingExists(String bookingId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('bookings').doc(bookingId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check booking existence: $e');
    }
  }

  /// Get bookings by car
  Future<List<Map<String, dynamic>>> getBookingsByCar(String carId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bookings')
          .where('carId', isEqualTo: carId)
          .orderBy('bookingDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get bookings by car: $e');
    }
  }

  /// Get upcoming bookings for user
  Future<List<Map<String, dynamic>>> getUpcomingUserBookings(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      QuerySnapshot querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('bookingDate', isGreaterThanOrEqualTo: today)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('bookingDate')
          .orderBy('timeSlot')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get upcoming user bookings: $e');
    }
  }

  /// Get upcoming bookings for current user
  Future<List<Map<String, dynamic>>> getCurrentUserUpcomingBookings() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getUpcomingUserBookings(currentUser!.uid);
  }

  /// Check time slot availability
  Future<bool> isTimeSlotAvailable(String date, String timeSlot) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bookings')
          .where('bookingDate', isEqualTo: date)
          .where('timeSlot', isEqualTo: timeSlot)
          .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check time slot availability: $e');
    }
  }

  /// Save selected services to temporary booking in Firestore
  /// Creates/updates document in users/{uid}/tempBooking/selectedServices
  Future<void> saveSelectedServices({
    required String userId,
    required List<String> selectedServiceIds,
  }) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('selectedServices');

      final selectedServicesData = {
        'selectedServiceIds': selectedServiceIds,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await tempBookingRef.set(selectedServicesData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save selected services: $e');
    }
  }

  /// Save selected services for current user
  Future<void> saveCurrentUserSelectedServices({
    required List<String> selectedServiceIds,
  }) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await saveSelectedServices(
      userId: currentUser!.uid,
      selectedServiceIds: selectedServiceIds,
    );
  }

  /// Update selected services in temporary booking
  /// Updates document in users/{uid}/tempBooking/selectedServices
  Future<void> updateSelectedServices({
    required String userId,
    required List<String> selectedServiceIds,
  }) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('selectedServices');

      final updateData = {
        'selectedServiceIds': selectedServiceIds,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await tempBookingRef.update(updateData);
    } catch (e) {
      throw Exception('Failed to update selected services: $e');
    }
  }

  /// Update selected services for current user
  Future<void> updateCurrentUserSelectedServices({
    required List<String> selectedServiceIds,
  }) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await updateSelectedServices(
      userId: currentUser!.uid,
      selectedServiceIds: selectedServiceIds,
    );
  }

  /// Get selected services from temporary booking
  /// Retrieves document from users/{uid}/tempBooking/selectedServices
  Future<List<String>?> getSelectedServices(String userId) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('selectedServices');

      final doc = await tempBookingRef.get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final selectedServiceIds = data['selectedServiceIds'] as List<dynamic>?;
        return selectedServiceIds?.cast<String>();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get selected services: $e');
    }
  }

  /// Get selected services for current user
  Future<List<String>?> getCurrentUserSelectedServices() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getSelectedServices(currentUser!.uid);
  }

  /// Clear selected services from temporary booking
  /// Deletes document from users/{uid}/tempBooking/selectedServices
  Future<void> clearSelectedServices(String userId) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('selectedServices');

      await tempBookingRef.delete();
    } catch (e) {
      throw Exception('Failed to clear selected services: $e');
    }
  }

  /// Clear selected services for current user
  Future<void> clearCurrentUserSelectedServices() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await clearSelectedServices(currentUser!.uid);
  }

  /// Stream selected services from temporary booking (real-time updates)
  /// Returns stream of document from users/{uid}/tempBooking/selectedServices
  Stream<DocumentSnapshot> getSelectedServicesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tempBooking')
        .doc('selectedServices')
        .snapshots();
  }

  /// Stream selected services for current user (real-time updates)
  Stream<DocumentSnapshot> getCurrentUserSelectedServicesStream() {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return getSelectedServicesStream(currentUser!.uid);
  }

  /// Save booking schedule to temporary booking in Firestore
  /// Creates/updates document in users/{uid}/tempBooking/bookingSchedule
  Future<void> saveBookingSchedule({
    required String userId,
    required String bookingDate,
    required String timeSlot,
  }) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('bookingSchedule');

      final bookingScheduleData = {
        'bookingDate': bookingDate,
        'timeSlot': timeSlot,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await tempBookingRef.set(bookingScheduleData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save booking schedule: $e');
    }
  }

  /// Save booking schedule for current user
  Future<void> saveCurrentUserBookingSchedule({
    required String bookingDate,
    required String timeSlot,
  }) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await saveBookingSchedule(
      userId: currentUser!.uid,
      bookingDate: bookingDate,
      timeSlot: timeSlot,
    );
  }

  /// Update booking schedule in temporary booking
  /// Updates document in users/{uid}/tempBooking/bookingSchedule
  Future<void> updateBookingSchedule({
    required String userId,
    required String bookingDate,
    required String timeSlot,
  }) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('bookingSchedule');

      final updateData = {
        'bookingDate': bookingDate,
        'timeSlot': timeSlot,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await tempBookingRef.update(updateData);
    } catch (e) {
      throw Exception('Failed to update booking schedule: $e');
    }
  }

  /// Update booking schedule for current user
  Future<void> updateCurrentUserBookingSchedule({
    required String bookingDate,
    required String timeSlot,
  }) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await updateBookingSchedule(
      userId: currentUser!.uid,
      bookingDate: bookingDate,
      timeSlot: timeSlot,
    );
  }

  /// Get booking schedule from temporary booking
  /// Retrieves document from users/{uid}/tempBooking/bookingSchedule
  Future<Map<String, dynamic>?> getBookingSchedule(String userId) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('bookingSchedule');

      final doc = await tempBookingRef.get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get booking schedule: $e');
    }
  }

  /// Get booking schedule for current user
  Future<Map<String, dynamic>?> getCurrentUserBookingSchedule() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getBookingSchedule(currentUser!.uid);
  }

  /// Clear booking schedule from temporary booking
  /// Deletes document from users/{uid}/tempBooking/bookingSchedule
  Future<void> clearBookingSchedule(String userId) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('bookingSchedule');

      await tempBookingRef.delete();
    } catch (e) {
      throw Exception('Failed to clear booking schedule: $e');
    }
  }

  /// Clear booking schedule for current user
  Future<void> clearCurrentUserBookingSchedule() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await clearBookingSchedule(currentUser!.uid);
  }

  /// Stream booking schedule from temporary booking (real-time updates)
  /// Returns stream of document from users/{uid}/tempBooking/bookingSchedule
  Stream<DocumentSnapshot> getBookingScheduleStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tempBooking')
        .doc('bookingSchedule')
        .snapshots();
  }

  /// Stream booking schedule for current user (real-time updates)
  Stream<DocumentSnapshot> getCurrentUserBookingScheduleStream() {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return getBookingScheduleStream(currentUser!.uid);
  }

  /// Add bookingId to user's temp_booking collection
  /// Updates users/{userId}/tempBooking/bookingIds array
  Future<void> _addBookingIdToUserTempBooking(String userId, String bookingId) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('bookingIds');

      await tempBookingRef.set({
        'bookingIds': FieldValue.arrayUnion([bookingId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add bookingId to user temp_booking: $e');
    }
  }

  /// Remove bookingId from user's temp_booking collection
  /// Updates users/{userId}/tempBooking/bookingIds array
  Future<void> _removeBookingIdFromUserTempBooking(String userId, String bookingId) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('bookingIds');

      await tempBookingRef.update({
        'bookingIds': FieldValue.arrayRemove([bookingId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove bookingId from user temp_booking: $e');
    }
  }

  /// Get bookingIds from user's temp_booking collection
  /// Retrieves users/{userId}/tempBooking/bookingIds document
  Future<List<String>?> getUserTempBookingIds(String userId) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('bookingIds');

      final doc = await tempBookingRef.get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final bookingIds = data['bookingIds'] as List<dynamic>?;
        return bookingIds?.cast<String>();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user temp booking IDs: $e');
    }
  }

  /// Get bookingIds for current user
  Future<List<String>?> getCurrentUserTempBookingIds() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getUserTempBookingIds(currentUser!.uid);
  }

  /// Clear all bookingIds from user's temp_booking collection
  /// Deletes users/{userId}/tempBooking/bookingIds document
  Future<void> clearUserTempBookingIds(String userId) async {
    try {
      final tempBookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tempBooking')
          .doc('bookingIds');

      await tempBookingRef.delete();
    } catch (e) {
      throw Exception('Failed to clear user temp booking IDs: $e');
    }
  }

  /// Clear all bookingIds for current user
  Future<void> clearCurrentUserTempBookingIds() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await clearUserTempBookingIds(currentUser!.uid);
  }

  /// Stream bookingIds from user's temp_booking collection (real-time updates)
  /// Returns stream of users/{userId}/tempBooking/bookingIds document
  Stream<DocumentSnapshot> getUserTempBookingIdsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tempBooking')
        .doc('bookingIds')
        .snapshots();
  }

  /// Stream bookingIds for current user (real-time updates)
  Stream<DocumentSnapshot> getCurrentUserTempBookingIdsStream() {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return getUserTempBookingIdsStream(currentUser!.uid);
  }

  /// Get pending bookings with payment status pending for a user
  Future<List<Map<String, dynamic>>> getUserPendingBookings(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .where('paymentStatus', isEqualTo: 'pending')
          .orderBy('bookingDate', descending: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get user pending bookings: $e');
    }
  }

  /// Get pending bookings with payment status pending for current user
  Future<List<Map<String, dynamic>>> getCurrentUserPendingBookings() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getUserPendingBookings(currentUser!.uid);
  }

  /// Check if user has any pending bookings
  Future<bool> hasUserPendingBookings(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .where('paymentStatus', isEqualTo: 'pending')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check user pending bookings: $e');
    }
  }

  /// Check if current user has any pending bookings
  Future<bool> hasCurrentUserPendingBookings() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await hasUserPendingBookings(currentUser!.uid);
  }
}
