import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/features/auth/presentation/login_page.dart';
import 'package:car_wash_app/features/auth/presentation/sign_up.dart';
import 'package:car_wash_app/features/profile/profile_setup.dart';
import 'package:car_wash_app/features/profile/car_details.dart';
import 'package:car_wash_app/features/dashboard/dashboard.dart';
import 'package:car_wash_app/features/slot_selection/slot_selection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarWashApp',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/login',
      routes: <String, WidgetBuilder>{
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const SignUpPage(),
        '/profile-setup': (_) => const ProfileSetupPage(),
        '/car-details': (_) => const CarDetailsPage(),
        '/dashboard': (_) => const DashboardPage(),
        '/slot-selection': (_) => const SlotSelectionPage(),
      },
    );
  }
}

