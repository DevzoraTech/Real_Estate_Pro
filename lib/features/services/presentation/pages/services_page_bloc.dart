import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/service_categories.dart';
import '../../../../core/models/service_provider_model.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/service_provider.dart';
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';
import '../bloc/service_state.dart';
import 'service_provider_detail_page.dart';

class ServicesBlocPage extends StatelessWidget {
  const ServicesBlocPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              di.sl<ServiceBloc>()
                ..add(const LoadFeaturedProviders())
                ..add(const LoadTopRatedProviders()),
      child: const _ServicesPageContent(),
    );
  }
}

class _ServicesPageContent extends StatefulWidget {
  const _ServicesPageContent();

  @override
  State<_ServicesPageContent> createState() => _ServicesPageContentState();
}

class _ServicesPageContentState extends State<_ServicesPageContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _showOnlineOnly = false;
  bool _showVerifiedOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
      _performSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (_searchQuery.isNotEmpty ||
        _selectedCategory != 'all' ||
        _showOnlineOnly ||
        _showVerifiedOnly) {
      context.read<ServiceBloc>().add(
        SearchServiceProviders(
          query: _searchQuery.isNotEmpty ? _searchQuery : null,
          category: _selectedCategory != 'all' ? _selectedCategory : null,
          isOnline: _showOnlineOnly ? true : null,
          isVerified: _showVerifiedOnly ? true : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<ServiceBloc>().add(const RefreshServices());
          },
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilters(),
              _buildServiceCategories(),
              _buildFeaturedProviders(),
              _buildTopRatedProviders(),
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
            colors: [AppColors.primary.withValues(alpha: 0.05), Colors.white],
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
                          'Professional Services',
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
                                color: Colors.black.withValues(alpha: 0.08),
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
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.work,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'All Services',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showVerifiedOnly
                              ? Icons.verified
                              : Icons.verified_outlined,
                          color:
                              _showVerifiedOnly
                                  ? AppColors.primary
                                  : Colors.grey[600],
                          size: 24,
                        ),
                        tooltip: 'Verified Only',
                        onPressed: () {
                          setState(() {
                            _showVerifiedOnly = !_showVerifiedOnly;
                          });
                          _performSearch();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _showOnlineOnly
                              ? Icons.online_prediction
                              : Icons.online_prediction_outlined,
                          color:
                              _showOnlineOnly ? Colors.green : Colors.grey[600],
                          size: 24,
                        ),
                        tooltip: 'Online Only',
                        onPressed: () {
                          setState(() {
                            _showOnlineOnly = !_showOnlineOnly;
                          });
                          _performSearch();
                        },
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
                      text: 'Right ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: 'Professional',
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
                'Connect with verified service providers for all your needs',
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
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    _searchQuery.isNotEmpty
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Search by name, service, or location...',
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
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                      : null,
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

  Widget _buildFilters() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildFilterChip('All Categories', 'all', Icons.apps),
            const SizedBox(width: 12),
            _buildFilterChip(
              'Real Estate',
              'real_estate_agents',
              Icons.business_center,
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              'Property Owners',
              'property_owners',
              Icons.home_work,
            ),
            const SizedBox(width: 12),
            _buildFilterChip('Contractors', 'contractors', Icons.construction),
            const SizedBox(width: 12),
            _buildFilterChip(
              'Designers',
              'interior_designers',
              Icons.design_services,
            ),
            const SizedBox(width: 12),
            _buildFilterChip('Legal', 'lawyers', Icons.gavel),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String category, IconData icon) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        _performSearch();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategories() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              'Service Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: ServiceCategories.categories.length,
              itemBuilder: (context, index) {
                final category = ServiceCategories.categories[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['id'];
                      });
                      _performSearch();
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: (category['color'] as Color).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  _selectedCategory == category['id']
                                      ? category['color']
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            category['icon'],
                            color: category['color'],
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                _selectedCategory == category['id']
                                    ? AppColors.primary
                                    : Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildFeaturedProviders() {
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
                  'Featured Providers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<ServiceBloc>().add(
                      const LoadServiceProviders(),
                    );
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
          ),
          SizedBox(
            height: 280,
            child: BlocBuilder<ServiceBloc, ServiceState>(
              builder: (context, state) {
                if (state is ServiceLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is FeaturedProvidersLoaded) {
                  if (state.providers.isEmpty) {
                    return _buildEmptyState('No featured providers found');
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.providers.length,
                    itemBuilder: (context, index) {
                      return _buildProviderCard(state.providers[index]);
                    },
                  );
                } else if (state is ServiceError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return _buildEmptyState('No featured providers found');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRatedProviders() {
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
                  'Top Rated',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<ServiceBloc>().add(
                      const LoadServiceProviders(),
                    );
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
          ),
          SizedBox(
            height: 280,
            child: BlocBuilder<ServiceBloc, ServiceState>(
              builder: (context, state) {
                if (state is ServiceLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TopRatedProvidersLoaded) {
                  if (state.providers.isEmpty) {
                    return _buildEmptyState('No top rated providers found');
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.providers.length,
                    itemBuilder: (context, index) {
                      return _buildProviderCard(state.providers[index]);
                    },
                  );
                } else if (state is ServiceError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return _buildEmptyState('No top rated providers found');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(ServiceProvider provider) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                // Convert ServiceProvider entity to ServiceProviderModel for the detail page
                final providerModel = ServiceProviderModel(
                  id: provider.id,
                  name: provider.name,
                  email: provider.email,
                  phone: provider.phone,
                  profileImage: provider.profileImage,
                  bio: provider.bio,
                  serviceCategories: provider.serviceCategories,
                  primaryService: provider.primaryService,
                  rating: provider.rating,
                  reviewsCount: provider.reviewsCount,
                  location: provider.location,
                  city: provider.city,
                  state: provider.state,
                  latitude: provider.latitude,
                  longitude: provider.longitude,
                  portfolioImages: provider.portfolioImages,
                  certifications: provider.certifications,
                  yearsOfExperience: provider.yearsOfExperience,
                  isVerified: provider.isVerified,
                  isOnline: provider.isOnline,
                  availability: provider.availability,
                  pricing: provider.pricing,
                  serviceAreas: provider.serviceAreas,
                  createdAt: provider.createdAt,
                  updatedAt: provider.updatedAt,
                  lastActive: provider.lastActive,
                );

                return ServiceProviderDetailPage(provider: providerModel);
              },
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image and Status
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child:
                        provider.profileImage.isNotEmpty
                            ? Image.network(
                              provider.profileImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar(provider.name);
                              },
                            )
                            : _buildDefaultAvatar(provider.name),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (provider.isVerified)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      if (provider.isVerified) const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: provider.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Provider Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.primaryService,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.rating.toStringAsFixed(1)} (${provider.reviewsCount})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[500],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          provider.city,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.isOnline ? 'Available Now' : 'Offline',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            provider.isOnline
                                ? AppColors.primary
                                : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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

  Widget _buildDefaultAvatar(String name) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
