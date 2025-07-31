import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_service_providers.dart';
import '../../domain/usecases/search_service_providers.dart';
import '../../domain/usecases/manage_service_requests.dart';
import '../../domain/repositories/service_repository.dart';
import 'service_event.dart';
import 'service_state.dart';

class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final GetServiceProvidersUseCase getServiceProviders;
  final GetFeaturedProvidersUseCase getFeaturedProviders;
  final GetTopRatedProvidersUseCase getTopRatedProviders;
  final GetNearbyProvidersUseCase getNearbyProviders;
  final SearchServiceProvidersUseCase searchServiceProviders;
  final GetServiceRequestsUseCase getServiceRequests;
  final CreateServiceRequestUseCase createServiceRequest;
  final UpdateServiceRequestUseCase updateServiceRequest;
  final GetServiceRequestByIdUseCase getServiceRequestById;
  final ServiceRepository repository;

  ServiceBloc({
    required this.getServiceProviders,
    required this.getFeaturedProviders,
    required this.getTopRatedProviders,
    required this.getNearbyProviders,
    required this.searchServiceProviders,
    required this.getServiceRequests,
    required this.createServiceRequest,
    required this.updateServiceRequest,
    required this.getServiceRequestById,
    required this.repository,
  }) : super(const ServiceInitial()) {
    on<LoadServiceProviders>(_onLoadServiceProviders);
    on<LoadFeaturedProviders>(_onLoadFeaturedProviders);
    on<LoadTopRatedProviders>(_onLoadTopRatedProviders);
    on<LoadNearbyProviders>(_onLoadNearbyProviders);
    on<SearchServiceProviders>(_onSearchServiceProviders);
    on<LoadServiceProviderById>(_onLoadServiceProviderById);
    on<LoadServiceRequests>(_onLoadServiceRequests);
    on<CreateServiceRequest>(_onCreateServiceRequest);
    on<UpdateServiceRequest>(_onUpdateServiceRequest);
    on<DeleteServiceRequest>(_onDeleteServiceRequest);
    on<LoadServiceRequestById>(_onLoadServiceRequestById);
    on<RateServiceProvider>(_onRateServiceProvider);
    on<LoadProviderReviews>(_onLoadProviderReviews);
    on<RefreshServices>(_onRefreshServices);
    on<ClearServiceCache>(_onClearServiceCache);
  }

  Future<void> _onLoadServiceProviders(
    LoadServiceProviders event,
    Emitter<ServiceState> emit,
  ) async {
    if (event.page == 1) {
      emit(const ServiceLoading());
    }

    final result = await getServiceProviders(
      page: event.page,
      limit: event.limit,
    );

    result.fold((failure) => emit(ServiceError(failure.message)), (providers) {
      if (state is ServiceProvidersLoaded && event.page > 1) {
        final currentState = state as ServiceProvidersLoaded;
        final updatedProviders = List.of(currentState.providers)
          ..addAll(providers);
        emit(
          ServiceProvidersLoaded(
            providers: updatedProviders,
            hasReachedMax: providers.length < event.limit,
            currentPage: event.page,
          ),
        );
      } else {
        emit(
          ServiceProvidersLoaded(
            providers: providers,
            hasReachedMax: providers.length < event.limit,
            currentPage: event.page,
          ),
        );
      }
    });
  }

  Future<void> _onLoadFeaturedProviders(
    LoadFeaturedProviders event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());

    final result = await getFeaturedProviders(limit: event.limit);

    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (providers) => emit(FeaturedProvidersLoaded(providers)),
    );
  }

  Future<void> _onLoadTopRatedProviders(
    LoadTopRatedProviders event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());

    final result = await getTopRatedProviders(limit: event.limit);

    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (providers) => emit(TopRatedProvidersLoaded(providers)),
    );
  }

  Future<void> _onLoadNearbyProviders(
    LoadNearbyProviders event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());

    final result = await getNearbyProviders(
      latitude: event.latitude,
      longitude: event.longitude,
      radiusKm: event.radiusKm,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (providers) => emit(NearbyProvidersLoaded(providers)),
    );
  }

  Future<void> _onSearchServiceProviders(
    SearchServiceProviders event,
    Emitter<ServiceState> emit,
  ) async {
    if (event.page == 1) {
      emit(const ServiceLoading());
    }

    final params = SearchServiceProvidersParams(
      query: event.query,
      category: event.category,
      location: event.location,
      minRating: event.minRating,
      isVerified: event.isVerified,
      isOnline: event.isOnline,
      page: event.page,
      limit: event.limit,
    );

    final result = await searchServiceProviders(params);

    result.fold((failure) => emit(ServiceError(failure.message)), (providers) {
      if (state is SearchResultsLoaded && event.page > 1) {
        final currentState = state as SearchResultsLoaded;
        final updatedProviders = List.of(currentState.providers)
          ..addAll(providers);
        emit(
          SearchResultsLoaded(
            providers: updatedProviders,
            query: event.query,
            category: event.category,
            hasReachedMax: providers.length < event.limit,
            currentPage: event.page,
          ),
        );
      } else {
        emit(
          SearchResultsLoaded(
            providers: providers,
            query: event.query,
            category: event.category,
            hasReachedMax: providers.length < event.limit,
            currentPage: event.page,
          ),
        );
      }
    });
  }

  Future<void> _onLoadServiceProviderById(
    LoadServiceProviderById event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());

    final result = await repository.getServiceProviderById(event.id);

    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (provider) => emit(ServiceProviderLoaded(provider)),
    );
  }

  Future<void> _onLoadServiceRequests(
    LoadServiceRequests event,
    Emitter<ServiceState> emit,
  ) async {
    if (event.page == 1) {
      emit(const ServiceLoading());
    }

    final params = GetServiceRequestsParams(
      customerId: event.customerId,
      providerId: event.providerId,
      status: event.status,
      page: event.page,
      limit: event.limit,
    );

    final result = await getServiceRequests(params);

    result.fold((failure) => emit(ServiceError(failure.message)), (requests) {
      if (state is ServiceRequestsLoaded && event.page > 1) {
        final currentState = state as ServiceRequestsLoaded;
        final updatedRequests = List.of(currentState.requests)
          ..addAll(requests);
        emit(
          ServiceRequestsLoaded(
            requests: updatedRequests,
            hasReachedMax: requests.length < event.limit,
            currentPage: event.page,
          ),
        );
      } else {
        emit(
          ServiceRequestsLoaded(
            requests: requests,
            hasReachedMax: requests.length < event.limit,
            currentPage: event.page,
          ),
        );
      }
    });
  }

  Future<void> _onCreateServiceRequest(
    CreateServiceRequest event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());

    final result = await createServiceRequest(event.request);

    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (request) => emit(ServiceRequestCreated(request)),
    );
  }

  Future<void> _onUpdateServiceRequest(
    UpdateServiceRequest event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());

    final result = await updateServiceRequest(event.request);

    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (request) => emit(ServiceRequestUpdated(request)),
    );
  }

  Future<void> _onDeleteServiceRequest(
    DeleteServiceRequest event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());

    final result = await repository.deleteServiceRequest(event.requestId);

    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (_) => emit(ServiceRequestDeleted(event.requestId)),
    );
  }

  Future<void> _onLoadServiceRequestById(
    LoadServiceRequestById event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());

    final result = await getServiceRequestById(event.id);

    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (request) => emit(ServiceRequestLoaded(request)),
    );
  }

  Future<void> _onRateServiceProvider(
    RateServiceProvider event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());

    final result = await repository.rateServiceProvider(
      providerId: event.providerId,
      customerId: event.customerId,
      rating: event.rating,
      review: event.review,
    );

    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (_) => emit(
        ProviderRated(providerId: event.providerId, rating: event.rating),
      ),
    );
  }

  Future<void> _onLoadProviderReviews(
    LoadProviderReviews event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());

    final result = await repository.getProviderReviews(
      providerId: event.providerId,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (reviews) => emit(
        ProviderReviewsLoaded(reviews: reviews, providerId: event.providerId),
      ),
    );
  }

  Future<void> _onRefreshServices(
    RefreshServices event,
    Emitter<ServiceState> emit,
  ) async {
    // Reload the current data
    if (state is ServiceProvidersLoaded) {
      add(const LoadServiceProviders(page: 1));
    } else if (state is FeaturedProvidersLoaded) {
      add(const LoadFeaturedProviders());
    } else if (state is TopRatedProvidersLoaded) {
      add(const LoadTopRatedProviders());
    } else if (state is SearchResultsLoaded) {
      final currentState = state as SearchResultsLoaded;
      add(
        SearchServiceProviders(
          query: currentState.query,
          category: currentState.category,
          page: 1,
        ),
      );
    }
  }

  Future<void> _onClearServiceCache(
    ClearServiceCache event,
    Emitter<ServiceState> emit,
  ) async {
    // This would typically clear local cache
    // For now, just reset to initial state
    emit(const ServiceInitial());
  }
}
