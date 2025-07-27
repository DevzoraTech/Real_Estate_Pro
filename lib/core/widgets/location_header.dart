import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';

class LocationHeader extends StatefulWidget {
  final double? currentLatitude;
  final double? currentLongitude;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final VoidCallback? onTap;
  final bool showRefreshButton;
  
  const LocationHeader({
    Key? key,
    this.currentLatitude,
    this.currentLongitude,
    this.isLoading = false,
    this.onRefresh,
    this.onTap,
    this.showRefreshButton = true,
  }) : super(key: key);

  @override
  State<LocationHeader> createState() => _LocationHeaderState();
}

class _LocationHeaderState extends State<LocationHeader> {
  String _locationText = 'Getting location...';
  IconData _locationIcon = Icons.location_searching;

  @override
  void initState() {
    super.initState();
    _updateLocationDisplay();
  }

  @override
  void didUpdateWidget(LocationHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLatitude != widget.currentLatitude ||
        oldWidget.currentLongitude != widget.currentLongitude ||
        oldWidget.isLoading != widget.isLoading) {
      _updateLocationDisplay();
    }
  }

  void _updateLocationDisplay() {
    if (widget.isLoading) {
      _locationText = 'Getting location...';
      _locationIcon = Icons.location_searching;
    } else if (widget.currentLatitude != null && widget.currentLongitude != null) {
      _locationText = 'Current Location';
      _locationIcon = Icons.location_on;
      _loadAddressFromCoordinates();
    } else {
      _locationText = 'San Francisco, CA, USA'; // Fallback
      _locationIcon = Icons.location_off;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadAddressFromCoordinates() async {
    if (widget.currentLatitude == null || widget.currentLongitude == null) return;
    
    try {
      final address = await LocationService.instance.getCurrentAddress();
      if (mounted && address != null) {
        setState(() {
          _locationText = address;
        });
      }
    } catch (e) {
      // Keep current location text if geocoding fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Icon(
                    _locationIcon,
                    color: AppColors.primary,
                    size: 16,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _locationText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.showRefreshButton) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.isLoading ? null : widget.onRefresh,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.refresh,
                  color: widget.isLoading ? Colors.grey : AppColors.primary,
                  size: 16,
                ),
              ),
            ),
          ],
          if (widget.onTap != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primary,
                  size: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NearbyPropertiesHeader extends StatelessWidget {
  final int count;
  final double? radius;
  final VoidCallback? onViewAll;
  
  const NearbyPropertiesHeader({
    Key? key,
    required this.count,
    this.radius,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.near_me,
              color: AppColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Properties Near You',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  radius != null
                      ? '$count properties within ${radius!.toInt()}km'
                      : '$count properties found',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (onViewAll != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
