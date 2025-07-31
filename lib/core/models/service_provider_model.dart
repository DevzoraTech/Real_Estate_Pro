import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/services/domain/entities/service_provider.dart';

class ServiceProviderModel extends ServiceProvider {
  const ServiceProviderModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.profileImage,
    required super.bio,
    required super.serviceCategories,
    required super.primaryService,
    required super.rating,
    required super.reviewsCount,
    required super.location,
    required super.city,
    required super.state,
    required super.latitude,
    required super.longitude,
    required super.portfolioImages,
    required super.certifications,
    required super.yearsOfExperience,
    required super.isVerified,
    required super.isOnline,
    required super.availability,
    required super.pricing,
    required super.serviceAreas,
    required super.createdAt,
    required super.updatedAt,
    super.lastActive,
  });

  String get fullLocation => '$location, $city, $state';
  String get mainPortfolioImage =>
      portfolioImages.isNotEmpty ? portfolioImages.first : '';
  bool get isAvailable => isOnline && availability != 'unavailable';

  factory ServiceProviderModel.fromJson(Map<String, dynamic> json) {
    return ServiceProviderModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
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
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      lastActive:
          json['last_active'] != null
              ? _parseDateTime(json['last_active'])
              : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.parse(value);
    }

    // Fallback for any other type
    return DateTime.now();
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
