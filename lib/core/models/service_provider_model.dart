class ServiceProviderModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String bio;
  final List<String> serviceCategories;
  final String primaryService;
  final double rating;
  final int reviewsCount;
  final String location;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final List<String> portfolioImages;
  final List<String> certifications;
  final int yearsOfExperience;
  final bool isVerified;
  final bool isOnline;
  final String availability;
  final Map<String, dynamic> pricing;
  final List<String> serviceAreas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActive;

  ServiceProviderModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.bio,
    required this.serviceCategories,
    required this.primaryService,
    required this.rating,
    required this.reviewsCount,
    required this.location,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.portfolioImages,
    required this.certifications,
    required this.yearsOfExperience,
    required this.isVerified,
    required this.isOnline,
    required this.availability,
    required this.pricing,
    required this.serviceAreas,
    required this.createdAt,
    required this.updatedAt,
    this.lastActive,
  });

  String get fullLocation => '$location, $city, $state';
  String get mainPortfolioImage =>
      portfolioImages.isNotEmpty ? portfolioImages.first : '';
  bool get isAvailable => isOnline && availability != 'unavailable';

  factory ServiceProviderModel.fromJson(Map<String, dynamic> json) {
    return ServiceProviderModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profile_image'] ?? '',
      bio: json['bio'] ?? '',
      serviceCategories: List<String>.from(json['service_categories'] ?? []),
      primaryService: json['primary_service'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviews_count'] ?? 0,
      location: json['location'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      portfolioImages: List<String>.from(json['portfolio_images'] ?? []),
      certifications: List<String>.from(json['certifications'] ?? []),
      yearsOfExperience: json['years_of_experience'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      isOnline: json['is_online'] ?? false,
      availability: json['availability'] ?? 'available',
      pricing: Map<String, dynamic>.from(json['pricing'] ?? {}),
      serviceAreas: List<String>.from(json['service_areas'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastActive:
          json['last_active'] != null
              ? DateTime.parse(json['last_active'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'bio': bio,
      'service_categories': serviceCategories,
      'primary_service': primaryService,
      'rating': rating,
      'reviews_count': reviewsCount,
      'location': location,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'portfolio_images': portfolioImages,
      'certifications': certifications,
      'years_of_experience': yearsOfExperience,
      'is_verified': isVerified,
      'is_online': isOnline,
      'availability': availability,
      'pricing': pricing,
      'service_areas': serviceAreas,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
    };
  }
}
