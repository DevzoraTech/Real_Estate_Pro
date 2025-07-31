import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_provider.dart';
import '../repositories/service_repository.dart';

class GetServiceProvidersUseCase {
  final ServiceRepository repository;

  GetServiceProvidersUseCase(this.repository);

  Future<Either<Failure, List<ServiceProvider>>> call({
    int page = 1,
    int limit = 20,
  }) async {
    return await repository.getServiceProviders(page: page, limit: limit);
  }
}

class GetFeaturedProvidersUseCase {
  final ServiceRepository repository;

  GetFeaturedProvidersUseCase(this.repository);

  Future<Either<Failure, List<ServiceProvider>>> call({int limit = 10}) async {
    return await repository.getFeaturedProviders(limit: limit);
  }
}

class GetTopRatedProvidersUseCase {
  final ServiceRepository repository;

  GetTopRatedProvidersUseCase(this.repository);

  Future<Either<Failure, List<ServiceProvider>>> call({int limit = 10}) async {
    return await repository.getTopRatedProviders(limit: limit);
  }
}

class GetNearbyProvidersUseCase {
  final ServiceRepository repository;

  GetNearbyProvidersUseCase(this.repository);

  Future<Either<Failure, List<ServiceProvider>>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 10,
  }) async {
    return await repository.getNearbyProviders(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
    );
  }
}
