import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';
import 'package:car_wash_app/services/auth_provider.dart';
import 'package:car_wash_app/services/service_firebase_service.dart';
import 'package:car_wash_app/services/booking_firebase_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _services = [];
  final Set<String> _selected = <String>{};
  Map<String, dynamic>? _userProfile;
  final ServiceFirebaseService _serviceService = ServiceFirebaseService();
  final BookingFirebaseService _bookingService = BookingFirebaseService();

  @override
  void initState() {
    super.initState();
    _checkPendingBookings();
    _fetchServices();
    _loadUserProfile();
    _loadSelectedServices();
  }

  Future<void> _checkPendingBookings() async {
    try {
      final hasPending = await _bookingService.hasCurrentUserPendingBookings();
      if (hasPending && mounted) {
        // Show dialog to user about pending bookings
        _showPendingBookingsDialog();
      }
    } catch (e) {
      // Silently handle error - don't block the dashboard
      print('Error checking pending bookings: $e');
    }
  }

  void _showPendingBookingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pending Bookings'),
        content: const Text(
          'You have pending bookings that require payment. Would you like to view and complete them first?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Continue Booking'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/my-bookings');
            },
            child: const Text('View Bookings'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUserProfile() async {
    final authProvider = context.read<AuthProvider>();
    final profile = await authProvider.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  Future<void> _fetchServices() async {
    setState(() { _loading = true; });
    try {
      final services = await _serviceService.getAllActiveServices();
      if (mounted) {
        setState(() {
          _loading = false;
          _services = services;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _services = [];
        });
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    // Save selected services to Firestore
    _saveSelectedServices();
  }

  /// Load previously selected services from Firestore
  Future<void> _loadSelectedServices() async {
    try {
      final selectedServices = await _bookingService.getCurrentUserSelectedServices();
      if (mounted && selectedServices != null) {
        setState(() {
          _selected.clear();
          _selected.addAll(selectedServices);
        });
      }
    } catch (e) {
      // Silently handle error - user can still select services
      debugPrint('Failed to load selected services: $e');
    }
  }

  /// Save selected services to Firestore
  Future<void> _saveSelectedServices() async {
    try {
      await _bookingService.saveCurrentUserSelectedServices(
        selectedServiceIds: _selected.toList(),
      );
    } catch (e) {
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save selection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Clear selected services from Firestore
  Future<void> _clearSelectedServices() async {
    try {
      await _bookingService.clearCurrentUserSelectedServices();
    } catch (e) {
      debugPrint('Failed to clear selected services: $e');
    }
  }

  Future<void> _logout() async {
    // Clear selected services before logout
    await _clearSelectedServices();
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    // Navigation will be handled automatically by the auth state listener
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Wash Services'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/my-bookings'),
            icon: const Icon(Icons.event_note),
            tooltip: 'My Bookings',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User welcome section
                if (_userProfile != null) ...[
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/profile-view'),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.secondary,
                            child: Text(
                              _userProfile!['name']?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: context.text.bodySmall?.copyWith(
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pushNamed('/profile-view'),
                                child: Text(
                                  _userProfile!['name'] ?? 'User',
                                  style: context.text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text('Services', style: context.text.titleLarge),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Choose a service', style: context.text.headlineSmall),
                      const SizedBox(height: AppSpacing.lg),
                      if (_loading) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ],
                        ),
                      ] else if (_services.isEmpty) ...[
                        Text('No services available.', style: context.text.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
                      ] else ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                            childAspectRatio: 1,
                          ),
                          itemCount: _services.length,
                          itemBuilder: (BuildContext context, int index) {
                            final service = _services[index];
                            final bool selected = _selected.contains(service['id']);
                            return SelectableCard(
                              selected: selected,
                              onTap: () => _toggleSelect(service['id']),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: AppRadii.small,
                                    ),
                                    child: Text(
                                      service['icon'] ?? 'S', 
                                      style: const TextStyle(fontWeight: FontWeight.w700)
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    service['name'] ?? 'Service', 
                                    style: context.text.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '\$${service['price']?.toStringAsFixed(0) ?? '0'}', 
                                    style: context.text.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Tap to select', 
                                    style: context.text.bodySmall?.copyWith(
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(label: 'Log out', primary: false, onPressed: _logout),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: AppButton(label: 'View Profile', primary: false, onPressed: () => Navigator.of(context).pushNamed('/profile-view')),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(
                            label: 'Proceed to Booking', 
                            primary: true, 
                            onPressed: _selected.isEmpty ? null : () async {
                              // Save final selection before proceeding
                              await _saveSelectedServices();
                              if (mounted) {
                                Navigator.of(context).pushNamed('/slot-selection');
                              }
                            }
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




