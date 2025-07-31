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
import '../../features/chat/data/services/chat_service.dart';
import '../../features/chat/data/services/notification_service.dart';
import '../../features/services/data/datasources/service_local_datasource.dart';
import '../../features/services/data/datasources/service_remote_datasource.dart';
import '../../features/services/data/repositories/service_repository_impl.dart';
import '../../features/services/domain/repositories/service_repository.dart';
import '../../features/services/domain/usecases/get_service_providers.dart';
import '../../features/services/domain/usecases/search_service_providers.dart';
import '../../features/services/domain/usecases/manage_service_requests.dart';
import '../../features/services/presentation/bloc/service_bloc.dart';

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

  //! Features - Services
  // Bloc
  sl.registerFactory(
    () => ServiceBloc(
      getServiceProviders: sl(),
      getFeaturedProviders: sl(),
      getTopRatedProviders: sl(),
      getNearbyProviders: sl(),
      searchServiceProviders: sl(),
      getServiceRequests: sl(),
      createServiceRequest: sl(),
      updateServiceRequest: sl(),
      getServiceRequestById: sl(),
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetServiceProvidersUseCase(sl()));
  sl.registerLazySingleton(() => GetFeaturedProvidersUseCase(sl()));
  sl.registerLazySingleton(() => GetTopRatedProvidersUseCase(sl()));
  sl.registerLazySingleton(() => GetNearbyProvidersUseCase(sl()));
  sl.registerLazySingleton(() => SearchServiceProvidersUseCase(sl()));
  sl.registerLazySingleton(() => GetServiceRequestsUseCase(sl()));
  sl.registerLazySingleton(() => CreateServiceRequestUseCase(sl()));
  sl.registerLazySingleton(() => UpdateServiceRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetServiceRequestByIdUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ServiceRepository>(
    () => ServiceRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ServiceRemoteDataSource>(
    () => ServiceRemoteDataSourceImpl(),
  );

  sl.registerLazySingleton<ServiceLocalDataSource>(
    () => ServiceLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Services
  // Initialize ChatService and NotificationService
  final chatService = ChatService();
  await chatService.initialize();
  sl.registerLazySingleton<ChatService>(() => chatService);

  // NotificationService is a singleton managed by ChatService
  sl.registerLazySingleton<NotificationService>(
    () => chatService.notificationService,
  );
}
