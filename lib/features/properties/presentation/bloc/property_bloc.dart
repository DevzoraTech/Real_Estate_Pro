import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_properties.dart';
import '../../domain/usecases/get_featured_properties.dart';
import '../../domain/usecases/search_properties.dart';
import '../../domain/repositories/property_repository.dart';
import 'property_event.dart';
import 'property_state.dart';

class PropertyBloc extends Bloc<PropertyEvent, PropertyState> {
  final GetPropertiesUseCase getProperties;
  final GetFeaturedPropertiesUseCase getFeaturedProperties;
  final SearchPropertiesUseCase searchProperties;
  final PropertyRepository repository;

  PropertyBloc({
    required this.getProperties,
    required this.getFeaturedProperties,
    required this.searchProperties,
    required this.repository,
  }) : super(PropertyInitial()) {
    on<LoadProperties>(_onLoadProperties);
    on<LoadFeaturedProperties>(_onLoadFeaturedProperties);
    on<LoadPropertyById>(_onLoadPropertyById);
    on<SearchProperties>(_onSearchProperties);
    on<RefreshProperties>(_onRefreshProperties);
    on<LoadMoreProperties>(_onLoadMoreProperties);
  }

  Future<void> _onLoadProperties(
    LoadProperties event,
    Emitter<PropertyState> emit,
  ) async {
    emit(PropertyLoading());

    final result = await getProperties(event.filter);

    result.fold(
      (failure) => emit(PropertyError(message: failure.message)),
      (properties) => emit(
        PropertyLoaded(
          properties: properties,
          hasReachedMax: properties.length < event.filter.limit,
        ),
      ),
    );
  }

  Future<void> _onLoadFeaturedProperties(
    LoadFeaturedProperties event,
    Emitter<PropertyState> emit,
  ) async {
    emit(FeaturedPropertiesLoading());

    final result = await getFeaturedProperties();

    result.fold(
      (failure) => emit(FeaturedPropertiesError(message: failure.message)),
      (properties) =>
          emit(FeaturedPropertiesLoaded(featuredProperties: properties)),
    );
  }

  Future<void> _onLoadPropertyById(
    LoadPropertyById event,
    Emitter<PropertyState> emit,
  ) async {
    emit(PropertyDetailLoading());

    final result = await repository.getPropertyById(event.propertyId);

    result.fold(
      (failure) => emit(PropertyDetailError(message: failure.message)),
      (property) => emit(PropertyDetailLoaded(property: property)),
    );
  }

  Future<void> _onSearchProperties(
    SearchProperties event,
    Emitter<PropertyState> emit,
  ) async {
    emit(SearchPropertiesLoading());

    final result = await searchProperties(event.query);

    result.fold(
      (failure) => emit(SearchPropertiesError(message: failure.message)),
      (properties) => emit(
        SearchPropertiesLoaded(searchResults: properties, query: event.query),
      ),
    );
  }

  Future<void> _onRefreshProperties(
    RefreshProperties event,
    Emitter<PropertyState> emit,
  ) async {
    final result = await getProperties(event.filter);

    result.fold(
      (failure) => emit(PropertyError(message: failure.message)),
      (properties) => emit(
        PropertyLoaded(
          properties: properties,
          hasReachedMax: properties.length < event.filter.limit,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreProperties(
    LoadMoreProperties event,
    Emitter<PropertyState> emit,
  ) async {
    final currentState = state;
    if (currentState is PropertyLoaded && !currentState.hasReachedMax) {
      final result = await getProperties(event.filter);

      result.fold((failure) => emit(PropertyError(message: failure.message)), (
        newProperties,
      ) {
        final allProperties = List.of(currentState.properties)
          ..addAll(newProperties);
        emit(
          PropertyLoaded(
            properties: allProperties,
            hasReachedMax: newProperties.length < event.filter.limit,
          ),
        );
      });
    }
  }
}
