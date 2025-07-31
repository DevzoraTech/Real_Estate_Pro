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
      final query = _firestore
          .collection('service_providers')
          .orderBy('created_at', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) =>
                ServiceProviderModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch service providers: $e');
    }
  }

  @override
  Future<List<ServiceProviderModel>> getFeaturedProviders({
    int limit = 10,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('service_providers')
              .where('is_featured', isEqualTo: true)
              .orderBy('rating', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                ServiceProviderModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured providers: $e');
    }
  }

  @override
  Future<List<ServiceProviderModel>> getTopRatedProviders({
    int limit = 10,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('service_providers')
              .where('rating', isGreaterThanOrEqualTo: 4.0)
              .orderBy('rating', descending: true)
              .orderBy('reviews_count', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                ServiceProviderModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .toList();
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
      // For now, we'll use a simple bounding box approach
      // In production, consider using GeoFlutterFire for more accurate geospatial queries
      final latRange = radiusKm / 111.0; // Rough conversion: 1 degree ≈ 111 km
      final lngRange = radiusKm / (111.0 * cos(latitude * pi / 180));

      final snapshot =
          await _firestore
              .collection('service_providers')
              .where('latitude', isGreaterThan: latitude - latRange)
              .where('latitude', isLessThan: latitude + latRange)
              .limit(limit * 2) // Get more to filter by longitude
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
      List<ServiceProviderModel> providers =
          snapshot.docs
              .map(
                (doc) => ServiceProviderModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }),
              )
              .toList();

      // Apply text search filter (client-side for now)
      if (query != null && query.isNotEmpty) {
        final searchQuery = query.toLowerCase();
        providers =
            providers.where((provider) {
              return provider.name.toLowerCase().contains(searchQuery) ||
                  provider.primaryService.toLowerCase().contains(searchQuery) ||
                  provider.bio.toLowerCase().contains(searchQuery) ||
                  provider.serviceCategories.any(
                    (cat) => cat.toLowerCase().contains(searchQuery),
                  );
            }).toList();
      }

      // Apply location filter (client-side for now)
      if (location != null && location.isNotEmpty) {
        final locationQuery = location.toLowerCase();
        providers =
            providers.where((provider) {
              return provider.city.toLowerCase().contains(locationQuery) ||
                  provider.state.toLowerCase().contains(locationQuery) ||
                  provider.location.toLowerCase().contains(locationQuery);
            }).toList();
      }

      return providers;
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
