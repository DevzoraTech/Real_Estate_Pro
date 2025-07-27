import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/property_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../domain/entities/property.dart';
import '../../../../core/models/user_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../chat/presentation/chat_page.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/helpers.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/models/user_profile.dart';
import '../../domain/repositories/property_repository.dart';

extension PropertyModelExtension on PropertyModel {
  static PropertyModel fromProperty(Property p) => PropertyModel(
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

  static PropertyModel fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) => PropertyModel(
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
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

class PropertyDetailPage extends StatefulWidget {
  final String? propertyId;
  final Property? property;

  const PropertyDetailPage({super.key, this.propertyId, this.property});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _showFullDescription = false;
  bool _isLoading = true;
  final PageController _pageController = PageController();
  PropertyModel? _property;
  bool? _isFeaturedRemote;
  UserModel? _agentUser;
  bool _agentLoading = true;
  double? _agentRating;
  int? _agentReviewsCount;
  bool _agentRatingLoading = false;
  List<Map<String, dynamic>> _agentReviews = [];
  bool _agentReviewsLoading = false;
  int _agentTotalReviews = 0;
  double? _propertyRating;
  int? _propertyReviewsCount;
  bool _propertyRatingLoading = false;
  List<Map<String, dynamic>> _propertyReviews = [];
  bool _propertyReviewsLoading = false;
  int _propertyTotalReviews = 0;
  final Map<String, bool> _expandedReviews = {};
  double? _newReviewRating;
  final TextEditingController _reviewCommentController =
      TextEditingController();
  bool _submittingReview = false;

  final PropertyRepository _propertyRepository = GetIt.I<PropertyRepository>();

  // Add this near the top of _PropertyDetailPageState:
  static const List<String> _images = [];

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _property = PropertyModel.fromProperty(widget.property!);
      _isLoading = false;
      _fetchIsFeatured(widget.property!.id);
      _fetchPropertyReviews();
      _fetchAgentUser();
      _checkIfFavorite();
    } else if (widget.propertyId != null) {
      _loadProperty(widget.propertyId!);
      _fetchIsFeatured(widget.propertyId!);
      _fetchPropertyReviews();
    }
  }

  void _loadProperty(String propertyId) async {
    print('Loading property with ID: $propertyId'); // Debug print
    final doc =
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(propertyId)
            .get();

    print('Document exists: ${doc.exists}'); // Debug print

    if (!doc.exists) {
      print('Property document not found for ID: $propertyId'); // Debug print
      setState(() {
        _property = null;
        _isLoading = false;
        _agentLoading = false;
      });
      return;
    }
    final data = doc.data()!;
    setState(() {
      _property = PropertyModel.fromFirestore(propertyId, data);
      _isLoading = false;
    });
    _fetchAgentUser();
    _checkIfFavorite();
  }

  void _checkIfFavorite() async {
    final propertyId = _property?.id ?? widget.propertyId;
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];
    if (propertyId == null || userId == null) return;
    final favDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(propertyId)
            .get();
    setState(() => _isFavorite = favDoc.exists);
  }

  Future<void> _toggleFavorite() async {
    final propertyId = _property?.id ?? widget.propertyId;
    if (propertyId == null) return;
    final user = UserProfile.currentUserProfile;
    final userId = user?['uid'];
    if (userId == null) return;
    setState(() => _isFavorite = !_isFavorite);
    final favDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(propertyId);
    if (_isFavorite) {
      await favDoc.set({
        'propertyId': propertyId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
    } else {
      await favDoc.delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    }
  }

  void _fetchIsFeatured(String propertyId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(propertyId)
            .get();
    if (doc.exists) {
      setState(() {
        _isFeaturedRemote = doc['isFeatured'] == true;
      });
    }
  }

  void _fetchAgentUser() async {
    final property = _property;
    if (property == null) {
      setState(() => _agentLoading = false);
      return;
    }
    final agentId = property.realtorId ?? property.ownerId;
    if (agentId.isEmpty) {
      setState(() => _agentLoading = false);
      return;
    }
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(agentId).get();
    if (!doc.exists) {
      setState(() {
        _agentUser = null;
        _agentLoading = false;
      });
      return;
    }
    final data = doc.data()!;
    setState(() {
      _agentUser = UserModel(
        id: data['uid'] ?? data['id'] ?? '',
        email: data['email'] ?? '',
        firstName:
            (data['firstName'] ??
                    data['first_name'] ??
                    data['displayName'] ??
                    '')
                .toString()
                .split(' ')
                .first,
        lastName: (data['lastName'] ??
                data['last_name'] ??
                data['displayName'] ??
                '')
            .toString()
            .split(' ')
            .skip(1)
            .join(' '),
        phone: data['phone'],
        avatar: data['avatar'],
        role: data['role'] ?? '',
        isVerified: data['isVerified'] ?? data['is_verified'] ?? false,
        createdAt:
            (data['createdAt'] is DateTime)
                ? data['createdAt']
                : (data['createdAt'] is Timestamp)
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
        updatedAt:
            (data['updatedAt'] is DateTime)
                ? data['updatedAt']
                : (data['updatedAt'] is Timestamp)
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.now(),
      );
      _agentLoading = false;
    });
    _fetchAgentRating(agentId);
  }

  void _fetchAgentRating(String agentId) async {
    setState(() {
      _agentRatingLoading = true;
      _agentReviewsLoading = true;
    });
    // Get all reviews for this agent
    final reviewsSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(agentId)
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .get();
    final reviews = reviewsSnapshot.docs;
    if (reviews.isEmpty) {
      setState(() {
        _agentRating = null;
        _agentReviewsCount = 0;
        _agentRatingLoading = false;
        _agentReviews = [];
        _agentReviewsLoading = false;
        _agentTotalReviews = 0;
      });
      return;
    }
    double sum = 0;
    List<Map<String, dynamic>> reviewList = [];
    for (final doc in reviews) {
      final data = doc.data();
      final rating = (data['rating'] as num?)?.toDouble();
      if (rating != null) sum += rating;
      reviewList.add({
        'userId': data['userId'],
        'comment': data['comment'] ?? '',
        'rating': rating ?? 0.0,
        'timestamp': data['timestamp'],
        'reviewId': doc.id,
      });
    }
    // Fetch reviewer names and contacts
    List<Map<String, dynamic>> reviewsWithNames = [];
    for (final review in reviewList) {
      String userId = review['userId'] ?? '';
      String name = '';
      String email = '';
      String phone = '';
      if (userId.isNotEmpty) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (userData['firstName'] != null && userData['lastName'] != null) {
            name = '${userData['firstName']} ${userData['lastName']}';
          } else if (userData['first_name'] != null &&
              userData['last_name'] != null) {
            name = '${userData['first_name']} ${userData['last_name']}';
          } else if (userData['displayName'] != null &&
              (userData['displayName'] as String).trim().isNotEmpty) {
            name = userData['displayName'];
          } else if (userData['email'] != null) {
            name = (userData['email'] as String).split('@').first;
          }
          if (userData['email'] != null) {
            email = userData['email'];
          }
          if (userData['phone'] != null) {
            phone = userData['phone'];
          }
        }
      }
      if (name.trim().isEmpty) name = 'User';
      reviewsWithNames.add({
        ...review,
        'reviewerName': name,
        'reviewerEmail': email,
        'reviewerPhone': phone,
      });
    }
    setState(() {
      _agentRating = sum / reviews.length;
      _agentReviewsCount = reviews.length;
      _agentRatingLoading = false;
      _agentReviews = reviewsWithNames;
      _agentReviewsLoading = false;
      _agentTotalReviews = reviews.length;
    });
  }

  void _fetchPropertyReviews() async {
    final property = _property;
    final propertyId = property?.id ?? widget.propertyId;
    if (propertyId == null) return;
    setState(() {
      _propertyRatingLoading = true;
      _propertyReviewsLoading = true;
    });
    // Get all reviews for this property
    final reviewsSnapshot =
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(propertyId)
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .get();
    final reviews = reviewsSnapshot.docs;
    if (reviews.isEmpty) {
      setState(() {
        _propertyRating = null;
        _propertyReviewsCount = 0;
        _propertyRatingLoading = false;
        _propertyReviews = [];
        _propertyReviewsLoading = false;
        _propertyTotalReviews = 0;
      });
      return;
    }
    double sum = 0;
    List<Map<String, dynamic>> reviewList = [];
    for (final doc in reviews) {
      final data = doc.data();
      final rating = (data['rating'] as num?)?.toDouble();
      if (rating != null) sum += rating;
      reviewList.add({
        'userId': data['userId'],
        'comment': data['comment'] ?? '',
        'rating': rating ?? 0.0,
        'timestamp': data['timestamp'],
        'reviewId': doc.id,
      });
    }
    // Fetch reviewer names and contacts
    List<Map<String, dynamic>> reviewsWithNames = [];
    for (final review in reviewList) {
      String userId = review['userId'] ?? '';
      String name = '';
      String email = '';
      String phone = '';
      if (userId.isNotEmpty) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (userData['firstName'] != null && userData['lastName'] != null) {
            name = '${userData['firstName']} ${userData['lastName']}';
          } else if (userData['first_name'] != null &&
              userData['last_name'] != null) {
            name = '${userData['first_name']} ${userData['last_name']}';
          } else if (userData['displayName'] != null &&
              (userData['displayName'] as String).trim().isNotEmpty) {
            name = userData['displayName'];
          } else if (userData['email'] != null) {
            name = (userData['email'] as String).split('@').first;
          }
          if (userData['email'] != null) {
            email = userData['email'];
          }
          if (userData['phone'] != null) {
            phone = userData['phone'];
          }
        }
      }
      if (name.trim().isEmpty) name = 'User';
      reviewsWithNames.add({
        ...review,
        'reviewerName': name,
        'reviewerEmail': email,
        'reviewerPhone': phone,
      });
    }
    setState(() {
      _propertyRating = sum / reviews.length;
      _propertyReviewsCount = reviews.length;
      _propertyRatingLoading = false;
      _propertyReviews = reviewsWithNames;
      _propertyReviewsLoading = false;
      _propertyTotalReviews = reviews.length;
    });
  }

  Future<void> _toggleFeatured(bool value) async {
    final id = widget.property?.id ?? widget.propertyId;
    if (id == null) return;
    await FirebaseFirestore.instance.collection('properties').doc(id).update({
      'isFeatured': value,
    });
    setState(() {
      _isFeaturedRemote = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> exchangeRates = {'USD': 1.0};
    String selectedCurrency = 'USD';
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      if (args['exchangeRates'] is Map<String, double>) {
        exchangeRates = args['exchangeRates'] as Map<String, double>;
      }
      if (args['selectedCurrency'] is String) {
        selectedCurrency = args['selectedCurrency'] as String;
      }
    }
    final PropertyModel property =
        _property ??
        PropertyModel(
          id: widget.propertyId ?? '',
          title: 'Premium House A24',
          description:
              'Elegant house with modern design and premium finishes. Located in a quiet neighborhood with easy access to schools and shopping centers. This property features spacious rooms, natural lighting, and a beautiful garden. The open floor plan creates a seamless flow between the living, dining, and kitchen areas, perfect for entertaining guests. The primary bedroom suite includes a walk-in closet and a luxurious bathroom with a soaking tub and separate shower. The backyard offers a private oasis with a covered patio and professionally landscaped gardens.',
          type: 'House',
          status: 'for_sale',
          price: 680000,
          area: 1800,
          bedrooms: 3,
          bathrooms: 2,
          parkingSpaces: 1,
          address: '123 Main St',
          city: 'San Francisco',
          state: 'CA',
          zipCode: '94102',
          latitude: 37.7749,
          longitude: -122.4194,
          images: _images,
          amenities: ['Garden', 'Garage'],
          ownerId: 'owner1',
          realtorId: 'agent1',
          isFeatured: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  // Content
                  CustomScrollView(
                    slivers: [
                      // Image Gallery
                      _buildImageGallery(),
                      // Property Details
                      SliverToBoxAdapter(
                        child: Transform.translate(
                          offset: const Offset(0, -20),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPropertyHeader(
                                  property,
                                  exchangeRates,
                                  selectedCurrency,
                                ),
                                _buildPropertyFeatures(),
                                _buildDescription(),
                                _buildAmenities(),
                                _buildLocation(),
                                _buildPropertyReviews(property.id),
                                _buildAgentInfo(),
                                _buildAgentReviews(),
                                _buildSimilarProperties(),
                                const SizedBox(
                                  height: 100,
                                ), // Space for bottom buttons
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Back button and favorite button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCircleButton(
                          Icons.arrow_back,
                          () => Navigator.pop(context),
                        ),
                        _buildCircleButton(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          _toggleFavorite,
                          color: _isFavorite ? Colors.red : null,
                        ),
                      ],
                    ),
                  ),
                  // Bottom action buttons
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomActions(),
                  ),
                ],
              ),
    );
  }

  Widget _buildImageGallery() {
    final images =
        _property?.images != null &&
                _property!.images.isNotEmpty &&
                _property!.images[0].toString().trim().isNotEmpty
            ? _property!.images
            : [''];
    return SliverAppBar(
      expandedHeight: 350,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Stack(
        children: [
          // Enhanced Image Carousel with hero animation
          Hero(
            tag: 'property-image-${_property?.id ?? 'default'}',
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child:
                      (images[index].isNotEmpty)
                          ? Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
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
                                    size: 80,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
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
                                size: 80,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                );
              },
            ),
          ),

          // Enhanced image indicators with modern design
          if (images.length > 1)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentImageIndex == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Enhanced action buttons row
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // Image counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_currentImageIndex + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Action buttons
                Row(
                  children: [
                    // Share button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share feature coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.share_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 3D Tour button with enhanced design
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('3D Tour feature coming soon!'),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.view_in_ar_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '3D Tour',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _buildPropertyHeader(
    PropertyModel property,
    Map<String, double> exchangeRates,
    String selectedCurrency,
  ) {
    final userProfile = UserProfile.currentUserProfile;
    final isOwner =
        userProfile != null && (property.ownerId == userProfile['uid']);
    final isRealtorOrOwner =
        userProfile != null &&
        (userProfile['role'] == 'realtor' ||
            userProfile['role'] == 'property_owner');
    final canFeature = isOwner && isRealtorOrOwner;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced status row with badges
          Row(
            children: [
              // Status badge with enhanced design
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        property.status == 'for_sale'
                            ? [
                              AppColors.success,
                              AppColors.success.withOpacity(0.8),
                            ]
                            : [AppColors.info, AppColors.info.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (property.status == 'for_sale'
                              ? AppColors.success
                              : AppColors.info)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      property.status == 'for_sale'
                          ? Icons.sell_rounded
                          : Icons.home_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      property.status == 'for_sale' ? 'For Sale' : 'For Rent',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Featured badge
              if (property.isFeatured) ...[
                const SizedBox(width: 8),
                Container(
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
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Featured toggle for owners
              if (canFeature && _isFeaturedRemote != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Featured',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Switch(
                        value: _isFeaturedRemote!,
                        onChanged: _toggleFeatured,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Enhanced title with property type
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        property.type,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Rating with enhanced design
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _propertyRating != null
                          ? _propertyRating!.toStringAsFixed(1)
                          : '0.0',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${_propertyReviewsCount ?? 0})',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Enhanced address with map icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.address,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${property.city}, ${property.state} ${property.zipCode}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Map view coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Enhanced price section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  AppColors.primary.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatPrice(
                          (property.price) *
                              (exchangeRates[selectedCurrency] ?? 1.0),
                          currency: selectedCurrency,
                        ),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (property.status == 'for_rent')
                        Text(
                          'per month',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    property.status == 'for_sale'
                        ? Icons.attach_money_rounded
                        : Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyFeatures() {
    final property = _property;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
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
                  Icons.home_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Property Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Compact horizontal features
          Row(
            children: [
              Expanded(
                child: _buildCompactFeatureItem(
                  Icons.bed_rounded,
                  '${property?.bedrooms ?? 0}',
                  'Beds',
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildCompactFeatureItem(
                  Icons.bathtub_rounded,
                  '${property?.bathrooms ?? 0}',
                  'Baths',
                  AppColors.secondary,
                ),
              ),
              Expanded(
                child: _buildCompactFeatureItem(
                  Icons.square_foot_rounded,
                  '${property?.area.toInt() ?? 0}',
                  'Sq Ft',
                  AppColors.accent,
                ),
              ),
              Expanded(
                child: _buildCompactFeatureItem(
                  Icons.local_parking_rounded,
                  '${property?.parkingSpaces ?? 0}',
                  'Parking',
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildEnhancedFeatureItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFeatureItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final property = _property;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property?.description ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.6,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: _showFullDescription ? null : 4,
                  overflow: _showFullDescription ? null : TextOverflow.ellipsis,
                ),
                if ((property?.description.length ?? 0) > 200) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              _showFullDescription = !_showFullDescription;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _showFullDescription
                                      ? 'Show Less'
                                      : 'Read More',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _showFullDescription
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities() {
    final amenities = _property?.amenities ?? [];
    if (amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    // Enhanced amenities with icons
    final amenityIcons = {
      'Pool': Icons.pool_rounded,
      'Gym': Icons.fitness_center_rounded,
      'Garden': Icons.local_florist_rounded,
      'Garage': Icons.garage_rounded,
      'Parking': Icons.local_parking_rounded,
      'Security': Icons.security_rounded,
      'Elevator': Icons.elevator_rounded,
      'Balcony': Icons.balcony_rounded,
      'Fireplace': Icons.fireplace_rounded,
      'Air Conditioning': Icons.ac_unit_rounded,
      'Heating': Icons.thermostat_rounded,
      'WiFi': Icons.wifi_rounded,
      'Laundry': Icons.local_laundry_service_rounded,
      'Kitchen': Icons.kitchen_rounded,
      'Furnished': Icons.chair_rounded,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Amenities & Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(amenities.length, (index) {
                final amenity = amenities[index];
                final icon =
                    amenityIcons[amenity] ?? Icons.check_circle_rounded;
                final colors = [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.accent,
                  AppColors.info,
                  AppColors.success,
                  AppColors.warning,
                ];
                final color = colors[index % colors.length];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        amenity,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation() {
    final property = _property;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Location & Neighborhood',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Enhanced address info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: AppColors.info,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property?.address ?? 'Address not available',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${property?.city}, ${property?.state} ${property?.zipCode}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Enhanced map placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.info.withOpacity(0.1),
                  AppColors.info.withOpacity(0.05),
                ],
              ),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.map_rounded,
                          size: 40,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Interactive Map',
                        style: TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view location',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Action buttons overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Container(
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
                        child: IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Directions feature coming soon!',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.directions_rounded,
                            color: AppColors.info,
                            size: 18,
                          ),
                          tooltip: 'Get Directions',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
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
                        child: IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Street view coming soon!'),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.streetview_rounded,
                            color: AppColors.info,
                            size: 18,
                          ),
                          tooltip: 'Street View',
                        ),
                      ),
                    ],
                  ),
                ),
                // Location pin overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
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
                          Icons.location_on_rounded,
                          color: AppColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${property?.city}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyReviews(String propertyId) {
    final currentUserId = UserProfile.currentUserProfile?['uid'] ?? '';
    final hasReviewed = _propertyReviews.any(
      (r) => r['userId'] == currentUserId,
    );
    final visibleReviews = _propertyReviews.take(1).toList();
    final hiddenCount = _propertyReviews.length - visibleReviews.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced header with rating summary
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Property Reviews',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_propertyReviews.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_propertyRating?.toStringAsFixed(1) ?? '0.0'} • ${_propertyReviews.length} reviews',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Write review button
              if (!hasReviewed && propertyId.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showSubmitPropertyReviewSheet(propertyId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.rate_review_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Write Review',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Reviews content
          if (_propertyReviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first to review this property',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children:
                  visibleReviews.map((review) {
                    final isExpanded =
                        _expandedReviews[review['reviewId']] ?? false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced review header
                          Row(
                            children: [
                              // Modern avatar
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.3),
                                      AppColors.primary.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Enhanced user info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review['reviewerName'] ??
                                          'Anonymous User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (review['timestamp'] != null)
                                      Text(
                                        _formatReviewDate(review['timestamp']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Enhanced rating display
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (review['rating'] as double)
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Enhanced comment section
                          if ((review['comment'] as String).isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review['comment'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                    maxLines: isExpanded ? null : 3,
                                    overflow:
                                        isExpanded
                                            ? null
                                            : TextOverflow.ellipsis,
                                  ),
                                  if ((review['comment'] as String).length >
                                      100)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _expandedReviews[review['reviewId']] =
                                                !isExpanded;
                                          });
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isExpanded
                                                  ? 'Show less'
                                                  : 'Read more',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              isExpanded
                                                  ? Icons
                                                      .keyboard_arrow_up_rounded
                                                  : Icons
                                                      .keyboard_arrow_down_rounded,
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

                          // Contact info (if expanded)
                          if (isExpanded) ...[
                            const SizedBox(height: 8),
                            if ((review['reviewerEmail'] as String?)
                                        ?.isNotEmpty ==
                                    true ||
                                (review['reviewerPhone'] as String?)
                                        ?.isNotEmpty ==
                                    true)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    if ((review['reviewerEmail'] as String?)
                                            ?.isNotEmpty ==
                                        true)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.email_rounded,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              review['reviewerEmail'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if ((review['reviewerPhone'] as String?)
                                            ?.isNotEmpty ==
                                        true)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.phone_rounded,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                review['reviewerPhone'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
            ),

          if (hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: TextButton.icon(
                onPressed: () => _showAllPropertyReviewsModal(),
                icon: Stack(
                  children: [
                    const Icon(Icons.reviews, color: Colors.blue),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text(
                          '+$hiddenCount',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                label: const Text('See all reviews'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgentInfo() {
    if (_agentLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final agent = _agentUser;
    final agentId = agent?.id;
    final currentUserId = UserProfile.currentUserProfile?['uid'] ?? '';
    final isSelf = agentId != null && agentId == currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Agent',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Compact agent card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                // Compact avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child:
                      agent?.avatar != null && agent!.avatar!.isNotEmpty
                          ? Image.network(
                            agent.avatar!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                              );
                            },
                          )
                          : Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                          ),
                ),
                const SizedBox(width: 12),

                // Compact agent info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent != null ? agent.fullName : 'Agent Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              agent?.role ?? 'Agent',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Compact rating
                          Container(
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
                                _agentRatingLoading
                                    ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                      ),
                                    )
                                    : Text(
                                      _agentRating != null
                                          ? _agentRating!.toStringAsFixed(1)
                                          : '0.0',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          if (agent != null &&
                              agent.phone != null &&
                              agent.phone!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    agent.phone!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          if (agent != null && agent.email.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.email,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    agent.email,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          if (agentId != null && agentId.isNotEmpty && !isSelf)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: OutlinedButton.icon(
                                onPressed:
                                    () => _showSubmitReviewSheet(agentId),
                                icon: const Icon(Icons.rate_review, size: 18),
                                label: const Text('Write a Review'),
                              ),
                            ),
                          if (isSelf)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.rate_review, size: 18),
                                label: const Text('You cannot review yourself'),
                              ),
                            ),
                        ],
                      ),
                      // Contact buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAgentContactButton(Icons.phone, Colors.green),
                          const SizedBox(width: 8),
                          _buildAgentContactButton(
                            Icons.message,
                            AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentReviews() {
    if (_agentReviewsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_agentReviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No reviews yet.'),
      );
    }
    final visibleAgentReviews = _agentReviews.take(1).toList();
    final hiddenAgentCount = _agentReviews.length - visibleAgentReviews.length;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 20, right: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Reviews',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (hiddenAgentCount > 0)
                TextButton.icon(
                  onPressed: _showAllAgentReviewsModal,
                  icon: Stack(
                    children: [
                      const Icon(Icons.list),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '+$hiddenAgentCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  label: const Text('See all'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...visibleAgentReviews.map(
            (review) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.person, size: 32),
                title: Text(
                  review['reviewerName'] ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedReviews[review['reviewId']] =
                          !(_expandedReviews[review['reviewId']] ?? false);
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((review['reviewerEmail'] as String?)?.isNotEmpty ==
                          true)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.email,
                                size: 14,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  review['reviewerEmail'],
                                  style: const TextStyle(fontSize: 12),
                                  overflow:
                                      _expandedReviews[review['reviewId']] ==
                                              true
                                          ? TextOverflow.visible
                                          : TextOverflow.ellipsis,
                                  maxLines:
                                      _expandedReviews[review['reviewId']] ==
                                              true
                                          ? null
                                          : 3,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if ((review['reviewerPhone'] as String?)?.isNotEmpty ==
                          true)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  review['reviewerPhone'],
                                  style: const TextStyle(fontSize: 12),
                                  overflow:
                                      _expandedReviews[review['reviewId']] ==
                                              true
                                          ? TextOverflow.visible
                                          : TextOverflow.ellipsis,
                                  maxLines:
                                      _expandedReviews[review['reviewId']] ==
                                              true
                                          ? null
                                          : 3,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text((review['rating'] as double).toStringAsFixed(1)),
                        ],
                      ),
                      if ((review['comment'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            review['comment'],
                            style: const TextStyle(fontSize: 13),
                            overflow:
                                _expandedReviews[review['reviewId']] == true
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                            maxLines:
                                _expandedReviews[review['reviewId']] == true
                                    ? null
                                    : 3,
                            softWrap: true,
                          ),
                        ),
                      if ((_expandedReviews[review['reviewId']] ?? false) ==
                          false)
                        const Padding(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Text(
                            'Tap to expand',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (review['timestamp'] != null)
                      Text(
                        _formatReviewDate(review['timestamp']),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    if (review['userId'] ==
                        (UserProfile.currentUserProfile?['uid'] ?? ''))
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.blue,
                        ),
                        tooltip: 'Edit Review',
                        onPressed:
                            () => _showEditReviewSheet(
                              review,
                              _agentUser?.id ?? '',
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (hiddenAgentCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: TextButton.icon(
                onPressed: () => _showAllAgentReviewsModal(),
                icon: Stack(
                  children: [
                    const Icon(Icons.reviews, color: Colors.blue),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text(
                          '+$hiddenAgentCount',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                label: const Text('See all reviews'),
              ),
            ),
        ],
      ),
    );
  }

  void _showAllAgentReviewsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'All Agent Reviews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._agentReviews.map(
                        (review) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.person, size: 32),
                            title: Text(
                              review['reviewerName'] ?? 'User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((review['reviewerEmail'] as String?)
                                        ?.isNotEmpty ==
                                    true)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.email,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            review['reviewerEmail'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if ((review['reviewerPhone'] as String?)
                                        ?.isNotEmpty ==
                                    true)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            review['reviewerPhone'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (review['rating'] as double)
                                          .toStringAsFixed(1),
                                    ),
                                  ],
                                ),
                                if ((review['comment'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      review['comment'],
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                review['timestamp'] != null
                                    ? Text(
                                      _formatReviewDate(review['timestamp']),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    )
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  String _formatReviewDate(dynamic timestamp) {
    if (timestamp is DateTime) {
      return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    } else if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return '';
  }

  void _callAgent() async {
    final phone = _agentUser?.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this agent.'),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the dialer.')),
      );
    }
  }

  void _messageAgent() {
    final agent = _agentUser;
    if (agent == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: {
        'agentId': agent.id,
        'agentName': agent.fullName,
      },
    );
  }

  Widget _buildAgentContactButton(IconData icon, Color color) {
    final currentUserId = UserProfile.currentUserProfile?['uid'] ?? '';
    final isSelf = _agentUser?.id == currentUserId;
    return InkWell(
      onTap: () {
        if (icon == Icons.phone) {
          if (isSelf) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You cannot call yourself.')),
            );
            return;
          }
          _callAgent();
        } else if (icon == Icons.message) {
          if (isSelf) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You cannot message yourself.')),
            );
            return;
          }
          _messageAgent();
        }
      },
      borderRadius: BorderRadius.circular(100),
      child: Opacity(
        opacity:
            ((icon == Icons.message || icon == Icons.phone) && isSelf)
                ? 0.5
                : 1.0,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildSimilarProperties() {
    final property = _property;
    if (property == null) return const SizedBox.shrink();
    final minPrice = (property.price * 0.8).round();
    final maxPrice = (property.price * 1.2).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Similar Properties',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Properties like this in ${property.city}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '±20% price range',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Enhanced similar properties list
          SizedBox(
            height: 240,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('similar_properties')
                      .where('id', isNotEqualTo: property.id)
                      .where('city', isEqualTo: property.city)
                      .where('type', isEqualTo: property.type)
                      .where('bedrooms', isEqualTo: property.bedrooms)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                print('Fetched docs: ${docs.length}');
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  print(
                    'Doc: id=${doc.id}, city=${data['city']}, type=${data['type']}, bedrooms=${data['bedrooms']}, price=${data['price']}',
                  );
                }
                // Filter by price range in Dart due to Firestore query limitations
                final filteredDocs =
                    docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
                      final inRange = price >= minPrice && price <= maxPrice;
                      print(
                        'Filtering: id=${doc.id}, price=$price, inRange=$inRange',
                      );
                      return inRange;
                    }).toList();
                print('Filtered docs: ${filteredDocs.length}');
                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No similar properties found.'),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    return SizedBox(
                      width: 200,
                      height: 220,
                      child: Card(
                        margin: const EdgeInsets.only(right: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.propertyDetail,
                              arguments: filteredDocs[index].id,
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              SizedBox(
                                height: 120,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    (data['images'] as List?)?.isNotEmpty ==
                                            true
                                        ? (data['images'] as List).first
                                        : '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['title'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        ' 24${_formatPrice((data['price'] as num?) ?? 0)}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.king_bed,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${data['bedrooms'] ?? ''}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.bathtub,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${data['bathrooms'] ?? ''}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.square_foot,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${data['area'] ?? ''}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
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
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyFeatureSmall(IconData icon, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Share button - compact
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon!'),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.share_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Call button - compact
            Container(
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Call feature coming soon!'),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.phone_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Schedule Tour button - compact but prominent
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _showScheduleTourDialog();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Schedule Tour',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color ?? Colors.black, size: 24),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatPrice(num price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}K';
    } else {
      return price.toString();
    }
  }

  void _showScheduleTourDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Schedule a Tour',
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
                  const Text(
                    'Select Date',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final date = DateTime.now().add(Duration(days: index));
                        return Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color:
                                index == 0 ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  index == 0
                                      ? AppColors.primary
                                      : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun',
                                ][date.weekday - 1],
                                style: TextStyle(
                                  color:
                                      index == 0
                                          ? Colors.white
                                          : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      index == 0 ? Colors.white : Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'May',
                                  'Jun',
                                  'Jul',
                                  'Aug',
                                  'Sep',
                                  'Oct',
                                  'Nov',
                                  'Dec',
                                ][date.month - 1],
                                style: TextStyle(
                                  color:
                                      index == 0
                                          ? Colors.white
                                          : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Time',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildTimeSlot('10:00 AM', isSelected: true),
                      _buildTimeSlot('11:30 AM'),
                      _buildTimeSlot('1:00 PM'),
                      _buildTimeSlot('2:30 PM'),
                      _buildTimeSlot('4:00 PM'),
                      _buildTimeSlot('5:30 PM'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Your Name',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Your Phone Number',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tour scheduled successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Tour',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTimeSlot(String time, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
        ),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _showSubmitReviewSheet(String agentId) {
    final currentUserId = UserProfile.currentUserProfile?['uid'] ?? '';
    if (agentId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot review yourself.')),
      );
      return;
    }
    _newReviewRating = null;
    _reviewCommentController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Write a Review',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Rating',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: RatingBar.builder(
                      initialRating: 0,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 32,
                      itemBuilder:
                          (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _newReviewRating = rating;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Comment (optional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reviewCommentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _submittingReview
                              ? null
                              : () => _submitAgentReview(agentId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _submittingReview
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Submit Review',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _submitPropertyReview(String propertyId) async {
    final currentUser = UserProfile.currentUserProfile;
    if (currentUser == null) return;
    final reviewerId = currentUser['uid'] ?? '';
    final reviewerName = currentUser['displayName'] ?? '';
    final reviewerEmail = currentUser['email'] ?? '';
    final reviewerPhone = currentUser['phone'] ?? '';
    if (_newReviewRating == null ||
        _reviewCommentController.text.trim().isEmpty) {
      return;
    }
    setState(() => _submittingReview = true);
    try {
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .collection('reviews')
          .add({
            'userId': reviewerId,
            'reviewerName': reviewerName,
            'reviewerEmail': reviewerEmail,
            'reviewerPhone': reviewerPhone,
            'comment': _reviewCommentController.text.trim(),
            'rating': _newReviewRating,
            'timestamp': FieldValue.serverTimestamp(),
          });
      Navigator.pop(context);
      await _updatePropertyRatingAndCount(propertyId);
      _fetchPropertyReviews();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: \\${e.toString()}')),
      );
    } finally {
      setState(() => _submittingReview = false);
    }
  }

  Future<void> _submitAgentReview(String agentId) async {
    final currentUser = UserProfile.currentUserProfile;
    if (currentUser == null) return;
    final reviewerId = currentUser['uid'] ?? '';
    if (_newReviewRating == null ||
        _reviewCommentController.text.trim().isEmpty) {
      return;
    }
    setState(() => _submittingReview = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(agentId)
          .collection('reviews')
          .add({
            'userId': reviewerId,
            'comment': _reviewCommentController.text.trim(),
            'rating': _newReviewRating,
            'timestamp': FieldValue.serverTimestamp(),
          });
      Navigator.pop(context);
      _fetchAgentRating(agentId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: ${e.toString()}')),
      );
    } finally {
      setState(() => _submittingReview = false);
    }
  }

  void _showEditReviewSheet(Map<String, dynamic> review, String agentId) {
    double? editRating = review['rating'];
    final TextEditingController editCommentController = TextEditingController(
      text: review['comment'] ?? '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Review',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  RatingBar.builder(
                    initialRating: editRating ?? 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 32,
                    unratedColor: Colors.grey[300],
                    itemBuilder:
                        (context, _) =>
                            const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) => editRating = rating,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: editCommentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (editRating == null ||
                            editCommentController.text.trim().isEmpty) {
                          return;
                        }
                        Navigator.pop(context);
                        await _updateAgentReview(
                          agentId,
                          review['reviewId'],
                          editRating!,
                          editCommentController.text.trim(),
                        );
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _updateAgentReview(
    String agentId,
    String reviewId,
    double rating,
    String comment,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(agentId)
          .collection('reviews')
          .doc(reviewId)
          .update({
            'rating': rating,
            'comment': comment,
            'timestamp': FieldValue.serverTimestamp(),
          });
      _fetchAgentRating(agentId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update review: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reviewCommentController.dispose();
    super.dispose();
  }

  void _showAllPropertyReviewsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'All Property Reviews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._propertyReviews.map(
                        (review) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.person, size: 32),
                            title: Text(
                              review['reviewerName'] ?? 'User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((review['reviewerEmail'] as String?)
                                        ?.isNotEmpty ==
                                    true)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.email,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            review['reviewerEmail'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if ((review['reviewerPhone'] as String?)
                                        ?.isNotEmpty ==
                                    true)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            review['reviewerPhone'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (review['rating'] as double)
                                          .toStringAsFixed(1),
                                    ),
                                  ],
                                ),
                                if ((review['comment'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      review['comment'],
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                review['timestamp'] != null
                                    ? Text(
                                      _formatReviewDate(review['timestamp']),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    )
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showSubmitPropertyReviewSheet(String propertyId) {
    _newReviewRating = null;
    _reviewCommentController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Write a Property Review',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 32,
                    unratedColor: Colors.grey[300],
                    itemBuilder:
                        (context, _) =>
                            const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) => _newReviewRating = rating,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewCommentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _submittingReview
                              ? null
                              : () => _submitPropertyReview(propertyId),
                      child:
                          _submittingReview
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Submit Review'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showEditPropertyReviewSheet(
    Map<String, dynamic> review,
    String propertyId,
  ) {
    double? editRating = review['rating'];
    final TextEditingController editCommentController = TextEditingController(
      text: review['comment'] ?? '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Property Review',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  RatingBar.builder(
                    initialRating: editRating ?? 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 32,
                    unratedColor: Colors.grey[300],
                    itemBuilder:
                        (context, _) =>
                            const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) => editRating = rating,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: editCommentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (editRating == null ||
                            editCommentController.text.trim().isEmpty) {
                          return;
                        }
                        Navigator.pop(context);
                        await _updateReview(
                          propertyId,
                          review['reviewId'],
                          editRating!,
                          editCommentController.text.trim(),
                        );
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _updatePropertyRatingAndCount(String propertyId) async {
    final reviewsSnapshot =
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(propertyId)
            .collection('reviews')
            .get();
    final reviews = reviewsSnapshot.docs;
    if (reviews.isEmpty) {
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .update({'rating': 0.0, 'reviews_count': 0});
      return;
    }
    double sum = 0;
    for (final doc in reviews) {
      final data = doc.data();
      final rating = (data['rating'] as num?)?.toDouble();
      if (rating != null) sum += rating;
    }
    final avg = sum / reviews.length;
    await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .update({'rating': avg, 'reviews_count': reviews.length});
  }

  Future<void> _updateReview(
    String propertyId,
    String reviewId,
    double rating,
    String comment,
  ) async {
    final currentUser = UserProfile.currentUserProfile;
    final reviewerName = currentUser?['displayName'] ?? '';
    final reviewerEmail = currentUser?['email'] ?? '';
    final reviewerPhone = currentUser?['phone'] ?? '';
    try {
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .collection('reviews')
          .doc(reviewId)
          .update({
            'rating': rating,
            'comment': comment,
            'timestamp': FieldValue.serverTimestamp(),
            'reviewerName': reviewerName,
            'reviewerEmail': reviewerEmail,
            'reviewerPhone': reviewerPhone,
          });
      await _updatePropertyRatingAndCount(propertyId);
      _fetchPropertyReviews();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update review: ${e.toString()}')),
      );
    }
  }
}
