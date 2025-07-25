import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/models/property_model.dart';
import '../../../../core/utils/helpers.dart';
import 'package:get_it/get_it.dart';
import '../../../properties/domain/repositories/property_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'package:mobile_1/features/properties/data/repositories/property_repository_impl.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<PropertyModel> _favorites = [];
  bool _isLoading = true;
  bool _clearingFavorites = false;

  final PropertyRepository _propertyRepository = GetIt.I<PropertyRepository>();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];
    List<String> firestoreFavoriteIds = [];
    if (userId != null) {
      // Load favorite IDs from Firestore
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('favorites')
              .get();
      firestoreFavoriteIds = snapshot.docs.map((doc) => doc.id).toList();
    }
    // Fetch property data for all favorite IDs directly from Firestore
    List<PropertyModel> favoriteProperties = [];
    for (final id in firestoreFavoriteIds) {
      final doc =
          await FirebaseFirestore.instance
              .collection('properties')
              .doc(id)
              .get();
      if (doc.exists) {
        final property = PropertyModel.fromFirestore(id, doc.data()!);
        favoriteProperties.add(property);
      }
    }
    setState(() {
      _favorites = favoriteProperties;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: const Center(child: Text('Please log in to view favorites.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('favorites')
                    .snapshots(),
            builder: (context, snapshot) {
              final hasFavorites =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              if (!hasFavorites) return const SizedBox.shrink();
              return IconButton(
                icon:
                    _clearingFavorites
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.clear_all),
                onPressed:
                    _clearingFavorites
                        ? null
                        : () {
                          _showClearAllDialog(userId);
                        },
                tooltip:
                    _clearingFavorites ? 'Clearing...' : 'Clear All Favorites',
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('favorites')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _buildEmptyState();
          return FutureBuilder<List<PropertyModel>>(
            future: _fetchFavoriteProperties(docs),
            builder: (context, propSnapshot) {
              if (propSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final favorites = propSnapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  return _buildFavoriteCard(favorites[index], userId);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<PropertyModel>> _fetchFavoriteProperties(
    List<QueryDocumentSnapshot> docs,
  ) async {
    List<PropertyModel> favoriteProperties = [];
    for (final doc in docs) {
      final id = doc.id;
      final propDoc =
          await FirebaseFirestore.instance
              .collection('properties')
              .doc(id)
              .get();
      if (propDoc.exists) {
        final property = PropertyModel.fromFirestore(id, propDoc.data()!);
        favoriteProperties.add(property);
      }
    }
    return favoriteProperties;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          const Text(
            'No favorites yet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Start browsing properties and add them\nto your favorites by tapping the heart icon',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate to property list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Browse Properties'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(PropertyModel property, String userId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.propertyDetail,
            arguments: property.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('favorites')
                            .doc(property.id)
                            .delete();
                      },
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          property.isForSale
                              ? AppColors.forSale
                              : AppColors.forRent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      Helpers.getPropertyStatusText(property.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                        size: 16,
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
                  Text(
                    Helpers.formatPrice(property.price),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
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
                        Helpers.formatArea(property.area),
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

  void _removeFavorite(PropertyModel property) {
    setState(() {
      _favorites.removeWhere((p) => p.id == property.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${property.title} removed from favorites'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _favorites.add(property);
            });
          },
        ),
      ),
    );
  }

  void _showClearAllDialog(String userId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Favorites'),
            content: const Text(
              'Are you sure you want to remove all properties from your favorites?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    _clearingFavorites
                        ? null
                        : () async {
                          setState(() => _clearingFavorites = true);
                          Navigator.pop(context);
                          try {
                            final favs =
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('favorites')
                                    .get();
                            for (final doc in favs.docs) {
                              await doc.reference.delete();
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All favorites cleared'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to clear favorites: ${e.toString()}',
                                ),
                              ),
                            );
                          } finally {
                            setState(() => _clearingFavorites = false);
                          }
                        },
                child:
                    _clearingFavorites
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Clear All'),
              ),
            ],
          ),
    );
  }
}
