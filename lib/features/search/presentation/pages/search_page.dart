import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/property_model.dart';
import '../../../../core/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/pages/login_page.dart';

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
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // _loadInitialResults(); // Remove this, as we use Firestore stream now
  }

  // Remove _loadInitialResults and _searchResults

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
                  color: Colors.black.withOpacity(0.05),
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
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close, size: 18),
                          ),
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildActiveFilterChips(),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    final List<Widget> chips = [];
    if (_selectedType != 'All') {
      chips.add(
        _buildRemovableChip('Type: $_selectedType', () {
          setState(() {
            _selectedType = 'All';
          });
        }),
      );
    }
    if (_selectedStatus != 'All') {
      chips.add(
        _buildRemovableChip('Status: $_selectedStatus', () {
          setState(() {
            _selectedStatus = 'All';
          });
        }),
      );
    }
    if (_minBedrooms > 0) {
      chips.add(
        _buildRemovableChip('Bedrooms: $_minBedrooms+', () {
          setState(() {
            _minBedrooms = 0;
          });
        }),
      );
    }
    if (_minBathrooms > 0) {
      chips.add(
        _buildRemovableChip('Bathrooms: $_minBathrooms+', () {
          setState(() {
            _minBathrooms = 0;
          });
        }),
      );
    }
    if (_priceRange.start > 0 || _priceRange.end < 1000000) {
      chips.add(
        _buildRemovableChip(
          'Price: €${(_priceRange.start / 30).round()}-€${(_priceRange.end / 30).round()}',
          () {
            setState(() {
              _priceRange = const RangeValues(0, 1000000);
            });
          },
        ),
      );
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }

  Widget _buildRemovableChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        onDeleted: onRemove,
        backgroundColor: AppColors.primary.withOpacity(0.08),
        labelStyle: const TextStyle(color: AppColors.primary),
        deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Query _buildPropertyQuery() {
    Query query = FirebaseFirestore.instance.collection('properties');
    if (_selectedType != 'All') {
      query = query.where('type', isEqualTo: _selectedType);
    }
    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    if (_minBedrooms > 0) {
      query = query.where('bedrooms', isGreaterThanOrEqualTo: _minBedrooms);
    }
    if (_minBathrooms > 0) {
      query = query.where('bathrooms', isGreaterThanOrEqualTo: _minBathrooms);
    }
    // Price range (per month)
    if (_priceRange.start > 0) {
      query = query.where('price', isGreaterThanOrEqualTo: _priceRange.start);
    }
    if (_priceRange.end < 1000000) {
      query = query.where('price', isLessThanOrEqualTo: _priceRange.end);
    }
    return query;
  }

  Widget _buildListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedType = 'All';
                  _selectedStatus = 'All';
                  _minBedrooms = 0;
                  _minBathrooms = 0;
                  _priceRange = const RangeValues(0, 15000);
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildPropertyQuery().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No properties found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try adjusting your filters or search another location.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              final docs = snapshot.data!.docs;
              final properties =
                  docs
                      .map(
                        (doc) => PropertyModel.fromFirestore(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        ),
                      )
                      .toList();
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                itemCount: properties.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final property = properties[index];
                  return _buildPropertyCard(property);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/propertyDetail', // Or use AppRoutes.propertyDetail if available
          arguments: property.id,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: AppColors.primary.withOpacity(0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child:
                      (property.images.isNotEmpty &&
                              property.images[0].toString().trim().isNotEmpty)
                          ? Image.network(
                            property.images[0],
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/house.png',
                                height: 170,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                          : Image.asset(
                            'assets/images/house.png',
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: buildFavoriteIcon(property.id),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
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
                            fontSize: 18,
                          ),
                        ),
                        // If you have real rating data, show it here. Otherwise, remove or show '-'.
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 15,
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildFeature(Icons.bed, '${property.bedrooms}'),
                      const SizedBox(width: 18),
                      _buildFeature(Icons.bathtub, '${property.bathrooms}'),
                      const SizedBox(width: 18),
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
    return StreamBuilder<QuerySnapshot>(
      stream: _buildPropertyQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
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
                  'No properties to display on the map.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        final docs = snapshot.data!.docs;
        final properties =
            docs
                .map(
                  (doc) => PropertyModel.fromFirestore(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  ),
                )
                .toList();
        // For demo, show the first property in the card at the bottom
        final property = properties.first;
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
            // Property Card at Bottom (real data)
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        image: DecorationImage(
                          image:
                              (property.images.isNotEmpty &&
                                      property.images[0]
                                          .toString()
                                          .trim()
                                          .isNotEmpty)
                                  ? NetworkImage(property.images[0])
                                  : const AssetImage('assets/images/house.png')
                                      as ImageProvider,
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
                            Text(
                              property.title,
                              style: const TextStyle(
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
                            const SizedBox(height: 4),
                            Text(
                              '€${(property.price / 30).round()}/night',
                              style: const TextStyle(
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
                                      setState(() {});
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
                              setState(() {});
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
                                      setState(() {});
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
                                      setState(() {});
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
