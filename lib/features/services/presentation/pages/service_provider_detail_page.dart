import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/service_provider_model.dart';
import '../../../../core/constants/service_categories.dart';
import 'service_booking_page.dart';

class ServiceProviderDetailPage extends StatefulWidget {
  final ServiceProviderModel provider;

  const ServiceProviderDetailPage({super.key, required this.provider});

  @override
  State<ServiceProviderDetailPage> createState() =>
      _ServiceProviderDetailPageState();
}

class _ServiceProviderDetailPageState extends State<ServiceProviderDetailPage> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          CustomScrollView(
            slivers: [
              // Profile Header
              _buildProfileHeader(),

              // Provider Details
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
                        _buildProviderInfo(),
                        _buildServices(),
                        _buildPortfolio(),
                        _buildReviews(),
                        _buildContactInfo(),
                        const SizedBox(height: 100), // Space for bottom buttons
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
                  () => setState(() => _isFavorite = !_isFavorite),
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

  Widget _buildProfileHeader() {
    final images =
        widget.provider.portfolioImages.isNotEmpty
            ? widget.provider.portfolioImages
            : [widget.provider.profileImage];

    return SliverAppBar(
      expandedHeight: 300,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Stack(
        children: [
          // Image Carousel
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return images[index].isNotEmpty
                  ? Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultProfileImage();
                    },
                  )
                  : _buildDefaultProfileImage();
            },
          ),

          // Image indicators
          if (images.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),

          // Status badges
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.provider.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.provider.isVerified) const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.provider.isOnline ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.provider.isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildDefaultProfileImage() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.provider.name.isNotEmpty
                  ? widget.provider.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.provider.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and primary service
          Text(
            widget.provider.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.provider.primaryService,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Rating and experience
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${widget.provider.rating.toStringAsFixed(1)} (${widget.provider.reviewsCount} reviews)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.provider.yearsOfExperience} years exp.',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Location
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
                  widget.provider.fullLocation,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bio
          if (widget.provider.bio.isNotEmpty) ...[
            _buildSectionTitle('About', Icons.person_outline),
            const SizedBox(height: 12),
            Text(
              widget.provider.bio,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServices() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Services', Icons.work_outline),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                widget.provider.serviceCategories.map((categoryId) {
                  final category = ServiceCategories.getCategoryById(
                    categoryId,
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          category != null
                              ? (category['color'] as Color).withValues(
                                alpha: 0.1,
                              )
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            category != null
                                ? (category['color'] as Color).withValues(
                                  alpha: 0.3,
                                )
                                : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category?['icon'] ?? Icons.work,
                          color: category?['color'] ?? Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ServiceCategories.getCategoryName(categoryId),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: category?['color'] ?? Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolio() {
    if (widget.provider.portfolioImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Portfolio', Icons.photo_library_outlined),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.provider.portfolioImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.provider.portfolioImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Reviews', Icons.star_outline),
              TextButton(
                onPressed: () {
                  // Navigate to all reviews
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      widget.provider.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < widget.provider.rating.floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.provider.reviewsCount} reviews',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
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
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Contact Information',
            Icons.contact_phone_outlined,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildContactItem(Icons.email_outlined, widget.provider.email),
                const SizedBox(height: 12),
                _buildContactItem(Icons.phone_outlined, widget.provider.phone),
                if (widget.provider.serviceAreas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildContactItem(
                    Icons.location_on_outlined,
                    'Service Areas: ${widget.provider.serviceAreas.join(', ')}',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary action - Book Service
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _bookService,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Book Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showContactDialog,
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Provider'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone, color: AppColors.primary),
                title: Text(widget.provider.phone),
                subtitle: const Text('Phone'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement phone call
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: AppColors.primary),
                title: Text(widget.provider.email),
                subtitle: const Text('Email'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement email
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _openChat() {
    // Navigate to chat page with this provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening chat...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _bookService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceBookingPage(provider: widget.provider),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
