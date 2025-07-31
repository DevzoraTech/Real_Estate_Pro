import 'package:equatable/equatable.dart';

class ServiceProvider extends Equatable {
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

  const ServiceProvider({
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

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    profileImage,
    bio,
    serviceCategories,
    primaryService,
    rating,
    reviewsCount,
    location,
    city,
    state,
    latitude,
    longitude,
    portfolioImages,
    certifications,
    yearsOfExperience,
    isVerified,
    isOnline,
    availability,
    pricing,
    serviceAreas,
    createdAt,
    updatedAt,
    lastActive,
  ];
}
