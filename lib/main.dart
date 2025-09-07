import 'package:car_wash_app/features/profile/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:car_wash_app/firebase_options.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/services/auth_provider.dart';
import 'package:car_wash_app/features/auth/presentation/login_page.dart';
import 'package:car_wash_app/features/auth/presentation/sign_up.dart';
import 'package:car_wash_app/features/profile/profile_setup.dart';
import 'package:car_wash_app/features/profile/car_details.dart';
import 'package:car_wash_app/features/dashboard/dashboard.dart';
import 'package:car_wash_app/features/slot_selection/slot_selection.dart';
import 'package:car_wash_app/features/payment/payment.dart';
import 'package:car_wash_app/features/payment/confirmation.dart';
import 'package:car_wash_app/features/bookings/my_bookings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp(
            title: 'CarWashApp',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            home: authProvider.isAuthenticated
                ? const DashboardPage()
                : const LoginPage(),
            initialRoute: authProvider.isAuthenticated
                ? '/dashboard'
                : '/login',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/payment':
                  final args = settings.arguments as Map<String, dynamic>;
                  return MaterialPageRoute(
                    builder: (_) => PaymentPage(bookingId: args['bookingId']),
                  );
                default:
                  return MaterialPageRoute(builder: (_) => const LoginPage());
              }
            },
            routes: <String, WidgetBuilder>{
              '/login': (_) => const LoginPage(),
              '/signup': (_) => const SignUpPage(),
              '/profile-setup': (_) => const ProfileSetupPage(),
              '/profile-view': (_) => const ProfileViewPage(),
              '/car-details': (_) => const CarDetailsPage(),
              '/dashboard': (_) => const DashboardPage(),
              '/slot-selection': (_) => const SlotSelectionPage(),
              '/my-bookings': (_) => const MyBookingsPage(),
              '/confirmation': (_) => const ConfirmationPage(),
            },
          );
        },
      ),
    );
  }
}
