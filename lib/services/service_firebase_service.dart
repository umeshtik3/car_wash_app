import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Create a new service in Firestore
  /// Creates document in services collection
  Future<String> createService({
    required String name,
    required String description,
    required double price,
    required int duration, // in minutes
    required String icon,
    required String category, // basic, premium, detailing
    bool isActive = true,
    bool requiresSlot = true,
    int maxConcurrentBookings = 3,
    List<String>? requirements,
    List<String>? addOns,
  }) async {
    try {
      final serviceRef = _firestore.collection('services').doc();
      final serviceId = serviceRef.id;

      final serviceData = {
        'id': serviceId,
        'name': name,
        'description': description,
        'price': price,
        'duration': duration,
        'icon': icon,
        'category': category,
        'isActive': isActive,
        'requiresSlot': requiresSlot,
        'maxConcurrentBookings': maxConcurrentBookings,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add optional fields if provided
      if (requirements != null && requirements.isNotEmpty) {
        serviceData['requirements'] = requirements;
      }
      if (addOns != null && addOns.isNotEmpty) {
        serviceData['addOns'] = addOns;
      }

      await serviceRef.set(serviceData);
      return serviceId;
    } catch (e) {
      throw Exception('Failed to create service: $e');
    }
  }

  /// Update service details in Firestore
  Future<void> updateService({
    required String serviceId,
    String? name,
    String? description,
    double? price,
    int? duration,
    String? icon,
    String? category,
    bool? isActive,
    bool? requiresSlot,
    int? maxConcurrentBookings,
    List<String>? requirements,
    List<String>? addOns,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update fields that are provided
      if (name != null && name.isNotEmpty) updateData['name'] = name;
      if (description != null && description.isNotEmpty) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (duration != null) updateData['duration'] = duration;
      if (icon != null && icon.isNotEmpty) updateData['icon'] = icon;
      if (category != null && category.isNotEmpty) updateData['category'] = category;
      if (isActive != null) updateData['isActive'] = isActive;
      if (requiresSlot != null) updateData['requiresSlot'] = requiresSlot;
      if (maxConcurrentBookings != null) updateData['maxConcurrentBookings'] = maxConcurrentBookings;
      if (requirements != null) updateData['requirements'] = requirements;
      if (addOns != null) updateData['addOns'] = addOns;

      if (updateData.length > 1) { // More than just updatedAt
        await _firestore.collection('services').doc(serviceId).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }

  /// Get all active services
  Future<List<Map<String, dynamic>>> getAllActiveServices() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .orderBy('category')
          .orderBy('price')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get active services: $e');
    }
  }

  /// Get all services (including inactive)
  Future<List<Map<String, dynamic>>> getAllServices() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('services')
          .orderBy('category')
          .orderBy('price')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get all services: $e');
    }
  }

  /// Get services by category
  Future<List<Map<String, dynamic>>> getServicesByCategory(String category) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('services')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('price')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get services by category: $e');
    }
  }

  /// Get specific service details
  Future<Map<String, dynamic>?> getServiceDetails(String serviceId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('services').doc(serviceId).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get service details: $e');
    }
  }

  /// Stream all active services (real-time updates)
  Stream<QuerySnapshot> getActiveServicesStream() {
    return _firestore
        .collection('services')
        .where('isActive', isEqualTo: true)
        .orderBy('category')
        .orderBy('price')
        .snapshots();
  }

  /// Stream all services (real-time updates)
  Stream<QuerySnapshot> getAllServicesStream() {
    return _firestore
        .collection('services')
        .orderBy('category')
        .orderBy('price')
        .snapshots();
  }

  /// Stream services by category (real-time updates)
  Stream<QuerySnapshot> getServicesByCategoryStream(String category) {
    return _firestore
        .collection('services')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('price')
        .snapshots();
  }

  /// Stream specific service details (real-time updates)
  Stream<DocumentSnapshot> getServiceDetailsStream(String serviceId) {
    return _firestore.collection('services').doc(serviceId).snapshots();
  }

  /// Delete service
  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore.collection('services').doc(serviceId).delete();
    } catch (e) {
      throw Exception('Failed to delete service: $e');
    }
  }

  /// Toggle service active status
  Future<void> toggleServiceStatus(String serviceId, bool isActive) async {
    try {
      await _firestore.collection('services').doc(serviceId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle service status: $e');
    }
  }

  /// Get service count
  Future<int> getServiceCount({bool activeOnly = false}) async {
    try {
      Query query = _firestore.collection('services');
      
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      
      QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get service count: $e');
    }
  }

  /// Check if service exists
  Future<bool> serviceExists(String serviceId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('services').doc(serviceId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check service existence: $e');
    }
  }

  /// Get services by price range
  Future<List<Map<String, dynamic>>> getServicesByPriceRange({
    required double minPrice,
    required double maxPrice,
  }) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .where('price', isGreaterThanOrEqualTo: minPrice)
          .where('price', isLessThanOrEqualTo: maxPrice)
          .orderBy('price')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get services by price range: $e');
    }
  }
}
