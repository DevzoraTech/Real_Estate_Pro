import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/property_filter.dart';
import '../../domain/entities/property.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../bloc/featured_property_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../auth/presentation/pages/login_page.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/widgets/location_header.dart';
import '../../../../core/constants/app_constants.dart';
import 'dart:async';

const List<Map<String, String>> supportedCurrencies = [
  {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  {'code': 'UGX', 'symbol': 'UGX', 'name': 'Ugandan Shilling'},
  {'code': 'KES', 'symbol': 'KSh', 'name': 'Kenyan Shilling'},
  {'code': 'TZS', 'symbol': 'TSh', 'name': 'Tanzanian Shilling'},
];

enum PropertyCardViewStyle { compact, largeImage, grid }

class PropertyListPage extends StatefulWidget {
  const PropertyListPage({super.key});

  @override
  State<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage> {
  String _selectedType = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PropertyCardViewStyle _recentlyAddedViewStyle = PropertyCardViewStyle.grid;
  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {'USD': 1.0};
  DateTime? _lastRatesFetch;
  PropertyCardViewStyle _featuredViewStyle = PropertyCardViewStyle.compact;
  bool _isLoading = false;

  // Location variables
  double? _currentLatitude;
  double? _currentLongitude;
  List<Property> _nearbyProperties = [];
  bool _isLoadingLocation = false;

  // Advanced filter variables
  RangeValues _priceRange = const RangeValues(0, 1000000);
  RangeValues _bedroomsRange = const RangeValues(1, 10);
  RangeValues _bathroomsRange = const RangeValues(1, 10);
  RangeValues _areaRange = const RangeValues(100, 10000);
  String _selectedStatus = 'All';
  List<String> _selectedAmenities = [];

  final List<Map<String, dynamic>> propertyTypes = [
    {'name': 'All', 'icon': Icons.apps_rounded},
    {'name': 'Villa', 'icon': Icons.villa_rounded},
    {'name': 'House', 'icon': Icons.house_rounded},
    {'name': 'Apartment', 'icon': Icons.apartment_rounded},
    {'name': 'Condo', 'icon': Icons.business_rounded},
    {'name': 'Townhouse', 'icon': Icons.home_rounded},
    {'name': 'Studio', 'icon': Icons.single_bed_rounded},
    {'name': 'Commercial', 'icon': Icons.business_center_rounded},
    {'name': 'Land', 'icon': Icons.landscape_rounded},
    {'name': 'Office', 'icon': Icons.business_rounded},
  ];

  void _cycleFeaturedViewStyle() {
    if (_isLoading) return;
    setState(() {
      switch (_featuredViewStyle) {
        case PropertyCardViewStyle.compact:
          _featuredViewStyle = PropertyCardViewStyle.largeImage;
          break;
        case PropertyCardViewStyle.largeImage:
          _featuredViewStyle = PropertyCardViewStyle.grid;
          break;
        case PropertyCardViewStyle.grid:
          _featuredViewStyle = PropertyCardViewStyle.compact;
          break;
      }
    });
  }

  void _cycleRecentlyAddedViewStyle() {
    if (_isLoading) return;
    setState(() {
      switch (_recentlyAddedViewStyle) {
        case PropertyCardViewStyle.compact:
          _recentlyAddedViewStyle = PropertyCardViewStyle.largeImage;
          break;
        case PropertyCardViewStyle.largeImage:
          _recentlyAddedViewStyle = PropertyCardViewStyle.grid;
          break;
        case PropertyCardViewStyle.grid:
          _recentlyAddedViewStyle = PropertyCardViewStyle.compact;
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    _fetchExchangeRates();
    _loadCurrentLocation();
  }

  // Update _fetchExchangeRates to use ExchangeRate-API with UGX as the base and the provided API key.
  Future<void> _fetchExchangeRates() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://v6.exchangerate-api.com/v6/a09f9bc5b63881137cc51638/latest/UGX',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _exchangeRates = Map<String, double>.from(data['conversion_rates']);
          _lastRatesFetch = DateTime.now();
        });
      }
    } catch (e) {
      // Fallback: keep previous rates
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load current location and find nearby properties
  Future<void> _loadCurrentLocation() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _currentLatitude = position.latitude;
          _currentLongitude = position.longitude;
        });
        await _loadNearbyProperties();
      }
    } catch (e) {
      print('Error loading location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Load properties near current location
  Future<void> _loadNearbyProperties() async {
    if (_currentLatitude == null || _currentLongitude == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('properties').get();

      final List<Property> nearby = [];
      for (final doc in snapshot.docs) {
        final property = _createPropertyFromDoc(doc);
        final distance = LocationService.instance.getDistanceBetween(
          _currentLatitude!,
          _currentLongitude!,
          property.latitude,
          property.longitude,
        );

        if (distance <= AppConstants.nearbySearchRadius) {
          nearby.add(property);
        }
      }

      // Sort by distance
      nearby.sort((a, b) {
        final distanceA = LocationService.instance.getDistanceBetween(
          _currentLatitude!,
          _currentLongitude!,
          a.latitude,
          a.longitude,
        );
        final distanceB = LocationService.instance.getDistanceBetween(
          _currentLatitude!,
          _currentLongitude!,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      if (mounted) {
        setState(() {
          _nearbyProperties = nearby;
        });
      }
    } catch (e) {
      print('Error loading nearby properties: $e');
    }
  }

  // Helper method to create Property from Firestore document
  Property _createPropertyFromDoc(QueryDocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return Property(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        type: data['type'] ?? '',
        status: data['status'] ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        area: (data['area'] as num?)?.toDouble() ?? 0.0,
        bedrooms: (data['bedrooms'] as num?)?.toInt() ?? 0,
        bathrooms: (data['bathrooms'] as num?)?.toInt() ?? 0,
        address: data['address'] ?? '',
        city: data['city'] ?? '',
        state: data['state'] ?? '',
        zipCode: data['zipCode'] ?? '',
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
        images:
            (data['images'] is List)
                ? (data['images'] as List).cast<String>()
                : <String>[],
        amenities:
            (data['amenities'] is List)
                ? (data['amenities'] as List).cast<String>()
                : <String>[],
        ownerId: data['ownerId'] ?? '',
        isFeatured: data['isFeatured'] ?? false,
        createdAt:
            (data['createdAt'] is Timestamp)
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
        updatedAt:
            (data['updatedAt'] is Timestamp)
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.now(),
        rating: (data['rating'] as num?)?.toDouble(),
        reviewsCount:
            (data['reviews_count'] is int)
                ? data['reviews_count'] as int
                : (data['reviews_count'] is num)
                ? (data['reviews_count'] as num).toInt()
                : null,
      );
    } catch (e) {
      print('Error creating property from doc ${doc.id}: $e');
      // Return a default property to prevent crashes
      return Property(
        id: doc.id,
        title: 'Property ${doc.id}',
        description: '',
        type: 'House',
        status: 'for_sale',
        price: 0.0,
        area: 0.0,
        bedrooms: 0,
        bathrooms: 0,
        address: '',
        city: '',
        state: '',
        zipCode: '',
        latitude: 0.0,
        longitude: 0.0,
        images: <String>[],
        amenities: <String>[],
        ownerId: '',
        isFeatured: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        rating: null,
        reviewsCount: null,
      );
    }
  }

  Stream<QuerySnapshot> _buildFeaturedPropertiesQuery() {
    return FirebaseFirestore.instance
        .collection('properties')
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot> _buildRecentlyAddedPropertiesQuery() {
    return FirebaseFirestore.instance
        .collection('properties')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterPropertiesByType(
    List<QueryDocumentSnapshot> docs,
  ) {
    // Debug: Log available property types in the database
    if (_selectedType != 'All' && docs.isNotEmpty) {
      final availableTypes = <String>{};
      final availableStatuses = <String>{};
      final typeCounts = <String, int>{};

      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['type']?.toString() ?? '';
        final status = data['status']?.toString() ?? '';

        if (type.isNotEmpty) {
          final typeLower = type.toLowerCase();
          availableTypes.add(typeLower);
          typeCounts[typeLower] = (typeCounts[typeLower] ?? 0) + 1;
        }
        if (status.isNotEmpty) {
          availableStatuses.add(status.toLowerCase());
        }
      }

      print('=== FILTER DEBUG ===');
      print('Available property types in database: $availableTypes');
      print('Property type counts: $typeCounts');
      print('Available property statuses in database: $availableStatuses');
      print('Selected filter type: ${_selectedType.toLowerCase()}');
      print('Total properties before filtering: ${docs.length}');
    }

    // If no filters are applied, return all properties
    if (_selectedType == 'All' &&
        _selectedStatus == 'All' &&
        _priceRange.start == 0 &&
        _priceRange.end == 1000000 &&
        _bedroomsRange.start == 1 &&
        _bedroomsRange.end == 10 &&
        _bathroomsRange.start == 1 &&
        _bathroomsRange.end == 10 &&
        _areaRange.start == 100 &&
        _areaRange.end == 10000 &&
        _selectedAmenities.isEmpty) {
      return docs;
    }

    int filteredCount = 0;
    final filteredDocs =
        docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Filter by property type (case-insensitive with flexible matching)
          if (_selectedType != 'All') {
            final propertyType = data['type']?.toString().toLowerCase() ?? '';
            final selectedType = _selectedType.toLowerCase();

            // Try exact match first
            bool matches = propertyType == selectedType;

            // If no exact match, try flexible matching
            if (!matches) {
              switch (selectedType) {
                case 'villa':
                  matches =
                      propertyType.contains('villa') ||
                      propertyType.contains('mansion') ||
                      propertyType.contains('luxury') ||
                      propertyType.contains('palace') ||
                      propertyType.contains('estate');
                  break;
                case 'house':
                  matches =
                      propertyType.contains('house') ||
                      propertyType.contains('home') ||
                      propertyType.contains('residential') ||
                      propertyType.contains('family') ||
                      propertyType.contains('detached') ||
                      propertyType.contains('single') ||
                      propertyType.contains('bungalow');
                  break;
                case 'apartment':
                  matches =
                      propertyType.contains('apartment') ||
                      propertyType.contains('apt') ||
                      propertyType.contains('flat') ||
                      propertyType.contains('unit') ||
                      propertyType.contains('suite') ||
                      propertyType.contains('room');
                  break;
                case 'condo':
                  matches =
                      propertyType.contains('condo') ||
                      propertyType.contains('condominium') ||
                      propertyType.contains('condominium') ||
                      propertyType.contains('condo-minium');
                  break;
                case 'townhouse':
                  matches =
                      propertyType.contains('townhouse') ||
                      propertyType.contains('town house') ||
                      propertyType.contains('town-home') ||
                      propertyType.contains('row house') ||
                      propertyType.contains('town') ||
                      propertyType.contains('terrace');
                  break;
                case 'studio':
                  matches =
                      propertyType.contains('studio') ||
                      propertyType.contains('bachelor') ||
                      propertyType.contains('efficiency') ||
                      propertyType.contains('loft') ||
                      propertyType.contains('single room');
                  break;
                case 'commercial':
                  matches =
                      propertyType.contains('commercial') ||
                      propertyType.contains('business') ||
                      propertyType.contains('retail') ||
                      propertyType.contains('industrial') ||
                      propertyType.contains('warehouse') ||
                      propertyType.contains('shop') ||
                      propertyType.contains('store');
                  break;
                case 'land':
                  matches =
                      propertyType.contains('land') ||
                      propertyType.contains('plot') ||
                      propertyType.contains('lot') ||
                      propertyType.contains('acre') ||
                      propertyType.contains('property') ||
                      propertyType.contains('ground') ||
                      propertyType.contains('site');
                  break;
                case 'office':
                  matches =
                      propertyType.contains('office') ||
                      propertyType.contains('workspace') ||
                      propertyType.contains('corporate') ||
                      propertyType.contains('professional') ||
                      propertyType.contains('business') ||
                      propertyType.contains('workplace');
                  break;
              }
            }

            // Debug: Log when a property doesn't match
            if (!matches && propertyType.isNotEmpty) {
              print(
                'Property type "$propertyType" does not match filter "$selectedType"',
              );
            }

            if (!matches) {
              return false;
            }
          }

          // Filter by property status (case-insensitive)
          if (_selectedStatus != 'All') {
            final propertyStatus =
                data['status']?.toString().toLowerCase() ?? '';
            final selectedStatus = _selectedStatus.toLowerCase();
            if (propertyStatus != selectedStatus) {
              return false;
            }
          }

          // Filter by price range
          final price = (data['price'] as num?)?.toDouble() ?? 0.0;
          if (price < _priceRange.start || price > _priceRange.end) {
            return false;
          }

          // Filter by bedrooms range
          final bedrooms = (data['bedrooms'] as num?)?.toInt() ?? 0;
          if (bedrooms < _bedroomsRange.start.round() ||
              bedrooms > _bedroomsRange.end.round()) {
            return false;
          }

          // Filter by bathrooms range
          final bathrooms = (data['bathrooms'] as num?)?.toInt() ?? 0;
          if (bathrooms < _bathroomsRange.start.round() ||
              bathrooms > _bathroomsRange.end.round()) {
            return false;
          }

          // Filter by area range
          final area = (data['area'] as num?)?.toDouble() ?? 0.0;
          if (area < _areaRange.start || area > _areaRange.end) {
            return false;
          }

          // Filter by amenities (if any amenities are selected)
          if (_selectedAmenities.isNotEmpty) {
            final amenities =
                (data['amenities'] as List?)?.cast<String>() ?? [];
            final hasAllSelectedAmenities = _selectedAmenities.every(
              (amenity) => amenities.contains(amenity),
            );
            if (!hasAllSelectedAmenities) {
              return false;
            }
          }

          filteredCount++;
          return true;
        }).toList();

    if (_selectedType != 'All') {
      print('Properties after filtering: ${filteredDocs.length}');
    }

    return filteredDocs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchExchangeRates();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildLocationHeader(),
              _buildSearchBar(),
              _buildPropertyTypeFilters(),
              _buildSearchResultsSection(),
              _buildNearbyPropertiesSection(),
              _buildFeaturedSection(),
              _buildRecentlyAddedSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary.withOpacity(0.05), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'More Than a Place To Call Home',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'UpSpace ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey[500],
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          items:
                              supportedCurrencies
                                  .map(
                                    (c) => DropdownMenuItem<String>(
                                      value: c['code']!,
                                      child: Text(
                                        c['code']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null && value != _selectedCurrency) {
                              setState(() {
                                _selectedCurrency = value;
                              });
                              _fetchExchangeRates();
                            }
                          },
                          underline: const SizedBox(),
                          icon: Icon(
                            Icons.expand_more,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          Icons.favorite_border,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        tooltip: 'Favorites',
                        onPressed: () {
                          Navigator.pushNamed(context, '/favorites');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.2,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Find the\n',
                      style: TextStyle(fontWeight: FontWeight.w300),
                    ),
                    TextSpan(
                      text: 'Perfect ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: 'Place',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Discover amazing properties that match your lifestyle',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  _searchQuery.isNotEmpty
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    _searchQuery.isNotEmpty
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Search by location, type, or features...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.search_rounded,
                  color:
                      _searchQuery.isNotEmpty
                          ? AppColors.primary
                          : Colors.grey[500],
                  size: 22,
                ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      tooltip: 'Clear search',
                    ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      onPressed: _showFilterBottomSheet,
                      tooltip: 'Advanced filters',
                    ),
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return SliverToBoxAdapter(
      child: LocationHeader(
        currentLatitude: _currentLatitude,
        currentLongitude: _currentLongitude,
        isLoading: _isLoadingLocation,
        onRefresh: _loadCurrentLocation,
        onTap: () {
          // Navigate to map view or location settings
          print('Location header tapped');
        },
      ),
    );
  }

  Widget _buildNearbyPropertiesSection() {
    if (_nearbyProperties.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NearbyPropertiesHeader(
            count: _nearbyProperties.length,
            onViewAll: () {
              // Navigate to nearby properties page
              print('View all nearby properties');
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _nearbyProperties.length,
              itemBuilder: (context, index) {
                final property = _nearbyProperties[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  child: CompactPropertyCard(
                    property: property,
                    onTap:
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.propertyDetail,
                          arguments: property,
                        ),
                    exchangeRates: _exchangeRates,
                    selectedCurrency: _selectedCurrency,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeFilters() {
    final types = propertyTypes;

    return SliverToBoxAdapter(
      child: Container(
        height: 70,
        margin: const EdgeInsets.only(top: 24),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            final isSelected = _selectedType == type['name'];

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  if (_selectedType != type['name']) {
                    print('=== HORIZONTAL FILTER TAPPED ===');
                    print('Tapped filter: ${type['name']}');
                    setState(() {
                      _selectedType = type['name'] as String;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.primary
                              : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isSelected
                                ? AppColors.primary.withOpacity(0.2)
                                : Colors.black.withOpacity(0.05),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        size: 20,
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type['name'] as String,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResultsSection() {
    if (_searchQuery.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('properties')
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final allDocs = snapshot.data?.docs ?? [];
            final query = _searchQuery.toLowerCase();

            // First filter by search query
            final searchResults =
                allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  bool matches(String? value) =>
                      value != null && value.toLowerCase().contains(query);
                  bool matchesList(List? list) =>
                      list != null &&
                      list.any(
                        (item) => item.toString().toLowerCase().contains(query),
                      );

                  return matches(data['title']) ||
                      matches(data['description']) ||
                      matches(data['city']) ||
                      matches(data['state']) ||
                      matches(data['address']) ||
                      matches(data['type']) ||
                      matchesList(data['amenities']);
                }).toList();

            // Then apply advanced filters
            final results = _filterPropertiesByType(searchResults);

            if (results.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No properties found. Try a different search!',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              itemBuilder:
                  (context, index) => _buildSearchPropertyCard(results[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchPropertyCard(QueryDocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['title'] == null) {
        return const SizedBox.shrink();
      }

      final property = Property(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        type: data['type'] ?? '',
        status: data['status'] ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        area: (data['area'] as num?)?.toDouble() ?? 0.0,
        bedrooms: (data['bedrooms'] as num?)?.toInt() ?? 0,
        bathrooms: (data['bathrooms'] as num?)?.toInt() ?? 0,
        address: data['address'] ?? '',
        city: data['city'] ?? '',
        state: data['state'] ?? '',
        zipCode: data['zipCode'] ?? '',
        latitude: 0,
        longitude: 0,
        images:
            (data['images'] is List)
                ? (data['images'] as List).cast<String>()
                : <String>[],
        amenities:
            (data['amenities'] is List)
                ? (data['amenities'] as List).cast<String>()
                : <String>[],
        ownerId: data['ownerId'] ?? '',
        isFeatured: data['isFeatured'] ?? false,
        createdAt:
            (data['createdAt'] is Timestamp)
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
        updatedAt:
            (data['updatedAt'] is Timestamp)
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.now(),
        rating: (data['rating'] as num?)?.toDouble(),
        reviewsCount:
            (data['reviews_count'] is int)
                ? data['reviews_count'] as int
                : (data['reviews_count'] is num)
                ? (data['reviews_count'] as num).toInt()
                : null,
      );

      return CompactPropertyCard(
        property: property,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.propertyDetail,
            arguments: property,
          );
        },
        exchangeRates: _exchangeRates,
        selectedCurrency: _selectedCurrency,
      );
    } catch (e) {
      print('Error building search property card for ${doc.id}: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildFeaturedSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Featured Properties',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Handpicked premium properties',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _buildFeaturedPropertiesQuery(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final allDocs = snapshot.data?.docs ?? [];
              final docs = _filterPropertiesByType(allDocs);
              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No featured properties found'),
                  ),
                );
              }

              return SizedBox(
                height: 370,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final property = _createPropertyFromDoc(doc);
                    return Container(
                      width: 300,
                      margin: const EdgeInsets.only(right: 16),
                      child: FeaturedPropertyCard(
                        property: property,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.propertyDetail,
                              arguments: property,
                            ),
                        exchangeRates: _exchangeRates,
                        selectedCurrency: _selectedCurrency,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.home_rounded, size: 30, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            'No Image',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'for rent':
        return Colors.green;
      case 'for sale':
        return Colors.blue;
      case 'sold':
        return Colors.red;
      case 'rented':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  String _formatPrice(double price) {
    final rate = _exchangeRates[_selectedCurrency] ?? 1.0;
    final convertedPrice = price * rate;
    final symbol =
        supportedCurrencies.firstWhere(
          (currency) => currency['code'] == _selectedCurrency,
          orElse: () => {'code': 'USD', 'symbol': '\$'},
        )['symbol'];
    return '$symbol${convertedPrice.round()}';
  }

  Widget _buildRecentlyAddedSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Recently Added',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latest properties on the market',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          switch (_recentlyAddedViewStyle) {
                            case PropertyCardViewStyle.compact:
                              _recentlyAddedViewStyle =
                                  PropertyCardViewStyle.largeImage;
                              break;
                            case PropertyCardViewStyle.largeImage:
                              _recentlyAddedViewStyle =
                                  PropertyCardViewStyle.grid;
                              break;
                            case PropertyCardViewStyle.grid:
                              _recentlyAddedViewStyle =
                                  PropertyCardViewStyle.compact;
                              break;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _recentlyAddedViewStyle ==
                                  PropertyCardViewStyle.compact
                              ? Icons.view_list_rounded
                              : _recentlyAddedViewStyle ==
                                  PropertyCardViewStyle.largeImage
                              ? Icons.grid_view_rounded
                              : Icons.view_module_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Navigate to all recently added properties page
                        Navigator.pushNamed(context, AppRoutes.properties);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _buildRecentlyAddedPropertiesQuery(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error:  [${snapshot.error}'));
              }

              final allDocs = snapshot.data?.docs ?? [];
              final docs = _filterPropertiesByType(allDocs);
              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No properties found'),
                  ),
                );
              }

              if (_recentlyAddedViewStyle == PropertyCardViewStyle.grid) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 240,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final property = _createPropertyFromDoc(doc);
                      return GridPropertyCard(
                        property: property,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.propertyDetail,
                              arguments: property,
                            ),
                        exchangeRates: _exchangeRates,
                        selectedCurrency: _selectedCurrency,
                      );
                    },
                  ),
                );
              }

              return SizedBox(
                height:
                    _recentlyAddedViewStyle == PropertyCardViewStyle.compact
                        ? 370
                        : 400,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final property = _createPropertyFromDoc(doc);
                    return Container(
                      width:
                          _recentlyAddedViewStyle ==
                                  PropertyCardViewStyle.compact
                              ? 300
                              : 320,
                      margin: const EdgeInsets.only(right: 16),
                      child:
                          _recentlyAddedViewStyle ==
                                  PropertyCardViewStyle.compact
                              ? FeaturedPropertyCard(
                                property: property,
                                onTap:
                                    () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.propertyDetail,
                                      arguments: property,
                                    ),
                                exchangeRates: _exchangeRates,
                                selectedCurrency: _selectedCurrency,
                              )
                              : LargeImagePropertyCard(
                                property: property,
                                onTap:
                                    () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.propertyDetail,
                                      arguments: property,
                                    ),
                                exchangeRates: _exchangeRates,
                                selectedCurrency: _selectedCurrency,
                              ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridPropertyCard(Property property) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              () => Navigator.pushNamed(
                context,
                AppRoutes.propertyDetail,
                arguments: property,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child:
                    property.images.isNotEmpty
                        ? Image.network(
                          property.images.first,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  _buildDefaultImage(),
                        )
                        : _buildDefaultImage(),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${property.city}, ${property.state}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatPrice(property.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildCompactFeature(
                          Icons.bed_rounded,
                          '${property.bedrooms}',
                        ),
                        const SizedBox(width: 8),
                        _buildCompactFeature(
                          Icons.bathtub_rounded,
                          '${property.bathrooms}',
                        ),
                        const SizedBox(width: 8),
                        _buildCompactFeature(
                          Icons.square_foot_rounded,
                          '${property.area.toInt()}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Advanced Filters',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  _priceRange = const RangeValues(0, 1000000);
                                  _bedroomsRange = const RangeValues(1, 10);
                                  _bathroomsRange = const RangeValues(1, 10);
                                  _areaRange = const RangeValues(100, 10000);
                                  _selectedStatus = 'All';
                                  _selectedAmenities = [];
                                });
                                setState(() {
                                  _priceRange = const RangeValues(0, 1000000);
                                  _bedroomsRange = const RangeValues(1, 10);
                                  _bathroomsRange = const RangeValues(1, 10);
                                  _areaRange = const RangeValues(100, 10000);
                                  _selectedStatus = 'All';
                                  _selectedAmenities = [];
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Property Status
                              const Text(
                                'Property Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    [
                                      'All',
                                      'For Sale',
                                      'For Rent',
                                      'Sold',
                                      'Rented',
                                    ].map((status) {
                                      final isSelected =
                                          _selectedStatus == status;
                                      return FilterChip(
                                        label: Text(status),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setModalState(() {
                                            _selectedStatus =
                                                selected ? status : 'All';
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 24),

                              // Price Range
                              const Text(
                                'Price Range',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              RangeSlider(
                                values: _priceRange,
                                min: 0,
                                max: 1000000,
                                divisions: 100,
                                labels: RangeLabels(
                                  '\$${_priceRange.start.round()}',
                                  '\$${_priceRange.end.round()}',
                                ),
                                onChanged: (values) {
                                  setModalState(() {
                                    _priceRange = values;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),

                              // Bedrooms Range
                              const Text(
                                'Bedrooms',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              RangeSlider(
                                values: _bedroomsRange,
                                min: 1,
                                max: 10,
                                divisions: 9,
                                labels: RangeLabels(
                                  '${_bedroomsRange.start.round()}',
                                  '${_bedroomsRange.end.round()}',
                                ),
                                onChanged: (values) {
                                  setModalState(() {
                                    _bedroomsRange = values;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),

                              // Bathrooms Range
                              const Text(
                                'Bathrooms',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              RangeSlider(
                                values: _bathroomsRange,
                                min: 1,
                                max: 10,
                                divisions: 9,
                                labels: RangeLabels(
                                  '${_bathroomsRange.start.round()}',
                                  '${_bathroomsRange.end.round()}',
                                ),
                                onChanged: (values) {
                                  setModalState(() {
                                    _bathroomsRange = values;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),

                              // Area Range
                              const Text(
                                'Area (sq ft)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              RangeSlider(
                                values: _areaRange,
                                min: 100,
                                max: 10000,
                                divisions: 99,
                                labels: RangeLabels(
                                  '${_areaRange.start.round()}',
                                  '${_areaRange.end.round()}',
                                ),
                                onChanged: (values) {
                                  setModalState(() {
                                    _areaRange = values;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),

                              // Amenities
                              const Text(
                                'Amenities',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    [
                                      'Parking',
                                      'Garden',
                                      'Pool',
                                      'Gym',
                                      'Security',
                                      'Balcony',
                                      'Air Conditioning',
                                      'Furnished',
                                    ].map((amenity) {
                                      final isSelected = _selectedAmenities
                                          .contains(amenity);
                                      return FilterChip(
                                        label: Text(amenity),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setModalState(() {
                                            if (selected) {
                                              _selectedAmenities.add(amenity);
                                            } else {
                                              _selectedAmenities.remove(
                                                amenity,
                                              );
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    // Apply the filters from modal state to main state
                                    // The filters are already applied through the modal state
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text('Apply Filters'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}

class LargeImagePropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final Map<String, double> exchangeRates;
  final String selectedCurrency;

  const LargeImagePropertyCard({
    Key? key,
    required this.property,
    required this.onTap,
    required this.exchangeRates,
    required this.selectedCurrency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large image section
              Container(
                height: 200,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child:
                          property.images.isNotEmpty
                              ? Image.network(
                                property.images.first,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildDefaultImage(),
                              )
                              : _buildDefaultImage(),
                    ),
                    // Status badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(property.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          property.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${property.city}, ${property.state}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        _formatPrice(property.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildFeature(Icons.bed, '${property.bedrooms}'),
                          const SizedBox(width: 16),
                          _buildFeature(Icons.bathtub, '${property.bathrooms}'),
                          const SizedBox(width: 16),
                          _buildFeature(
                            Icons.square_foot,
                            '${property.area.toInt()}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            'No Image Available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'for rent':
        return Colors.green;
      case 'for sale':
        return Colors.blue;
      case 'sold':
        return Colors.red;
      case 'rented':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  String _formatPrice(double price) {
    final rate = exchangeRates[selectedCurrency] ?? 1.0;
    final convertedPrice = price * rate;
    final symbol =
        supportedCurrencies.firstWhere(
          (currency) => currency['code'] == selectedCurrency,
          orElse: () => {'code': 'USD', 'symbol': '\$'},
        )['symbol'];
    return '$symbol${convertedPrice.round()}';
  }
}

class CompactPropertyCard extends StatefulWidget {
  final Property property;
  final VoidCallback onTap;
  final Map<String, double> exchangeRates;
  final String selectedCurrency;

  const CompactPropertyCard({
    Key? key,
    required this.property,
    required this.onTap,
    required this.exchangeRates,
    required this.selectedCurrency,
  }) : super(key: key);

  @override
  State<CompactPropertyCard> createState() => _CompactPropertyCardState();
}

class _CompactPropertyCardState extends State<CompactPropertyCard> {
  bool _isFavorite = false;
  bool _loadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];
    if (userId == null) return;
    final favDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(widget.property.id)
            .get();
    if (mounted) setState(() => _isFavorite = favDoc.exists);
  }

  Future<void> _toggleFavorite() async {
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];
    if (userId == null) return;
    setState(() => _loadingFavorite = true);
    final favDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(widget.property.id);
    if (_isFavorite) {
      await favDoc.delete();
      if (mounted) setState(() => _isFavorite = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    } else {
      await favDoc.set({
        'propertyId': widget.property.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _isFavorite = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
    }
    if (mounted) setState(() => _loadingFavorite = false);
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final exchangeRates = widget.exchangeRates;
    final selectedCurrency = widget.selectedCurrency;
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: Row(
            children: [
              // Image section
              Container(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      child:
                          property.images.isNotEmpty
                              ? Image.network(
                                property.images.first,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildDefaultImage(),
                              )
                              : _buildDefaultImage(),
                    ),
                    // Status badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(property.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _loadingFavorite ? null : _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: _isFavorite ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${property.city}, ${property.state}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        _formatPrice(property.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildCompactFeature(
                            Icons.bed_rounded,
                            '${property.bedrooms}',
                          ),
                          const SizedBox(width: 12),
                          _buildCompactFeature(
                            Icons.bathtub_rounded,
                            '${property.bathrooms}',
                          ),
                          const SizedBox(width: 12),
                          _buildCompactFeature(
                            Icons.square_foot_rounded,
                            '${property.area.toInt()}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_rounded, size: 24, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'for rent':
        return Colors.green;
      case 'for sale':
        return Colors.blue;
      case 'sold':
        return Colors.red;
      case 'rented':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  String _formatPrice(double price) {
    final rate = widget.exchangeRates[widget.selectedCurrency] ?? 1.0;
    final convertedPrice = price * rate;
    final symbol =
        supportedCurrencies.firstWhere(
          (currency) => currency['code'] == widget.selectedCurrency,
          orElse: () => {'code': 'USD', 'symbol': ' 24'},
        )['symbol'];
    return '$symbol${convertedPrice.round()}';
  }
}

class FeaturedPropertyCard extends StatefulWidget {
  final Property property;
  final VoidCallback onTap;
  final Map<String, double> exchangeRates;
  final String selectedCurrency;

  const FeaturedPropertyCard({
    Key? key,
    required this.property,
    required this.onTap,
    required this.exchangeRates,
    required this.selectedCurrency,
  }) : super(key: key);

  @override
  State<FeaturedPropertyCard> createState() => _FeaturedPropertyCardState();
}

class _FeaturedPropertyCardState extends State<FeaturedPropertyCard> {
  bool _isFavorite = false;
  bool _loadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];
    if (userId == null) return;
    final favDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(widget.property.id)
            .get();
    if (mounted) setState(() => _isFavorite = favDoc.exists);
  }

  Future<void> _toggleFavorite() async {
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];
    if (userId == null) return;
    setState(() => _loadingFavorite = true);
    final favDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(widget.property.id);
    if (_isFavorite) {
      await favDoc.delete();
      if (mounted) setState(() => _isFavorite = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    } else {
      await favDoc.set({
        'propertyId': widget.property.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _isFavorite = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
    }
    if (mounted) setState(() => _loadingFavorite = false);
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final exchangeRates = widget.exchangeRates;
    final selectedCurrency = widget.selectedCurrency;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image section with featured tag
              Container(
                height: 180,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child:
                          property.images.isNotEmpty
                              ? Image.network(
                                property.images.first,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildDefaultImage(),
                              )
                              : _buildDefaultImage(),
                    ),
                    // Featured tag (orange gradient)
                    if (property.isFeatured)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF9800), // deep orange
                                Color(0xFFFFB74D), // lighter orange
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF9800).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'FEATURED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Status badge (colored by status)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(property.status),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _getStatusText(property.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: _loadingFavorite ? null : _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: _isFavorite ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and rating row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (property.rating != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFF8E1), // light amber
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFC107), // amber
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  property.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Color(0xFFFFA000), // dark amber
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${property.city}, ${property.state}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatPrice(property.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFeature(
                          Icons.bed_rounded,
                          '${property.bedrooms}',
                        ),
                        const SizedBox(width: 16),
                        _buildFeature(
                          Icons.bathtub_rounded,
                          '${property.bathrooms}',
                        ),
                        const SizedBox(width: 16),
                        _buildFeature(
                          Icons.square_foot_rounded,
                          '${property.area.toInt()}',
                        ),
                      ],
                    ),
                    if (property.reviewsCount != null &&
                        property.reviewsCount! > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${property.reviewsCount} reviews',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            'No Image Available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'for rent':
        return Colors.green;
      case 'for sale':
        return Colors.blue;
      case 'sold':
        return Colors.red;
      case 'rented':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'for rent':
        return 'Rent';
      case 'for sale':
        return 'Sale';
      case 'sold':
        return 'Sold';
      case 'rented':
        return 'Rented';
      default:
        return status;
    }
  }

  String _formatPrice(double price) {
    final rate = widget.exchangeRates[widget.selectedCurrency] ?? 1.0;
    final convertedPrice = price * rate;
    final symbol =
        supportedCurrencies.firstWhere(
          (currency) => currency['code'] == widget.selectedCurrency,
          orElse: () => {'code': 'USD', 'symbol': ' 24'},
        )['symbol'];
    return '$symbol${convertedPrice.round()}';
  }
}

class GridPropertyCard extends StatefulWidget {
  final Property property;
  final VoidCallback onTap;
  final Map<String, double> exchangeRates;
  final String selectedCurrency;

  const GridPropertyCard({
    Key? key,
    required this.property,
    required this.onTap,
    required this.exchangeRates,
    required this.selectedCurrency,
  }) : super(key: key);

  @override
  State<GridPropertyCard> createState() => _GridPropertyCardState();
}

class _GridPropertyCardState extends State<GridPropertyCard> {
  bool _isFavorite = false;
  bool _loadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];
    if (userId == null) return;
    final favDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(widget.property.id)
            .get();
    if (mounted) setState(() => _isFavorite = favDoc.exists);
  }

  Future<void> _toggleFavorite() async {
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];
    if (userId == null) return;
    setState(() => _loadingFavorite = true);
    final favDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(widget.property.id);
    if (_isFavorite) {
      await favDoc.delete();
      if (mounted) setState(() => _isFavorite = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    } else {
      await favDoc.set({
        'propertyId': widget.property.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _isFavorite = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
    }
    if (mounted) setState(() => _loadingFavorite = false);
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final exchangeRates = widget.exchangeRates;
    final selectedCurrency = widget.selectedCurrency;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image and badges
              Container(
                height: 110,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child:
                          property.images.isNotEmpty
                              ? Image.network(
                                property.images.first,
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildDefaultImage(),
                              )
                              : _buildDefaultImage(),
                    ),
                    if (property.isFeatured)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF9800).withOpacity(0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              const Text(
                                'FEATURED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _loadingFavorite ? null : _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: _isFavorite ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(property.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(property.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 10,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${property.city}, ${property.state}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatPrice(property.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildFeature(
                            Icons.bed_rounded,
                            '${property.bedrooms}',
                          ),
                          const SizedBox(width: 6),
                          _buildFeature(
                            Icons.bathtub_rounded,
                            '${property.bathrooms}',
                          ),
                          const SizedBox(width: 6),
                          _buildFeature(
                            Icons.square_foot_rounded,
                            '${property.area.toInt()}',
                          ),
                        ],
                      ),
                      if (property.rating != null) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFC107),
                                size: 10,
                              ),
                              const SizedBox(width: 1),
                              Text(
                                property.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Color(0xFFFFA000),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: double.infinity,
      height: 110,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_rounded, size: 24, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'for rent':
        return Colors.green;
      case 'for sale':
        return Colors.blue;
      case 'sold':
        return Colors.red;
      case 'rented':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'for rent':
        return 'Rent';
      case 'for sale':
        return 'Sale';
      case 'sold':
        return 'Sold';
      case 'rented':
        return 'Rented';
      default:
        return status;
    }
  }

  String _formatPrice(double price) {
    final rate = widget.exchangeRates[widget.selectedCurrency] ?? 1.0;
    final convertedPrice = price * rate;
    final symbol =
        supportedCurrencies.firstWhere(
          (currency) => currency['code'] == widget.selectedCurrency,
          orElse: () => {'code': 'USD', 'symbol': '\$'},
        )['symbol'];
    return '$symbol${convertedPrice.round()}';
  }
}
