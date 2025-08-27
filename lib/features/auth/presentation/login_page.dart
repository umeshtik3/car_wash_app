import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';
import 'package:car_wash_app/utils/app_validations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrorsOnInput() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
  }

  Future<void> _submit() async {
    final Map<String, String?> errors = AppValidations.validateLogin(
      email: _emailController.text,
      password: _passwordController.text,
    );
    setState(() {
      _emailError = errors['email'];
      _passwordError = errors['password'];
    });
    final bool valid = errors.values.every((String? e) => e == null);
    if (!valid) return;

    setState(() { _loading = true; });
    await AppValidations.fakeDelay();
    if (!mounted) return;
    setState(() { _loading = false; });

    // For static flow, navigate to a placeholder route name 'dashboard'
    // Replace with real navigation later.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login successful (demo)')),
    );
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
                  child: Text('Welcome back', style: context.text.titleLarge),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Login', style: context.text.headlineSmall),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Email',
                        hint: 'you@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: (_) => _clearErrorsOnInput(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        obscureText: true,
                        errorText: _passwordError,
                        onChanged: (_) => _clearErrorsOnInput(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppButton(label: 'Forgot password?', primary: false, onPressed: () {}),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Login',
                        primary: true,
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?", style: context.text.bodySmall),
                          const SizedBox(width: AppSpacing.sm),
                          AppButton(label: 'Sign up', primary: false, onPressed: () {}),
                        ],
                      )
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


