import 'package:car_wash_app/services/service_firebase_service.dart';

/// Utility class to seed the Firestore services collection with sample data
/// Run this once to populate your services collection for testing
class SeedServices {
  static final ServiceFirebaseService _serviceService = ServiceFirebaseService();

  /// Seed the services collection with sample car wash services
  static Future<void> seedServices() async {
    try {
      print('🌱 Starting to seed services collection...');

      // Define sample services
      final services = [
        {
          'name': 'Basic Wash',
          'description': 'Exterior wash with soap and water, tire cleaning, and basic drying',
          'price': 15.00,
          'duration': 30,
          'icon': 'W',
          'category': 'basic',
          'requirements': ['Any car type'],
          'addOns': ['Wax', 'Tire Shine'],
        },
        {
          'name': 'Premium Wash',
          'description': 'Complete exterior wash with premium soap, tire cleaning, wheel detailing, and thorough drying',
          'price': 25.00,
          'duration': 45,
          'icon': 'P',
          'category': 'premium',
          'requirements': ['Any car type'],
          'addOns': ['Wax', 'Tire Shine', 'Interior Vacuum'],
        },
        {
          'name': 'Interior Clean',
          'description': 'Complete interior cleaning including vacuum, dashboard cleaning, and seat conditioning',
          'price': 20.00,
          'duration': 40,
          'icon': 'I',
          'category': 'basic',
          'requirements': ['Any car type'],
          'addOns': ['Leather Conditioning', 'Fabric Protection'],
        },
        {
          'name': 'Exterior Detailing',
          'description': 'Professional exterior detailing with clay bar treatment, polish, and protective coating',
          'price': 60.00,
          'duration': 120,
          'icon': 'D',
          'category': 'detailing',
          'requirements': ['Sedan', 'SUV', 'Hatchback'],
          'addOns': ['Ceramic Coating', 'Paint Correction'],
        },
        {
          'name': 'Full Detail Package',
          'description': 'Complete interior and exterior detailing with premium products and professional finish',
          'price': 100.00,
          'duration': 180,
          'icon': 'F',
          'category': 'detailing',
          'requirements': ['Any car type'],
          'addOns': ['Ceramic Coating', 'Paint Correction', 'Leather Conditioning'],
        },
        {
          'name': 'Quick Express',
          'description': 'Fast exterior wash for busy customers - 15 minutes or less',
          'price': 10.00,
          'duration': 15,
          'icon': 'Q',
          'category': 'basic',
          'requirements': ['Any car type'],
          'addOns': [],
        },
        {
          'name': 'Luxury Detail',
          'description': 'Premium detailing service with luxury products and white-glove treatment',
          'price': 150.00,
          'duration': 240,
          'icon': 'L',
          'category': 'detailing',
          'requirements': ['Luxury vehicles only'],
          'addOns': ['Ceramic Coating', 'Paint Correction', 'Leather Conditioning', 'Engine Bay Cleaning'],
        },
        {
          'name': 'Truck Wash',
          'description': 'Specialized wash for trucks and large vehicles with extended service time',
          'price': 35.00,
          'duration': 60,
          'icon': 'T',
          'category': 'premium',
          'requirements': ['Truck', 'SUV', 'Van'],
          'addOns': ['Bed Liner Treatment', 'Tire Shine'],
        },
      ];

      // Create each service
      for (final serviceData in services) {
        try {
          final serviceId = await _serviceService.createService(
            name: serviceData['name'] as String,
            description: serviceData['description'] as String,
            price: serviceData['price'] as double,
            duration: serviceData['duration'] as int,
            icon: serviceData['icon'] as String,
            category: serviceData['category'] as String,
            requirements: serviceData['requirements'] as List<String>?,
            addOns: serviceData['addOns'] as List<String>?,
          );
          
          print('✅ Created service: ${serviceData['name']} (ID: $serviceId)');
        } catch (e) {
          print('❌ Failed to create service ${serviceData['name']}: $e');
        }
      }

      print('🎉 Services seeding completed!');
      print('📊 Total services created: ${services.length}');
      
      // Verify services were created
      final activeServices = await _serviceService.getAllActiveServices();
      print('🔍 Active services in database: ${activeServices.length}');
      
    } catch (e) {
      print('💥 Error seeding services: $e');
    }
  }

  /// Clear all services from the collection (use with caution!)
  static Future<void> clearAllServices() async {
    try {
      print('🗑️ Clearing all services...');
      
      final services = await _serviceService.getAllServices();
      for (final service in services) {
        await _serviceService.deleteService(service['id']);
        print('🗑️ Deleted service: ${service['name']}');
      }
      
      print('✅ All services cleared!');
    } catch (e) {
      print('💥 Error clearing services: $e');
    }
  }

  /// Update existing services with new data
  static Future<void> updateSampleServices() async {
    try {
      print('🔄 Updating sample services...');
      
      final services = await _serviceService.getAllActiveServices();
      
      for (final service in services) {
        // Example: Update prices by 10%
        final newPrice = (service['price'] as double) * 1.1;
        
        await _serviceService.updateService(
          serviceId: service['id'],
          price: newPrice,
        );
        
        print('🔄 Updated ${service['name']} price to \$${newPrice.toStringAsFixed(2)}');
      }
      
      print('✅ Services updated!');
    } catch (e) {
      print('💥 Error updating services: $e');
    }
  }

  /// Display current services in the collection
  static Future<void> displayServices() async {
    try {
      print('📋 Current services in collection:');
      print('=' * 50);
      
      final services = await _serviceService.getAllActiveServices();
      
      if (services.isEmpty) {
        print('No services found in collection.');
        return;
      }
      
      for (final service in services) {
        print('📦 ${service['name']}');
        print('   💰 Price: \$${service['price']}');
        print('   ⏱️ Duration: ${service['duration']} minutes');
        print('   🏷️ Category: ${service['category']}');
        print('   📝 Description: ${service['description']}');
        if (service['requirements'] != null) {
          print('   📋 Requirements: ${service['requirements'].join(', ')}');
        }
        if (service['addOns'] != null && (service['addOns'] as List).isNotEmpty) {
          print('   ➕ Add-ons: ${service['addOns'].join(', ')}');
        }
        print('   🆔 ID: ${service['id']}');
        print('-' * 30);
      }
      
      print('📊 Total services: ${services.length}');
    } catch (e) {
      print('💥 Error displaying services: $e');
    }
  }
}

/// Example usage:
/// 
/// To seed services:
/// ```dart
/// await SeedServices.seedServices();
/// ```
/// 
/// To clear all services:
/// ```dart
/// await SeedServices.clearAllServices();
/// ```
/// 
/// To display current services:
/// ```dart
/// await SeedServices.displayServices();
/// ```
/// 
/// To update services:
/// ```dart
/// await SeedServices.updateSampleServices();
/// ```
