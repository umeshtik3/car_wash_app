import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:car_wash_app/services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _firebaseService.authStateChanges.listen((User? user) {
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Method to manually refresh the current user state
  Future<void> refreshUserState() async {
    final currentUser = _firebaseService.currentUser;
    if (_currentUser != currentUser) {
      _currentUser = currentUser;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      // Navigation will be handled by the auth state listener
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_currentUser == null) return null;
    try {
      return await _firebaseService.getUserProfile(_currentUser!.uid);
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }
}
