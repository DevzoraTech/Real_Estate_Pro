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

const supportedCurrencies = [
  {'code': 'USD', 'symbol': ' 4'},
  {'code': 'UGX', 'symbol': 'USh'},
  {'code': 'EUR', 'symbol': ' 0'},
];

class PropertyListPage extends StatefulWidget {
  const PropertyListPage({super.key});

  @override
  State<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage> {
  String _selectedType = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PropertyCardViewStyle _recentlyAddedViewStyle = PropertyCardViewStyle.compact;
  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {'USD': 1.0};
  DateTime? _lastRatesFetch;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    _fetchExchangeRates();
  }

  // Update _fetchExchangeRates to use ExchangeRate-API with UGX as the base and the provided API key.
  Future<void> _fetchExchangeRates() async {
    // Only fetch if not fetched in the last hour
    if (_lastRatesFetch != null &&
        DateTime.now().difference(_lastRatesFetch!) < Duration(hours: 1))
      return;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildSearchBar(),
            _buildPropertyTypeFilters(),
            _buildSearchResultsSection(),
            _buildFeaturedSection(),
            _buildRecentlyAddedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Location',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'San Francisco, CA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _selectedCurrency,
                      items:
                          supportedCurrencies
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c['code']!,
                                  child: Text(c['code']!),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCurrency = value;
                          });
                          _fetchExchangeRates();
                        }
                      },
                      underline: SizedBox(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.notifications_outlined, size: 24),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Find the',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
            ),
            const Text(
              'Perfect Place',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
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
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search property...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.tune,
                  color: AppColors.primary,
                  size: 24,
                ),
                onPressed: _showFilterBottomSheet,
                tooltip: 'Filter',
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyTypeFilters() {
    final types = ['All', 'Villa', 'House', 'Apartment', 'Condo'];

    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        margin: const EdgeInsets.only(top: 24),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            final isSelected = _selectedType == type;

            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = type;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
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
            final docs = snapshot.data?.docs ?? [];
            final query = _searchQuery.toLowerCase();
            final results =
                docs.where((doc) {
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
              itemBuilder: (context, index) {
                try {
                  final doc = results[index];
                  final data = doc.data() as Map<String, dynamic>?;
                  print('Search property data at $index: $data');
                  if (data == null || data['title'] == null) {
                    print(
                      'Null or invalid search property data at index: $index',
                    );
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
                  print(
                    'Property \'${doc.id}\' rating: \'${data['rating']}\', reviews_count: \'${data['reviews_count']}\'',
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
                  print(
                    'Error building Search property card at index $index: $e',
                  );
                  return const SizedBox.shrink();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Properties',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(onPressed: () {}, child: const Text('See all')),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('properties')
                    .where('isFeatured', isEqualTo: true)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No featured properties.'));
              }
              return SizedBox(
                height: 300,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    try {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>?;
                      print('Featured property data at $index: $data');
                      if (data == null || data['title'] == null) {
                        print(
                          'Null or invalid featured property data at index: $index',
                        );
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
                      print(
                        'Property \'${doc.id}\' rating: \'${data['rating']}\', reviews_count: \'${data['reviews_count']}\'',
                      );
                      return ModernPropertyCard(
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
                      print(
                        'Error building Featured property card at index $index: $e',
                      );
                      return const SizedBox.shrink();
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyAddedSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('properties')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        print('Recently Added fetched: ${docs.length}');
        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(child: Text('No properties found.')),
          );
        }
        final showSeeMore = docs.length > 2;
        final visibleDocs = showSeeMore ? docs.take(2).toList() : docs;
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index < visibleDocs.length) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recently Added Properties',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _recentlyAddedViewStyle ==
                                      PropertyCardViewStyle.compact
                                  ? Icons.view_agenda
                                  : Icons.view_module,
                            ),
                            tooltip:
                                _recentlyAddedViewStyle ==
                                        PropertyCardViewStyle.compact
                                    ? 'Large image view'
                                    : 'Compact view',
                            onPressed: () {
                              setState(() {
                                _recentlyAddedViewStyle =
                                    _recentlyAddedViewStyle ==
                                            PropertyCardViewStyle.compact
                                        ? PropertyCardViewStyle.largeImage
                                        : PropertyCardViewStyle.compact;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildRecentlyAddedCard(visibleDocs[index], context),
                  ],
                );
              }
              return _buildRecentlyAddedCard(visibleDocs[index], context);
            } else if (showSeeMore && index == visibleDocs.length) {
              final remaining = docs.length - 2;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AllRecentlyAddedPage(
                              docs: docs,
                              cardBuilder: _buildRecentlyAddedCard,
                              exchangeRates: _exchangeRates,
                              selectedCurrency: _selectedCurrency,
                            ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('See more'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          remaining.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return null;
          }, childCount: visibleDocs.length + (showSeeMore ? 1 : 0)),
        );
      },
    );
  }

  Widget _buildRecentlyAddedCard(
    QueryDocumentSnapshot doc,
    BuildContext context,
  ) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      print('Recently Added property data: $data');
      if (data == null || data['title'] == null) {
        print('Null or invalid property data');
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
        latitude: 0, // Add geolocation if available
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
      print(
        'Property \'${doc.id}\' rating: \'${data['rating']}\', reviews_count: \'${data['reviews_count']}\'',
      );
      if (_recentlyAddedViewStyle == PropertyCardViewStyle.largeImage) {
        return LargeImagePropertyCard(
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
      }
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
      print('Error building Recently Added property card: $e');
      return const SizedBox.shrink();
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: const Center(child: Text('Filter options go here')),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

Future<Map<String, dynamic>> fetchPropertyReviewStats(String propertyId) async {
  final reviewsSnapshot =
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .collection('reviews')
          .get();
  final reviews = reviewsSnapshot.docs;
  if (reviews.isEmpty) {
    return {'rating': 0.0, 'reviewsCount': 0};
  }
  double sum = 0;
  for (final doc in reviews) {
    final data = doc.data();
    final rating = (data['rating'] as num?)?.toDouble();
    if (rating != null) sum += rating;
  }
  return {'rating': sum / reviews.length, 'reviewsCount': reviews.length};
}

class ModernPropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final Map<String, double> exchangeRates;
  final String selectedCurrency;

  const ModernPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    required this.exchangeRates,
    required this.selectedCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Image section
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        color: Colors.grey[300],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          property.mainImage.isNotEmpty
                              ? property.mainImage
                              : 'https://via.placeholder.com/150', // fallback placeholder
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image_not_supported, size: 40),
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
                    if (property.isFeatured)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content section
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<Map<String, dynamic>>(
                      future: fetchPropertyReviewStats(property.id),
                      builder: (context, snapshot) {
                        final rating =
                            snapshot.data != null
                                ? snapshot.data!['rating'] as double
                                : 0.0;
                        final reviewsCount =
                            snapshot.data != null
                                ? snapshot.data!['reviewsCount'] as int
                                : 0;
                        return Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (reviewsCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '($reviewsCount reviews)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${property.city}, ${property.state}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.formatPrice(
                        property.price *
                            (exchangeRates[selectedCurrency] ?? 1.0),
                        currency: selectedCurrency,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildFeature(Icons.bed, property.bedrooms.toString()),
                        const SizedBox(width: 12),
                        _buildFeature(
                          Icons.bathtub,
                          property.bathrooms.toString(),
                        ),
                        const SizedBox(width: 12),
                        _buildFeature(
                          Icons.square_foot,
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

  Widget _buildFeature(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(value, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

class CompactPropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final Map<String, double> exchangeRates;
  final String selectedCurrency;

  const CompactPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    required this.exchangeRates,
    required this.selectedCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10), // Slightly reduced padding
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    property.mainImage.isNotEmpty
                        ? property.mainImage
                        : 'https://via.placeholder.com/150', // fallback placeholder
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported, size: 30),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<Map<String, dynamic>>(
                      future: fetchPropertyReviewStats(property.id),
                      builder: (context, snapshot) {
                        final rating =
                            snapshot.data != null
                                ? snapshot.data!['rating'] as double
                                : 0.0;
                        final reviewsCount =
                            snapshot.data != null
                                ? snapshot.data!['reviewsCount'] as int
                                : 0;
                        return Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (reviewsCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '($reviewsCount reviews)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${property.city}, ${property.state}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.formatPrice(
                        property.price *
                            (exchangeRates[selectedCurrency] ?? 1.0),
                        currency: selectedCurrency,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _buildFeature(Icons.bed, property.bedrooms.toString()),
                        const SizedBox(width: 12),
                        _buildFeature(
                          Icons.bathtub,
                          property.bathrooms.toString(),
                        ),
                        const SizedBox(width: 12),
                        _buildFeature(
                          Icons.square_foot,
                          '${property.area.toInt()}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.favorite_border, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(value, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

enum PropertyCardViewStyle { compact, largeImage }

class AllRecentlyAddedPage extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final Widget Function(QueryDocumentSnapshot, BuildContext) cardBuilder;
  final Map<String, double> exchangeRates;
  final String selectedCurrency;
  const AllRecentlyAddedPage({
    Key? key,
    required this.docs,
    required this.cardBuilder,
    required this.exchangeRates,
    required this.selectedCurrency,
  }) : super(key: key);

  @override
  State<AllRecentlyAddedPage> createState() => _AllRecentlyAddedPageState();
}

class _AllRecentlyAddedPageState extends State<AllRecentlyAddedPage> {
  PropertyCardViewStyle _viewStyle = PropertyCardViewStyle.compact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Recently Added Properties'),
        actions: [
          IconButton(
            icon: Icon(
              _viewStyle == PropertyCardViewStyle.compact
                  ? Icons.view_agenda
                  : Icons.view_module,
            ),
            tooltip:
                _viewStyle == PropertyCardViewStyle.compact
                    ? 'Large image view'
                    : 'Compact view',
            onPressed: () {
              setState(() {
                _viewStyle =
                    _viewStyle == PropertyCardViewStyle.compact
                        ? PropertyCardViewStyle.largeImage
                        : PropertyCardViewStyle.compact;
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.docs.length,
        itemBuilder: (context, index) {
          final doc = widget.docs[index];
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
          if (_viewStyle == PropertyCardViewStyle.largeImage) {
            return LargeImagePropertyCard(
              property: property,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.propertyDetail,
                  arguments: property,
                );
              },
              exchangeRates: widget.exchangeRates,
              selectedCurrency: widget.selectedCurrency,
            );
          }
          return CompactPropertyCard(
            property: property,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.propertyDetail,
                arguments: property,
              );
            },
            exchangeRates: widget.exchangeRates,
            selectedCurrency: widget.selectedCurrency,
          );
        },
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              height: 160,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                ),
                              ),
                            ),
                      )
                      : Container(
                        height: 160,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 40),
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        property.price > 0
                            ? Helpers.formatPrice(
                              property.price *
                                  (exchangeRates[selectedCurrency] ?? 1.0),
                              currency: selectedCurrency,
                            )
                            : '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      FutureBuilder<Map<String, dynamic>>(
                        future: fetchPropertyReviewStats(property.id),
                        builder: (context, snapshot) {
                          final rating =
                              snapshot.data != null
                                  ? snapshot.data!['rating'] as double
                                  : 0.0;
                          return Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address.isNotEmpty
                              ? property.address
                              : '${property.city}, ${property.state}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFeature(Icons.bed, property.bedrooms.toString()),
                      const SizedBox(width: 12),
                      _buildFeature(
                        Icons.bathtub,
                        property.bathrooms.toString(),
                      ),
                      const SizedBox(width: 12),
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
      ),
    );
  }

  Widget _buildFeature(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}
