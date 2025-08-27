import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';
import 'package:car_wash_app/utils/app_validations.dart';

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

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _registrationController.dispose();
    _yearController.dispose();
    super.dispose();
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
    await AppValidations.fakeDelay();
    if (!mounted) return;
    setState(() { _loading = false; });

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
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
  }
}


