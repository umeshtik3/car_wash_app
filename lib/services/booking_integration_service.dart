import 'package:car_wash_app/services/booking_firebase_service.dart';
import 'package:car_wash_app/services/service_firebase_service.dart';
import 'package:car_wash_app/services/car_firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingIntegrationService {
  final BookingFirebaseService _bookingService = BookingFirebaseService();
  final ServiceFirebaseService _serviceService = ServiceFirebaseService();
  final CarFirebaseService _carService = CarFirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Create a complete booking with service details and car information
  /// This method integrates all the services to create a comprehensive booking
  Future<Map<String, dynamic>> createCompleteBooking({
    required String carId,
    required List<String> selectedServiceIds,
    required String bookingDate,
    required String timeSlot,
    String? specialInstructions,
    String? paymentMethod,
    String? location,
  }) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    try {
      // 1. Validate that all selected services exist and are active
      final services = await _serviceService.getAllActiveServices();
      final validServiceIds = services.map((s) => s['id'] as String).toSet();
      
      for (String serviceId in selectedServiceIds) {
        if (!validServiceIds.contains(serviceId)) {
          throw Exception('Service $serviceId is not available');
        }
      }

      // 2. Get service details to calculate total price
      final selectedServices = services.where((s) => selectedServiceIds.contains(s['id'])).toList();
      final totalPrice = selectedServices.fold<double>(0.0, (sum, service) => sum + (service['price'] as double));

      // 3. Validate that the car belongs to the current user
      final carDetails = await _carService.getCurrentUserCarDetails(carId);
      if (carDetails == null) {
        throw Exception('Car not found or does not belong to current user');
      }

      // 4. Check if time slot is available
      final isAvailable = await _bookingService.isTimeSlotAvailable(bookingDate, timeSlot);
      if (!isAvailable) {
        throw Exception('Time slot $timeSlot on $bookingDate is not available');
      }

      // 5. Create the booking
      final bookingId = await _bookingService.createCurrentUserBooking(
        carId: carId,
        selectedServices: selectedServiceIds,
        totalPrice: totalPrice,
        bookingDate: bookingDate,
        timeSlot: timeSlot,
        specialInstructions: specialInstructions,
        paymentMethod: paymentMethod,
        location: location,
      );

      // 6. Return comprehensive booking details
      return {
        'bookingId': bookingId,
        'carDetails': carDetails,
        'selectedServices': selectedServices,
        'totalPrice': totalPrice,
        'bookingDate': bookingDate,
        'timeSlot': timeSlot,
        'status': 'pending',
        'paymentStatus': 'pending',
      };
    } catch (e) {
      throw Exception('Failed to create complete booking: $e');
    }
  }

  /// Get booking details with full service and car information
  Future<Map<String, dynamic>?> getCompleteBookingDetails(String bookingId) async {
    try {
      // 1. Get basic booking details
      final booking = await _bookingService.getBookingDetails(bookingId);
      if (booking == null) return null;

      // 2. Get car details
      final carDetails = await _carService.getCarDetails(booking['userId'], booking['carId']);

      // 3. Get service details for all selected services
      final selectedServiceIds = List<String>.from(booking['selectedServices'] ?? []);
      final services = await _serviceService.getAllActiveServices();
      final selectedServices = services.where((s) => selectedServiceIds.contains(s['id'])).toList();

      // 4. Combine all information
      return {
        ...booking,
        'carDetails': carDetails,
        'selectedServices': selectedServices,
      };
    } catch (e) {
      throw Exception('Failed to get complete booking details: $e');
    }
  }

  /// Get all bookings for current user with complete details
  Future<List<Map<String, dynamic>>> getCurrentUserCompleteBookings() async {
    try {
      final bookings = await _bookingService.getCurrentUserBookings();
      final completeBookings = <Map<String, dynamic>>[];

      for (final booking in bookings) {
        final completeBooking = await getCompleteBookingDetails(booking['id']);
        if (completeBooking != null) {
          completeBookings.add(completeBooking);
        }
      }

      return completeBookings;
    } catch (e) {
      throw Exception('Failed to get current user complete bookings: $e');
    }
  }

  /// Get upcoming bookings for current user with complete details
  Future<List<Map<String, dynamic>>> getCurrentUserUpcomingCompleteBookings() async {
    try {
      final bookings = await _bookingService.getCurrentUserUpcomingBookings();
      final completeBookings = <Map<String, dynamic>>[];

      for (final booking in bookings) {
        final completeBooking = await getCompleteBookingDetails(booking['id']);
        if (completeBooking != null) {
          completeBookings.add(completeBooking);
        }
      }

      return completeBookings;
    } catch (e) {
      throw Exception('Failed to get current user upcoming complete bookings: $e');
    }
  }

  /// Calculate total price for selected services
  Future<double> calculateTotalPrice(List<String> selectedServiceIds) async {
    try {
      final services = await _serviceService.getAllActiveServices();
      final selectedServices = services.where((s) => selectedServiceIds.contains(s['id'])).toList();
      
      return selectedServices.fold<double>(0.0, (sum, service) => sum + (service['price'] as double));
    } catch (e) {
      throw Exception('Failed to calculate total price: $e');
    }
  }

  /// Get available time slots for a specific date
  Future<List<String>> getAvailableTimeSlots(String date) async {
    try {
      // Define available time slots (you can customize this)
      final allTimeSlots = [
        '08:00-09:00', '09:00-10:00', '10:00-11:00', '11:00-12:00',
        '12:00-13:00', '13:00-14:00', '14:00-15:00', '15:00-16:00',
        '16:00-17:00', '17:00-18:00'
      ];

      final availableSlots = <String>[];
      
      for (final slot in allTimeSlots) {
        final isAvailable = await _bookingService.isTimeSlotAvailable(date, slot);
        if (isAvailable) {
          availableSlots.add(slot);
        }
      }

      return availableSlots;
    } catch (e) {
      throw Exception('Failed to get available time slots: $e');
    }
  }

  /// Validate booking data before creation
  Future<Map<String, dynamic>> validateBookingData({
    required String carId,
    required List<String> selectedServiceIds,
    required String bookingDate,
    required String timeSlot,
  }) async {
    final validation = <String, dynamic>{
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };

    try {
      // Check if user is authenticated
      if (currentUser == null) {
        validation['isValid'] = false;
        validation['errors'].add('User not authenticated');
        return validation;
      }

      // Validate car ownership
      final carDetails = await _carService.getCurrentUserCarDetails(carId);
      if (carDetails == null) {
        validation['isValid'] = false;
        validation['errors'].add('Car not found or does not belong to current user');
      }

      // Validate services
      if (selectedServiceIds.isEmpty) {
        validation['isValid'] = false;
        validation['errors'].add('At least one service must be selected');
      } else {
        final services = await _serviceService.getAllActiveServices();
        final validServiceIds = services.map((s) => s['id'] as String).toSet();
        
        for (String serviceId in selectedServiceIds) {
          if (!validServiceIds.contains(serviceId)) {
            validation['isValid'] = false;
            validation['errors'].add('Service $serviceId is not available');
          }
        }
      }

      // Validate date (basic check)
      final now = DateTime.now();
      final bookingDateTime = DateTime.tryParse(bookingDate);
      if (bookingDateTime == null) {
        validation['isValid'] = false;
        validation['errors'].add('Invalid booking date format');
      } else if (bookingDateTime.isBefore(now.subtract(const Duration(days: 1)))) {
        validation['isValid'] = false;
        validation['errors'].add('Cannot book for past dates');
      }

      // Check time slot availability
      if (validation['isValid']) {
        final isAvailable = await _bookingService.isTimeSlotAvailable(bookingDate, timeSlot);
        if (!isAvailable) {
          validation['isValid'] = false;
          validation['errors'].add('Time slot $timeSlot on $bookingDate is not available');
        }
      }

      return validation;
    } catch (e) {
      validation['isValid'] = false;
      validation['errors'].add('Validation error: $e');
      return validation;
    }
  }

  /// Cancel booking with proper cleanup
  Future<void> cancelBookingWithCleanup(String bookingId) async {
    try {
      // Get booking details first
      final booking = await _bookingService.getBookingDetails(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      // Check if booking belongs to current user
      if (booking['userId'] != currentUser?.uid) {
        throw Exception('Booking does not belong to current user');
      }

      // Check if booking can be cancelled
      final status = booking['status'] as String;
      if (status == 'completed' || status == 'cancelled') {
        throw Exception('Booking cannot be cancelled in current status: $status');
      }

      // Cancel the booking
      await _bookingService.cancelBooking(bookingId);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }
}
