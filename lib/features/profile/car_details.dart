import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';
import 'package:car_wash_app/utils/app_validations.dart';
import 'package:provider/provider.dart';
import 'package:car_wash_app/services/auth_provider.dart';
import 'package:car_wash_app/services/car_firebase_service.dart';

class CarDetailsPage extends StatefulWidget {
  const CarDetailsPage({super.key});

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  String? _brandError;
  String? _modelError;
  String? _registrationError;
  String? _yearError;
  bool _loading = false;
  final CarFirebaseService _carService = CarFirebaseService();

  @override
  void initState() {
    super.initState();
    _loadExistingCarData();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _registrationController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCarData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      try {
        // Load existing car data if available (get the first car for editing)
        final userCars = await _carService.getUserCars(user.uid);
        if (userCars.isNotEmpty && mounted) {
          final firstCar = userCars.first;
          setState(() {
            _brandController.text = firstCar['brand'] ?? '';
            _modelController.text = firstCar['model'] ?? '';
            _registrationController.text = firstCar['registrationNumber'] ?? '';
            _yearController.text = firstCar['year']?.toString() ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error loading car data: $e');
        // Continue with empty form if no cars exist yet
      }
    }
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'brand':
          _brandError = null;
          break;
        case 'model':
          _modelError = null;
          break;
        case 'registration':
          _registrationError = null;
          break;
        case 'year':
          _yearError = null;
          break;
      }
    });
  }

  Future<void> _submit() async {
    final Map<String, String?> errors = AppValidations.validateCarDetails(
      brand: _brandController.text,
      model: _modelController.text,
      registration: _registrationController.text,
      year: _yearController.text,
    );
    setState(() {
      _brandError = errors['brand'];
      _modelError = errors['model'];
      _registrationError = errors['registration'];
      _yearError = errors['year'];
    });
    final bool valid = errors.values.every((String? e) => e == null);
    if (!valid) return;

    setState(() { _loading = true; });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        // Check if user already has cars
        final existingCars = await _carService.getUserCars(user.uid);
        
        if (existingCars.isNotEmpty) {
          // Update the first car (for now, we'll update the first car)
          final firstCar = existingCars.first;
          await _carService.updateCarDetails(
            uid: user.uid,
            carId: firstCar['carId'],
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            registrationNumber: _registrationController.text.trim(),
            year: int.tryParse(_yearController.text.trim()) ?? 0,
          );
        } else {
          // Create new car
          await _carService.saveCarDetails(
            uid: user.uid,
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            registrationNumber: _registrationController.text.trim(),
            year: int.tryParse(_yearController.text.trim()) ?? 0,
          );
        }
      }

      if (!mounted) return;
      setState(() { _loading = false; });

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard');
      
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save car details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          // Redirect to login if not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

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
                      child: Text('Car details', style: context.text.titleLarge),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Add your car', style: context.text.headlineSmall),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            label: 'Brand',
                            hint: 'e.g., Toyota',
                            controller: _brandController,
                            errorText: _brandError,
                            onChanged: (_) => _clearError('brand'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Model',
                            hint: 'e.g., Corolla',
                            controller: _modelController,
                            errorText: _modelError,
                            onChanged: (_) => _clearError('model'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Registration Number',
                            hint: 'e.g., MH 12 AB 1234',
                            controller: _registrationController,
                            errorText: _registrationError,
                            onChanged: (_) => _clearError('registration'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Year',
                            hint: 'e.g., 2020',
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            errorText: _yearError,
                            onChanged: (_) => _clearError('year'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: 'Save',
                            primary: true,
                            loading: _loading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(label: 'Skip for now', primary: false, onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


