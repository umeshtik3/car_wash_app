import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';

class ConfirmationPage extends StatelessWidget {
  const ConfirmationPage({super.key});

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
                  child: Text('Confirmation', style: context.text.titleLarge),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Booking confirmed!', style: context.text.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Your payment has been recorded.', style: context.text.bodySmall, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(label: 'Go to Dashboard', primary: true, onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (Route<dynamic> r) => false)),
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


