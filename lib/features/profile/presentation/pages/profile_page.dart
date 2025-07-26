import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _animationController!.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Return early if animations aren't ready
    if (_fadeAnimation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation!,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [_buildModernSliverAppBar(user), _buildTabBar()];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildEnhancedProfileTab(),
              _buildPropertiesTab(),
              _buildActivityTab(),
              _buildAnalyticsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSliverAppBar(User? user) {
    return SliverAppBar(
      expandedHeight: 320, // Increased height
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: StreamBuilder<DocumentSnapshot>(
        stream:
            user != null
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots()
                : null,
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          return FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                    Colors.purple.shade400,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Animated background pattern
                  Positioned.fill(
                    child: CustomPaint(painter: BackgroundPatternPainter()),
                  ),
                  // Profile content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16), // Reduced padding
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Center content
                        children: [
                          const SizedBox(height: 20), // Reduced spacing
                          _buildProfileAvatar(data),
                          const SizedBox(height: 12), // Reduced spacing
                          _buildProfileInfo(data, user),
                          const SizedBox(height: 16), // Reduced spacing
                          _buildQuickStats(user?.uid),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
          onPressed: _showQRCode,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showAdvancedMenu,
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(Map<String, dynamic>? data) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3), // Reduced border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15, // Reduced shadow
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 45, // Reduced size
            backgroundColor: Colors.white,
            backgroundImage:
                data?['photoURL'] != null
                    ? NetworkImage(data!['photoURL'])
                    : null,
            child:
                data?['photoURL'] == null
                    ? Icon(
                      Icons.person,
                      size: 45,
                      color: Theme.of(context).primaryColor,
                    )
                    : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _updateProfilePhoto,
            child: Container(
              padding: const EdgeInsets.all(6), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic>? data, User? user) {
    final displayName = data?['displayName'] ?? user?.displayName ?? 'User';
    final role = data?['role'] ?? 'Customer';
    final isVerified = data?['isVerified'] ?? false;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: Colors.blue, size: 24),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            _getRoleDisplayName(role),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(String? userId) {
    if (userId == null) return const SizedBox();

    final userProfile = UserProfile.currentUserProfile;
    final role = userProfile?['role'] ?? 'customer';

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('properties')
              .where(
                role == AppConstants.realtor ? 'realtorId' : 'ownerId',
                isEqualTo: userId,
              )
              .snapshots(),
      builder: (context, propertiesSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('favorites')
                  .snapshots(),
          builder: (context, favoritesSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('reviews')
                      .snapshots(),
              builder: (context, reviewsSnapshot) {
                final propertiesCount =
                    propertiesSnapshot.data?.docs.length ?? 0;
                final favoritesCount = favoritesSnapshot.data?.docs.length ?? 0;
                final reviewsCount = reviewsSnapshot.data?.docs.length ?? 0;

                // Calculate average rating
                double avgRating = 0.0;
                if (reviewsCount > 0) {
                  final reviews = reviewsSnapshot.data!.docs;
                  double totalRating = 0.0;
                  for (var review in reviews) {
                    totalRating +=
                        (review.data() as Map<String, dynamic>)['rating']
                            ?.toDouble() ??
                        0.0;
                  }
                  avgRating = totalRating / reviewsCount;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Properties', propertiesCount.toString()),
                      _buildStatItem('Favorites', favoritesCount.toString()),
                      _buildStatItem(
                        'Rating',
                        reviewsCount > 0 ? avgRating.toStringAsFixed(1) : 'N/A',
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Flexible(
      // Use Flexible instead of fixed width
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18, // Reduced font size
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11, // Reduced font size
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      delegate: _SliverAppBarDelegate(
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
              Tab(icon: Icon(Icons.home_outlined), text: 'Properties'),
              Tab(icon: Icon(Icons.timeline_outlined), text: 'Activity'),
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
          ),
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildEnhancedProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPersonalInfoCard(),
          const SizedBox(height: 20),
          _buildPreferencesCard(),
          const SizedBox(height: 20),
          _buildSecurityCard(),
          const SizedBox(height: 20),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream:
          user != null
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots()
              : null,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.grey[50],
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showEditProfileDialog(data),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoTile(
                  Icons.email_outlined,
                  'Email',
                  data?['email'] ?? user?.email ?? 'N/A',
                ),
                _buildInfoTile(
                  Icons.phone_outlined,
                  'Phone',
                  data?['phone'] ?? 'Not provided',
                ),
                _buildInfoTile(
                  Icons.work_outline,
                  'Role',
                  _getRoleDisplayName(data?['role'] ?? 'customer'),
                ),
                _buildInfoTile(
                  Icons.cake_outlined,
                  'Member Since',
                  _getMemberSince(),
                ),
                if (data?['bio'] != null && data!['bio'].toString().isNotEmpty)
                  _buildInfoTile(Icons.info_outline, 'Bio', data['bio']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final user = FirebaseAuth.instance.currentUser;
    final userProfile = UserProfile.currentUserProfile;
    final role = userProfile?['role'] ?? 'customer';

    if (user == null) {
      return const Center(child: Text('Please log in to view analytics'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsOverview(user.uid, role),
          const SizedBox(height: 20),
          _buildPerformanceMetrics(user.uid, role),
          const SizedBox(height: 20),
          _buildRecentActivity(user.uid),
          const SizedBox(height: 20),
          _buildInsightsCard(user.uid, role),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverview(String userId, String role) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Analytics Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('properties')
                      .where(
                        role == 'realtor' ? 'realtorId' : 'ownerId',
                        isEqualTo: userId,
                      )
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final properties = snapshot.data!.docs;
                final totalProperties = properties.length;
                final activeProperties =
                    properties
                        .where(
                          (p) => (p.data() as Map)['status'] == 'available',
                        )
                        .length;
                final soldRented =
                    properties
                        .where(
                          (p) =>
                              (p.data() as Map)['status'] == 'sold' ||
                              (p.data() as Map)['status'] == 'rented',
                        )
                        .length;

                return Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Total Properties',
                        totalProperties.toString(),
                        Icons.home_outlined,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Active Listings',
                        activeProperties.toString(),
                        Icons.visibility_outlined,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Sold/Rented',
                        soldRented.toString(),
                        Icons.check_circle_outline,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(String userId, String role) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Performance Metrics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Average Rating', '4.5', Icons.star, Colors.amber),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Response Time',
              '< 2 hours',
              Icons.schedule,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Success Rate',
              '85%',
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Client Satisfaction',
              '92%',
              Icons.sentiment_satisfied,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard(String userId, String role) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Insights & Tips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              'Market Trend',
              'Property prices in your area have increased by 5% this month.',
              Icons.trending_up,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              'Optimization Tip',
              'Add more photos to increase property views by up to 40%.',
              Icons.photo_camera,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              'Best Time to List',
              'Properties listed on weekends get 25% more views.',
              Icons.calendar_today,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesTab() {
    final user = FirebaseAuth.instance.currentUser;
    final userProfile = UserProfile.currentUserProfile;
    final role = userProfile?['role'] ?? 'customer';

    if (user == null) {
      return const Center(child: Text('Please log in to view properties'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('properties')
              .where(
                role == AppConstants.realtor ? 'realtorId' : 'ownerId',
                isEqualTo: user.uid,
              )
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyPropertiesState(role);
        }

        final properties = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            final data = property.data() as Map<String, dynamic>;

            return _buildPropertyCard(property.id, data);
          },
        );
      },
    );
  }

  Widget _buildEmptyPropertiesState(String role) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Properties Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            role == AppConstants.realtor || role == AppConstants.propertyOwner
                ? 'Start by adding your first property'
                : 'Properties you own will appear here',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (role == AppConstants.realtor ||
              role == AppConstants.propertyOwner) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-property'),
              icon: const Icon(Icons.add),
              label: const Text('Add Property'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPropertyCard(String propertyId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap:
            () => Navigator.pushNamed(
              context,
              '/property-detail',
              arguments: propertyId,
            ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child:
                      data['images'] != null &&
                              (data['images'] as List).isNotEmpty
                          ? Image.network(
                            data['images'][0],
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    Icon(Icons.home, color: Colors.grey[400]),
                          )
                          : Icon(Icons.home, color: Colors.grey[400]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Property',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['location'] ?? 'Location not specified',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$${data['price']?.toString() ?? '0'}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                data['status'] == 'available'
                                    ? Colors.green
                                    : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data['status']?.toString().toUpperCase() ??
                                'UNKNOWN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
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

  Widget _buildActivityTab() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view activity'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('activities')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyActivityState();
        }

        final activities = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final data = activity.data() as Map<String, dynamic>;

            return _buildActivityItem(data);
          },
        );
      },
    );
  }

  Widget _buildEmptyActivityState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Activity Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your activity history will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as Timestamp?;
    final timeAgo =
        timestamp != null ? _getTimeAgo(timestamp.toDate()) : 'Unknown time';

    IconData icon;
    Color iconColor;

    switch (data['type']) {
      case 'property_added':
        icon = Icons.add_home;
        iconColor = Colors.green;
        break;
      case 'property_updated':
        icon = Icons.edit;
        iconColor = Colors.blue;
        break;
      case 'favorite_added':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'inquiry_sent':
        icon = Icons.message;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(data['title'] ?? 'Activity'),
        subtitle: Text(data['description'] ?? ''),
        trailing: Text(
          timeAgo,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    final userProfile = UserProfile.currentUserProfile;
    final role = userProfile?['role'] ?? 'customer';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (role == AppConstants.realtor ||
                role == AppConstants.propertyOwner) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      Icons.add_home,
                      'Add Property',
                      () => Navigator.pushNamed(context, '/add-property'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      Icons.analytics,
                      'Analytics',
                      () => _tabController.animateTo(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    Icons.favorite_outline,
                    'Favorites',
                    () => Navigator.pushNamed(context, '/favorites'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    Icons.settings,
                    'Settings',
                    () => _showAdvancedMenu(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Preferences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreferenceItem('Notifications', true),
            _buildPreferenceItem('Email Updates', false),
            _buildPreferenceItem('Dark Mode', false),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem(String title, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Switch(
            value: value,
            onChanged: (newValue) {
              // Handle preference change
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Security',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Handle password change
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Two-Factor Authentication'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Handle 2FA setup
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Share Profile'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code, size: 100),
                Text('QR Code for profile sharing'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showAdvancedMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Settings & More',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildMenuOption(
                  Icons.notifications_outlined,
                  'Notifications',
                  () => _showNotificationSettings(),
                ),
                _buildMenuOption(
                  Icons.privacy_tip_outlined,
                  'Privacy Settings',
                  () => _showPrivacySettings(),
                ),
                _buildMenuOption(
                  Icons.language_outlined,
                  'Language',
                  () => _showLanguageSettings(),
                ),
                _buildMenuOption(
                  Icons.help_outline,
                  'Help & Support',
                  () => _showHelpSupport(),
                ),
                _buildMenuOption(
                  Icons.info_outline,
                  'About',
                  () => _showAboutDialog(),
                ),
                _buildMenuOption(
                  Icons.logout,
                  'Sign Out',
                  () => _signOut(),
                  isDestructive: true,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildMenuOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showNotificationSettings() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Notification Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive notifications on your device'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive notifications via email'),
                  value: false,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('Property Updates'),
                  subtitle: const Text('Get notified about property changes'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved!')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showPrivacySettings() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Privacy Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Profile Visibility'),
                  subtitle: const Text('Make your profile visible to others'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('Show Contact Info'),
                  subtitle: const Text(
                    'Allow others to see your contact details',
                  ),
                  value: false,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('Activity Status'),
                  subtitle: const Text('Show when you were last active'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy settings updated!')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showLanguageSettings() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('English'),
                  value: 'en',
                  groupValue: 'en',
                  onChanged: (value) {},
                ),
                RadioListTile<String>(
                  title: const Text('Spanish'),
                  value: 'es',
                  groupValue: 'en',
                  onChanged: (value) {},
                ),
                RadioListTile<String>(
                  title: const Text('French'),
                  value: 'fr',
                  groupValue: 'en',
                  onChanged: (value) {},
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language updated!')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showHelpSupport() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Help & Support'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email Support'),
                  subtitle: const Text('support@propertyapp.com'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone Support'),
                  subtitle: const Text('+1 (555) 123-4567'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Available 24/7'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('FAQ'),
                  subtitle: const Text('Frequently asked questions'),
                  onTap: () {},
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog() {
    Navigator.pop(context);
    showAboutDialog(
      context: context,
      applicationName: 'Property App',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.home, color: Colors.white, size: 32),
      ),
      children: [
        const Text(
          'A comprehensive property management and discovery platform.',
        ),
        const SizedBox(height: 16),
        const Text('© 2024 Property App. All rights reserved.'),
      ],
    );
  }

  void _signOut() async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        UserProfile.currentUserProfile = null;
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
        }
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case AppConstants.realtor:
        return 'Realtor';
      case AppConstants.propertyOwner:
        return 'Property Owner';
      case 'customer':
        return 'Customer';
      default:
        return 'User';
    }
  }

  String _getMemberSince() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.metadata.creationTime != null) {
      final date = user!.metadata.creationTime!;
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'N/A';
  }

  void _updateProfilePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('profile_photos')
              .child('${user.uid}.jpg');

          await ref.putFile(File(image.path));
          final downloadURL = await ref.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'photoURL': downloadURL});

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated!')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to update photo: $e')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditProfileDialog(Map<String, dynamic>? currentData) {
    final nameController = TextEditingController(
      text: currentData?['displayName'] ?? '',
    );
    final phoneController = TextEditingController(
      text: currentData?['phone'] ?? '',
    );
    final bioController = TextEditingController(
      text: currentData?['bio'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    () => _updateProfile(
                      nameController.text,
                      phoneController.text,
                      bioController.text,
                    ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _updateProfile(String name, String phone, String bio) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'displayName': name,
            'phone': phone,
            'bio': bio,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update local profile
      UserProfile.currentUserProfile = {
        ...?UserProfile.currentUserProfile,
        'displayName': name,
        'phone': phone,
        'bio': bio,
      };

      // Log activity
      await _logActivity(
        'profile_updated',
        'Profile Updated',
        'Updated profile information',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    }
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        UserProfile.currentUserProfile = null;

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to logout: $e')));
        }
      }
    }
  }

  Future<void> _logActivity(
    String type,
    String title,
    String description,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('activities')
          .add({
            'type': type,
            'title': title,
            'description': description,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // Silently fail for activity logging
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildRecentActivity(String userId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('activities')
                      .orderBy('timestamp', descending: true)
                      .limit(5)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final activities = snapshot.data!.docs;

                if (activities.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.timeline_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children:
                      activities.map((activity) {
                        final data = activity.data() as Map<String, dynamic>;
                        final timestamp = data['timestamp'] as Timestamp?;
                        final timeAgo =
                            timestamp != null
                                ? _getTimeAgo(timestamp.toDate())
                                : 'Unknown time';

                        IconData icon;
                        Color iconColor;

                        switch (data['type']) {
                          case 'property_added':
                            icon = Icons.add_home;
                            iconColor = Colors.green;
                            break;
                          case 'property_updated':
                            icon = Icons.edit;
                            iconColor = Colors.blue;
                            break;
                          case 'favorite_added':
                            icon = Icons.favorite;
                            iconColor = Colors.red;
                            break;
                          case 'inquiry_sent':
                            icon = Icons.message;
                            iconColor = Colors.orange;
                            break;
                          case 'profile_updated':
                            icon = Icons.person;
                            iconColor = Colors.purple;
                            break;
                          default:
                            icon = Icons.info;
                            iconColor = Colors.grey;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: iconColor, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title'] ?? 'Activity',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (data['description'] != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        data['description'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 1;

    for (int i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
