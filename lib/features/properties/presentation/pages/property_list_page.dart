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
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchExchangeRates();
            // Add a small delay for better UX
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildSearchBar(),
              _buildPropertyTypeFilters(),
              _buildSearchResultsSection(),
              _buildFeaturedSection(),
              _buildRecentlyAddedSection(),
              // Add bottom padding for better scrolling experience
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
                          'Your Location',
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
                                'San Francisco, CA',
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
                            if (value != null) {
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              size: 24,
                              color: AppColors.textPrimary,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildPropertyTypeFilters() {
    final types = [
      {'name': 'All', 'icon': Icons.apps_rounded},
      {'name': 'Villa', 'icon': Icons.villa_rounded},
      {'name': 'House', 'icon': Icons.house_rounded},
      {'name': 'Apartment', 'icon': Icons.apartment_rounded},
      {'name': 'Condo', 'icon': Icons.business_rounded},
    ];

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
                  setState(() {
                    _selectedType = type['name'] as String;
                  });
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
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Featured Properties',
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
                  child: GestureDetector(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'See all',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
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
                                      color: AppColors.secondary.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.schedule_rounded,
                                      color: AppColors.secondary,
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                _recentlyAddedViewStyle ==
                                        PropertyCardViewStyle.compact
                                    ? Icons.view_agenda_rounded
                                    : Icons.view_module_rounded,
                                color: AppColors.primary,
                                size: 20,
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
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.visibility_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'View all properties',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+$remaining',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

Widget buildFavoriteIcon(String propertyId) {
  final user = UserProfile.currentUserProfile;
  final userId = user?['uid'];
  if (userId == null) {
    return const Icon(Icons.favorite_border, size: 18, color: Colors.grey);
  }
  return StreamBuilder<DocumentSnapshot>(
    stream:
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(propertyId)
            .snapshots(),
    builder: (context, snapshot) {
      final isFavorite = snapshot.hasData && snapshot.data!.exists;
      return GestureDetector(
        onTap: () async {
          final favDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('favorites')
              .doc(propertyId);
          if (isFavorite) {
            await favDoc.delete();
          } else {
            await favDoc.set({
              'propertyId': propertyId,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        },
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.grey,
          size: 18,
        ),
      );
    },
  );
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
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with enhanced styling
              Container(
                height: 160,
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.grey[300]!, Colors.grey[200]!],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child:
                            (property.images.isNotEmpty &&
                                    property.images[0]
                                        .toString()
                                        .trim()
                                        .isNotEmpty)
                                ? Image.network(
                                  property.images[0],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary.withOpacity(0.1),
                                            AppColors.primary.withOpacity(0.05),
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.home_work_rounded,
                                          size: 40,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.1),
                                        AppColors.primary.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.home_work_rounded,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                      ),
                    ),
                    // Gradient overlay for better text readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    // Favorite button with enhanced styling
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
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: buildFavoriteIcon(property.id),
                      ),
                    ),
                    // Featured badge with enhanced styling
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
                                AppColors.accent,
                                AppColors.accent.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 8,
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
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Featured',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Enhanced content section - optimized for height
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Price with status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                property.isForSale
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            property.isForSale ? 'Sale' : 'Rent',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color:
                                  property.isForSale
                                      ? AppColors.success
                                      : AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Location with enhanced styling
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 10,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${property.city}, ${property.state}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Rating and Features in one row to save space
                    Row(
                      children: [
                        // Rating
                        FutureBuilder<Map<String, dynamic>>(
                          future: fetchPropertyReviewStats(property.id),
                          builder: (context, snapshot) {
                            final rating =
                                snapshot.data?['rating'] as double? ?? 0.0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // Compact features
                        Expanded(
                          child: Row(
                            children: [
                              _buildCompactFeatureIcon(
                                Icons.bed_rounded,
                                property.bedrooms.toString(),
                              ),
                              const SizedBox(width: 8),
                              _buildCompactFeatureIcon(
                                Icons.bathtub_rounded,
                                property.bathrooms.toString(),
                              ),
                              const SizedBox(width: 8),
                              _buildCompactFeatureIcon(
                                Icons.square_foot_rounded,
                                '${property.area.toInt()}',
                              ),
                            ],
                          ),
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

  Widget _buildEnhancedFeature(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(height: 1),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFeatureIcon(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.primary),
          const SizedBox(width: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Enhanced image container
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.grey[200]!, Colors.grey[100]!],
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            (property.images.isNotEmpty &&
                                    property.images[0]
                                        .toString()
                                        .trim()
                                        .isNotEmpty)
                                ? Image.network(
                                  property.images[0],
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary.withOpacity(0.1),
                                            AppColors.primary.withOpacity(0.05),
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.home_work_rounded,
                                          size: 24,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.1),
                                        AppColors.primary.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.home_work_rounded,
                                      size: 24,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                      ),
                      // Status badge
                      if (property.isFeatured)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Featured',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Enhanced content section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and price row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              property.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: buildFavoriteIcon(property.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Price with status
                      Row(
                        children: [
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
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  property.isForSale
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              property.isForSale ? 'Sale' : 'Rent',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    property.isForSale
                                        ? AppColors.success
                                        : AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Location with enhanced styling
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${property.city}, ${property.state}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Rating and features row
                      Row(
                        children: [
                          // Rating
                          FutureBuilder<Map<String, dynamic>>(
                            future: fetchPropertyReviewStats(property.id),
                            builder: (context, snapshot) {
                              final rating =
                                  snapshot.data?['rating'] as double? ?? 0.0;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          // Features
                          Expanded(
                            child: Row(
                              children: [
                                _buildCompactFeature(
                                  Icons.bed_rounded,
                                  property.bedrooms.toString(),
                                ),
                                const SizedBox(width: 8),
                                _buildCompactFeature(
                                  Icons.bathtub_rounded,
                                  property.bathrooms.toString(),
                                ),
                                const SizedBox(width: 8),
                                _buildCompactFeature(
                                  Icons.square_foot_rounded,
                                  '${property.area.toInt()}',
                                ),
                              ],
                            ),
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

  Widget _buildCompactFeature(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced image section with overlay elements
              Container(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    // Main image container
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          colors: [Colors.grey[300]!, Colors.grey[200]!],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child:
                            property.images.isNotEmpty &&
                                    property.images[0]
                                        .toString()
                                        .trim()
                                        .isNotEmpty
                                ? Image.network(
                                  property.images.first,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AppColors.primary.withOpacity(
                                                0.1,
                                              ),
                                              AppColors.primary.withOpacity(
                                                0.05,
                                              ),
                                            ],
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.home_work_rounded,
                                            size: 60,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                )
                                : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary.withOpacity(0.1),
                                        AppColors.primary.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.home_work_rounded,
                                      size: 60,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                      ),
                    ),
                    // Gradient overlay for better text readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    // Top row with status and favorite
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status badges
                          Row(
                            children: [
                              if (property.isFeatured)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.accent,
                                        AppColors.accent.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 8,
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
                                        'Featured',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      property.isForSale
                                          ? AppColors.success
                                          : AppColors.info,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (property.isForSale
                                              ? AppColors.success
                                              : AppColors.info)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  property.isForSale ? 'For Sale' : 'For Rent',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Favorite button
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: buildFavoriteIcon(property.id),
                          ),
                        ],
                      ),
                    ),
                    // Bottom price overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              Helpers.formatPrice(
                                property.price *
                                    (exchangeRates[selectedCurrency] ?? 1.0),
                                currency: selectedCurrency,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          // Rating badge
                          FutureBuilder<Map<String, dynamic>>(
                            future: fetchPropertyReviewStats(property.id),
                            builder: (context, snapshot) {
                              final rating =
                                  snapshot.data?['rating'] as double? ?? 0.0;
                              final reviewsCount =
                                  snapshot.data?['reviewsCount'] as int? ?? 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (reviewsCount > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '($reviewsCount)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Enhanced content section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Location with enhanced styling
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            property.address.isNotEmpty
                                ? property.address
                                : '${property.city}, ${property.state}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Enhanced features section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildLargeFeature(
                            Icons.bed_rounded,
                            property.bedrooms.toString(),
                            'Bedrooms',
                          ),
                          const SizedBox(width: 20),
                          _buildLargeFeature(
                            Icons.bathtub_rounded,
                            property.bathrooms.toString(),
                            'Bathrooms',
                          ),
                          const SizedBox(width: 20),
                          _buildLargeFeature(
                            Icons.square_foot_rounded,
                            '${property.area.toInt()}',
                            'sq ft',
                          ),
                        ],
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

  Widget _buildFeature(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLargeFeature(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
