import 'dart:math' show cos, pi;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/service_provider_model.dart';
import '../models/service_request_model.dart';
import '../../domain/entities/service_request.dart';

abstract class ServiceRemoteDataSource {
  Future<List<ServiceProviderModel>> getServiceProviders({
    int page = 1,
    int limit = 20,
  });

  Future<List<ServiceProviderModel>> getFeaturedProviders({int limit = 10});

  Future<List<ServiceProviderModel>> getTopRatedProviders({int limit = 10});

  Future<List<ServiceProviderModel>> getNearbyProviders({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 10,
  });

  Future<List<ServiceProviderModel>> searchServiceProviders({
    String? query,
    String? category,
    String? location,
    double? minRating,
    bool? isVerified,
    bool? isOnline,
    int page = 1,
    int limit = 20,
  });

  Future<ServiceProviderModel> getServiceProviderById(String id);

  Future<List<ServiceRequestModel>> getServiceRequests({
    String? customerId,
    String? providerId,
    ServiceRequestStatus? status,
    int page = 1,
    int limit = 20,
  });

  Future<ServiceRequestModel> createServiceRequest(ServiceRequestModel request);
  Future<ServiceRequestModel> updateServiceRequest(ServiceRequestModel request);
  Future<void> deleteServiceRequest(String requestId);
  Future<ServiceRequestModel> getServiceRequestById(String id);

  Future<void> rateServiceProvider({
    required String providerId,
    required String customerId,
    required double rating,
    String? review,
  });

  Future<List<Map<String, dynamic>>> getProviderReviews({
    required String providerId,
    int page = 1,
    int limit = 10,
  });
}

class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  final FirebaseFirestore _firestore;

  ServiceRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ServiceProviderModel>> getServiceProviders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Debug: Check what fields exist in properties
      await _debugPropertyFields();

      // Fetch service providers
      final serviceProvidersQuery = _firestore
          .collection('service_providers')
          .orderBy('created_at', descending: true)
          .limit(limit);

      final serviceProvidersSnapshot = await serviceProvidersQuery.get();
      final serviceProviders =
          serviceProvidersSnapshot.docs
          .map(
                (doc) => ServiceProviderModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }),
          )
          .toList();

      // Fetch real estate agents from properties collection
      // Look for properties where ownerId corresponds to users with realtor/property_owner roles
      final allPropertiesQuery = _firestore
          .collection('properties')
          .limit(100); // Get more properties to find agents

      final allPropertiesSnapshot = await allPropertiesQuery.get();
      final agentIds = <String>{};
      final agents = <ServiceProviderModel>[];

      print(
        'Found ${allPropertiesSnapshot.docs.length} properties to check for agents',
      );

      for (final doc in allPropertiesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ownerId = data['ownerId'] as String?;
        final ownerRole = data['ownerRole'] as String?;

        // Check if this property belongs to a realtor or property owner
        if (ownerId != null &&
            (ownerRole == 'realtor' || ownerRole == 'property_owner') &&
            !agentIds.contains(ownerId)) {
          agentIds.add(ownerId);

          // Get agent details from users collection
          try {
            final userDoc =
                await _firestore.collection('users').doc(ownerId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;

              print(
                'Found agent: ${userData['displayName'] ?? 'Real Estate Agent'} (Role: $ownerRole)',
              );

              // Fetch real-time rating and reviews count
              double realTimeRating = 0.0;
              int realTimeReviewsCount = 0;

              try {
                final reviewsSnapshot =
                    await _firestore
                        .collection('users')
                        .doc(ownerId)
                        .collection('reviews')
                        .get();

                if (reviewsSnapshot.docs.isNotEmpty) {
                  double totalRating = 0.0;
                  for (final doc in reviewsSnapshot.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
                    totalRating += rating;
                  }
                  realTimeRating = totalRating / reviewsSnapshot.docs.length;
                  realTimeReviewsCount = reviewsSnapshot.docs.length;
                }
              } catch (e) {
                print('Error fetching real-time rating for $ownerId: $e');
              }

              // Create service provider model from agent data
              final agentProvider = ServiceProviderModel(
                id: ownerId,
                name: userData['displayName'] ?? 'Real Estate Agent',
                email: userData['email'] ?? '',
                phone: userData['phone'] ?? '',
                profileImage: userData['photoURL'] ?? '',
                bio: userData['bio'] ?? 'Professional real estate agent',
                serviceCategories: ['real_estate_agents'],
                primaryService: 'Real Estate Agent',
                rating: realTimeRating,
                reviewsCount: realTimeReviewsCount,
                location: data['address'] ?? '',
                city: data['city'] ?? 'Unknown',
                state: data['state'] ?? '',
                latitude: (data['latitude'] ?? 0.0).toDouble(),
                longitude: (data['longitude'] ?? 0.0).toDouble(),
                portfolioImages: userData['portfolioImages'] ?? [],
                certifications:
                    userData['certifications'] ??
                    ['Licensed Real Estate Agent'],
                yearsOfExperience: userData['yearsOfExperience'] ?? 5,
                isVerified: userData['isVerified'] ?? false,
                isOnline: userData['isOnline'] ?? false,
                availability: userData['availability'] ?? 'available',
                pricing: userData['pricing'] ?? {},
                serviceAreas: userData['serviceAreas'] ?? [],
                createdAt:
                    userData['createdAt'] is Timestamp
                        ? (userData['createdAt'] as Timestamp).toDate()
                        : (userData['createdAt'] ?? DateTime.now()),
                updatedAt:
                    userData['updatedAt'] is Timestamp
                        ? (userData['updatedAt'] as Timestamp).toDate()
                        : (userData['updatedAt'] ?? DateTime.now()),
              );

              agents.add(agentProvider);
            } else {
              print('User document not found for ownerId: $ownerId');
            }
          } catch (e) {
            print('Error fetching agent details: $e');
          }
        }
      }

      // Combine service providers and agents
      final allProviders = [...serviceProviders, ...agents];

      print('Total service providers: ${serviceProviders.length}');
      print('Total agents: ${agents.length}');
      print('Total combined providers: ${allProviders.length}');

      // Sort by creation date and limit results
      allProviders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allProviders.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch service providers: $e');
    }
  }

  // Debug method to check property fields
  Future<void> _debugPropertyFields() async {
    try {
      final allPropertiesQuery = _firestore.collection('properties').limit(5);
      final allPropertiesSnapshot = await allPropertiesQuery.get();

      print('=== PROPERTY FIELDS DEBUG ===');
      print('Total properties found: ${allPropertiesSnapshot.docs.length}');

      if (allPropertiesSnapshot.docs.isNotEmpty) {
        final sampleProperty =
            allPropertiesSnapshot.docs.first.data() as Map<String, dynamic>;
        print('Sample property fields: ${sampleProperty.keys.toList()}');

        // Check for alternative agent/realtor field names
        final possibleAgentFields = [
          'realtorId',
          'agentId',
          'realtor_id',
          'agent_id',
          'ownerId',
          'owner_id',
          'userId',
          'user_id',
        ];
        for (final field in possibleAgentFields) {
          if (sampleProperty.containsKey(field)) {
            print('Found agent field: $field = ${sampleProperty[field]}');
          }
        }

        // Show all property data for debugging
        print('Sample property data: $sampleProperty');
      }
      print('=== END DEBUG ===');
    } catch (e) {
      print('Error in debug: $e');
    }
  }

  @override
  Future<List<ServiceProviderModel>> getFeaturedProviders({
    int limit = 10,
  }) async {
    try {
      List<ServiceProviderModel> allFeaturedProviders = [];

      // Fetch featured service providers
      final snapshot =
          await _firestore
              .collection('service_providers')
              .where('is_featured', isEqualTo: true)
              .orderBy('rating', descending: true)
              .limit(limit)
              .get();

      final serviceProviders =
          snapshot.docs
          .map(
                (doc) => ServiceProviderModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }),
          )
          .toList();

      allFeaturedProviders.addAll(serviceProviders);

      // Fetch featured real estate agents (agents with high ratings and good reviews)
      final allPropertiesQuery = _firestore.collection('properties').limit(100);

      final allPropertiesSnapshot = await allPropertiesQuery.get();
      final agentIds = <String>{};
      final featuredAgents = <ServiceProviderModel>[];

      for (final doc in allPropertiesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ownerId = data['ownerId'] as String?;
        final ownerRole = data['ownerRole'] as String?;

        if (ownerId != null &&
            (ownerRole == 'realtor' || ownerRole == 'property_owner') &&
            !agentIds.contains(ownerId)) {
          agentIds.add(ownerId);

          try {
            final userDoc =
                await _firestore.collection('users').doc(ownerId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;

              // Fetch real-time rating and reviews count
              double realTimeRating = 0.0;
              int realTimeReviewsCount = 0;

              try {
                final reviewsSnapshot =
                    await _firestore
                        .collection('users')
                        .doc(ownerId)
                        .collection('reviews')
                        .get();

                if (reviewsSnapshot.docs.isNotEmpty) {
                  double totalRating = 0.0;
                  for (final doc in reviewsSnapshot.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
                    totalRating += rating;
                  }
                  realTimeRating = totalRating / reviewsSnapshot.docs.length;
                  realTimeReviewsCount = reviewsSnapshot.docs.length;
                }
              } catch (e) {
                print('Error fetching real-time rating for $ownerId: $e');
              }

              // Featured conditions for agents:
              // 1. High rating (4.0 or above)
              // 2. Good number of reviews (at least 3)
              // 3. Verified status or years of experience
              bool isFeatured =
                  realTimeRating >= 4.0 &&
                  realTimeReviewsCount >= 3 &&
                  (userData['isVerified'] == true ||
                      (userData['yearsOfExperience'] ?? 0) >= 3);

              if (isFeatured) {
                final agentProvider = ServiceProviderModel(
                  id: ownerId,
                  name: userData['displayName'] ?? 'Real Estate Agent',
                  email: userData['email'] ?? '',
                  phone: userData['phone'] ?? '',
                  profileImage: userData['photoURL'] ?? '',
                  bio: userData['bio'] ?? 'Professional real estate agent',
                  serviceCategories: ['real_estate_agents'],
                  primaryService: 'Real Estate Agent',
                  rating: realTimeRating,
                  reviewsCount: realTimeReviewsCount,
                  location: data['address'] ?? '',
                  city: data['city'] ?? 'Unknown',
                  state: data['state'] ?? '',
                  latitude: (data['latitude'] ?? 0.0).toDouble(),
                  longitude: (data['longitude'] ?? 0.0).toDouble(),
                  portfolioImages: userData['portfolioImages'] ?? [],
                  certifications:
                      userData['certifications'] ??
                      ['Licensed Real Estate Agent'],
                  yearsOfExperience: userData['yearsOfExperience'] ?? 5,
                  isVerified: userData['isVerified'] ?? false,
                  isOnline: userData['isOnline'] ?? false,
                  availability: userData['availability'] ?? 'available',
                  pricing: userData['pricing'] ?? {},
                  serviceAreas: userData['serviceAreas'] ?? [],
                  createdAt:
                      userData['createdAt'] is Timestamp
                          ? (userData['createdAt'] as Timestamp).toDate()
                          : (userData['createdAt'] ?? DateTime.now()),
                  updatedAt:
                      userData['updatedAt'] is Timestamp
                          ? (userData['updatedAt'] as Timestamp).toDate()
                          : (userData['updatedAt'] ?? DateTime.now()),
                );

                featuredAgents.add(agentProvider);
              }
            }
          } catch (e) {
            print('Error fetching agent details: $e');
          }
        }
      }

      // Combine and sort by rating
      allFeaturedProviders.addAll(featuredAgents);
      allFeaturedProviders.sort((a, b) => b.rating.compareTo(a.rating));

      return allFeaturedProviders.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured providers: $e');
    }
  }

  @override
  Future<List<ServiceProviderModel>> getTopRatedProviders({
    int limit = 10,
  }) async {
    try {
      List<ServiceProviderModel> allTopRatedProviders = [];

      print('=== TOP RATED PROVIDERS DEBUG ===');

      // Fetch top rated service providers
      final snapshot =
          await _firestore
              .collection('service_providers')
              .where('rating', isGreaterThanOrEqualTo: 4.0)
              .orderBy('rating', descending: true)
              .orderBy('reviews_count', descending: true)
              .limit(limit)
              .get();

      final serviceProviders =
          snapshot.docs
          .map(
                (doc) => ServiceProviderModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }),
          )
          .toList();

      allTopRatedProviders.addAll(serviceProviders);
      print(
        'Found ${serviceProviders.length} regular service providers with rating >= 4.0',
      );

      // Fetch top rated real estate agents
      final allPropertiesQuery = _firestore.collection('properties').limit(100);

      final allPropertiesSnapshot = await allPropertiesQuery.get();
      final agentIds = <String>{};
      final topRatedAgents = <ServiceProviderModel>[];

      print(
        'Checking ${allPropertiesSnapshot.docs.length} properties for agents',
      );

      for (final doc in allPropertiesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ownerId = data['ownerId'] as String?;
        final ownerRole = data['ownerRole'] as String?;

        if (ownerId != null &&
            (ownerRole == 'realtor' || ownerRole == 'property_owner') &&
            !agentIds.contains(ownerId)) {
          agentIds.add(ownerId);

          try {
            final userDoc =
                await _firestore.collection('users').doc(ownerId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;

              // Fetch real-time rating and reviews count
              double realTimeRating = 0.0;
              int realTimeReviewsCount = 0;

              try {
                final reviewsSnapshot =
                    await _firestore
                        .collection('users')
                        .doc(ownerId)
                        .collection('reviews')
                        .get();

                if (reviewsSnapshot.docs.isNotEmpty) {
                  double totalRating = 0.0;
                  for (final doc in reviewsSnapshot.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
                    totalRating += rating;
                  }
                  realTimeRating = totalRating / reviewsSnapshot.docs.length;
                  realTimeReviewsCount = reviewsSnapshot.docs.length;
                }
              } catch (e) {
                print('Error fetching real-time rating for $ownerId: $e');
              }

              print(
                'Agent: ${userData['displayName'] ?? 'Unknown'} - Rating: $realTimeRating, Reviews: $realTimeReviewsCount',
              );

              // Top rated conditions for agents:
              // 1. High rating (4.0 or above)
              // 2. At least 1 review (reduced from 2)
              bool isTopRated =
                  realTimeRating >= 4.0 && realTimeReviewsCount >= 1;

              if (isTopRated) {
                print(
                  '✅ Agent qualifies for top-rated: ${userData['displayName']}',
                );
                final agentProvider = ServiceProviderModel(
                  id: ownerId,
                  name: userData['displayName'] ?? 'Real Estate Agent',
                  email: userData['email'] ?? '',
                  phone: userData['phone'] ?? '',
                  profileImage: userData['photoURL'] ?? '',
                  bio: userData['bio'] ?? 'Professional real estate agent',
                  serviceCategories: ['real_estate_agents'],
                  primaryService: 'Real Estate Agent',
                  rating: realTimeRating,
                  reviewsCount: realTimeReviewsCount,
                  location: data['address'] ?? '',
                  city: data['city'] ?? 'Unknown',
                  state: data['state'] ?? '',
                  latitude: (data['latitude'] ?? 0.0).toDouble(),
                  longitude: (data['longitude'] ?? 0.0).toDouble(),
                  portfolioImages: userData['portfolioImages'] ?? [],
                  certifications:
                      userData['certifications'] ??
                      ['Licensed Real Estate Agent'],
                  yearsOfExperience: userData['yearsOfExperience'] ?? 5,
                  isVerified: userData['isVerified'] ?? false,
                  isOnline: userData['isOnline'] ?? false,
                  availability: userData['availability'] ?? 'available',
                  pricing: userData['pricing'] ?? {},
                  serviceAreas: userData['serviceAreas'] ?? [],
                  createdAt:
                      userData['createdAt'] is Timestamp
                          ? (userData['createdAt'] as Timestamp).toDate()
                          : (userData['createdAt'] ?? DateTime.now()),
                  updatedAt:
                      userData['updatedAt'] is Timestamp
                          ? (userData['updatedAt'] as Timestamp).toDate()
                          : (userData['updatedAt'] ?? DateTime.now()),
                );

                topRatedAgents.add(agentProvider);
              } else {
                print(
                  '❌ Agent does not qualify: ${userData['displayName']} - Rating: $realTimeRating, Reviews: $realTimeReviewsCount',
                );
              }
            }
          } catch (e) {
            print('Error fetching agent details: $e');
          }
        }
      }

      print('Found ${topRatedAgents.length} top-rated agents');

      // Combine and sort by rating, then by review count
      allTopRatedProviders.addAll(topRatedAgents);
      allTopRatedProviders.sort((a, b) {
        // First sort by rating (descending)
        int ratingComparison = b.rating.compareTo(a.rating);
        if (ratingComparison != 0) return ratingComparison;

        // If ratings are equal, sort by review count (descending)
        return b.reviewsCount.compareTo(a.reviewsCount);
      });

      print('Total top-rated providers: ${allTopRatedProviders.length}');
      print('=== END TOP RATED DEBUG ===');

      return allTopRatedProviders.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch top rated providers: $e');
    }
  }

  @override
  Future<List<ServiceProviderModel>> getNearbyProviders({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 10,
  }) async {
    try {
      final latRange = radiusKm / 111.0;
      final lngRange = radiusKm / (111.0 * cos(latitude * pi / 180));

      final snapshot =
          await _firestore
              .collection('service_providers')
              .where('latitude', isGreaterThan: latitude - latRange)
              .where('latitude', isLessThan: latitude + latRange)
              .limit(limit * 2)
              .get();

      final providers =
          snapshot.docs
              .map(
                (doc) => ServiceProviderModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }),
              )
              .where((provider) {
                final lngDiff = (provider.longitude - longitude).abs();
                return lngDiff <= lngRange;
              })
              .take(limit)
              .toList();

      return providers;
    } catch (e) {
      throw Exception('Failed to fetch nearby providers: $e');
    }
  }

  @override
  Future<List<ServiceProviderModel>> searchServiceProviders({
    String? query,
    String? category,
    String? location,
    double? minRating,
    bool? isVerified,
    bool? isOnline,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      List<ServiceProviderModel> allProviders = [];

      // Search service providers
      Query firestoreQuery = _firestore.collection('service_providers');

      // Apply filters
      if (category != null && category != 'all') {
        firestoreQuery = firestoreQuery.where(
          'service_categories',
          arrayContains: category,
        );
      }

      if (minRating != null) {
        firestoreQuery = firestoreQuery.where(
          'rating',
          isGreaterThanOrEqualTo: minRating,
        );
      }

      if (isVerified != null) {
        firestoreQuery = firestoreQuery.where(
          'is_verified',
          isEqualTo: isVerified,
        );
      }

      if (isOnline != null) {
        firestoreQuery = firestoreQuery.where('is_online', isEqualTo: isOnline);
      }

      // Order and limit
      firestoreQuery = firestoreQuery
          .orderBy('rating', descending: true)
          .limit(limit);

      final snapshot = await firestoreQuery.get();
      final serviceProviders =
          snapshot.docs
              .map(
                (doc) => ServiceProviderModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }),
              )
              .toList();

      allProviders.addAll(serviceProviders);

      // Search real estate agents if category includes real estate or is all
      if (category == null ||
          category == 'all' ||
          category == 'real_estate_agents') {
        final allPropertiesQuery = _firestore
            .collection('properties')
            .limit(100);
        final allPropertiesSnapshot = await allPropertiesQuery.get();
        final agentIds = <String>{};

        for (final doc in allPropertiesSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final ownerId = data['ownerId'] as String?;
          final ownerRole = data['ownerRole'] as String?;

          // Check if this property belongs to a realtor or property owner
          if (ownerId != null &&
              (ownerRole == 'realtor' || ownerRole == 'property_owner') &&
              !agentIds.contains(ownerId)) {
            agentIds.add(ownerId);

            try {
              final userDoc =
                  await _firestore.collection('users').doc(ownerId).get();
              if (userDoc.exists) {
                final userData = userDoc.data() as Map<String, dynamic>;

                // Fetch real-time rating and reviews count
                double realTimeRating = 0.0;
                int realTimeReviewsCount = 0;

                try {
                  final reviewsSnapshot =
                      await _firestore
                          .collection('users')
                          .doc(ownerId)
                          .collection('reviews')
                          .get();

                  if (reviewsSnapshot.docs.isNotEmpty) {
                    double totalRating = 0.0;
                    for (final doc in reviewsSnapshot.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final rating =
                          (data['rating'] as num?)?.toDouble() ?? 0.0;
                      totalRating += rating;
                    }
                    realTimeRating = totalRating / reviewsSnapshot.docs.length;
                    realTimeReviewsCount = reviewsSnapshot.docs.length;
                  }
                } catch (e) {
                  print('Error fetching real-time rating for $ownerId: $e');
                }

                final agentProvider = ServiceProviderModel(
                  id: ownerId,
                  name: userData['displayName'] ?? 'Real Estate Agent',
                  email: userData['email'] ?? '',
                  phone: userData['phone'] ?? '',
                  profileImage: userData['photoURL'] ?? '',
                  bio: userData['bio'] ?? 'Professional real estate agent',
                  serviceCategories: ['real_estate_agents'],
                  primaryService: 'Real Estate Agent',
                  rating: realTimeRating,
                  reviewsCount: realTimeReviewsCount,
                  location: data['address'] ?? '',
                  city: data['city'] ?? 'Unknown',
                  state: data['state'] ?? '',
                  latitude: (data['latitude'] ?? 0.0).toDouble(),
                  longitude: (data['longitude'] ?? 0.0).toDouble(),
                  portfolioImages: userData['portfolioImages'] ?? [],
                  certifications:
                      userData['certifications'] ??
                      ['Licensed Real Estate Agent'],
                  yearsOfExperience: userData['yearsOfExperience'] ?? 5,
                  isVerified: userData['isVerified'] ?? false,
                  isOnline: userData['isOnline'] ?? false,
                  availability: userData['availability'] ?? 'available',
                  pricing: userData['pricing'] ?? {},
                  serviceAreas: userData['serviceAreas'] ?? [],
                  createdAt:
                      userData['createdAt'] is Timestamp
                          ? (userData['createdAt'] as Timestamp).toDate()
                          : (userData['createdAt'] ?? DateTime.now()),
                  updatedAt:
                      userData['updatedAt'] is Timestamp
                          ? (userData['updatedAt'] as Timestamp).toDate()
                          : (userData['updatedAt'] ?? DateTime.now()),
                );

                allProviders.add(agentProvider);
              }
            } catch (e) {
              print('Error fetching agent details: $e');
            }
          }
        }
      }

      // Apply text search filter
      if (query != null && query.isNotEmpty) {
        final searchQuery = query.toLowerCase();
        allProviders =
            allProviders.where((provider) {
              return provider.name.toLowerCase().contains(searchQuery) ||
                  provider.primaryService.toLowerCase().contains(searchQuery) ||
                  provider.bio.toLowerCase().contains(searchQuery) ||
                  provider.serviceCategories.any(
                    (cat) => cat.toLowerCase().contains(searchQuery),
                  );
            }).toList();
      }

      // Apply location filter
      if (location != null && location.isNotEmpty) {
        final locationQuery = location.toLowerCase();
        allProviders =
            allProviders.where((provider) {
              return provider.city.toLowerCase().contains(locationQuery) ||
                  provider.state.toLowerCase().contains(locationQuery) ||
                  provider.location.toLowerCase().contains(locationQuery);
            }).toList();
      }

      return allProviders;
    } catch (e) {
      throw Exception('Failed to search service providers: $e');
    }
  }

  @override
  Future<ServiceProviderModel> getServiceProviderById(String id) async {
    try {
      final doc =
          await _firestore.collection('service_providers').doc(id).get();
      if (!doc.exists) {
        throw Exception('Service provider not found');
      }
      return ServiceProviderModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to fetch service provider: $e');
    }
  }

  @override
  Future<List<ServiceRequestModel>> getServiceRequests({
    String? customerId,
    String? providerId,
    ServiceRequestStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('service_requests');

      if (customerId != null) {
        query = query.where('customer_id', isEqualTo: customerId);
      }

      if (providerId != null) {
        query = query.where('provider_id', isEqualTo: providerId);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: _statusToString(status));
      }

      query = query.orderBy('created_at', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => ServiceRequestModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch service requests: $e');
    }
  }

  @override
  Future<ServiceRequestModel> createServiceRequest(
    ServiceRequestModel request,
  ) async {
    try {
      final docRef = await _firestore
          .collection('service_requests')
          .add(request.toJson());
      final doc = await docRef.get();
      return ServiceRequestModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to create service request: $e');
    }
  }

  @override
  Future<ServiceRequestModel> updateServiceRequest(
    ServiceRequestModel request,
  ) async {
    try {
      await _firestore
          .collection('service_requests')
          .doc(request.id)
          .update(request.toJson());
      return request;
    } catch (e) {
      throw Exception('Failed to update service request: $e');
    }
  }

  @override
  Future<void> deleteServiceRequest(String requestId) async {
    try {
      await _firestore.collection('service_requests').doc(requestId).delete();
    } catch (e) {
      throw Exception('Failed to delete service request: $e');
    }
  }

  @override
  Future<ServiceRequestModel> getServiceRequestById(String id) async {
    try {
      final doc = await _firestore.collection('service_requests').doc(id).get();
      if (!doc.exists) {
        throw Exception('Service request not found');
      }
      return ServiceRequestModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to fetch service request: $e');
    }
  }

  @override
  Future<void> rateServiceProvider({
    required String providerId,
    required String customerId,
    required double rating,
    String? review,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add review
      final reviewRef = _firestore.collection('service_reviews').doc();
      batch.set(reviewRef, {
        'provider_id': providerId,
        'customer_id': customerId,
        'rating': rating,
        'review': review,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Update provider's average rating
      final providerRef = _firestore
          .collection('service_providers')
          .doc(providerId);
      batch.update(providerRef, {
        'reviews_count': FieldValue.increment(1),
        'total_rating': FieldValue.increment(rating),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to rate service provider: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProviderReviews({
    required String providerId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('service_reviews')
              .where('provider_id', isEqualTo: providerId)
              .orderBy('created_at', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      throw Exception('Failed to fetch provider reviews: $e');
    }
  }

  String _statusToString(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.pending:
        return 'pending';
      case ServiceRequestStatus.accepted:
        return 'accepted';
      case ServiceRequestStatus.inProgress:
        return 'in_progress';
      case ServiceRequestStatus.completed:
        return 'completed';
      case ServiceRequestStatus.cancelled:
        return 'cancelled';
      case ServiceRequestStatus.rejected:
        return 'rejected';
    }
  }
}
