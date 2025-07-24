import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/properties/data/datasources/property_local_datasource.dart';
import '../../features/properties/data/datasources/property_remote_datasource.dart';
import '../../features/properties/data/repositories/property_repository_impl.dart';
import '../../features/properties/domain/repositories/property_repository.dart';
import '../../features/properties/domain/usecases/get_properties.dart';
import '../../features/properties/domain/usecases/get_featured_properties.dart';
import '../../features/properties/domain/usecases/search_properties.dart';
import '../../features/properties/presentation/bloc/property_bloc.dart';
import '../../features/properties/presentation/bloc/featured_property_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Properties
  // Bloc
  sl.registerFactory(
    () => PropertyBloc(
      getProperties: sl(),
      getFeaturedProperties: sl(),
      searchProperties: sl(),
      repository: sl(),
    ),
  );

  sl.registerFactory(() => FeaturedPropertyBloc(getFeaturedProperties: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetPropertiesUseCase(sl()));
  sl.registerLazySingleton(() => GetFeaturedPropertiesUseCase(sl()));
  sl.registerLazySingleton(() => SearchPropertiesUseCase(sl()));

  // Repository
  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<PropertyRemoteDataSource>(
    () => PropertyRemoteDataSourceImpl(),
  );

  sl.registerLazySingleton<PropertyLocalDataSource>(
    () => PropertyLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Core
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
