import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  Position? _currentPosition;
  String? _currentAddress;
  DateTime? _lastLocationUpdate;

  // Cache location for 10 minutes to avoid excessive GPS usage
  static const Duration _locationCacheTimeout = Duration(minutes: 10);

  /// Get current position with caching
  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    // Return cached position if still valid and not forcing refresh
    if (!forceRefresh && 
        _currentPosition != null && 
        _lastLocationUpdate != null &&
        DateTime.now().difference(_lastLocationUpdate!) < _locationCacheTimeout) {
      return _currentPosition;
    }

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lastLocationUpdate = DateTime.now();

      return _currentPosition;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get current address from coordinates
  Future<String?> getCurrentAddress({bool forceRefresh = false}) async {
    // Return cached address if still valid and not forcing refresh
    if (!forceRefresh && 
        _currentAddress != null && 
        _lastLocationUpdate != null &&
        DateTime.now().difference(_lastLocationUpdate!) < _locationCacheTimeout) {
      return _currentAddress;
    }

    try {
      final position = await getCurrentPosition(forceRefresh: forceRefresh);
      if (position == null) return null;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentAddress = '${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
        return _currentAddress;
      }
    } catch (e) {
      print('Error getting current address: $e');
    }
    return null;
  }

  /// Get default coordinates (live location or fallback)
  Future<Map<String, double>> getDefaultCoordinates() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    }
    
    // Fallback to San Francisco coordinates
    return {
      'latitude': 37.7749,
      'longitude': -122.4194,
    };
  }

  /// Check if we have a valid cached location
  bool get hasValidLocation => 
      _currentPosition != null && 
      _lastLocationUpdate != null &&
      DateTime.now().difference(_lastLocationUpdate!) < _locationCacheTimeout;

  /// Get cached position without making new request
  Position? get cachedPosition => hasValidLocation ? _currentPosition : null;

  /// Get cached address without making new request
  String? get cachedAddress => hasValidLocation ? _currentAddress : null;

  /// Clear cached location data
  void clearCache() {
    _currentPosition = null;
    _currentAddress = null;
    _lastLocationUpdate = null;
  }

  /// Get distance between two coordinates in kilometers
  double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Convert to kilometers
  }
}
