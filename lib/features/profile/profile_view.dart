import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';
import 'package:car_wash_app/services/auth_provider.dart';
import 'package:car_wash_app/services/car_firebase_service.dart';
import 'package:car_wash_app/services/user_car_integration_service.dart';

class ProfileViewPage extends StatefulWidget {
  const ProfileViewPage({super.key});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  bool _loading = true;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userCars = [];
  final CarFirebaseService _carService = CarFirebaseService();
  final UserCarIntegrationService _integrationService = UserCarIntegrationService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() { _loading = true; });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        // Load complete user data (profile + cars)
        final completeData = await _integrationService.getCompleteUserData(user.uid);
        
        if (mounted) {
          setState(() {
            _userProfile = completeData?['profile'];
            _userCars = completeData?['cars'] ?? [];
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() { _loading = false; });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() { _loading = false; });
        _showErrorSnackBar('Failed to load profile data');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadUserData();
    _showSuccessSnackBar('Profile data refreshed');
  }

  Future<void> _editProfile() async {
    Navigator.of(context).pushNamed('/profile-setup').then((_) {
      // Refresh data when returning from profile setup
      _loadUserData();
    });
  }

  Future<void> _editCarDetails() async {
    Navigator.of(context).pushNamed('/car-details').then((_) {
      // Refresh data when returning from car details
      _loadUserData();
    });
  }

  Future<void> _addNewCar() async {
    Navigator.of(context).pushNamed('/car-details').then((_) {
      // Refresh data when returning from car details
      _loadUserData();
    });
  }

  Future<void> _deleteCar(String carId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: const Text('Are you sure you want to delete this car? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _carService.deleteCarDetails(user.uid, carId);
        _showSuccessSnackBar('Car deleted successfully');
        _loadUserData(); // Refresh the data
      } catch (e) {
        _showErrorSnackBar('Failed to delete car: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Profile Section
                          _buildProfileSection(),
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Cars Section
                          _buildCarsSection(),
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Quick Actions
                          _buildQuickActionsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileSection() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary,
                child: Text(
                  _userProfile?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userProfile?['name'] ?? 'No Name',
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _userProfile?['email'] ?? 'No Email',
                      style: context.text.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editProfile,
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Profile Details
          _buildProfileDetail('Phone', _userProfile?['phone'] ?? 'Not provided'),
          _buildProfileDetail('Address', _userProfile?['address'] ?? 'Not provided'),
          _buildProfileDetail('Member Since', _formatDate(_userProfile?['createdAt'])),
        ],
      ),
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarsSection() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'My Cars (${_userCars.length})',
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addNewCar,
                tooltip: 'Add New Car',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          if (_userCars.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                borderRadius: AppRadii.medium,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 48,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No cars added yet',
                    style: context.text.titleMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add your first car to get started',
                    style: context.text.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Add Car',
                    primary: true,
                    onPressed: _addNewCar,
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userCars.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final car = _userCars[index];
                return _buildCarCard(car);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: AppRadii.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: AppRadii.small,
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car['brand']} ${car['model']}',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      car['registrationNumber'] ?? 'No registration',
                      style: context.text.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editCarDetails();
                      break;
                    case 'delete':
                      _deleteCar(car['carId']);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // Car Details
          Row(
            children: [
              Expanded(
                child: _buildCarDetail('Year', car['year']?.toString() ?? 'N/A'),
              ),
              Expanded(
                child: _buildCarDetail('Color', car['color'] ?? 'Not specified'),
              ),
            ],
          ),
          
          if (car['notes'] != null && car['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Notes: ${car['notes']}',
              style: context.text.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCarDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
        Text(
          value,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick Actions',
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Edit Profile',
                  primary: false,
                  onPressed: _editProfile,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Add Car',
                  primary: true,
                  onPressed: _addNewCar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      if (timestamp is DateTime) {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      }
      // Handle Firestore Timestamp
      return 'Recently';
    } catch (e) {
      return 'Unknown';
    }
  }
}
