import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:car_wash_app/services/profile_firebase_service.dart';
import 'package:car_wash_app/services/car_firebase_service.dart';

/// Integration service that combines profile and car management
/// Demonstrates the complete Firestore structure: users/{uid} and users/{uid}/cars
class UserCarIntegrationService {
  final ProfileFirebaseService _profileService = ProfileFirebaseService();
  final CarFirebaseService _carService = CarFirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Complete user setup with profile and first car
  /// Creates both user profile and car details in one operation
  Future<Map<String, dynamic>> completeUserSetup({
    required String name,
    required String email,
    String? phone,
    String? address,
    required String carBrand,
    required String carModel,
    required String carRegistration,
    required int carYear,
    String? carColor,
    String? carNotes,
  }) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    final uid = currentUser!.uid;
    
    try {
      // Start a batch write for atomic operations
      WriteBatch batch = _firestore.batch();

      // 1. Create user profile document
      final userRef = _firestore.collection('users').doc(uid);
      final userData = {
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (phone != null && phone.isNotEmpty) {
        userData['phone'] = phone;
      }
      if (address != null && address.isNotEmpty) {
        userData['address'] = address;
      }

      batch.set(userRef, userData, SetOptions(merge: true));

      // 2. Create first car document
      final carRef = _firestore.collection('users').doc(uid).collection('cars').doc();
      final carId = carRef.id;
      
      final carData = {
        'carId': carId,
        'brand': carBrand,
        'model': carModel,
        'registrationNumber': carRegistration,
        'year': carYear,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (carColor != null && carColor.isNotEmpty) {
        carData['color'] = carColor;
      }
      if (carNotes != null && carNotes.isNotEmpty) {
        carData['notes'] = carNotes;
      }

      batch.set(carRef, carData);

      // Commit the batch
      await batch.commit();

      return {
        'success': true,
        'userId': uid,
        'carId': carId,
        'message': 'User profile and car details created successfully'
      };
    } catch (e) {
      throw Exception('Failed to complete user setup: $e');
    }
  }

  /// Get complete user data (profile + all cars)
  /// Returns combined data from users/{uid} and users/{uid}/cars
  Future<Map<String, dynamic>?> getCompleteUserData(String uid) async {
    try {
      // Get user profile
      final profile = await _profileService.getUserProfile(uid);
      if (profile == null) return null;

      // Get user cars
      final cars = await _carService.getUserCars(uid);

      return {
        'profile': profile,
        'cars': cars,
        'carCount': cars.length,
      };
    } catch (e) {
      throw Exception('Failed to get complete user data: $e');
    }
  }

  /// Get complete data for current user
  Future<Map<String, dynamic>?> getCurrentUserCompleteData() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getCompleteUserData(currentUser!.uid);
  }

  /// Stream complete user data (real-time updates)
  /// Combines profile and cars streams
  Stream<Map<String, dynamic>?> getCompleteUserDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().asyncMap((profileDoc) async {
      if (!profileDoc.exists) return null;

      // Get cars data
      final carsQuery = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .orderBy('createdAt', descending: true)
          .get();

      final cars = carsQuery.docs
          .map((doc) => doc.data())
          .toList();

      return {
        'profile': profileDoc.data(),
        'cars': cars,
        'carCount': cars.length,
      };
    });
  }

  /// Stream complete data for current user (real-time updates)
  Stream<Map<String, dynamic>?> getCurrentUserCompleteDataStream() {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return getCompleteUserDataStream(currentUser!.uid);
  }

  /// Validate user setup completeness
  /// Checks if user has profile and at least one car
  Future<Map<String, dynamic>> validateUserSetup(String uid) async {
    try {
      final profile = await _profileService.getUserProfile(uid);
      final cars = await _carService.getUserCars(uid);

      final hasProfile = profile != null && 
                        profile['name'] != null && 
                        profile['email'] != null;
      
      final hasCars = cars.isNotEmpty;
      final isComplete = hasProfile && hasCars;

      return {
        'isComplete': isComplete,
        'hasProfile': hasProfile,
        'hasCars': hasCars,
        'profileComplete': hasProfile,
        'carCount': cars.length,
        'missingFields': _getMissingFields(profile, cars),
      };
    } catch (e) {
      throw Exception('Failed to validate user setup: $e');
    }
  }

  /// Validate current user setup
  Future<Map<String, dynamic>> validateCurrentUserSetup() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await validateUserSetup(currentUser!.uid);
  }

  /// Get missing fields for user setup
  List<String> _getMissingFields(Map<String, dynamic>? profile, List<Map<String, dynamic>> cars) {
    final missing = <String>[];

    if (profile == null) {
      missing.add('profile');
    } else {
      if (profile['name'] == null || profile['name'].toString().isEmpty) {
        missing.add('name');
      }
      if (profile['email'] == null || profile['email'].toString().isEmpty) {
        missing.add('email');
      }
    }

    if (cars.isEmpty) {
      missing.add('cars');
    }

    return missing;
  }

  /// Delete user and all associated data
  /// Removes user profile and all cars (use with caution)
  Future<void> deleteUserAndAllData(String uid) async {
    try {
      WriteBatch batch = _firestore.batch();

      // Delete all cars
      final carsQuery = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .get();

      for (var doc in carsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete user profile
      batch.delete(_firestore.collection('users').doc(uid));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user and all data: $e');
    }
  }

  /// Get Firestore structure documentation
  /// Returns the expected Firestore structure for reference
  Map<String, dynamic> getFirestoreStructure() {
    return {
      'collections': {
        'users': {
          'description': 'Main collection for user profiles',
          'documentId': 'uid (from Firebase Auth)',
          'fields': {
            'name': 'String (required)',
            'email': 'String (required)',
            'phone': 'String (optional)',
            'address': 'String (optional)',
            'createdAt': 'Timestamp',
            'updatedAt': 'Timestamp',
          },
          'subcollections': {
            'cars': {
              'description': 'Subcollection for user cars',
              'documentId': 'auto-generated carId',
              'fields': {
                'carId': 'String (auto-generated)',
                'brand': 'String (required)',
                'model': 'String (required)',
                'registrationNumber': 'String (required)',
                'year': 'int (required)',
                'color': 'String (optional)',
                'notes': 'String (optional)',
                'createdAt': 'Timestamp',
                'updatedAt': 'Timestamp',
              }
            }
          }
        }
      },
      'examplePaths': {
        'userProfile': 'users/{uid}',
        'userCars': 'users/{uid}/cars',
        'specificCar': 'users/{uid}/cars/{carId}',
      }
    };
  }
}
