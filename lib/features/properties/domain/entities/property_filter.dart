import 'package:equatable/equatable.dart';

class PropertyFilter extends Equatable {
  final String? searchQuery;
  final String? type;
  final String? status;
  final double? minPrice;
  final double? maxPrice;
  final int? minBedrooms;
  final int? minBathrooms;
  final List<String>? amenities;
  final double? latitude;
  final double? longitude;
  final double? radius;
  final int page;
  final int limit;
  final String? sortBy;
  final String? sortOrder;

  const PropertyFilter({
    this.searchQuery,
    this.type,
    this.status,
    this.minPrice,
    this.maxPrice,
    this.minBedrooms,
    this.minBathrooms,
    this.amenities,
    this.latitude,
    this.longitude,
    this.radius,
    this.page = 1,
    this.limit = 20,
    this.sortBy,
    this.sortOrder = 'desc',
  });

  PropertyFilter copyWith({
    String? searchQuery,
    String? type,
    String? status,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? minBathrooms,
    List<String>? amenities,
    double? latitude,
    double? longitude,
    double? radius,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) {
    return PropertyFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      type: type ?? this.type,
      status: status ?? this.status,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      minBathrooms: minBathrooms ?? this.minBathrooms,
      amenities: amenities ?? this.amenities,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    searchQuery,
    type,
    status,
    minPrice,
    maxPrice,
    minBedrooms,
    minBathrooms,
    amenities,
    latitude,
    longitude,
    radius,
    page,
    limit,
    sortBy,
    sortOrder,
  ];
}
