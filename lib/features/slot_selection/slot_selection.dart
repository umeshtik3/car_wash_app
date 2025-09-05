import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';
import 'package:car_wash_app/services/booking_firebase_service.dart';
import 'package:car_wash_app/services/service_firebase_service.dart';
import 'package:car_wash_app/services/car_firebase_service.dart';

class SlotSelectionPage extends StatefulWidget {
  const SlotSelectionPage({super.key});

  @override
  State<SlotSelectionPage> createState() => _SlotSelectionPageState();
}

class _SlotSelectionPageState extends State<SlotSelectionPage> {
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _dateError;
  String? _timeError;
  bool _isLoading = false;
  bool _isCheckingAvailability = false;
  bool _isLoadingServices = false;
  bool _isLoadingCars = false;
  Map<String, bool> _slotAvailability = {};
  List<Map<String, dynamic>> _selectedServices = [];
  List<Map<String, dynamic>> _userCars = [];
  Map<String, dynamic>? _selectedCar;
  double _totalPrice = 0.0;

  final BookingFirebaseService _bookingService = BookingFirebaseService();
  final ServiceFirebaseService _serviceService = ServiceFirebaseService();
  final CarFirebaseService _carService = CarFirebaseService();
  
  final List<String> _slots = const <String>[
    '09:00','10:00','11:00','12:00','13:00','14:00','15:00','16:00','17:00','18:00'
  ];

  @override
  void initState() {
    super.initState();
    // Fetch selected services and user cars when page loads
    _fetchSelectedServices();
    _fetchUserCars();
  }

  String _formatDate(DateTime date) {
    return '${_pad(date.year, 4)}-${_pad(date.month)}-${_pad(date.day)}';
  }

  String _pad(int n, [int width = 2]) => n.toString().padLeft(width, '0');

  bool _isToday(DateTime date) {
    final DateTime now = DateTime.now();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  bool _isSlotDisabled(String time, DateTime forDate) {
    // Check if slot is in the past (for today)
    if (_isToday(forDate)) {
      final DateTime now = DateTime.now();
      final List<String> parts = time.split(':');
      final int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);
      final DateTime slotDateTime = DateTime(forDate.year, forDate.month, forDate.day, hour, minute);
      if (slotDateTime.isBefore(now) || slotDateTime.isAtSameMomentAs(now)) {
        return true;
      }
    }
    
    // Check if slot is unavailable (booked by someone else)
    final String dateStr = _formatDate(forDate);
    final String timeSlot = '$time-${_getEndTime(time)}';
    return _slotAvailability['$dateStr-$timeSlot'] == false;
  }
  
  String _getEndTime(String startTime) {
    final List<String> parts = startTime.split(':');
    final int hour = int.parse(parts[0]);
    final int nextHour = hour + 1;
    return '${_pad(nextHour)}:00';
  }

  /// Fetch selected services and their details from Firestore
  Future<void> _fetchSelectedServices() async {
    if (_bookingService.currentUser == null) return;
    
    setState(() {
      _isLoadingServices = true;
    });

    try {
      // Get selected service IDs from temporary booking
      final List<String>? selectedServiceIds = await _bookingService.getCurrentUserSelectedServices();
      
      if (selectedServiceIds == null || selectedServiceIds.isEmpty) {
        setState(() {
          _selectedServices = [];
          _totalPrice = 0.0;
          _isLoadingServices = false;
        });
        return;
      }

      // Fetch service details for each selected service
      final List<Map<String, dynamic>> services = [];
      double totalPrice = 0.0;

      for (String serviceId in selectedServiceIds) {
        final Map<String, dynamic>? serviceDetails = await _serviceService.getServiceDetails(serviceId);
        if (serviceDetails != null) {
          services.add(serviceDetails);
          totalPrice += (serviceDetails['price'] as num).toDouble();
        }
      }

      setState(() {
        _selectedServices = services;
        _totalPrice = totalPrice;
        _isLoadingServices = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingServices = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading services: $e')),
        );
      }
    }
  }

  /// Fetch user's cars from Firestore
  Future<void> _fetchUserCars() async {
    if (_bookingService.currentUser == null) return;
    
    setState(() {
      _isLoadingCars = true;
    });

    try {
      final cars = await _carService.getCurrentUserCars();
      setState(() {
        _userCars = cars;
        _isLoadingCars = false;
        // Auto-select first car if available
        if (cars.isNotEmpty) {
          _selectedCar = cars.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCars = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cars: $e')),
        );
      }
    }
  }

  void _validateState() {
    final bool validDate = _selectedDate != null && !_selectedDate!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    final bool validTime = _selectedTime != null && _selectedTime!.isNotEmpty;
    setState(() {
      _dateError = validDate ? null : 'Please select a valid date.';
      _timeError = validTime ? null : 'Please select a time.';
    });
  }

  /// Check availability for all slots on the selected date
  Future<void> _checkSlotAvailability() async {
    if (_selectedDate == null) return;
    
    setState(() {
      _isCheckingAvailability = true;
    });

    try {
      final String dateStr = _formatDate(_selectedDate!);
      final Map<String, bool> availability = {};
      
      for (String slot in _slots) {
        final String timeSlot = '$slot-${_getEndTime(slot)}';
        final bool isAvailable = await _bookingService.isTimeSlotAvailable(dateStr, timeSlot);
        availability['$dateStr-$timeSlot'] = isAvailable;
      }
      
      setState(() {
        _slotAvailability = availability;
        _isCheckingAvailability = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingAvailability = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking availability: $e')),
        );
      }
    }
  }

  /// Create actual booking with selected services, car, date and time
  Future<void> _createBooking() async {
    if (_selectedDate == null || _selectedTime == null || _selectedCar == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final String dateStr = _formatDate(_selectedDate!);
      final String timeSlot = '$_selectedTime-${_getEndTime(_selectedTime!)}';
      
      // Get selected service IDs
      final List<String> selectedServiceIds = _selectedServices.map((s) => s['id'] as String).toList();
      
      // Create actual booking in standalone collection
      final String bookingId = await _bookingService.createCurrentUserBooking(
        carId: _selectedCar!['id'] as String,
        selectedServices: selectedServiceIds,
        totalPrice: _totalPrice,
        bookingDate: dateStr,
        timeSlot: timeSlot,
        specialInstructions: '',
        paymentMethod: '',
        location: '',
      );
      
      // Clear temporary booking data after successful creation
      await _bookingService.clearCurrentUserSelectedServices();
      await _bookingService.clearCurrentUserBookingSchedule();
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        // Navigate to payment with booking ID
        Navigator.of(context).pushNamed('/payment', arguments: {'bookingId': bookingId});
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating booking: $e')),
        );
      }
    }
  }

  void _onPickDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year, now.month, now.day);
    final DateTime lastDate = DateTime(now.year + 2);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // reset selection on date change
        _slotAvailability.clear(); // clear previous availability data
      });
      _validateState();
      // Check availability for the new date
      _checkSlotAvailability();
    }
  }

  Widget _buildSummary() {
    final String dateStr = _selectedDate != null ? _formatDate(_selectedDate!) : '—';
    final String timeStr = _selectedTime ?? '—';
    final String carStr = _selectedCar != null ? '${_selectedCar!['brand']} ${_selectedCar!['model']}' : '—';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show loading indicator while fetching services
        if (_isLoadingServices)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_selectedServices.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('No services selected'),
            ),
          )
        else
          // Show selected services
          for (final service in _selectedServices)
            Row(children: [
              Text(service['name'] ?? 'Unknown Service'),
              const Spacer(),
              Text('₹${(service['price'] as num).toStringAsFixed(2)}'),
            ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [Text('Car'), const Spacer(), Text(carStr)]),
        Row(children: [Text('Date'), const Spacer(), Text(dateStr)]),
        Row(children: [Text('Time'), const Spacer(), Text(timeStr)]),
        Row(children: [
          Text('Total', style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('₹${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String dateDisplay = _selectedDate != null ? _formatDate(_selectedDate!) : '';
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
                  child: Text('Select a slot', style: context.text.titleLarge),
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
                      // Car selection
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Choose car', style: context.text.bodySmall),
                        const SizedBox(height: AppSpacing.xs),
                        if (_isLoadingCars)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_userCars.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).dividerColor),
                              borderRadius: AppRadii.small,
                            ),
                            child: Text(
                              'No cars available. Please add a car in your profile.',
                              style: context.text.bodySmall?.copyWith(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          )
                        else
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedCar,
                            decoration: const InputDecoration(
                              hintText: 'Select a car',
                              border: OutlineInputBorder(),
                            ),
                            items: _userCars.map((car) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: car,
                                child: Text('${car['brand']} ${car['model']} (${car['registrationNumber']})'),
                              );
                            }).toList(),
                            onChanged: (Map<String, dynamic>? newValue) {
                              setState(() {
                                _selectedCar = newValue;
                              });
                            },
                          ),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Choose date', style: context.text.bodySmall),
                        const SizedBox(height: AppSpacing.xs),
                        GestureDetector(
                          onTap: _onPickDate,
                          child: AbsorbPointer(
                            child: TextField(
                              controller: TextEditingController(text: dateDisplay),
                              decoration: InputDecoration(
                                hintText: 'Pick a date',
                                errorText: _dateError,
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                            ),
                          ),
                        ),
                        if (_dateError != null) Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(_dateError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Choose time', style: context.text.bodySmall),
                        const SizedBox(height: AppSpacing.xs),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                            childAspectRatio: 2.8,
                          ),
                          itemCount: _slots.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String t = _slots[index];
                            final bool disabled = _selectedDate == null ? true : _isSlotDisabled(t, _selectedDate!);
                            final bool selected = t == _selectedTime;
                            final bool isChecking = _isCheckingAvailability;
                            
                            return OutlinedButton(
                              onPressed: (disabled || isChecking) ? null : () {
                                setState(() { _selectedTime = t; });
                                _validateState();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: selected 
                                    ? AppColors.primary 
                                    : disabled 
                                      ? Theme.of(context).disabledColor
                                      : Theme.of(context).dividerColor
                                ),
                                shape: RoundedRectangleBorder(borderRadius: AppRadii.small),
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                backgroundColor: selected ? AppColors.primary.withValues(alpha:0.02) : null,
                              ),
                              child: isChecking 
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).disabledColor),
                                    ),
                                  )
                                : Text(
                                    t, 
                                    style: TextStyle(
                                      color: disabled ? Theme.of(context).disabledColor : null
                                    )
                                  ),
                            );
                          },
                        ),
                        if (_timeError != null) Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(_timeError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppButton(label: 'Back', primary: false, onPressed: () => Navigator.of(context).pop()),
                          AppButton(
                            label: _isLoading ? 'Creating...' : 'Continue',
                            primary: true,
                            onPressed: (_selectedDate != null && _selectedTime != null && _selectedCar != null && !_isLoading) 
                              ? _createBooking 
                              : null,
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


