class AppConstants {
  // API
  static const String baseUrl = 'https://api.realestate.com';
  static const String apiVersion = 'v1';

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Property Types
  static const List<String> propertyTypes = [
    'House',
    'Apartment',
    'Condo',
    'Townhouse',
    'Villa',
    'Studio',
    'Duplex',
    'Commercial',
    'Land',
    'Office',
  ];

  // Property Status
  static const String forSale = 'for_sale';
  static const String forRent = 'for_rent';
  static const String sold = 'sold';
  static const String rented = 'rented';

  // User Roles
  static const String customer = 'customer';
  static const String realtor = 'realtor';
  static const String propertyOwner = 'property_owner';
  static const String admin = 'admin';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Map
  static const double fallbackLatitude = 37.7749; // San Francisco fallback
  static const double fallbackLongitude = -122.4194;
  static const double defaultLatitude = 37.7749; // San Francisco default
  static const double defaultLongitude = -122.4194;
  static const double defaultZoom = 12.0;
  static const double nearbySearchRadius = 50.0; // kilometers
}
