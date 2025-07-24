import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/property.dart';
import '../repositories/property_repository.dart';

class SearchPropertiesUseCase {
  final PropertyRepository repository;

  SearchPropertiesUseCase(this.repository);

  Future<Either<Failure, List<Property>>> call(String query) async {
    if (query.trim().isEmpty) {
      return const Left(ValidationFailure('Search query cannot be empty'));
    }
    return await repository.searchProperties(query);
  }
}
