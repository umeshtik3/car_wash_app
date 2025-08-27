import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';
import 'package:car_wash_app/utils/app_validations.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _nameError;
  String? _phoneError;
  String? _addressError;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'name':
          _nameError = null;
          break;
        case 'phone':
          _phoneError = null;
          break;
        case 'address':
          _addressError = null;
          break;
      }
    });
  }

  Future<void> _submit() async {
    final Map<String, String?> errors = AppValidations.validateProfileSetup(
      name: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
    );
    setState(() {
      _nameError = errors['name'];
      _phoneError = errors['phone'];
      _addressError = errors['address'];
    });
    final bool valid = errors.values.every((String? e) => e == null);
    if (!valid) return;

    setState(() { _loading = true; });
    await AppValidations.fakeDelay();
    if (!mounted) return;
    setState(() { _loading = false; });

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/car-details');
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
                  child: Text('Profile setup', style: context.text.titleLarge),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Tell us about you', style: context.text.headlineSmall),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Name',
                        hint: 'Your full name',
                        controller: _nameController,
                        errorText: _nameError,
                        onChanged: (_) => _clearError('name'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Phone',
                        hint: 'Your phone number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        errorText: _phoneError,
                        onChanged: (_) => _clearError('phone'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Multiline textarea equivalent
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Address', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _addressController,
                            maxLines: 3,
                            keyboardType: TextInputType.multiline,
                            onChanged: (_) => _clearError('address'),
                            decoration: InputDecoration(
                              hintText: 'Street, City, State, ZIP',
                              errorText: _addressError,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Save',
                        primary: true,
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(label: 'Skip for now', primary: false, onPressed: () => Navigator.of(context).pushReplacementNamed('/car-details')),
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


