import '../../domain/entities/property.dart';

class PropertyModel extends Property {
  const PropertyModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    required super.status,
    required super.price,
    required super.area,
    required super.bedrooms,
    required super.bathrooms,
    super.parkingSpaces,
    required super.address,
    required super.city,
    required super.state,
    required super.zipCode,
    required super.latitude,
    required super.longitude,
    required super.images,
    required super.amenities,
    required super.ownerId,
    super.realtorId,
    required super.isFeatured,
    required super.createdAt,
    required super.updatedAt,
    super.rating,
    super.reviewsCount,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      status: json['status'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      parkingSpaces: json['parking_spaces'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      images:
          (json['images'] is List)
              ? List<String>.from(json['images'])
              : <String>[],
      amenities:
          (json['amenities'] is List)
              ? List<String>.from(json['amenities'])
              : <String>[],
      ownerId: json['owner_id'],
      realtorId: json['realtor_id'],
      isFeatured: json['is_featured'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewsCount: json['reviews_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'price': price,
      'area': area,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'parking_spaces': parkingSpaces,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'amenities': amenities,
      'owner_id': ownerId,
      'realtor_id': realtorId,
      'is_featured': isFeatured,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'rating': rating,
      'reviews_count': reviewsCount,
    };
  }

  factory PropertyModel.fromEntity(Property property) {
    return PropertyModel(
      id: property.id,
      title: property.title,
      description: property.description,
      type: property.type,
      status: property.status,
      price: property.price,
      area: property.area,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      parkingSpaces: property.parkingSpaces,
      address: property.address,
      city: property.city,
      state: property.state,
      zipCode: property.zipCode,
      latitude: property.latitude,
      longitude: property.longitude,
      images: property.images,
      amenities: property.amenities,
      ownerId: property.ownerId,
      realtorId: property.realtorId,
      isFeatured: property.isFeatured,
      createdAt: property.createdAt,
      updatedAt: property.updatedAt,
      rating: property.rating,
      reviewsCount: property.reviewsCount,
    );
  }
}
