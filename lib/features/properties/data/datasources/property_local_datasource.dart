import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property_model.dart';

abstract class PropertyLocalDataSource {
  Future<List<PropertyModel>> getCachedProperties();
  Future<void> cacheProperties(List<PropertyModel> properties);
  Future<PropertyModel?> getCachedProperty(String id);
  Future<void> cacheProperty(PropertyModel property);
  Future<List<String>> getFavoritePropertyIds();
  Future<void> addToFavorites(String propertyId);
  Future<void> removeFromFavorites(String propertyId);
  Future<void> clearCache();
}

class PropertyLocalDataSourceImpl implements PropertyLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String cachedPropertiesKey = 'CACHED_PROPERTIES';
  static const String favoritePropertiesKey = 'FAVORITE_PROPERTIES';

  PropertyLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<PropertyModel>> getCachedProperties() async {
    final jsonString = sharedPreferences.getString(cachedPropertiesKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => PropertyModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> cacheProperties(List<PropertyModel> properties) async {
    final jsonList = properties.map((property) => property.toJson()).toList();
    await sharedPreferences.setString(
      cachedPropertiesKey,
      json.encode(jsonList),
    );
  }

  @override
  Future<PropertyModel?> getCachedProperty(String id) async {
    final properties = await getCachedProperties();
    try {
      return properties.firstWhere((property) => property.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheProperty(PropertyModel property) async {
    final properties = await getCachedProperties();
    final index = properties.indexWhere((p) => p.id == property.id);

    if (index != -1) {
      properties[index] = property;
    } else {
      properties.add(property);
    }

    await cacheProperties(properties);
  }

  @override
  Future<List<String>> getFavoritePropertyIds() async {
    final favoriteIds = sharedPreferences.getStringList(favoritePropertiesKey);
    return favoriteIds ?? [];
  }

  @override
  Future<void> addToFavorites(String propertyId) async {
    final favoriteIds = await getFavoritePropertyIds();
    if (!favoriteIds.contains(propertyId)) {
      favoriteIds.add(propertyId);
      await sharedPreferences.setStringList(favoritePropertiesKey, favoriteIds);
    }
  }

  @override
  Future<void> removeFromFavorites(String propertyId) async {
    final favoriteIds = await getFavoritePropertyIds();
    favoriteIds.remove(propertyId);
    await sharedPreferences.setStringList(favoritePropertiesKey, favoriteIds);
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(cachedPropertiesKey);
  }
}
