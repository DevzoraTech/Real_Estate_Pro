import 'package:equatable/equatable.dart';
import '../../domain/entities/service_provider.dart';
import '../../domain/entities/service_request.dart';

abstract class ServiceState extends Equatable {
  const ServiceState();

  @override
  List<Object?> get props => [];
}

class ServiceInitial extends ServiceState {
  const ServiceInitial();
}

class ServiceLoading extends ServiceState {
  const ServiceLoading();
}

class ServiceError extends ServiceState {
  final String message;

  const ServiceError(this.message);

  @override
  List<Object?> get props => [message];
}

// Service Provider States
class ServiceProvidersLoaded extends ServiceState {
  final List<ServiceProvider> providers;
  final bool hasReachedMax;
  final int currentPage;

  const ServiceProvidersLoaded({
    required this.providers,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [providers, hasReachedMax, currentPage];

  ServiceProvidersLoaded copyWith({
    List<ServiceProvider>? providers,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return ServiceProvidersLoaded(
      providers: providers ?? this.providers,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class FeaturedProvidersLoaded extends ServiceState {
  final List<ServiceProvider> providers;

  const FeaturedProvidersLoaded(this.providers);

  @override
  List<Object?> get props => [providers];
}

class TopRatedProvidersLoaded extends ServiceState {
  final List<ServiceProvider> providers;

  const TopRatedProvidersLoaded(this.providers);

  @override
  List<Object?> get props => [providers];
}

class NearbyProvidersLoaded extends ServiceState {
  final List<ServiceProvider> providers;

  const NearbyProvidersLoaded(this.providers);

  @override
  List<Object?> get props => [providers];
}

class ServiceProviderLoaded extends ServiceState {
  final ServiceProvider provider;

  const ServiceProviderLoaded(this.provider);

  @override
  List<Object?> get props => [provider];
}

class SearchResultsLoaded extends ServiceState {
  final List<ServiceProvider> providers;
  final String? query;
  final String? category;
  final bool hasReachedMax;
  final int currentPage;

  const SearchResultsLoaded({
    required this.providers,
    this.query,
    this.category,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [
    providers,
    query,
    category,
    hasReachedMax,
    currentPage,
  ];

  SearchResultsLoaded copyWith({
    List<ServiceProvider>? providers,
    String? query,
    String? category,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return SearchResultsLoaded(
      providers: providers ?? this.providers,
      query: query ?? this.query,
      category: category ?? this.category,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Service Request States
class ServiceRequestsLoaded extends ServiceState {
  final List<ServiceRequest> requests;
  final bool hasReachedMax;
  final int currentPage;

  const ServiceRequestsLoaded({
    required this.requests,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [requests, hasReachedMax, currentPage];

  ServiceRequestsLoaded copyWith({
    List<ServiceRequest>? requests,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return ServiceRequestsLoaded(
      requests: requests ?? this.requests,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class ServiceRequestLoaded extends ServiceState {
  final ServiceRequest request;

  const ServiceRequestLoaded(this.request);

  @override
  List<Object?> get props => [request];
}

class ServiceRequestCreated extends ServiceState {
  final ServiceRequest request;

  const ServiceRequestCreated(this.request);

  @override
  List<Object?> get props => [request];
}

class ServiceRequestUpdated extends ServiceState {
  final ServiceRequest request;

  const ServiceRequestUpdated(this.request);

  @override
  List<Object?> get props => [request];
}

class ServiceRequestDeleted extends ServiceState {
  final String requestId;

  const ServiceRequestDeleted(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

// Review States
class ProviderRated extends ServiceState {
  final String providerId;
  final double rating;

  const ProviderRated({required this.providerId, required this.rating});

  @override
  List<Object?> get props => [providerId, rating];
}

class ProviderReviewsLoaded extends ServiceState {
  final List<Map<String, dynamic>> reviews;
  final String providerId;

  const ProviderReviewsLoaded({
    required this.reviews,
    required this.providerId,
  });

  @override
  List<Object?> get props => [reviews, providerId];
}

// Combined State for Complex UI
class ServiceCombinedState extends ServiceState {
  final List<ServiceProvider>? allProviders;
  final List<ServiceProvider>? featuredProviders;
  final List<ServiceProvider>? topRatedProviders;
  final List<ServiceProvider>? nearbyProviders;
  final List<ServiceProvider>? searchResults;
  final List<ServiceRequest>? serviceRequests;
  final ServiceProvider? selectedProvider;
  final ServiceRequest? selectedRequest;
  final List<Map<String, dynamic>>? reviews;
  final bool isLoading;
  final String? error;

  const ServiceCombinedState({
    this.allProviders,
    this.featuredProviders,
    this.topRatedProviders,
    this.nearbyProviders,
    this.searchResults,
    this.serviceRequests,
    this.selectedProvider,
    this.selectedRequest,
    this.reviews,
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object?> get props => [
    allProviders,
    featuredProviders,
    topRatedProviders,
    nearbyProviders,
    searchResults,
    serviceRequests,
    selectedProvider,
    selectedRequest,
    reviews,
    isLoading,
    error,
  ];

  ServiceCombinedState copyWith({
    List<ServiceProvider>? allProviders,
    List<ServiceProvider>? featuredProviders,
    List<ServiceProvider>? topRatedProviders,
    List<ServiceProvider>? nearbyProviders,
    List<ServiceProvider>? searchResults,
    List<ServiceRequest>? serviceRequests,
    ServiceProvider? selectedProvider,
    ServiceRequest? selectedRequest,
    List<Map<String, dynamic>>? reviews,
    bool? isLoading,
    String? error,
  }) {
    return ServiceCombinedState(
      allProviders: allProviders ?? this.allProviders,
      featuredProviders: featuredProviders ?? this.featuredProviders,
      topRatedProviders: topRatedProviders ?? this.topRatedProviders,
      nearbyProviders: nearbyProviders ?? this.nearbyProviders,
      searchResults: searchResults ?? this.searchResults,
      serviceRequests: serviceRequests ?? this.serviceRequests,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedRequest: selectedRequest ?? this.selectedRequest,
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
