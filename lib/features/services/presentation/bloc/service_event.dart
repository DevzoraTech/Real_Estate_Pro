import 'package:equatable/equatable.dart';
import '../../domain/entities/service_request.dart';

abstract class ServiceEvent extends Equatable {
  const ServiceEvent();

  @override
  List<Object?> get props => [];
}

// Service Provider Events
class LoadServiceProviders extends ServiceEvent {
  final int page;
  final int limit;

  const LoadServiceProviders({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}

class LoadFeaturedProviders extends ServiceEvent {
  final int limit;

  const LoadFeaturedProviders({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class LoadTopRatedProviders extends ServiceEvent {
  final int limit;

  const LoadTopRatedProviders({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class LoadNearbyProviders extends ServiceEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final int limit;

  const LoadNearbyProviders({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 50.0,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm, limit];
}

class SearchServiceProviders extends ServiceEvent {
  final String? query;
  final String? category;
  final String? location;
  final double? minRating;
  final bool? isVerified;
  final bool? isOnline;
  final int page;
  final int limit;

  const SearchServiceProviders({
    this.query,
    this.category,
    this.location,
    this.minRating,
    this.isVerified,
    this.isOnline,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [
    query,
    category,
    location,
    minRating,
    isVerified,
    isOnline,
    page,
    limit,
  ];
}

class LoadServiceProviderById extends ServiceEvent {
  final String id;

  const LoadServiceProviderById(this.id);

  @override
  List<Object?> get props => [id];
}

// Service Request Events
class LoadServiceRequests extends ServiceEvent {
  final String? customerId;
  final String? providerId;
  final ServiceRequestStatus? status;
  final int page;
  final int limit;

  const LoadServiceRequests({
    this.customerId,
    this.providerId,
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [customerId, providerId, status, page, limit];
}

class CreateServiceRequest extends ServiceEvent {
  final ServiceRequest request;

  const CreateServiceRequest(this.request);

  @override
  List<Object?> get props => [request];
}

class UpdateServiceRequest extends ServiceEvent {
  final ServiceRequest request;

  const UpdateServiceRequest(this.request);

  @override
  List<Object?> get props => [request];
}

class DeleteServiceRequest extends ServiceEvent {
  final String requestId;

  const DeleteServiceRequest(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class LoadServiceRequestById extends ServiceEvent {
  final String id;

  const LoadServiceRequestById(this.id);

  @override
  List<Object?> get props => [id];
}

// Rating and Review Events
class RateServiceProvider extends ServiceEvent {
  final String providerId;
  final String customerId;
  final double rating;
  final String? review;

  const RateServiceProvider({
    required this.providerId,
    required this.customerId,
    required this.rating,
    this.review,
  });

  @override
  List<Object?> get props => [providerId, customerId, rating, review];
}

class LoadProviderReviews extends ServiceEvent {
  final String providerId;
  final int page;
  final int limit;

  const LoadProviderReviews({
    required this.providerId,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [providerId, page, limit];
}

// Utility Events
class RefreshServices extends ServiceEvent {
  const RefreshServices();
}

class ClearServiceCache extends ServiceEvent {
  const ClearServiceCache();
}
