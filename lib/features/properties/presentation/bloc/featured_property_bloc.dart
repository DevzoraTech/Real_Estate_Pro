import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/property.dart';
import '../../domain/usecases/get_featured_properties.dart';

// Events
abstract class FeaturedPropertyEvent extends Equatable {
  const FeaturedPropertyEvent();

  @override
  List<Object?> get props => [];
}

class LoadFeaturedProperties extends FeaturedPropertyEvent {}

// States
abstract class FeaturedPropertyState extends Equatable {
  const FeaturedPropertyState();

  @override
  List<Object?> get props => [];
}

class FeaturedPropertyInitial extends FeaturedPropertyState {}

class FeaturedPropertyLoading extends FeaturedPropertyState {}

class FeaturedPropertyLoaded extends FeaturedPropertyState {
  final List<Property> properties;

  const FeaturedPropertyLoaded({required this.properties});

  @override
  List<Object?> get props => [properties];
}

class FeaturedPropertyError extends FeaturedPropertyState {
  final String message;

  const FeaturedPropertyError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class FeaturedPropertyBloc
    extends Bloc<FeaturedPropertyEvent, FeaturedPropertyState> {
  final GetFeaturedPropertiesUseCase getFeaturedProperties;

  FeaturedPropertyBloc({required this.getFeaturedProperties})
    : super(FeaturedPropertyInitial()) {
    on<LoadFeaturedProperties>(_onLoadFeaturedProperties);
  }

  Future<void> _onLoadFeaturedProperties(
    LoadFeaturedProperties event,
    Emitter<FeaturedPropertyState> emit,
  ) async {
    emit(FeaturedPropertyLoading());

    final result = await getFeaturedProperties();

    result.fold(
      (failure) {
        print('Featured properties error: ${failure.message}');
        emit(FeaturedPropertyError(message: failure.message));
      },
      (properties) {
        print('Featured properties loaded: ${properties.length}');
        emit(FeaturedPropertyLoaded(properties: properties));
      },
    );
  }
}
