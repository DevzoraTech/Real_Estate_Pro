import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedServiceProviders() async {
    try {
      // Check if data already exists
      final existingProviders =
          await _firestore.collection('service_providers').limit(1).get();
      if (existingProviders.docs.isNotEmpty) {
        print('Service providers already exist. Skipping seeding.');
        return;
      }

      print('Seeding service providers...');

      final providers = [
        {
          'name': 'John Smith',
          'email': 'john.smith@example.com',
          'phone': '+1 (555) 123-4567',
          'profile_image': '',
          'bio':
              'Experienced real estate agent with over 10 years in the San Francisco Bay Area. Specializing in residential properties and first-time home buyers.',
          'service_categories': ['real_estate_agents'],
          'primary_service': 'Real Estate Agents',
          'rating': 4.8,
          'reviews_count': 127,
          'total_rating': 609.6,
          'location': '123 Market Street',
          'city': 'San Francisco',
          'state': 'CA',
          'latitude': 37.7749,
          'longitude': -122.4194,
          'portfolio_images': [],
          'certifications': [
            'Licensed Real Estate Agent',
            'Certified Residential Specialist',
          ],
          'years_of_experience': 10,
          'is_verified': true,
          'is_online': true,
          'is_featured': true,
          'availability': 'available',
          'pricing': {'consultation': 100.0, 'commission_rate': 2.5},
          'service_areas': ['San Francisco', 'Oakland', 'Berkeley'],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Sarah Johnson',
          'email': 'sarah.johnson@example.com',
          'phone': '+1 (555) 234-5678',
          'profile_image': '',
          'bio':
              'Award-winning interior designer with a passion for creating beautiful, functional spaces. Specializing in modern and contemporary design.',
          'service_categories': ['interior_designers'],
          'primary_service': 'Interior Designers',
          'rating': 4.9,
          'reviews_count': 89,
          'total_rating': 436.1,
          'location': '456 Design Avenue',
          'city': 'San Francisco',
          'state': 'CA',
          'latitude': 37.7849,
          'longitude': -122.4094,
          'portfolio_images': [],
          'certifications': [
            'Certified Interior Designer',
            'LEED Accredited Professional',
          ],
          'years_of_experience': 8,
          'is_verified': true,
          'is_online': false,
          'is_featured': true,
          'availability': 'busy',
          'pricing': {'consultation': 150.0, 'hourly_rate': 125.0},
          'service_areas': ['San Francisco', 'Palo Alto', 'San Jose'],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 2)),
          ),
        },
        {
          'name': 'Mike Wilson',
          'email': 'mike.wilson@example.com',
          'phone': '+1 (555) 345-6789',
          'profile_image': '',
          'bio':
              'Licensed general contractor with expertise in home renovations, kitchen remodels, and bathroom upgrades. Quality workmanship guaranteed.',
          'service_categories': ['contractors'],
          'primary_service': 'Contractors',
          'rating': 4.7,
          'reviews_count': 156,
          'total_rating': 733.2,
          'location': '789 Construction Way',
          'city': 'Oakland',
          'state': 'CA',
          'latitude': 37.8044,
          'longitude': -122.2711,
          'portfolio_images': [],
          'certifications': [
            'Licensed General Contractor',
            'OSHA Safety Certified',
          ],
          'years_of_experience': 15,
          'is_verified': true,
          'is_online': true,
          'is_featured': false,
          'availability': 'available',
          'pricing': {'consultation': 75.0, 'hourly_rate': 85.0},
          'service_areas': ['Oakland', 'San Francisco', 'Berkeley', 'San Jose'],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Lisa Chen',
          'email': 'lisa.chen@example.com',
          'phone': '+1 (555) 456-7890',
          'profile_image': '',
          'bio':
              'Experienced real estate attorney specializing in property transactions, contract negotiations, and title issues. Protecting your investment.',
          'service_categories': ['lawyers'],
          'primary_service': 'Legal Services',
          'rating': 4.9,
          'reviews_count': 203,
          'total_rating': 994.7,
          'location': '321 Legal Plaza',
          'city': 'San Francisco',
          'state': 'CA',
          'latitude': 37.7949,
          'longitude': -122.3994,
          'portfolio_images': [],
          'certifications': [
            'Licensed Attorney',
            'Real Estate Law Specialist',
            'Certified Mediator',
          ],
          'years_of_experience': 12,
          'is_verified': true,
          'is_online': true,
          'is_featured': true,
          'availability': 'available',
          'pricing': {'consultation': 300.0, 'hourly_rate': 450.0},
          'service_areas': [
            'San Francisco',
            'Oakland',
            'San Jose',
            'Palo Alto',
          ],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active': FieldValue.serverTimestamp(),
        },
        {
          'name': 'David Rodriguez',
          'email': 'david.rodriguez@example.com',
          'phone': '+1 (555) 567-8901',
          'profile_image': '',
          'bio':
              'Professional home inspector with thorough attention to detail. Comprehensive inspections to help you make informed decisions.',
          'service_categories': ['home_inspectors'],
          'primary_service': 'Home Inspectors',
          'rating': 4.6,
          'reviews_count': 94,
          'total_rating': 432.4,
          'location': '654 Inspection Drive',
          'city': 'Berkeley',
          'state': 'CA',
          'latitude': 37.8715,
          'longitude': -122.2730,
          'portfolio_images': [],
          'certifications': [
            'Certified Home Inspector',
            'Structural Inspection Certified',
          ],
          'years_of_experience': 7,
          'is_verified': true,
          'is_online': true,
          'is_featured': false,
          'availability': 'available',
          'pricing': {
            'basic_inspection': 400.0,
            'comprehensive_inspection': 650.0,
          },
          'service_areas': ['Berkeley', 'Oakland', 'San Francisco'],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Amanda Foster',
          'email': 'amanda.foster@example.com',
          'phone': '+1 (555) 678-9012',
          'profile_image': '',
          'bio':
              'Experienced mortgage broker helping clients find the best financing options. First-time buyers and refinancing specialist.',
          'service_categories': ['mortgage_brokers'],
          'primary_service': 'Mortgage Brokers',
          'rating': 4.8,
          'reviews_count': 167,
          'total_rating': 801.6,
          'location': '987 Finance Street',
          'city': 'San Jose',
          'state': 'CA',
          'latitude': 37.3382,
          'longitude': -121.8863,
          'portfolio_images': [],
          'certifications': [
            'Licensed Mortgage Broker',
            'Certified Mortgage Planning Specialist',
          ],
          'years_of_experience': 9,
          'is_verified': true,
          'is_online': false,
          'is_featured': true,
          'availability': 'available',
          'pricing': {'consultation': 0.0, 'processing_fee': 1200.0},
          'service_areas': [
            'San Jose',
            'Palo Alto',
            'Mountain View',
            'Santa Clara',
          ],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 4)),
          ),
        },
        {
          'name': 'Maria Rodriguez',
          'email': 'maria.rodriguez@example.com',
          'phone': '+1 (555) 789-0123',
          'profile_image': '',
          'bio':
              'Top-performing real estate agent specializing in luxury properties and commercial real estate. 15+ years of experience in the Bay Area market.',
          'service_categories': ['real_estate_agents'],
          'primary_service': 'Real Estate Agents',
          'rating': 4.9,
          'reviews_count': 245,
          'total_rating': 1200.5,
          'location': '555 Luxury Lane',
          'city': 'Palo Alto',
          'state': 'CA',
          'latitude': 37.4419,
          'longitude': -122.1430,
          'portfolio_images': [],
          'certifications': [
            'Licensed Real Estate Agent',
            'Luxury Home Marketing Specialist',
            'Commercial Real Estate Certified',
          ],
          'years_of_experience': 15,
          'is_verified': true,
          'is_online': true,
          'is_featured': true,
          'availability': 'available',
          'pricing': {'consultation': 150.0, 'commission_rate': 3.0},
          'service_areas': [
            'Palo Alto',
            'Mountain View',
            'Menlo Park',
            'San Jose',
          ],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Robert Kim',
          'email': 'robert.kim@example.com',
          'phone': '+1 (555) 890-1234',
          'profile_image': '',
          'bio':
              'Professional property manager with extensive experience managing residential and commercial properties. Specializing in tenant relations and property maintenance.',
          'service_categories': ['property_managers'],
          'primary_service': 'Property Managers',
          'rating': 4.7,
          'reviews_count': 178,
          'total_rating': 836.6,
          'location': '888 Management Blvd',
          'city': 'San Francisco',
          'state': 'CA',
          'latitude': 37.7849,
          'longitude': -122.4094,
          'portfolio_images': [],
          'certifications': [
            'Certified Property Manager',
            'Real Estate License',
            'Fair Housing Certified',
          ],
          'years_of_experience': 11,
          'is_verified': true,
          'is_online': true,
          'is_featured': false,
          'availability': 'available',
          'pricing': {'monthly_management': 8.0, 'setup_fee': 500.0},
          'service_areas': ['San Francisco', 'Oakland', 'Berkeley'],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Jennifer Walsh',
          'email': 'jennifer.walsh@example.com',
          'phone': '+1 (555) 901-2345',
          'profile_image': '',
          'bio':
              'Property owner with multiple rental properties in the Bay Area. Offering direct rental opportunities and property investment advice.',
          'service_categories': ['property_owners'],
          'primary_service': 'Property Owners',
          'rating': 4.5,
          'reviews_count': 89,
          'total_rating': 400.5,
          'location': '777 Investment Ave',
          'city': 'Oakland',
          'state': 'CA',
          'latitude': 37.8044,
          'longitude': -122.2711,
          'portfolio_images': [],
          'certifications': [
            'Real Estate Investment Certified',
            'Property Management License',
          ],
          'years_of_experience': 8,
          'is_verified': true,
          'is_online': false,
          'is_featured': false,
          'availability': 'available',
          'pricing': {'consultation': 100.0, 'property_showing': 0.0},
          'service_areas': ['Oakland', 'Berkeley', 'San Francisco'],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 6)),
          ),
        },
        {
          'name': 'Thomas Anderson',
          'email': 'thomas.anderson@example.com',
          'phone': '+1 (555) 012-3456',
          'profile_image': '',
          'bio':
              'First-time home buyer specialist and real estate agent. Helping young professionals and families find their dream homes with personalized service.',
          'service_categories': ['real_estate_agents'],
          'primary_service': 'Real Estate Agents',
          'rating': 4.8,
          'reviews_count': 156,
          'total_rating': 748.8,
          'location': '333 First Home Street',
          'city': 'San Jose',
          'state': 'CA',
          'latitude': 37.3382,
          'longitude': -121.8863,
          'portfolio_images': [],
          'certifications': [
            'Licensed Real Estate Agent',
            'First-Time Home Buyer Specialist',
            'Accredited Buyer Representative',
          ],
          'years_of_experience': 7,
          'is_verified': true,
          'is_online': true,
          'is_featured': false,
          'availability': 'available',
          'pricing': {'consultation': 0.0, 'commission_rate': 2.5},
          'service_areas': ['San Jose', 'Santa Clara', 'Milpitas', 'Fremont'],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active': FieldValue.serverTimestamp(),
        },
      ];

      // Add providers to Firestore
      final batch = _firestore.batch();
      for (int i = 0; i < providers.length; i++) {
        final docRef = _firestore.collection('service_providers').doc();
        batch.set(docRef, {...providers[i], 'id': docRef.id});
      }

      await batch.commit();
      print('Successfully seeded ${providers.length} service providers!');
    } catch (e) {
      print('Error seeding service providers: $e');
      rethrow;
    }
  }

  static Future<void> seedServiceReviews() async {
    try {
      // Get all service providers
      final providersSnapshot =
          await _firestore.collection('service_providers').get();
      if (providersSnapshot.docs.isEmpty) {
        print('No service providers found. Please seed providers first.');
        return;
      }

      print('Seeding service reviews...');

      final batch = _firestore.batch();
      int reviewCount = 0;

      for (final providerDoc in providersSnapshot.docs) {
        final providerId = providerDoc.id;
        final providerData = providerDoc.data();
        final reviewsCount = providerData['reviews_count'] as int;

        // Create sample reviews for each provider
        final sampleReviews = _generateSampleReviews(providerId, reviewsCount);

        for (final review in sampleReviews) {
          final reviewRef = _firestore.collection('service_reviews').doc();
          batch.set(reviewRef, {...review, 'id': reviewRef.id});
          reviewCount++;
        }
      }

      await batch.commit();
      print('Successfully seeded $reviewCount service reviews!');
    } catch (e) {
      print('Error seeding service reviews: $e');
      rethrow;
    }
  }

  static List<Map<String, dynamic>> _generateSampleReviews(
    String providerId,
    int count,
  ) {
    final reviews = <Map<String, dynamic>>[];
    final sampleReviewTexts = [
      'Excellent service! Very professional and knowledgeable.',
      'Great experience working with this provider. Highly recommended!',
      'Outstanding work quality and attention to detail.',
      'Very responsive and delivered exactly what was promised.',
      'Professional, reliable, and great value for money.',
      'Exceeded my expectations. Will definitely use again.',
      'Fantastic service from start to finish.',
      'Very knowledgeable and helpful throughout the process.',
      'Great communication and timely delivery.',
      'Highly skilled professional. Very satisfied with the results.',
    ];

    final customerNames = [
      'Jennifer Martinez',
      'Robert Thompson',
      'Emily Davis',
      'Michael Brown',
      'Jessica Wilson',
      'Christopher Lee',
      'Ashley Garcia',
      'Daniel Miller',
      'Stephanie Anderson',
      'Kevin Taylor',
    ];

    // Generate a subset of reviews (not all, to make it realistic)
    final reviewsToGenerate =
        (count * 0.3).round(); // About 30% of claimed reviews

    for (int i = 0; i < reviewsToGenerate; i++) {
      final rating =
          4.0 + (i % 2 == 0 ? 0.5 : 1.0); // Mix of 4.5 and 5.0 ratings
      reviews.add({
        'provider_id': providerId,
        'customer_id': 'customer_${i}_$providerId',
        'customer_name': customerNames[i % customerNames.length],
        'rating': rating,
        'review': sampleReviewTexts[i % sampleReviewTexts.length],
        'created_at': Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: i * 7 + (i % 30))),
        ),
      });
    }

    return reviews;
  }

  static Future<void> seedAllData() async {
    print('Starting Firebase data seeding...');

    try {
      await seedServiceProviders();
      await seedServiceReviews();
      print('✅ All data seeded successfully!');
    } catch (e) {
      print('❌ Error during seeding: $e');
      rethrow;
    }
  }
}
