import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_provider.dart';
import '../repositories/service_repository.dart';

class SearchServiceProvidersParams {
  final String? query;
  final String? category;
  final String? location;
  final double? minRating;
  final bool? isVerified;
  final bool? isOnline;
  final int page;
  final int limit;

  const SearchServiceProvidersParams({
    this.query,
    this.category,
    this.location,
    this.minRating,
    this.isVerified,
    this.isOnline,
    this.page = 1,
    this.limit = 20,
  });
}

class SearchServiceProvidersUseCase {
  final ServiceRepository repository;

  SearchServiceProvidersUseCase(this.repository);

  Future<Either<Failure, List<ServiceProvider>>> call(
    SearchServiceProvidersParams params,
  ) async {
    return await repository.searchServiceProviders(
      query: params.query,
      category: params.category,
      location: params.location,
      minRating: params.minRating,
      isVerified: params.isVerified,
      isOnline: params.isOnline,
      page: params.page,
      limit: params.limit,
    );
  }
}
