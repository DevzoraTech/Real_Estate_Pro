import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/property.dart';
import '../entities/property_filter.dart';

abstract class PropertyRepository {
  Future<Either<Failure, List<Property>>> getProperties(PropertyFilter filter);
  Future<Either<Failure, Property>> getPropertyById(String id);
  Future<Either<Failure, List<Property>>> getFeaturedProperties();
  Future<Either<Failure, List<Property>>> searchProperties(String query);
  Future<Either<Failure, void>> addToFavorites(String propertyId);
  Future<Either<Failure, void>> removeFromFavorites(String propertyId);
  Future<Either<Failure, List<Property>>> getFavoriteProperties();
  Future<Either<Failure, Property>> createProperty(Property property);
  Future<Either<Failure, Property>> updateProperty(Property property);
  Future<Either<Failure, void>> deleteProperty(String id);
}
