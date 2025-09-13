import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/services/booking_firebase_service.dart';
import 'package:car_wash_app/services/service_firebase_service.dart';
import 'package:car_wash_app/services/car_firebase_service.dart';
import 'package:car_wash_app/features/slot_selection/slot_selection.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _pendingBookings = [];
  final BookingFirebaseService _bookingService = BookingFirebaseService();
  final ServiceFirebaseService _serviceService = ServiceFirebaseService();
  final CarFirebaseService _carService = CarFirebaseService();

  @override
  void initState() {
    super.initState();
    _loadPendingBookings();
  }

  Future<void> _loadPendingBookings() async {
    setState(() {
      _loading = true;
    });

    try {
      // Get all user bookings
      final allBookings = await _bookingService.getCurrentUserBookings();

      // Filter for pending bookings with payment status pending
      final pendingBookings = allBookings
          .where(
            (booking) =>
                booking['status'] == 'pending' &&
                booking['paymentStatus'] == 'pending',
          )
          .toList();

      // Enrich booking data with service and car details
      final enrichedBookings = <Map<String, dynamic>>[];

      for (final booking in pendingBookings) {
        try {
          // Get service details
          final serviceDetails = <Map<String, dynamic>>[];
          final selectedServices =
              booking['selectedServices'] as List<dynamic>? ?? [];

          for (final serviceId in selectedServices) {
            final service = await _serviceService.getServiceDetails(
              serviceId.toString(),
            );
            if (service != null) {
              serviceDetails.add(service);
            }
          }

          // Get car details
          final carDetails = await _carService.getCurrentUserCarDetails(
            booking['carId'],
          );

          enrichedBookings.add({
            ...booking,
            'serviceDetails': serviceDetails,
            'carDetails': carDetails,
          });
        } catch (e) {
          // If we can't get details for a booking, still include it
          enrichedBookings.add({
            ...booking,
            'serviceDetails': <Map<String, dynamic>>[],
            'carDetails': null,
          });
        }
      }

      if (mounted) {
        setState(() {
          _loading = false;
          _pendingBookings = enrichedBookings;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _pendingBookings = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _proceedToPayment(String bookingId) async {
    Navigator.of(
      context,
    ).pushNamed('/payment', arguments: {'bookingId': bookingId});
  }

  Future<void> _modifyBooking(String bookingId) async {
    // Navigate to slot selection with existing booking data
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SlotSelectionPage(editingBookingId: bookingId),
      ),
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bookingService.cancelBooking(bookingId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadPendingBookings(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking'),
        content: const Text(
          'Are you sure you want to permanently delete this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bookingService.deleteBooking(bookingId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadPendingBookings(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete booking: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTimeSlot(String timeSlot) {
    try {
      final parts = timeSlot.split('-');
      if (parts.length == 2) {
        return '${parts[0]} - ${parts[1]}';
      }
      return timeSlot;
    } catch (e) {
      return timeSlot;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingBookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No Pending Bookings',
                    style: context.text.titleLarge?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'You don\'t have any pending bookings at the moment.',
                    style: context.text.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushReplacementNamed('/dashboard'),
                    child: const Text('Book New Service'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPendingBookings,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _pendingBookings.length,
                itemBuilder: (context, index) {
                  final booking = _pendingBookings[index];
                  final serviceDetails =
                      booking['serviceDetails'] as List<Map<String, dynamic>>;
                  final carDetails =
                      booking['carDetails'] as Map<String, dynamic>?;

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Booking ID and Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Booking #${booking['id'].toString().substring(0, 8)}',
                                style: context.text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  // ignore: deprecated_member_use
                                  color: AppColors.warning.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.warning),
                                ),
                                child: Text(
                                  'Payment Pending',
                                  style: context.text.bodySmall?.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
 Text(
                               'Payment by: ${ booking['paymentMethod'] == 'cash'
                                    ? 'Cash'
                                    : 'Online'}',
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          const SizedBox(height: AppSpacing.sm),

                          // Service Details
                          if (serviceDetails.isNotEmpty) ...[
                            Text(
                              'Services:',
                              style: context.text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            ...serviceDetails.map(
                              (service) => Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.sm,
                                  bottom: 2,
                                ),
                                child: Text(
                                  '• ${service['name']} - ₹${service['price']}',
                                  style: context.text.bodySmall,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],

                          // Car Details
                          if (carDetails != null) ...[
                            Text(
                              'Car: ${carDetails['brand']} ${carDetails['model']} (${carDetails['registrationNumber']})',
                              style: context.text.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],

                          // Date and Time
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                _formatDate(booking['bookingDate']),
                                style: context.text.bodyMedium,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                _formatTimeSlot(booking['timeSlot']),
                                style: context.text.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Total Amount
                          Text(
                            'Total: ₹${booking['totalPrice']}',
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _modifyBooking(booking['id']),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Modify'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _proceedToPayment(booking['id']),
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text('Pay Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () =>
                                      _cancelBooking(booking['id']),
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Cancel'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.warning,
                                  ),
                                ),
                              ),

                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () =>
                                      _deleteBooking(booking['id']),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                  ),
                                  label: const Text('Delete'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
