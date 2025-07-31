import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_provider.dart';
import '../entities/service_request.dart';

abstract class ServiceRepository {
  // Service Providers
  Future<Either<Failure, List<ServiceProvider>>> getServiceProviders({
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, List<ServiceProvider>>> getFeaturedProviders({
    int limit = 10,
  });

  Future<Either<Failure, List<ServiceProvider>>> getTopRatedProviders({
    int limit = 10,
  });

  Future<Either<Failure, List<ServiceProvider>>> getNearbyProviders({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 10,
  });

  Future<Either<Failure, List<ServiceProvider>>> searchServiceProviders({
    String? query,
    String? category,
    String? location,
    double? minRating,
    bool? isVerified,
    bool? isOnline,
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, ServiceProvider>> getServiceProviderById(String id);

  // Service Requests
  Future<Either<Failure, List<ServiceRequest>>> getServiceRequests({
    String? customerId,
    String? providerId,
    ServiceRequestStatus? status,
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, ServiceRequest>> createServiceRequest(
    ServiceRequest request,
  );

  Future<Either<Failure, ServiceRequest>> updateServiceRequest(
    ServiceRequest request,
  );

  Future<Either<Failure, void>> deleteServiceRequest(String requestId);

  Future<Either<Failure, ServiceRequest>> getServiceRequestById(String id);

  // Reviews and Ratings
  Future<Either<Failure, void>> rateServiceProvider({
    required String providerId,
    required String customerId,
    required double rating,
    String? review,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getProviderReviews({
    required String providerId,
    int page = 1,
    int limit = 10,
  });
}
