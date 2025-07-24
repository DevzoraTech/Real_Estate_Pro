import 'package:equatable/equatable.dart';

class Property extends Equatable {
  final String id;
  final String title;
  final String description;
  final String type;
  final String status;
  final double price;
  final double area;
  final int bedrooms;
  final int bathrooms;
  final int? parkingSpaces;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<String> amenities;
  final String ownerId;
  final String? realtorId;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? rating;
  final int? reviewsCount;

  const Property({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.price,
    required this.area,
    required this.bedrooms,
    required this.bathrooms,
    this.parkingSpaces,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
    List<String>? images,
    List<String>? amenities,
    required this.ownerId,
    this.realtorId,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
    this.rating,
    this.reviewsCount,
  }) : images = images ?? const [],
       amenities = amenities ?? const [];

  String get fullAddress => '$address, $city, $state $zipCode';
  String get mainImage {
    // Always safe: images is never null
    if (images.isEmpty) {
      // Debug print for missing images
      print('Property $id has empty images list');
      return '';
    }
    return images.first;
  }

  bool get isForSale => status == 'for_sale';
  bool get isForRent => status == 'for_rent';

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    type,
    status,
    price,
    area,
    bedrooms,
    bathrooms,
    parkingSpaces,
    address,
    city,
    state,
    zipCode,
    latitude,
    longitude,
    images,
    amenities,
    ownerId,
    realtorId,
    isFeatured,
    createdAt,
    updatedAt,
    rating,
    reviewsCount,
  ];
}
