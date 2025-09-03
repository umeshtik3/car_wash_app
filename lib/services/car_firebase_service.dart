import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Save car details to Firestore
  /// Creates document in users/{uid}/cars/{carId} collection
  Future<String> saveCarDetails({
    required String uid,
    required String brand,
    required String model,
    required String registrationNumber,
    required int year,
    String? color,
    String? notes,
  }) async {
    try {
      // Generate a unique car ID
      final carRef = _firestore.collection('users').doc(uid).collection('cars').doc();
      final carId = carRef.id;

      final carData = {
        'carId': carId,
        'brand': brand,
        'model': model,
        'registrationNumber': registrationNumber,
        'year': year,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add optional fields if provided
      if (color != null && color.isNotEmpty) {
        carData['color'] = color;
      }
      if (notes != null && notes.isNotEmpty) {
        carData['notes'] = notes;
      }

      await carRef.set(carData);
      return carId;
    } catch (e) {
      throw Exception('Failed to save car details: $e');
    }
  }

  /// Save car details for current user
  /// Uses the current authenticated user's UID
  Future<String> saveCurrentUserCarDetails({
    required String brand,
    required String model,
    required String registrationNumber,
    required int year,
    String? color,
    String? notes,
  }) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await saveCarDetails(
      uid: currentUser!.uid,
      brand: brand,
      model: model,
      registrationNumber: registrationNumber,
      year: year,
      color: color,
      notes: notes,
    );
  }

  /// Update car details in Firestore
  /// Updates specific fields in users/{uid}/cars/{carId} document
  Future<void> updateCarDetails({
    required String uid,
    required String carId,
    String? brand,
    String? model,
    String? registrationNumber,
    int? year,
    String? color,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update fields that are provided
      if (brand != null && brand.isNotEmpty) {
        updateData['brand'] = brand;
      }
      if (model != null && model.isNotEmpty) {
        updateData['model'] = model;
      }
      if (registrationNumber != null && registrationNumber.isNotEmpty) {
        updateData['registrationNumber'] = registrationNumber;
      }
      if (year != null) {
        updateData['year'] = year;
      }
      if (color != null && color.isNotEmpty) {
        updateData['color'] = color;
      }
      if (notes != null) {
        updateData['notes'] = notes;
      }

      if (updateData.length > 1) { // More than just updatedAt
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('cars')
            .doc(carId)
            .update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update car details: $e');
    }
  }

  /// Update car details for current user
  Future<void> updateCurrentUserCarDetails({
    required String carId,
    String? brand,
    String? model,
    String? registrationNumber,
    int? year,
    String? color,
    String? notes,
  }) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await updateCarDetails(
      uid: currentUser!.uid,
      carId: carId,
      brand: brand,
      model: model,
      registrationNumber: registrationNumber,
      year: year,
      color: color,
      notes: notes,
    );
  }

  /// Get all cars for a user
  /// Returns list of car documents from users/{uid}/cars collection
  Future<List<Map<String, dynamic>>> getUserCars(String uid) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get user cars: $e');
    }
  }

  /// Get all cars for current user
  Future<List<Map<String, dynamic>>> getCurrentUserCars() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getUserCars(currentUser!.uid);
  }

  /// Get specific car details
  /// Returns car document from users/{uid}/cars/{carId}
  Future<Map<String, dynamic>?> getCarDetails(String uid, String carId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .doc(carId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get car details: $e');
    }
  }

  /// Get specific car details for current user
  Future<Map<String, dynamic>?> getCurrentUserCarDetails(String carId) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getCarDetails(currentUser!.uid, carId);
  }

  /// Stream all cars for a user (real-time updates)
  /// Returns stream of car documents from users/{uid}/cars collection
  Stream<QuerySnapshot> getUserCarsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cars')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream all cars for current user (real-time updates)
  Stream<QuerySnapshot> getCurrentUserCarsStream() {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return getUserCarsStream(currentUser!.uid);
  }

  /// Stream specific car details (real-time updates)
  Stream<DocumentSnapshot> getCarDetailsStream(String uid, String carId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cars')
        .doc(carId)
        .snapshots();
  }

  /// Stream specific car details for current user (real-time updates)
  Stream<DocumentSnapshot> getCurrentUserCarDetailsStream(String carId) {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return getCarDetailsStream(currentUser!.uid, carId);
  }

  /// Delete car details
  /// Removes car document from users/{uid}/cars/{carId}
  Future<void> deleteCarDetails(String uid, String carId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .doc(carId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete car details: $e');
    }
  }

  /// Delete car details for current user
  Future<void> deleteCurrentUserCarDetails(String carId) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await deleteCarDetails(currentUser!.uid, carId);
  }

  /// Check if car exists by registration number
  /// Returns true if car with registration number exists for user
  Future<bool> carExistsByRegistration(String uid, String registrationNumber) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .where('registrationNumber', isEqualTo: registrationNumber)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check car existence: $e');
    }
  }

  /// Check if car exists by registration number for current user
  Future<bool> currentUserCarExistsByRegistration(String registrationNumber) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await carExistsByRegistration(currentUser!.uid, registrationNumber);
  }

  /// Get car count for user
  /// Returns number of cars owned by user
  Future<int> getUserCarCount(String uid) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get car count: $e');
    }
  }

  /// Get car count for current user
  Future<int> getCurrentUserCarCount() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getUserCarCount(currentUser!.uid);
  }
}
