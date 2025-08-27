import 'dart:async';

class AppValidations {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  // Primitive validators
  static String? validateEmail(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty || !_emailRegex.hasMatch(v.toLowerCase())) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final String v = (value ?? '');
    if (v.isEmpty || v.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty || v.length < 2) {
      return 'Enter your name';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty || v.length < 7) {
      return 'Enter a valid phone';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty || v.length < 6) {
      return 'Enter your address';
    }
    return null;
  }

  static String? validateBrand(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty || v.length < 2) {
      return 'Enter brand';
    }
    return null;
  }

  static String? validateModel(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty || v.length < 1) {
      return 'Enter model';
    }
    return null;
  }

  static String? validateRegistration(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty || v.length < 5) {
      return 'Enter registration';
    }
    return null;
  }

  static String? validateYear(String? value) {
    final String v = (value ?? '').trim();
    final int? year = int.tryParse(v);
    if (year == null || year < 1980 || year > 2100) {
      return 'Enter valid year';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    final String v = (value ?? '');
    final String p = (password ?? '');
    if (v != p) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Composite helpers mirroring validation.js flows
  static Map<String, String?> validateLogin({required String email, required String password}) {
    return <String, String?>{
      'email': validateEmail(email),
      'password': validatePassword(password),
    };
  }

  static Map<String, String?> validateSignup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return <String, String?>{
      'name': validateName(name),
      'email': validateEmail(email),
      'password': validatePassword(password),
      'confirmPassword': validateConfirmPassword(confirmPassword, password),
    };
  }

  static Map<String, String?> validateProfileSetup({
    required String name,
    required String phone,
    required String address,
  }) {
    return <String, String?>{
      'name': validateName(name),
      'phone': validatePhone(phone),
      'address': validateAddress(address),
    };
  }

  static Map<String, String?> validateCarDetails({
    required String brand,
    required String model,
    required String registration,
    required String year,
  }) {
    return <String, String?>{
      'brand': validateBrand(brand),
      'model': validateModel(model),
      'registration': validateRegistration(registration),
      'year': validateYear(year),
    };
  }

  // Utility to mimic async delay used in JS setTimeout for demo flows
  static Future<void> fakeDelay([Duration duration = const Duration(milliseconds: 1200)]) async {
    await Future<void>.delayed(duration);
  }
}


