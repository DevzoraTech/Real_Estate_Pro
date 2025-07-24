import 'package:equatable/equatable.dart';
import '../../domain/entities/property_filter.dart';

abstract class PropertyEvent extends Equatable {
  const PropertyEvent();

  @override
  List<Object?> get props => [];
}

class LoadProperties extends PropertyEvent {
  final PropertyFilter filter;

  const LoadProperties({required this.filter});

  @override
  List<Object?> get props => [filter];
}

class LoadFeaturedProperties extends PropertyEvent {}

class LoadPropertyById extends PropertyEvent {
  final String propertyId;

  const LoadPropertyById({required this.propertyId});

  @override
  List<Object?> get props => [propertyId];
}

class SearchProperties extends PropertyEvent {
  final String query;

  const SearchProperties({required this.query});

  @override
  List<Object?> get props => [query];
}

class RefreshProperties extends PropertyEvent {
  final PropertyFilter filter;

  const RefreshProperties({required this.filter});

  @override
  List<Object?> get props => [filter];
}

class LoadMoreProperties extends PropertyEvent {
  final PropertyFilter filter;

  const LoadMoreProperties({required this.filter});

  @override
  List<Object?> get props => [filter];
}
