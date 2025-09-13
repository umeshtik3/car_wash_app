import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';
import 'package:car_wash_app/utils/app_validations.dart';
import 'package:car_wash_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:car_wash_app/services/auth_provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  bool _loading = false;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'name':
          _nameError = null;
          break;
        case 'email':
          _emailError = null;
          break;
        case 'password':
          _passwordError = null;
          break;
        case 'confirmPassword':
          _confirmError = null;
          break;
      }
    });
  }

  Future<void> _submit() async {
    final Map<String, String?> errors = AppValidations.validateSignup(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
    );
    setState(() {
      _nameError = errors['name'];
      _emailError = errors['email'];
      _passwordError = errors['password'];
      _confirmError = errors['confirmPassword'];
    });
    final bool valid = errors.values.every((String? e) => e == null);
    if (!valid) return;

    setState(() {
      _loading = true;
    });

    try {
      // Create user with Firebase Auth
      final userCredential = await _firebaseService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save user profile to Firestore
      await _firebaseService.saveUserProfile(
        uid: userCredential.user!.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created successfully! Welcome ${_nameController.text.trim()}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Ensure the AuthProvider is properly updated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserState();

      // Wait a moment for the AuthProvider to properly update the state
      // This ensures the authentication state is properly reflected
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to profile setup
      Navigator.of(context).pushReplacementNamed('/profile-setup');
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'Create your account',
                    style: context.text.titleLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Sign up', style: context.text.headlineSmall),
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
                        label: 'Email',
                        hint: 'you@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: (_) => _clearError('email'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Password',
                        hint: 'Create a password',
                        controller: _passwordController,
                        obscureText: true,
                        errorText: _passwordError,
                        onChanged: (_) => _clearError('password'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        controller: _confirmController,
                        obscureText: true,
                        errorText: _confirmError,
                        onChanged: (_) => _clearError('confirmPassword'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Sign up',
                        primary: true,
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: context.text.bodySmall,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppButton(
                            label: 'Login',
                            primary: false,
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacementNamed('/login'),
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
