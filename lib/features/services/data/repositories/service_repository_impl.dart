import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/service_provider.dart';
import '../../domain/entities/service_request.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_remote_datasource.dart';
import '../datasources/service_local_datasource.dart';
import '../models/service_request_model.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;
  final ServiceLocalDataSource localDataSource;

  ServiceRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<ServiceProvider>>> getServiceProviders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final providers = await remoteDataSource.getServiceProviders(
        page: page,
        limit: limit,
      );

      // Cache the results
      await localDataSource.cacheServiceProviders(providers);

      return Right(providers);
    } catch (e) {
      // Try to get cached data on failure
      try {
        final cachedProviders =
            await localDataSource.getCachedServiceProviders();
        if (cachedProviders.isNotEmpty) {
          return Right(cachedProviders);
        }
      } catch (_) {}

      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceProvider>>> getFeaturedProviders({
    int limit = 10,
  }) async {
    try {
      final providers = await remoteDataSource.getFeaturedProviders(
        limit: limit,
      );

      // Cache the results
      await localDataSource.cacheFeaturedProviders(providers);

      return Right(providers);
    } catch (e) {
      // Try to get cached data on failure
      try {
        final cachedProviders =
            await localDataSource.getCachedFeaturedProviders();
        if (cachedProviders.isNotEmpty) {
          return Right(cachedProviders);
        }
      } catch (_) {}

      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceProvider>>> getTopRatedProviders({
    int limit = 10,
  }) async {
    try {
      final providers = await remoteDataSource.getTopRatedProviders(
        limit: limit,
      );

      // Cache the results
      await localDataSource.cacheTopRatedProviders(providers);

      return Right(providers);
    } catch (e) {
      // Try to get cached data on failure
      try {
        final cachedProviders =
            await localDataSource.getCachedTopRatedProviders();
        if (cachedProviders.isNotEmpty) {
          return Right(cachedProviders);
        }
      } catch (_) {}

      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceProvider>>> getNearbyProviders({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 10,
  }) async {
    try {
      final providers = await remoteDataSource.getNearbyProviders(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );

      return Right(providers);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceProvider>>> searchServiceProviders({
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
      final providers = await remoteDataSource.searchServiceProviders(
        query: query,
        category: category,
        location: location,
        minRating: minRating,
        isVerified: isVerified,
        isOnline: isOnline,
        page: page,
        limit: limit,
      );

      return Right(providers);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceProvider>> getServiceProviderById(
    String id,
  ) async {
    try {
      final provider = await remoteDataSource.getServiceProviderById(id);

      // Cache the individual provider
      await localDataSource.cacheServiceProvider(provider);

      return Right(provider);
    } catch (e) {
      // Try to get cached data on failure
      try {
        final cachedProvider = await localDataSource.getCachedServiceProvider(
          id,
        );
        if (cachedProvider != null) {
          return Right(cachedProvider);
        }
      } catch (_) {}

      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceRequest>>> getServiceRequests({
    String? customerId,
    String? providerId,
    ServiceRequestStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final requests = await remoteDataSource.getServiceRequests(
        customerId: customerId,
        providerId: providerId,
        status: status,
        page: page,
        limit: limit,
      );

      // Cache the results
      await localDataSource.cacheServiceRequests(requests);

      return Right(requests);
    } catch (e) {
      // Try to get cached data on failure
      try {
        final cachedRequests = await localDataSource.getCachedServiceRequests();
        if (cachedRequests.isNotEmpty) {
          return Right(cachedRequests);
        }
      } catch (_) {}

      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceRequest>> createServiceRequest(
    ServiceRequest request,
  ) async {
    try {
      final requestModel = ServiceRequestModel.fromEntity(request);
      final createdRequest = await remoteDataSource.createServiceRequest(
        requestModel,
      );

      return Right(createdRequest);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceRequest>> updateServiceRequest(
    ServiceRequest request,
  ) async {
    try {
      final requestModel = ServiceRequestModel.fromEntity(request);
      final updatedRequest = await remoteDataSource.updateServiceRequest(
        requestModel,
      );

      return Right(updatedRequest);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteServiceRequest(String requestId) async {
    try {
      await remoteDataSource.deleteServiceRequest(requestId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceRequest>> getServiceRequestById(
    String id,
  ) async {
    try {
      final request = await remoteDataSource.getServiceRequestById(id);
      return Right(request);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rateServiceProvider({
    required String providerId,
    required String customerId,
    required double rating,
    String? review,
  }) async {
    try {
      await remoteDataSource.rateServiceProvider(
        providerId: providerId,
        customerId: customerId,
        rating: rating,
        review: review,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getProviderReviews({
    required String providerId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final reviews = await remoteDataSource.getProviderReviews(
        providerId: providerId,
        page: page,
        limit: limit,
      );
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
