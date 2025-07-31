import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/service_provider_model.dart';
import '../models/service_request_model.dart';

abstract class ServiceLocalDataSource {
  Future<List<ServiceProviderModel>> getCachedServiceProviders();
  Future<void> cacheServiceProviders(List<ServiceProviderModel> providers);

  Future<List<ServiceProviderModel>> getCachedFeaturedProviders();
  Future<void> cacheFeaturedProviders(List<ServiceProviderModel> providers);

  Future<List<ServiceProviderModel>> getCachedTopRatedProviders();
  Future<void> cacheTopRatedProviders(List<ServiceProviderModel> providers);

  Future<ServiceProviderModel?> getCachedServiceProvider(String id);
  Future<void> cacheServiceProvider(ServiceProviderModel provider);

  Future<List<ServiceRequestModel>> getCachedServiceRequests();
  Future<void> cacheServiceRequests(List<ServiceRequestModel> requests);

  Future<void> clearCache();
}

class ServiceLocalDataSourceImpl implements ServiceLocalDataSource {
  final SharedPreferences sharedPreferences;

  ServiceLocalDataSourceImpl({required this.sharedPreferences});

  static const String _serviceProvidersKey = 'CACHED_SERVICE_PROVIDERS';
  static const String _featuredProvidersKey = 'CACHED_FEATURED_PROVIDERS';
  static const String _topRatedProvidersKey = 'CACHED_TOP_RATED_PROVIDERS';
  static const String _serviceRequestsKey = 'CACHED_SERVICE_REQUESTS';
  static const String _providerPrefix = 'CACHED_PROVIDER_';

  @override
  Future<List<ServiceProviderModel>> getCachedServiceProviders() async {
    try {
      final jsonString = sharedPreferences.getString(_serviceProvidersKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => ServiceProviderModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheServiceProviders(
    List<ServiceProviderModel> providers,
  ) async {
    try {
      final jsonList = providers.map((provider) => provider.toJson()).toList();
      await sharedPreferences.setString(
        _serviceProvidersKey,
        json.encode(jsonList),
      );
    } catch (e) {
      // Silently fail caching
    }
  }

  @override
  Future<List<ServiceProviderModel>> getCachedFeaturedProviders() async {
    try {
      final jsonString = sharedPreferences.getString(_featuredProvidersKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => ServiceProviderModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheFeaturedProviders(
    List<ServiceProviderModel> providers,
  ) async {
    try {
      final jsonList = providers.map((provider) => provider.toJson()).toList();
      await sharedPreferences.setString(
        _featuredProvidersKey,
        json.encode(jsonList),
      );
    } catch (e) {
      // Silently fail caching
    }
  }

  @override
  Future<List<ServiceProviderModel>> getCachedTopRatedProviders() async {
    try {
      final jsonString = sharedPreferences.getString(_topRatedProvidersKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => ServiceProviderModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheTopRatedProviders(
    List<ServiceProviderModel> providers,
  ) async {
    try {
      final jsonList = providers.map((provider) => provider.toJson()).toList();
      await sharedPreferences.setString(
        _topRatedProvidersKey,
        json.encode(jsonList),
      );
    } catch (e) {
      // Silently fail caching
    }
  }

  @override
  Future<ServiceProviderModel?> getCachedServiceProvider(String id) async {
    try {
      final jsonString = sharedPreferences.getString('$_providerPrefix$id');
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        return ServiceProviderModel.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheServiceProvider(ServiceProviderModel provider) async {
    try {
      await sharedPreferences.setString(
        '$_providerPrefix${provider.id}',
        json.encode(provider.toJson()),
      );
    } catch (e) {
      // Silently fail caching
    }
  }

  @override
  Future<List<ServiceRequestModel>> getCachedServiceRequests() async {
    try {
      final jsonString = sharedPreferences.getString(_serviceRequestsKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => ServiceRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheServiceRequests(List<ServiceRequestModel> requests) async {
    try {
      final jsonList = requests.map((request) => request.toJson()).toList();
      await sharedPreferences.setString(
        _serviceRequestsKey,
        json.encode(jsonList),
      );
    } catch (e) {
      // Silently fail caching
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await Future.wait([
        sharedPreferences.remove(_serviceProvidersKey),
        sharedPreferences.remove(_featuredProvidersKey),
        sharedPreferences.remove(_topRatedProvidersKey),
        sharedPreferences.remove(_serviceRequestsKey),
      ]);

      // Clear individual provider caches
      final keys = sharedPreferences.getKeys();
      final providerKeys = keys.where((key) => key.startsWith(_providerPrefix));
      await Future.wait(
        providerKeys.map((key) => sharedPreferences.remove(key)),
      );
    } catch (e) {
      // Silently fail cache clearing
    }
  }
}
