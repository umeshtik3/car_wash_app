import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Save user profile data to Firestore
  /// Creates or updates user document in users/{uid} collection
  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    String? phone,
    String? address,
  }) async {
    try {
      final userData = {
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add optional fields if provided
      if (phone != null && phone.isNotEmpty) {
        userData['phone'] = phone;
      }
      if (address != null && address.isNotEmpty) {
        userData['address'] = address;
      }

      await _firestore.collection('users').doc(uid).set(userData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  /// Update user profile data in Firestore
  /// Updates specific fields in users/{uid} document
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update fields that are provided
      if (name != null && name.isNotEmpty) {
        updateData['name'] = name;
      }
      if (phone != null && phone.isNotEmpty) {
        updateData['phone'] = phone;
      }
      if (address != null && address.isNotEmpty) {
        updateData['address'] = address;
      }

      if (updateData.length > 1) { // More than just updatedAt
        await _firestore.collection('users').doc(uid).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Get user profile data from Firestore
  /// Returns user document from users/{uid} collection
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Get current user's profile data
  /// Uses the current authenticated user's UID
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return await getUserProfile(currentUser!.uid);
  }

  /// Stream user profile data for real-time updates
  /// Returns a stream of user document from users/{uid} collection
  Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Stream current user's profile data for real-time updates
  Stream<DocumentSnapshot> getCurrentUserProfileStream() {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    return getUserProfileStream(currentUser!.uid);
  }

  /// Check if user profile exists
  /// Returns true if user document exists in Firestore
  Future<bool> userProfileExists(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check user profile existence: $e');
    }
  }

  /// Delete user profile (use with caution)
  /// Removes user document from users/{uid} collection
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  /// Get user profile with validation
  /// Ensures required fields are present
  Future<Map<String, dynamic>?> getUserProfileWithValidation(String uid) async {
    try {
      final profile = await getUserProfile(uid);
      
      if (profile == null) return null;
      
      // Validate required fields
      if (profile['name'] == null || profile['email'] == null) {
        throw Exception('User profile is incomplete - missing required fields');
      }
      
      return profile;
    } catch (e) {
      throw Exception('Failed to get validated user profile: $e');
    }
  }
}
