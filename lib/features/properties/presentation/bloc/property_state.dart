import 'package:equatable/equatable.dart';
import '../../domain/entities/property.dart';

abstract class PropertyState extends Equatable {
  const PropertyState();

  @override
  List<Object?> get props => [];
}

class PropertyInitial extends PropertyState {}

class PropertyLoading extends PropertyState {}

class PropertyLoaded extends PropertyState {
  final List<Property> properties;
  final bool hasReachedMax;

  const PropertyLoaded({required this.properties, this.hasReachedMax = false});

  PropertyLoaded copyWith({List<Property>? properties, bool? hasReachedMax}) {
    return PropertyLoaded(
      properties: properties ?? this.properties,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [properties, hasReachedMax];
}

class PropertyError extends PropertyState {
  final String message;

  const PropertyError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PropertyDetailLoading extends PropertyState {}

class PropertyDetailLoaded extends PropertyState {
  final Property property;

  const PropertyDetailLoaded({required this.property});

  @override
  List<Object?> get props => [property];
}

class PropertyDetailError extends PropertyState {
  final String message;

  const PropertyDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}

class FeaturedPropertiesLoading extends PropertyState {}

class FeaturedPropertiesLoaded extends PropertyState {
  final List<Property> featuredProperties;

  const FeaturedPropertiesLoaded({required this.featuredProperties});

  @override
  List<Object?> get props => [featuredProperties];
}

class FeaturedPropertiesError extends PropertyState {
  final String message;

  const FeaturedPropertiesError({required this.message});

  @override
  List<Object?> get props => [message];
}

class SearchPropertiesLoading extends PropertyState {}

class SearchPropertiesLoaded extends PropertyState {
  final List<Property> searchResults;
  final String query;

  const SearchPropertiesLoaded({
    required this.searchResults,
    required this.query,
  });

  @override
  List<Object?> get props => [searchResults, query];
}

class SearchPropertiesError extends PropertyState {
  final String message;

  const SearchPropertiesError({required this.message});

  @override
  List<Object?> get props => [message];
}
