import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/property.dart';
import '../repositories/property_repository.dart';

class GetFeaturedPropertiesUseCase {
  final PropertyRepository repository;

  GetFeaturedPropertiesUseCase(this.repository);

  Future<Either<Failure, List<Property>>> call() async {
    return await repository.getFeaturedProperties();
  }
}
