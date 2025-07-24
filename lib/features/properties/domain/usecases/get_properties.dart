import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/property.dart';
import '../entities/property_filter.dart';
import '../repositories/property_repository.dart';

class GetPropertiesUseCase {
  final PropertyRepository repository;

  GetPropertiesUseCase(this.repository);

  Future<Either<Failure, List<Property>>> call(PropertyFilter filter) async {
    return await repository.getProperties(filter);
  }
}
