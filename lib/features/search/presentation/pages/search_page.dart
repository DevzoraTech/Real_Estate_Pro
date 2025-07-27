import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/property_model.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../../core/routes/app_routes.dart';

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.withOpacity(0.1)
          ..strokeWidth = 1;

    const gridSize = 50.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  RangeValues _priceRange = const RangeValues(0, 15000);
  int _minBedrooms = 0;
  int _minBathrooms = 0;
  final bool _showMap = false;
  bool _isLoading = false;
  late TabController _tabController;

  // Add these for search functionality
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<PropertyModel> _searchResults = [];
  bool _isSearching = false;
  String _sortBy = 'Recently Added';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);

    // Test database connection
    _testDatabaseConnection();
  }

  void _testDatabaseConnection() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('properties')
              .limit(1)
              .get();
      print('Database test - Found ${snapshot.docs.length} documents');
      if (snapshot.docs.isNotEmpty) {
        print('Sample document: ${snapshot.docs.first.data()}');
      }
    } catch (e) {
      print('Database connection error: $e');
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280, // Increased to accommodate all content
              floating: true,
              pinned: false,
              snap: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildSearchHeader(),
                collapseMode: CollapseMode.pin,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [Tab(text: 'List'), Tab(text: 'Map')],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_buildListView(), _buildMapView()],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Properties',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Find your perfect home',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Modern search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by location, type, or features...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      Icons.search_rounded,
                      color:
                          _searchQuery.isNotEmpty
                              ? AppColors.primary
                              : Colors.grey[500],
                      size: 24,
                    ),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            size: 22,
                            color: AppColors.primary,
                          ),
                          onPressed: _showFilterBottomSheet,
                          tooltip: 'Advanced Filters',
                        ),
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildActiveFilterChips(),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedType != 'All' ||
        _selectedStatus != 'All' ||
        _minBedrooms > 0 ||
        _minBathrooms > 0 ||
        _priceRange.start > 0 ||
        _priceRange.end < 15000 ||
        _searchQuery.isNotEmpty;
  }

  Widget _buildActiveFilterChips() {
    if (!_hasActiveFilters()) return const SizedBox.shrink();

    return Container(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedType != 'All')
            _buildRemovableChip('Type: $_selectedType', () {
              setState(() => _selectedType = 'All');
            }),
          if (_selectedStatus != 'All')
            _buildRemovableChip('Status: $_selectedStatus', () {
              setState(() => _selectedStatus = 'All');
            }),
          if (_minBedrooms > 0)
            _buildRemovableChip('${_minBedrooms}+ Beds', () {
              setState(() => _minBedrooms = 0);
            }),
          if (_minBathrooms > 0)
            _buildRemovableChip('${_minBathrooms}+ Baths', () {
              setState(() => _minBathrooms = 0);
            }),
          if (_priceRange.start > 0 || _priceRange.end < 15000)
            _buildRemovableChip(
              '\$${_priceRange.start.toInt()}K - \$${_priceRange.end.toInt()}K',
              () {
                setState(() => _priceRange = const RangeValues(0, 15000));
              },
            ),
          _buildClearAllChip(),
        ],
      ),
    );
  }

  Widget _buildRemovableChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        deleteIcon: const Icon(
          Icons.close_rounded,
          size: 16,
          color: Colors.white,
        ),
        onDeleted: onRemove,
        backgroundColor: Colors.white.withOpacity(0.2),
        side: BorderSide(color: Colors.white.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildClearAllChip() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: const Text(
          'Clear All',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () {
          setState(() {
            _selectedType = 'All';
            _selectedStatus = 'All';
            _minBedrooms = 0;
            _minBathrooms = 0;
            _priceRange = const RangeValues(0, 15000);
            _searchController.clear();
            _searchQuery = '';
          });
        },
        backgroundColor: Colors.red.withOpacity(0.8),
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Query _buildPropertyQuery() {
    Query query = FirebaseFirestore.instance.collection('properties');

    // Start with a simple query and add filters gradually
    try {
      // Apply basic filters
      if (_selectedType != 'All') {
        query = query.where('type', isEqualTo: _selectedType);
      }
      if (_selectedStatus != 'All') {
        query = query.where('status', isEqualTo: _selectedStatus);
      }

      // Add ordering - try with and without other filters
      query = query.orderBy('createdAt', descending: true);

      // Limit results
      query = query.limit(50);
    } catch (e) {
      print('Query building error: $e');
      // Fallback to simple query
      query = FirebaseFirestore.instance
          .collection('properties')
          .orderBy('createdAt', descending: true)
          .limit(50);
    }

    return query;
  }

  List<PropertyModel> _filterProperties(List<PropertyModel> properties) {
    List<PropertyModel> filtered = List.from(properties);

    // Apply price range filter (client-side due to Firestore limitations)
    filtered =
        filtered.where((property) {
          final priceInK = property.price / 1000;
          return priceInK >= _priceRange.start && priceInK <= _priceRange.end;
        }).toList();

    // Apply text search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((property) {
            return property.title.toLowerCase().contains(query) ||
                property.description.toLowerCase().contains(query) ||
                property.city.toLowerCase().contains(query) ||
                property.address.toLowerCase().contains(query) ||
                property.state.toLowerCase().contains(query) ||
                property.type.toLowerCase().contains(query);
          }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Price: Low to High':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Bedrooms':
        filtered.sort((a, b) => b.bedrooms.compareTo(a.bedrooms));
        break;
      case 'Area Size':
        filtered.sort((a, b) => b.area.compareTo(a.area));
        break;
      case 'Most Popular':
        filtered.sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case 'Recently Added':
      default:
        // Keep original order (most recent first from Firestore)
        break;
    }

    return filtered;
  }

  Widget _buildListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildPropertyQuery().snapshots(),
      builder: (context, snapshot) {
        print('StreamBuilder state: ${snapshot.connectionState}');
        print('Has data: ${snapshot.hasData}');
        print('Has error: ${snapshot.hasError}');

        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Container(
            color: const Color(0xFFFAFAFA),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading properties',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Trigger rebuild
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('No data or empty docs');
          return _buildEmptyState();
        }

        final docs = snapshot.data!.docs;
        print('Found ${docs.length} documents');

        final properties =
            docs
                .map((doc) {
                  try {
                    return PropertyModel.fromFirestore(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    );
                  } catch (e) {
                    print('Error parsing property ${doc.id}: $e');
                    return null;
                  }
                })
                .where((property) => property != null)
                .cast<PropertyModel>()
                .toList();

        print('Parsed ${properties.length} properties');

        final filteredProperties = _filterProperties(properties);
        print('Filtered to ${filteredProperties.length} properties');

        if (filteredProperties.isEmpty) {
          return _buildNoResultsState();
        }

        return Container(
          color: const Color(0xFFFAFAFA),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Modern results header
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${filteredProperties.length} Properties Found',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_hasActiveFilters() || _searchQuery.isNotEmpty)
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Results for "$_searchQuery"'
                                    : 'Filtered results',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.sort_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: _showSortBottomSheet,
                          tooltip: 'Sort Properties',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Modern properties list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final property = filteredProperties[index];
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOutBack,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: _buildPropertyCard(property),
                    );
                  }, childCount: filteredProperties.length),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Searching Properties...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the best matches for you',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Properties Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any properties matching your criteria.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedType = 'All';
                      _selectedStatus = 'All';
                      _minBedrooms = 0;
                      _minBathrooms = 0;
                      _priceRange = const RangeValues(0, 15000);
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Clear All Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    _showFilterBottomSheet();
                  },
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Adjust Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Properties Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms or filters'
                  : 'Try adjusting your filters',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedType = 'All';
                  _selectedStatus = 'All';
                  _minBedrooms = 0;
                  _minBathrooms = 0;
                  _priceRange = const RangeValues(0, 15000);
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort Properties',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildSortOption('Recently Added', Icons.access_time),
              _buildSortOption('Price: Low to High', Icons.arrow_upward),
              _buildSortOption('Price: High to Low', Icons.arrow_downward),
              _buildSortOption('Most Popular', Icons.trending_up),
              _buildSortOption('Bedrooms', Icons.bed),
              _buildSortOption('Area Size', Icons.square_foot),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, IconData icon) {
    final isSelected = _sortBy == title;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing:
          isSelected
              ? Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
              : null,
      onTap: () {
        setState(() {
          _sortBy = title;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.propertyDetail,
              arguments: property,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced image section
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      child:
                          property.images.isNotEmpty
                              ? Image.network(
                                property.images.first,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                              )
                              : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.home_rounded,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                    ),
                  ),

                  // Status badge
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(property.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        property.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Favorite button with Firebase integration
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: _buildFavoriteButton(property.id),
                    ),
                  ),

                  // Image count indicator
                  if (property.images.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${property.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Enhanced content section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price and title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$${property.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                property.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (property.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: AppColors.warning,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Featured',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${property.address}, ${property.city}, ${property.state}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Enhanced Property Features
                    Row(
                      children: [
                        _buildEnhancedFeature(
                          Icons.bed_rounded,
                          '${property.bedrooms}',
                          'Bedrooms',
                        ),
                        const SizedBox(width: 20),
                        _buildEnhancedFeature(
                          Icons.bathtub_rounded,
                          '${property.bathrooms}',
                          'Bathrooms',
                        ),
                        const SizedBox(width: 20),
                        _buildEnhancedFeature(
                          Icons.square_foot_rounded,
                          '${property.area.toInt()}',
                          'm²',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Property Description Preview
                    if (property.description.isNotEmpty)
                      Text(
                        property.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.propertyDetail,
                                arguments: property,
                              );
                            },
                            icon: const Icon(
                              Icons.visibility_rounded,
                              size: 18,
                            ),
                            label: const Text('View Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () {
                              _showContactOptions(property);
                            },
                            icon: Icon(
                              Icons.phone_rounded,
                              color: AppColors.primary,
                            ),
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

  Widget _buildEnhancedFeature(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'for sale':
        return AppColors.success;
      case 'for rent':
        return AppColors.primary;
      case 'sold':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildFavoriteButton(String propertyId) {
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];

    if (userId == null) {
      return IconButton(
        icon: const Icon(
          Icons.favorite_border_rounded,
          color: AppColors.textSecondary,
        ),
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.login);
        },
      );
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

        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? Colors.red : AppColors.textSecondary,
          ),
          onPressed: () => _toggleFavorite(propertyId, isFavorite),
        );
      },
    );
  }

  Future<void> _toggleFavorite(String propertyId, bool isFavorite) async {
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];

    if (userId == null) {
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }

    try {
      final favDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(propertyId);

      if (isFavorite) {
        await favDoc.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Removed from favorites'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        await favDoc.set({
          'propertyId': propertyId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Added to favorites'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showContactOptions(PropertyModel property) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Contact Options',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone, color: Colors.green),
                ),
                title: const Text('Call'),
                subtitle: const Text('Speak directly with the agent'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement call functionality
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.message, color: Colors.blue),
                ),
                title: const Text('Message'),
                subtitle: const Text('Send a message to the agent'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement message functionality
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.email, color: Colors.orange),
                ),
                title: const Text('Email'),
                subtitle: const Text('Send an email inquiry'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement email functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildPropertyQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMapLoadingState();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildMapEmptyState();
        }
        final docs = snapshot.data!.docs;
        final properties =
            docs.map((doc) {
              print('Document ID: ${doc.id}'); // Debug print
              return PropertyModel.fromFirestore(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );
            }).toList();

        return Stack(
          children: [
            // Enhanced Map Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[50]!, Colors.green[50]!],
                ),
              ),
              child: Stack(
                children: [
                  // Map Grid Pattern
                  CustomPaint(size: Size.infinite, painter: MapGridPainter()),
                  // Map Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  Icons.map_rounded,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Interactive Map View',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Showing ${properties.length} properties in your area',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Handle current location
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Getting your location...',
                                          ),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.my_location_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('My Location'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      // Handle map settings
                                      _showMapSettings();
                                    },
                                    icon: const Icon(
                                      Icons.settings_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Settings'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
                  // Property Markers Simulation
                  ...properties
                      .take(5)
                      .map((property) => _buildPropertyMarker(property))
                      .toList(),
                ],
              ),
            ),

            // Enhanced Property Card Carousel at Bottom
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                height: 140,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.85),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildMapPropertyCard(property),
                    );
                  },
                ),
              ),
            ),

            // Map Controls
            Positioned(
              top: 20,
              right: 20,
              child: Column(
                children: [
                  _buildMapControlButton(Icons.add, () {}),
                  const SizedBox(height: 8),
                  _buildMapControlButton(Icons.remove, () {}),
                  const SizedBox(height: 8),
                  _buildMapControlButton(Icons.layers_rounded, () {}),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[50]!, Colors.green[50]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading Map...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preparing property locations',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[50]!, Colors.green[50]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Properties on Map',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No properties match your current filters.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedType = 'All';
                        _selectedStatus = 'All';
                        _minBedrooms = 0;
                        _minBathrooms = 0;
                        _priceRange = const RangeValues(0, 15000);
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyMarker(PropertyModel property) {
    final random = property.id.hashCode;
    final left = (random % 200).toDouble() + 50;
    final top = (random % 300).toDouble() + 100;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.propertyDetail,
            arguments: property.id, // Use property.id directly
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '€${(property.price / 30).round()}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapPropertyCard(PropertyModel property) {
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
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.propertyDetail,
            arguments: property.id, // Use property.id directly
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Container(
                width: 120,
                height: 140,
                child:
                    (property.images.isNotEmpty &&
                            property.images[0].toString().trim().isNotEmpty)
                        ? Image.network(
                          property.images[0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/house.png',
                              fit: BoxFit.cover,
                            );
                          },
                        )
                        : Image.asset(
                          'assets/images/house.png',
                          fit: BoxFit.cover,
                        ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.fullAddress,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '€${(property.price / 30).round()}/night',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '4.${property.id.hashCode % 10}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildMapControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primary),
        onPressed: onPressed,
        iconSize: 20,
      ),
    );
  }

  void _showMapSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Map Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.map, color: Colors.blue),
                ),
                title: const Text('Satellite View'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.traffic, color: Colors.green),
                ),
                title: const Text('Traffic Layer'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_city, color: Colors.orange),
                ),
                title: const Text('Show Nearby'),
                subtitle: const Text('Schools, hospitals, etc.'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
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
            color: Colors.black.withOpacity(0.1),
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

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
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                [
                                  'All',
                                  'House',
                                  'Apartment',
                                  'Condo',
                                  'Villa',
                                ].map((type) {
                                  return ChoiceChip(
                                    label: Text(type),
                                    selected: _selectedType == type,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        _selectedType = type;
                                      });
                                    },
                                    selectedColor: AppColors.primary
                                        .withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color:
                                          _selectedType == type
                                              ? AppColors.primary
                                              : Colors.grey[600],
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Status
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                ['All', 'For Rent', 'For Sale', 'Sold'].map((
                                  status,
                                ) {
                                  return ChoiceChip(
                                    label: Text(status),
                                    selected: _selectedStatus == status,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        _selectedStatus = status;
                                      });
                                    },
                                    selectedColor: AppColors.primary
                                        .withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color:
                                          _selectedStatus == status
                                              ? AppColors.primary
                                              : Colors.grey[600],
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Price Range
                          const Text(
                            'Price Range',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 15000,
                            divisions: 100,
                            labels: RangeLabels(
                              '€${(_priceRange.start / 30).round()}',
                              '€${(_priceRange.end / 30).round()}',
                            ),
                            onChanged: (values) {
                              setModalState(() {
                                _priceRange = values;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                          const SizedBox(height: 20),

                          // Bedrooms
                          const Text(
                            'Minimum Bedrooms',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                [0, 1, 2, 3, 4, 5].map((beds) {
                                  return ChoiceChip(
                                    label: Text(beds == 0 ? 'Any' : '$beds+'),
                                    selected: _minBedrooms == beds,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        _minBedrooms = beds;
                                      });
                                    },
                                    selectedColor: AppColors.primary
                                        .withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color:
                                          _minBedrooms == beds
                                              ? AppColors.primary
                                              : Colors.grey[600],
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Bathrooms
                          const Text(
                            'Minimum Bathrooms',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                [0, 1, 2, 3, 4].map((baths) {
                                  return ChoiceChip(
                                    label: Text(baths == 0 ? 'Any' : '$baths+'),
                                    selected: _minBathrooms == baths,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        _minBathrooms = baths;
                                      });
                                    },
                                    selectedColor: AppColors.primary
                                        .withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color:
                                          _minBathrooms == baths
                                              ? AppColors.primary
                                              : Colors.grey[600],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = 'All';
      _selectedStatus = 'All';
      _priceRange = const RangeValues(0, 15000);
      _minBedrooms = 0;
      _minBathrooms = 0;
    });
  }

  void _applyFilters() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filters applied!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
