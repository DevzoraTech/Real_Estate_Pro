class PropertyModel {
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

  PropertyModel({
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
    required this.images,
    required this.amenities,
    required this.ownerId,
    this.realtorId,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullAddress => '$address, $city, $state $zipCode';
  String get mainImage => images.isNotEmpty ? images.first : '';
  bool get isForSale => status == 'for_sale';
  bool get isForRent => status == 'for_rent';

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      status: json['status'],
      price: json['price'].toDouble(),
      area: json['area'].toDouble(),
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      parkingSpaces: json['parking_spaces'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      images: List<String>.from(json['images'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      ownerId: json['owner_id'],
      realtorId: json['realtor_id'],
      isFeatured: json['is_featured'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
    };
  }

  static PropertyModel fromProperty(dynamic p) => PropertyModel(
    id: p.id,
    title: p.title,
    description: p.description,
    type: p.type,
    status: p.status,
    price: p.price,
    area: p.area,
    bedrooms: p.bedrooms,
    bathrooms: p.bathrooms,
    parkingSpaces: p.parkingSpaces,
    address: p.address,
    city: p.city,
    state: p.state,
    zipCode: p.zipCode,
    latitude: p.latitude,
    longitude: p.longitude,
    images: p.images,
    amenities: p.amenities,
    ownerId: p.ownerId,
    realtorId: p.realtorId,
    isFeatured: p.isFeatured,
    createdAt: p.createdAt,
    updatedAt: p.updatedAt,
  );

  static PropertyModel fromFirestore(String id, Map<String, dynamic> data) =>
      PropertyModel(
        id: id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        type: data['type'] ?? '',
        status: data['status'] ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        area: (data['area'] as num?)?.toDouble() ?? 0.0,
        bedrooms: (data['bedrooms'] as num?)?.toInt() ?? 0,
        bathrooms: (data['bathrooms'] as num?)?.toInt() ?? 0,
        parkingSpaces: (data['parkingSpaces'] as num?)?.toInt(),
        address: data['address'] ?? '',
        city: data['city'] ?? '',
        state: data['state'] ?? '',
        zipCode: data['zipCode'] ?? '',
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
        images: (data['images'] as List?)?.cast<String>() ?? [],
        amenities: (data['amenities'] as List?)?.cast<String>() ?? [],
        ownerId: data['ownerId'] ?? '',
        realtorId: data['realtorId'],
        isFeatured: data['isFeatured'] == true,
        createdAt:
            data['createdAt'] is DateTime ? data['createdAt'] : DateTime.now(),
        updatedAt:
            data['updatedAt'] is DateTime ? data['updatedAt'] : DateTime.now(),
      );
}
