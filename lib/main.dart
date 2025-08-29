import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/features/auth/presentation/login_page.dart';
import 'package:car_wash_app/features/auth/presentation/sign_up.dart';
import 'package:car_wash_app/features/profile/profile_setup.dart';
import 'package:car_wash_app/features/profile/car_details.dart';
import 'package:car_wash_app/features/dashboard/dashboard.dart';
import 'package:car_wash_app/features/slot_selection/slot_selection.dart';
import 'package:car_wash_app/features/payment/payment.dart';
import 'package:car_wash_app/features/payment/confirmation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        '/payment': (_) => const PaymentPage(),
        '/confirmation': (_) => const ConfirmationPage(),
      },
    );
  }
}

