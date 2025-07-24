import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_filter.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/property_local_datasource.dart';
import '../datasources/property_remote_datasource.dart';
import '../models/property_model.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyRemoteDataSource remoteDataSource;
  final PropertyLocalDataSource localDataSource;

  PropertyRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Property>>> getProperties(
    PropertyFilter filter,
  ) async {
    try {
      final remoteProperties = await remoteDataSource.getProperties(filter);

      // Cache the properties locally
      await localDataSource.cacheProperties(remoteProperties);

      return Right(remoteProperties);
    } catch (e) {
      // If remote fails, try to get cached properties
      try {
        final cachedProperties = await localDataSource.getCachedProperties();
        if (cachedProperties.isNotEmpty) {
          return Right(cachedProperties);
        }
        return Left(
          NetworkFailure('Failed to load properties: ${e.toString()}'),
        );
      } catch (cacheError) {
        return Left(
          CacheFailure(
            'Failed to load cached properties: ${cacheError.toString()}',
          ),
        );
      }
    }
  }

  @override
  Future<Either<Failure, Property>> getPropertyById(String id) async {
    try {
      // Try to get from cache first
      final cachedProperty = await localDataSource.getCachedProperty(id);
      if (cachedProperty != null) {
        return Right(cachedProperty);
      }

      // If not in cache, get from remote
      final remoteProperty = await remoteDataSource.getPropertyById(id);

      // Cache the property
      await localDataSource.cacheProperty(remoteProperty);

      return Right(remoteProperty);
    } catch (e) {
      return Left(ServerFailure('Failed to load property: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Property>>> getFeaturedProperties() async {
    try {
      final featuredProperties = await remoteDataSource.getFeaturedProperties();
      return Right(featuredProperties);
    } catch (e) {
      // Try to get cached properties and filter featured ones
      try {
        final cachedProperties = await localDataSource.getCachedProperties();
        final featuredCached =
            cachedProperties.where((p) => p.isFeatured).toList();
        if (featuredCached.isNotEmpty) {
          return Right(featuredCached);
        }
        return Left(
          NetworkFailure('Failed to load featured properties: ${e.toString()}'),
        );
      } catch (cacheError) {
        return Left(
          CacheFailure(
            'Failed to load cached featured properties: ${cacheError.toString()}',
          ),
        );
      }
    }
  }

  @override
  Future<Either<Failure, List<Property>>> searchProperties(String query) async {
    try {
      final searchResults = await remoteDataSource.searchProperties(query);
      return Right(searchResults);
    } catch (e) {
      return Left(
        ServerFailure('Failed to search properties: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> addToFavorites(String propertyId) async {
    try {
      await localDataSource.addToFavorites(propertyId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to add to favorites: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromFavorites(String propertyId) async {
    try {
      await localDataSource.removeFromFavorites(propertyId);
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Failed to remove from favorites: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Property>>> getFavoriteProperties() async {
    try {
      final favoriteIds = await localDataSource.getFavoritePropertyIds();
      final cachedProperties = await localDataSource.getCachedProperties();

      final favoriteProperties =
          cachedProperties
              .where((property) => favoriteIds.contains(property.id))
              .toList();

      return Right(favoriteProperties);
    } catch (e) {
      return Left(
        CacheFailure('Failed to load favorite properties: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Property>> createProperty(Property property) async {
    try {
      final propertyModel = PropertyModel.fromEntity(property);
      final createdProperty = await remoteDataSource.createProperty(
        propertyModel,
      );

      // Cache the new property
      await localDataSource.cacheProperty(createdProperty);

      return Right(createdProperty);
    } catch (e) {
      return Left(ServerFailure('Failed to create property: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Property>> updateProperty(Property property) async {
    try {
      final propertyModel = PropertyModel.fromEntity(property);
      final updatedProperty = await remoteDataSource.updateProperty(
        propertyModel,
      );

      // Update cache
      await localDataSource.cacheProperty(updatedProperty);

      return Right(updatedProperty);
    } catch (e) {
      return Left(ServerFailure('Failed to update property: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProperty(String id) async {
    try {
      await remoteDataSource.deleteProperty(id);

      // Remove from cache
      final cachedProperties = await localDataSource.getCachedProperties();
      final updatedProperties =
          cachedProperties.where((p) => p.id != id).toList();
      await localDataSource.cacheProperties(updatedProperties);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete property: ${e.toString()}'));
    }
  }
}
