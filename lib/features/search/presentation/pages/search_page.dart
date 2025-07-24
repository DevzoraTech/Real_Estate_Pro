import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/property_model.dart';
import '../../../../core/utils/helpers.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _selectedType = 'All';
  String _selectedStatus = 'All';
  RangeValues _priceRange = const RangeValues(
    0,
    15000,
  ); // €0 to €500/night * 30 days
  int _minBedrooms = 0;
  int _minBathrooms = 0;
  final bool _showMap = false;
  bool _isLoading = false;
  List<PropertyModel> _searchResults = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialResults();
  }

  void _loadInitialResults() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    final mockResults = [
      PropertyModel(
        id: '1',
        title: 'Cozy apartment for rent',
        description:
            'Located on the plateau, central and close to all amenities',
        type: 'Apartment',
        status: 'for_rent',
        price: 80 * 30, // €80/night * 30 days
        area: 1200,
        bedrooms: 2,
        bathrooms: 1,
        address: '164 Avenue du Vallon de la Lauvette',
        city: 'Nice',
        state: 'France',
        zipCode: '06000',
        latitude: 43.7102,
        longitude: 7.2620,
        images: [
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400',
        ],
        amenities: ['WiFi', 'Kitchen', 'Heating'],
        ownerId: 'owner1',
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
      PropertyModel(
        id: '2',
        title: 'Modern Studio',
        description: 'Bright studio in the heart of the city',
        type: 'Studio',
        status: 'for_rent',
        price: 55 * 30, // €55/night * 30 days
        area: 450,
        bedrooms: 1,
        bathrooms: 1,
        address: '25 Rue de la Liberté',
        city: 'Nice',
        state: 'France',
        zipCode: '06000',
        latitude: 43.7009,
        longitude: 7.2828,
        images: [
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400',
        ],
        amenities: ['WiFi', 'Kitchen'],
        ownerId: 'owner2',
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      ),
      PropertyModel(
        id: '3',
        title: 'Luxury Apartment',
        description: 'Spacious apartment with sea view',
        type: 'Apartment',
        status: 'for_rent',
        price: 80 * 30, // €80/night * 30 days
        area: 900,
        bedrooms: 2,
        bathrooms: 1,
        address: '10 Promenade des Anglais',
        city: 'Nice',
        state: 'France',
        zipCode: '06000',
        latitude: 43.6959,
        longitude: 7.2654,
        images: [
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400',
        ],
        amenities: ['WiFi', 'Kitchen', 'Sea View', 'Air Conditioning'],
        ownerId: 'owner3',
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      ),
      PropertyModel(
        id: '4',
        title: 'Cozy Studio',
        description: 'Perfect for a single person or couple',
        type: 'Studio',
        status: 'for_rent',
        price: 69 * 30, // €69/night * 30 days
        area: 400,
        bedrooms: 1,
        bathrooms: 1,
        address: '35 Rue Pastorelli',
        city: 'Nice',
        state: 'France',
        zipCode: '06000',
        latitude: 43.7032,
        longitude: 7.2707,
        images: [
          'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=400',
        ],
        amenities: ['WiFi', 'Kitchen', 'Heating'],
        ownerId: 'owner2',
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
    ];

    setState(() {
      _searchResults = mockResults;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            _buildSearchHeader(),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'List'), Tab(text: 'Map')],
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildListView(), _buildMapView()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Handle back navigation
                },
              ),
              const Expanded(
                child: Text(
                  'Search Properties',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () {
                  _showFilterBottomSheet();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'France, Nice',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                // Implement search
              },
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Type: Apartment', true),
                _buildFilterChip('Price: €50-€80', true),
                _buildFilterChip('Area', false),
                _buildFilterChip('Floor', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          // Handle filter selection
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No properties found matching your criteria'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final property = _searchResults[index];
        return _buildPropertyCard(property);
      },
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    property.mainImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.favorite_border, size: 18),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '€${(property.price / 30).round()}/night',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            '4.8',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Property Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.fullAddress,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                      '${property.area.toInt()} m²',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // Map Placeholder
        Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map, size: 80, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Map View',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Interactive map would be displayed here',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.location_on),
                  label: const Text('Use Current Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Map Price Markers
        Positioned(left: 100, top: 150, child: _buildPriceMarker('€80')),
        Positioned(right: 120, top: 200, child: _buildPriceMarker('€55')),
        Positioned(left: 180, bottom: 180, child: _buildPriceMarker('€69')),

        // Property Card at Bottom
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        _searchResults.isNotEmpty
                            ? _searchResults[0].mainImage
                            : '',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Cozy apartment for rent',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text(
                                'Nice, France',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '€80/night',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceMarker(String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        price,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property Type
                          const Text(
                            'Property Type',
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
                                AppConstants.propertyTypes.map((type) {
                                  final isSelected = _selectedType == type;
                                  return ChoiceChip(
                                    label: Text(type),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        _selectedType = selected ? type : 'All';
                                      });
                                    },
                                    backgroundColor: Colors.white,
                                    selectedColor: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    labelStyle: TextStyle(
                                      color:
                                          isSelected
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Price Range
                          const Text(
                            'Price Range (per night)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RangeSlider(
                            values: RangeValues(
                              _priceRange.start / 30,
                              _priceRange.end / 30,
                            ),
                            min: 0,
                            max: 500,
                            divisions: 50,
                            labels: RangeLabels(
                              '€${(_priceRange.start / 30).round()}',
                              '€${(_priceRange.end / 30).round()}',
                            ),
                            onChanged: (values) {
                              setModalState(() {
                                _priceRange = RangeValues(
                                  values.start * 30,
                                  values.end * 30,
                                );
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('€${(_priceRange.start / 30).round()}'),
                              Text('€${(_priceRange.end / 30).round()}'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Bedrooms
                          const Text(
                            'Bedrooms',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(5, (index) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: ChoiceChip(
                                    label: Text('${index + 1}'),
                                    selected: _minBedrooms == index + 1,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        _minBedrooms = selected ? index + 1 : 0;
                                      });
                                    },
                                    backgroundColor: Colors.white,
                                    selectedColor: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    labelStyle: TextStyle(
                                      color:
                                          _minBedrooms == index + 1
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),

                          // Bathrooms
                          const Text(
                            'Bathrooms',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(3, (index) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: ChoiceChip(
                                    label: Text('${index + 1}'),
                                    selected: _minBathrooms == index + 1,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        _minBathrooms =
                                            selected ? index + 1 : 0;
                                      });
                                    },
                                    backgroundColor: Colors.white,
                                    selectedColor: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    labelStyle: TextStyle(
                                      color:
                                          _minBathrooms == index + 1
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),

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
                            children: [
                              _buildAmenityChip('WiFi', true),
                              _buildAmenityChip('Kitchen', false),
                              _buildAmenityChip('Parking', false),
                              _buildAmenityChip('Pool', false),
                              _buildAmenityChip('Air Conditioning', true),
                              _buildAmenityChip('Heating', false),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _clearFilters();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Show Results'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAmenityChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // Handle amenity selection
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      checkmarkColor: AppColors.primary,
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = 'All';
      _selectedStatus = 'All';
      _priceRange = const RangeValues(0, 1000000);
      _minBedrooms = 0;
      _minBathrooms = 0;
    });
  }

  void _applyFilters() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call with delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filters applied!'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
