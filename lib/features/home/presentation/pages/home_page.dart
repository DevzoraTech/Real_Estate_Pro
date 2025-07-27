import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/user_profile.dart';
import '../../../properties/presentation/pages/property_list_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../favorites/presentation/pages/favorites_page.dart';
import '../../../chat/presentation/chat_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabController;
  late AnimationController _navController;
  late AnimationController _appBarController;
  late AnimationController _fabMenuController;
  late AnimationController _scrollController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;
  late Animation<double> _navIndicatorAnimation;
  late Animation<Offset> _appBarSlideAnimation;
  late Animation<double> _appBarFadeAnimation;
  late Animation<double> _fabMenuAnimation;
  late Animation<double> _fabBackgroundAnimation;
  late Animation<double> _appBarScrollAnimation;

  int _notificationCount = 0;
  String _greeting = '';
  bool _isFabMenuOpen = false;
  bool _isAppBarVisible = true;
  double _lastScrollOffset = 0;

  // Add exchange rate variables
  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {'USD': 1.0};
  DateTime? _lastRatesFetch;

  // Keep only the search query
  String _searchQuery = '';

  // Filter variables for saved searches
  String _selectedType = 'All';
  String _selectedStatus = 'All';
  RangeValues _priceRange = const RangeValues(0, 1000000);
  RangeValues _bedroomsRange = const RangeValues(1, 10);
  RangeValues _bathroomsRange = const RangeValues(1, 10);
  RangeValues _areaRange = const RangeValues(100, 10000);
  List<String> _selectedAmenities = [];

  final List<Widget> _pages = [
    const PropertyListPage(),
    const SearchPage(),
    const FavoritesPage(),
    const ChatListPage(),
    const ProfilePage(),
  ];

  final List<NavItem> _navItems = [
    NavItem(Icons.home, Icons.home_outlined, 'Home'),
    NavItem(Icons.search, Icons.search_outlined, 'Search'),
    NavItem(Icons.favorite, Icons.favorite_border, 'Favorites'),
    NavItem(Icons.chat, Icons.chat_outlined, 'Chat'),
    NavItem(Icons.person, Icons.person_outline, 'Profile'),
  ];

  final List<FabMenuItem> _fabMenuItems = [
    FabMenuItem(
      icon: Icons.home_work,
      label: 'Add Property',
      color: Colors.blue,
      route: AppRoutes.addProperty,
    ),
    FabMenuItem(
      icon: Icons.camera_alt,
      label: 'Quick Photo',
      color: Colors.green,
      action: 'camera',
    ),
    FabMenuItem(
      icon: Icons.bookmark_add,
      label: 'Save Search',
      color: Colors.orange,
      action: 'save_search',
    ),
    FabMenuItem(
      icon: Icons.share,
      label: 'Share App',
      color: Colors.purple,
      action: 'share',
    ),
  ];

  List<FabMenuItem> get _contextualFabMenuItems {
    switch (_currentIndex) {
      case 0: // Home page
        return [
          FabMenuItem(
            icon: Icons.home_work,
            label: 'Add Property',
            color: Colors.blue,
            route: AppRoutes.addProperty,
          ),
          FabMenuItem(
            icon: Icons.camera_alt,
            label: 'Quick Photo',
            color: Colors.green,
            action: 'camera',
          ),
          FabMenuItem(
            icon: Icons.location_on,
            label: 'Nearby',
            color: Colors.red,
            action: 'nearby',
          ),
        ];
      case 1: // Search page
        return [
          FabMenuItem(
            icon: Icons.bookmark_add,
            label: 'Save Search',
            color: Colors.orange,
            action: 'save_search',
          ),
          FabMenuItem(
            icon: Icons.filter_list,
            label: 'Advanced Filter',
            color: Colors.purple,
            action: 'filter',
          ),
          FabMenuItem(
            icon: Icons.map,
            label: 'Map View',
            color: Colors.teal,
            action: 'map_view',
          ),
        ];
      case 2: // Favorites page
        return [
          FabMenuItem(
            icon: Icons.share,
            label: 'Share List',
            color: Colors.indigo,
            action: 'share_favorites',
          ),
          FabMenuItem(
            icon: Icons.compare_arrows,
            label: 'Compare',
            color: Colors.deepOrange,
            action: 'compare',
          ),
          FabMenuItem(
            icon: Icons.notifications_active,
            label: 'Price Alerts',
            color: Colors.amber,
            action: 'price_alerts',
          ),
        ];
      case 3: // Chat page
        return [
          FabMenuItem(
            icon: Icons.chat_bubble_outline,
            label: 'New Chat',
            color: Colors.blue,
            action: 'new_chat',
          ),
          FabMenuItem(
            icon: Icons.search,
            label: 'Search Chats',
            color: Colors.green,
            action: 'search_chats',
          ),
          FabMenuItem(
            icon: Icons.archive,
            label: 'Archive',
            color: Colors.orange,
            action: 'archive_chats',
          ),
        ];
      case 4: // Profile page
        return [
          FabMenuItem(
            icon: Icons.settings,
            label: 'Settings',
            color: Colors.grey,
            action: 'settings',
          ),
          FabMenuItem(
            icon: Icons.help_outline,
            label: 'Help',
            color: Colors.blue,
            action: 'help',
          ),
          FabMenuItem(
            icon: Icons.logout,
            label: 'Sign Out',
            color: Colors.red,
            action: 'logout',
          ),
        ];
      default:
        return _fabMenuItems;
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _setGreeting();
    _loadUserData();

    // FAB animations
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Navigation animations
    _navController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // App bar animations
    _appBarController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // FAB menu animations
    _fabMenuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Scroll-responsive app bar controller
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));

    _fabRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));

    _navIndicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _navController, curve: Curves.elasticOut),
    );

    _appBarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _appBarController, curve: Curves.easeOutBack),
    );

    _appBarFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appBarController, curve: Curves.easeInOut),
    );

    _fabMenuAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabMenuController, curve: Curves.easeOutBack),
    );

    _fabBackgroundAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _fabMenuController, curve: Curves.easeInOut),
    );

    // Scroll animation for app bar
    _appBarScrollAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scrollController, curve: Curves.easeInOut),
    );

    _navController.forward();
    _appBarController.forward();
    _scrollController.forward();
  }

  void _handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final currentOffset = notification.metrics.pixels;
      final delta = currentOffset - _lastScrollOffset;

      // Show app bar when scrolling up, hide when scrolling down
      if (delta > 5 && _isAppBarVisible) {
        setState(() => _isAppBarVisible = false);
        _scrollController.reverse();
      } else if (delta < -5 && !_isAppBarVisible) {
        setState(() => _isAppBarVisible = true);
        _scrollController.forward();
      }

      _lastScrollOffset = currentOffset;
    }
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          UserProfile.currentUserProfile = userDoc.data();
          // Trigger a rebuild to update the UI with new user data
          if (mounted) {
            setState(() {});
          }
        }

        // Load notification count
        await _loadNotificationCount(user.uid);
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _loadNotificationCount(String userId) async {
    try {
      final notificationsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .get();

      if (mounted) {
        setState(() {
          _notificationCount = notificationsSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    final userProfile = UserProfile.currentUserProfile;

    // First try to get from UserProfile (which should be populated from Firestore)
    if (userProfile != null && userProfile['displayName'] != null) {
      final fullName = userProfile['displayName'] as String;
      return fullName.split(' ').first; // Return first name only
    }

    // Fallback to Firebase Auth user display name
    if (user?.displayName != null) {
      final fullName = user!.displayName!;
      return fullName.split(' ').first;
    }

    // Fallback to email username
    if (user?.email != null) {
      final email = user!.email!;
      return email.split('@').first;
    }

    return 'User';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabController.dispose();
    _navController.dispose();
    _appBarController.dispose();
    _fabMenuController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });

      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _toggleFabMenu() {
    print('=== TOGGLE FAB MENU ===');
    print('Current state: $_isFabMenuOpen');

    setState(() {
      _isFabMenuOpen = !_isFabMenuOpen;
    });

    print('New state: $_isFabMenuOpen');

    if (_isFabMenuOpen) {
      print('Opening FAB menu...');
      _fabMenuController.forward();
    } else {
      print('Closing FAB menu...');
      _fabMenuController.reverse();
    }
  }

  void _onFabMenuItemTap(FabMenuItem item) {
    print('=== FAB MENU ITEM TAPPED ===');
    print('Item: ${item.label}');
    print('Action: ${item.action}');
    print('Route: ${item.route}');

    // Add haptic feedback
    HapticFeedback.lightImpact();

    // Close menu first
    _toggleFabMenu();

    // Execute action after menu closes
    Future.delayed(const Duration(milliseconds: 250), () {
      if (item.route != null) {
        print('Navigating to route: ${item.route}');
        Navigator.pushNamed(context, item.route!);
      } else if (item.action != null) {
        print('Executing action: ${item.action}');
        _handleFabAction(item.action!);
      }
    });
  }

  void _handleFabAction(String action) {
    print('=== HANDLING FAB ACTION ===');
    print('Action: $action');

    switch (action) {
      case 'camera':
        print('Opening camera...');
        _openCamera();
        break;
      case 'save_search':
        print('Saving current search...');
        _saveCurrentSearch();
        break;
      case 'nearby':
        print('Finding nearby properties...');
        _findNearbyProperties();
        break;
      case 'filter':
        print('Opening advanced filters...');
        _openAdvancedFilters();
        break;
      case 'map_view':
        print('Switching to map view...');
        _switchToMapView();
        break;
      case 'share_favorites':
        print('Sharing favorites...');
        _shareFavorites();
        break;
      case 'compare':
        print('Opening comparison tool...');
        _openComparisonTool();
        break;
      case 'price_alerts':
        print('Setting up price alerts...');
        _setupPriceAlerts();
        break;
      case 'settings':
        print('Opening settings...');
        _openSettings();
        break;
      case 'help':
        print('Opening help center...');
        _openHelpCenter();
        break;
      case 'logout':
        print('Showing logout dialog...');
        _showLogoutDialog();
        break;
      case 'share':
        print('Sharing app...');
        _shareApp();
        break;
      default:
        print('Unknown action: $action');
        _showActionSnackBar('Feature coming soon!', AppColors.primary);
    }
  }

  void _showActionSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  // Camera functionality
  void _openCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        _showActionSnackBar('Photo captured successfully!', Colors.green);
        // TODO: Upload photo to property or save for later use
        // You can implement photo upload logic here
      }
    } catch (e) {
      _showActionSnackBar('Failed to open camera: $e', Colors.red);
    }
  }

  // Save current search
  void _saveCurrentSearch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showActionSnackBar('Please log in to save searches', Colors.orange);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_searches')
          .add({
            'query': _searchQuery,
            'timestamp': FieldValue.serverTimestamp(),
            'filters': {
              'type': _selectedType,
              'status': _selectedStatus,
              'priceRange': {
                'start': _priceRange.start,
                'end': _priceRange.end,
              },
              'bedroomsRange': {
                'start': _bedroomsRange.start,
                'end': _bedroomsRange.end,
              },
              'bathroomsRange': {
                'start': _bathroomsRange.start,
                'end': _bathroomsRange.end,
              },
              'areaRange': {'start': _areaRange.start, 'end': _areaRange.end},
              'amenities': _selectedAmenities,
            },
          });

      _showActionSnackBar('Search saved successfully!', Colors.green);
    } catch (e) {
      _showActionSnackBar('Failed to save search: $e', Colors.red);
    }
  }

  // Find nearby properties
  void _findNearbyProperties() {
    // Switch to search page and trigger location-based search
    _onTabTapped(1);
    _showActionSnackBar('Searching nearby properties...', Colors.blue);
    // TODO: Could integrate with location services later
  }

  // Open advanced filters
  void _openAdvancedFilters() {
    // Navigate to search page and show filters
    _onTabTapped(1);
    Future.delayed(const Duration(milliseconds: 300), () {
      _showActionSnackBar(
        'Advanced filters available in search',
        Colors.purple,
      );
    });
  }

  // Switch to map view
  void _switchToMapView() {
    // Navigate to search page (where map view would be implemented)
    _onTabTapped(1);
    _showActionSnackBar('Map view coming soon in search!', Colors.teal);
  }

  // Share favorites
  void _shareFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showActionSnackBar('Please log in to share favorites', Colors.indigo);
      return;
    }

    try {
      final favoritesSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .get();

      if (favoritesSnapshot.docs.isEmpty) {
        _showActionSnackBar('No favorites to share', Colors.indigo);
        return;
      }

      // Navigate to favorites page to show what's being shared
      _onTabTapped(2);
      Future.delayed(const Duration(milliseconds: 300), () {
        _showActionSnackBar(
          '${favoritesSnapshot.docs.length} favorites ready to share!',
          Colors.indigo,
        );
      });
    } catch (e) {
      _showActionSnackBar('Failed to load favorites: $e', Colors.red);
    }
  }

  // Open comparison tool
  void _openComparisonTool() {
    // Navigate to favorites where comparison would be available
    _onTabTapped(2);
    Future.delayed(const Duration(milliseconds: 300), () {
      _showActionSnackBar(
        'Select properties to compare in favorites',
        Colors.deepOrange,
      );
    });
  }

  // Setup price alerts
  void _setupPriceAlerts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showActionSnackBar('Please log in to set up price alerts', Colors.amber);
      return;
    }

    // Navigate to favorites where alerts can be set
    _onTabTapped(2);
    Future.delayed(const Duration(milliseconds: 300), () {
      _showActionSnackBar(
        'Price alerts can be set from favorites',
        Colors.amber,
      );
    });
  }

  // Open settings
  void _openSettings() {
    // Navigate to profile page where settings are
    _onTabTapped(3);
    Future.delayed(const Duration(milliseconds: 300), () {
      _showActionSnackBar('Settings available in profile', Colors.grey);
    });
  }

  // Open help center
  void _openHelpCenter() {
    // Navigate to profile page where help would be
    _onTabTapped(3);
    Future.delayed(const Duration(milliseconds: 300), () {
      _showActionSnackBar('Help & support in profile section', Colors.blue);
    });
  }

  // Share app
  void _shareApp() {
    _showActionSnackBar('Sharing app...', Colors.purple);
    // TODO: Implement app sharing functionality
  }

  // Handle logout
  void _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      UserProfile.currentUserProfile = null;
      _showActionSnackBar('Signed out successfully!', Colors.green);

      // Navigate to login page
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      _showActionSnackBar('Failed to sign out: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _handleScroll(notification);
          return false;
        },
        child: Stack(
          children: [
            // Main content with dynamic padding based on app bar position
            AnimatedBuilder(
              animation: _appBarScrollAnimation,
              builder: (context, child) {
                final appBarHeight =
                    (MediaQuery.of(context).padding.top + 140) *
                    _appBarScrollAnimation.value;
                return Padding(
                  padding: EdgeInsets.only(top: appBarHeight),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchExchangeRates();
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: AppColors.primary,
                    backgroundColor: Colors.white,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      children:
                          _pages
                              .map(
                                (page) => AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: page,
                                ),
                              )
                              .toList(),
                    ),
                  ),
                );
              },
            ),

            // Positioned app bar that moves with scroll
            Positioned(top: 0, left: 0, right: 0, child: _buildCustomAppBar()),

            // FAB menu background overlay
            if (_isFabMenuOpen)
              AnimatedBuilder(
                animation: _fabBackgroundAnimation,
                builder: (context, child) {
                  final backgroundOpacity = _fabBackgroundAnimation.value.clamp(
                    0.0,
                    1.0,
                  );
                  return GestureDetector(
                    onTap: _toggleFabMenu,
                    child: Container(
                      color: Colors.black.withOpacity(backgroundOpacity * 0.5),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNav(),
      floatingActionButton: _buildExpandableFab(),
    );
  }

  Widget _buildCustomAppBar() {
    return AnimatedBuilder(
      animation: _appBarScrollAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -140 * (1 - _appBarScrollAnimation.value)),
          child: SlideTransition(
            position: _appBarSlideAnimation,
            child: FadeTransition(
              opacity: _appBarFadeAnimation,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with greeting and actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Greeting and user name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getUserName(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action buttons
                        Row(
                          children: [
                            // Notification button
                            _buildActionButton(
                              icon: Icons.notifications_outlined,
                              onTap: _showNotifications,
                              badge:
                                  _notificationCount > 0
                                      ? _notificationCount
                                      : null,
                            ),

                            const SizedBox(width: 12),

                            // User avatar
                            _buildUserAvatar(),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quick search bar
                    _buildQuickSearchBar(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            if (badge != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    final userProfile = UserProfile.currentUserProfile;

    // Get profile photo URL from multiple sources
    String? photoURL = userProfile?['photoURL'] ?? user?.photoURL;

    return GestureDetector(
      onTap: () => _onTabTapped(3), // Navigate to profile
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: ClipOval(
          child:
              photoURL != null && photoURL.isNotEmpty
                  ? Image.network(
                    photoURL,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 24,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 24,
                      );
                    },
                  )
                  : Icon(Icons.person, color: AppColors.primary, size: 24),
        ),
      ),
    );
  }

  Widget _buildQuickSearchBar() {
    return GestureDetector(
      onTap: () => _onTabTapped(1), // Navigate to search
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.white.withOpacity(0.8), size: 20),
            const SizedBox(width: 12),
            Text(
              'Search properties...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    // TODO: Implement notifications page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_notificationCount new notifications'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Clear notification count after viewing
    setState(() {
      _notificationCount = 0;
    });
  }

  Widget _buildCustomBottomNav() {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            return _buildNavItem(index);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentIndex == index;
    final item = _navItems[index];

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 6 : 0,
              height: isSelected ? 6 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(height: 4),

            // Animated icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? item.selectedIcon : item.unselectedIcon,
                key: ValueKey('${index}_$isSelected'),
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: isSelected ? 26 : 24,
              ),
            ),

            const SizedBox(height: 4),

            // Animated label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableFab() {
    final currentItems = _contextualFabMenuItems;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // FAB menu items
        ...currentItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return AnimatedBuilder(
            animation: _fabMenuAnimation,
            builder: (context, child) {
              final offset = (index + 1) * 70.0 * _fabMenuAnimation.value;
              final opacity = _fabMenuAnimation.value.clamp(0.0, 1.0);
              final scale = _fabMenuAnimation.value.clamp(0.0, 1.0);

              return Transform.translate(
                offset: Offset(0, -offset),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: _buildFabMenuItem(item),
                  ),
                ),
              );
            },
          );
        }).toList(),

        // Main FAB with contextual icon
        AnimatedBuilder(
          animation: _fabController,
          builder: (context, child) {
            return Transform.scale(
              scale: _fabScaleAnimation.value.clamp(0.1, 2.0),
              child: Transform.rotate(
                angle: _isFabMenuOpen ? 0.785398 : 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getContextualColor().withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: _toggleFabMenu,
                    backgroundColor: _getContextualColor(),
                    elevation: 0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isFabMenuOpen ? Icons.close : _getContextualIcon(),
                        key: ValueKey('${_isFabMenuOpen}_${_currentIndex}'),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getContextualColor() {
    switch (_currentIndex) {
      case 0:
        return AppColors.primary; // Home - Blue
      case 1:
        return Colors.green; // Search - Green
      case 2:
        return Colors.red; // Favorites - Red
      case 3:
        return Colors.purple; // Profile - Purple
      default:
        return AppColors.primary;
    }
  }

  IconData _getContextualIcon() {
    switch (_currentIndex) {
      case 0:
        return Icons.add_home; // Home
      case 1:
        return Icons.search_off; // Search
      case 2:
        return Icons.favorite; // Favorites
      case 3:
        return Icons.person_add; // Profile
      default:
        return Icons.add;
    }
  }

  Widget _buildFabMenuItem(FabMenuItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onFabMenuItemTap(item),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                item.label,
                style: TextStyle(
                  color: item.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Icon button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onFabMenuItemTap(item),
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: item.color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(item.icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  // Add the missing _processProperties method
  List<QueryDocumentSnapshot> _getFilteredProperties(
    List<QueryDocumentSnapshot> docs,
    String type,
  ) {
    switch (type) {
      case 'featured':
        return docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['isFeatured'] == true;
        }).toList();
      case 'search':
        if (_searchQuery.isEmpty) return [];
        return docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;

          final title = (data['title'] ?? '').toString().toLowerCase();
          final description =
              (data['description'] ?? '').toString().toLowerCase();
          final city = (data['city'] ?? '').toString().toLowerCase();
          final address = (data['address'] ?? '').toString().toLowerCase();
          final query = _searchQuery.toLowerCase();

          return title.contains(query) ||
              description.contains(query) ||
              city.contains(query) ||
              address.contains(query);
        }).toList();
      case 'recent':
      default:
        return docs;
    }
  }

  // Add the missing _fetchExchangeRates method
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

  Widget _buildCurrencySelector() {
    return GestureDetector(
      onTap: _showCurrencySelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCurrency,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Currency',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...supportedCurrencies.map((currency) {
                final currencyCode = currency['code'] ?? 'USD';
                final currencySymbol = currency['symbol'] ?? '\$';
                final currencyName = currency['name'] ?? 'Unknown';
                final isSelected = currencyCode == _selectedCurrency;

                return ListTile(
                  leading: Text(
                    currencySymbol,
                    style: const TextStyle(fontSize: 18),
                  ),
                  title: Text(currencyCode),
                  subtitle: Text(currencyName),
                  trailing:
                      isSelected
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                  onTap: () {
                    setState(() {
                      _selectedCurrency = currencyCode;
                    });
                    Navigator.pop(context);
                    _showActionSnackBar(
                      'Currency changed to $currencyCode',
                      AppColors.primary,
                    );
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class NavItem {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;

  NavItem(this.selectedIcon, this.unselectedIcon, this.label);
}

class FabMenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final String? route;
  final String? action;

  FabMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    this.route,
    this.action,
  });
}

final List<Map<String, String>> supportedCurrencies = [
  {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
  {'code': 'UGX', 'symbol': 'USh', 'name': 'Ugandan Shilling'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  {'code': 'KES', 'symbol': 'KSh', 'name': 'Kenyan Shilling'},
  {'code': 'TZS', 'symbol': 'TSh', 'name': 'Tanzanian Shilling'},
];
