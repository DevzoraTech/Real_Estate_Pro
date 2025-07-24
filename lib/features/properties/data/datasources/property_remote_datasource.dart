import '../models/property_model.dart';
import '../../domain/entities/property_filter.dart';

abstract class PropertyRemoteDataSource {
  Future<List<PropertyModel>> getProperties(PropertyFilter filter);
  Future<PropertyModel> getPropertyById(String id);
  Future<List<PropertyModel>> getFeaturedProperties();
  Future<List<PropertyModel>> searchProperties(String query);
  Future<PropertyModel> createProperty(PropertyModel property);
  Future<PropertyModel> updateProperty(PropertyModel property);
  Future<void> deleteProperty(String id);
}

class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  // In a real app, you would use Dio for HTTP requests
  // For now, we'll simulate API calls with mock data

  @override
  Future<List<PropertyModel>> getProperties(PropertyFilter filter) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data - in real app, this would be an API call
    return _getMockProperties()
        .where((property) => _matchesFilter(property, filter))
        .skip((filter.page - 1) * filter.limit)
        .take(filter.limit)
        .toList();
  }

  @override
  Future<PropertyModel> getPropertyById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final properties = _getMockProperties();
    final property = properties.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Property not found'),
    );

    return property;
  }

  @override
  Future<List<PropertyModel>> getFeaturedProperties() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final featuredProperties =
        _getMockProperties().where((p) => p.isFeatured).toList();
    print(
      'Remote data source - Featured properties: ${featuredProperties.length}',
    );
    return featuredProperties;
  }

  @override
  Future<List<PropertyModel>> searchProperties(String query) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final lowercaseQuery = query.toLowerCase();
    return _getMockProperties()
        .where(
          (property) =>
              property.title.toLowerCase().contains(lowercaseQuery) ||
              property.description.toLowerCase().contains(lowercaseQuery) ||
              property.city.toLowerCase().contains(lowercaseQuery) ||
              property.address.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  @override
  Future<PropertyModel> createProperty(PropertyModel property) async {
    await Future.delayed(const Duration(seconds: 1));
    // In real app, send POST request to API
    return property;
  }

  @override
  Future<PropertyModel> updateProperty(PropertyModel property) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // In real app, send PUT request to API
    return property;
  }

  @override
  Future<void> deleteProperty(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In real app, send DELETE request to API
  }

  bool _matchesFilter(PropertyModel property, PropertyFilter filter) {
    if (filter.type != null &&
        filter.type != 'All' &&
        property.type != filter.type) {
      return false;
    }

    if (filter.status != null &&
        filter.status != 'All' &&
        property.status != filter.status) {
      return false;
    }

    if (filter.minPrice != null && property.price < filter.minPrice!) {
      return false;
    }

    if (filter.maxPrice != null && property.price > filter.maxPrice!) {
      return false;
    }

    if (filter.minBedrooms != null && property.bedrooms < filter.minBedrooms!) {
      return false;
    }

    if (filter.minBathrooms != null &&
        property.bathrooms < filter.minBathrooms!) {
      return false;
    }

    return true;
  }

  List<PropertyModel> _getMockProperties() {
    return [
      PropertyModel(
        id: '1',
        title: 'Luxury Villa Paradise',
        description:
            'Stunning luxury villa with ocean views and modern amenities',
        type: 'Villa',
        status: 'for_sale',
        price: 1250000,
        area: 3500,
        bedrooms: 4,
        bathrooms: 3,
        address: '789 Ocean Drive',
        city: 'Miami',
        state: 'FL',
        zipCode: '33139',
        latitude: 25.7617,
        longitude: -80.1918,
        images: [
          'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=400',
        ],
        amenities: ['Pool', 'Ocean View', 'Garage', 'Garden'],
        ownerId: 'owner1',
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
      PropertyModel(
        id: '2',
        title: 'Modern Downtown Apartment',
        description: 'Beautiful modern apartment in the heart of downtown',
        type: 'Apartment',
        status: 'for_sale',
        price: 450000,
        area: 1200,
        bedrooms: 2,
        bathrooms: 2,
        address: '123 Main St',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94102',
        latitude: 37.7749,
        longitude: -122.4194,
        images: [
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=400',
        ],
        amenities: ['Gym', 'Pool', 'Parking'],
        ownerId: 'owner1',
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
      PropertyModel(
        id: '3',
        title: 'Cozy Family House',
        description: 'Perfect family home with large backyard',
        type: 'House',
        status: 'for_rent',
        price: 3500,
        area: 2000,
        bedrooms: 3,
        bathrooms: 2,
        parkingSpaces: 2,
        address: '456 Oak Ave',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94103',
        latitude: 37.7849,
        longitude: -122.4094,
        images: [
          'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=400',
        ],
        amenities: ['Garden', 'Garage', 'Fireplace'],
        ownerId: 'owner2',
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      ),
      PropertyModel(
        id: '4',
        title: 'Premium Condo Suite',
        description: 'Elegant condo with city skyline views',
        type: 'Condo',
        status: 'for_sale',
        price: 680000,
        area: 1500,
        bedrooms: 2,
        bathrooms: 2,
        address: '321 Sky Tower',
        city: 'New York',
        state: 'NY',
        zipCode: '10001',
        latitude: 40.7128,
        longitude: -74.0060,
        images: [
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400',
        ],
        amenities: ['Concierge', 'Gym', 'Rooftop'],
        ownerId: 'owner3',
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
