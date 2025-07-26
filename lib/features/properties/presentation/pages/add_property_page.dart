import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKeys = [
    GlobalKey<FormState>(), // Basic Info
    GlobalKey<FormState>(), // Details
    GlobalKey<FormState>(), // Location
    GlobalKey<FormState>(), // Photos (not used for validation)
  ];
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _parkingController = TextEditingController();

  String _selectedType = AppConstants.propertyTypes.first;
  String _selectedStatus = AppConstants.forSale;
  bool _isLoading = false;
  int _currentStep = 0;
  final List<String> _selectedAmenities = [];
  List<XFile> _selectedImages = [];

  final List<String> _amenities = [
    'WiFi',
    'Air Conditioning',
    'Heating',
    'Kitchen',
    'TV',
    'Parking',
    'Elevator',
    'Pool',
    'Gym',
    'Balcony',
    'Garden',
    'Security System',
    'Washer',
    'Dryer',
    'Dishwasher',
    'Fireplace',
  ];

  // Location variables
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoadingLocation = false;
  bool _isGeocodingAddress = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _selectedLocation = const LatLng(
      AppConstants.defaultLatitude,
      AppConstants.defaultLongitude,
    );
    _updateMapMarker();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = UserProfile.currentUserProfile;
    final role = userProfile != null ? userProfile['role'] : null;
    if (role != AppConstants.realtor && role != AppConstants.propertyOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Property')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'You do not have permission to add properties.',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Add Property'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Custom stepper indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepIndicator(0, 'Basic'),
                _buildStepConnector(_currentStep > 0),
                _buildStepIndicator(1, 'Details'),
                _buildStepConnector(_currentStep > 1),
                _buildStepIndicator(2, 'Location'),
                _buildStepConnector(_currentStep > 2),
                _buildStepIndicator(3, 'Photos'),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKeys[_currentStep],
                child: _buildCurrentStep(),
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_currentStep < 3) {
                        if (_formKeys[_currentStep].currentState!.validate()) {
                          setState(() {
                            _currentStep++;
                          });
                        }
                      } else {
                        _handleSubmit();
                      }
                    },
                    icon: Icon(
                      _currentStep == 3 ? Icons.check : Icons.arrow_forward,
                    ),
                    label: Text(_currentStep == 3 ? 'Submit' : 'Continue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrentStep = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey[300],
            shape: BoxShape.circle,
            border:
                isCurrentStep
                    ? Border.all(color: AppColors.primary, width: 3)
                    : null,
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child:
                isActive
                    ? Icon(
                      step < _currentStep ? Icons.check : Icons.circle,
                      color: Colors.white,
                      size: 18,
                    )
                    : Text(
                      '${step + 1}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primary : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isActive ? AppColors.primary : Colors.grey[300],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildLocationStep();
      case 3:
        return _buildPhotosStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Basic Information', Icons.info_outline),
        const SizedBox(height: 20),

        // Property Title
        _buildAnimatedContainer(
          child: TextFormField(
            controller: _titleController,
            decoration: _buildInputDecoration(
              'Property Title',
              'e.g., Modern Downtown Apartment',
              Icons.title,
            ),
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Title is required'
                        : null,
          ),
        ),
        const SizedBox(height: 16),

        // Property Description
        _buildAnimatedContainer(
          child: TextFormField(
            controller: _descriptionController,
            decoration: _buildInputDecoration(
              'Description',
              'Describe your property...',
              Icons.description,
              maxLines: 3,
            ),
            maxLines: 3,
            validator: (value) => Validators.required(value, 'Description'),
          ),
        ),
        const SizedBox(height: 16),

        // Property Type & Status
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  child: _buildAnimatedContainer(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      isDense: true,
                      decoration: _buildInputDecoration(
                        'Property Type',
                        '',
                        Icons.home_work,
                        maxLines: 1,
                      ).copyWith(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      items:
                          AppConstants.propertyTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Type is required'
                                  : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  fit: FlexFit.tight,
                  child: _buildAnimatedContainer(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      isDense: true,
                      decoration: _buildInputDecoration(
                        'Status',
                        '',
                        Icons.sell,
                        maxLines: 1,
                      ).copyWith(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AppConstants.forSale,
                          child: Text(
                            'For Sale',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.forRent,
                          child: Text(
                            'For Rent',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Status is required'
                                  : null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Price
        _buildAnimatedContainer(
          child: TextFormField(
            controller: _priceController,
            decoration: _buildInputDecoration(
              _selectedStatus == AppConstants.forSale
                  ? 'Price ( 24)'
                  : 'Price ( 24/month)',
              _selectedStatus == AppConstants.forSale ? '450000' : '2500',
              Icons.attach_money,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return 'Price is required';
              final num? price = num.tryParse(value.trim());
              if (price == null || price <= 0) return 'Enter a valid price';
              return null;
            },
          ),
        ),

        const SizedBox(height: 20),
        _buildInfoCard(
          'Pro Tip',
          'Properties with detailed descriptions and accurate pricing tend to get 45% more inquiries.',
          Icons.lightbulb_outline,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Property Details', Icons.apartment),
        const SizedBox(height: 20),

        // Bedrooms & Bathrooms
        Row(
          children: [
            Expanded(
              child: _buildAnimatedContainer(
                child: TextFormField(
                  controller: _bedroomsController,
                  decoration: _buildInputDecoration('Bedrooms', '2', Icons.bed),
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.required(value, 'Bedrooms'),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnimatedContainer(
                child: TextFormField(
                  controller: _bathroomsController,
                  decoration: _buildInputDecoration(
                    'Bathrooms',
                    '2',
                    Icons.bathtub,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.required(value, 'Bathrooms'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Area & Parking
        Row(
          children: [
            Expanded(
              child: _buildAnimatedContainer(
                child: TextFormField(
                  controller: _areaController,
                  decoration: _buildInputDecoration(
                    'Area (sq ft)',
                    '1200',
                    Icons.square_foot,
                  ),
                  keyboardType: TextInputType.number,
                  validator: Validators.area,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnimatedContainer(
                child: TextFormField(
                  controller: _parkingController,
                  decoration: _buildInputDecoration(
                    'Parking Spaces',
                    '1',
                    Icons.directions_car,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Amenities
        _buildSectionHeader(
          'Amenities',
          Icons.check_circle_outline,
          fontSize: 18,
        ),
        const SizedBox(height: 16),

        _buildAnimatedContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select all that apply:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _amenities.map((amenity) {
                      final isSelected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        label: Text(amenity),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primary.withOpacity(0.1),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : Colors.grey[300]!,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildInfoCard(
          'Boost Visibility',
          'Properties with 5+ amenities get 60% more views from potential buyers.',
          Icons.visibility,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Property Location', Icons.location_on),
        const SizedBox(height: 20),

        // Street Address with geocoding
        _buildAnimatedContainer(
          child: TextFormField(
            controller: _addressController,
            decoration: _buildInputDecoration(
              'Street Address',
              '123 Main St',
              Icons.home,
              suffixIcon:
                  _isGeocodingAddress
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _geocodeAddress,
                      ),
            ),
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Address is required'
                        : null,
            onChanged: (value) {
              // Auto-geocode after user stops typing
              if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
                if (value.isNotEmpty) _geocodeAddress();
              });
            },
          ),
        ),
        const SizedBox(height: 16),

        // City & State Row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildAnimatedContainer(
                child: TextFormField(
                  controller: _cityController,
                  decoration: _buildInputDecoration(
                    'City',
                    'San Francisco',
                    Icons.location_city,
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'City is required'
                              : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnimatedContainer(
                child: TextFormField(
                  controller: _stateController,
                  decoration: _buildInputDecoration('State', 'CA', Icons.map),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'State is required'
                              : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ZIP Code
        _buildAnimatedContainer(
          child: TextFormField(
            controller: _zipCodeController,
            decoration: _buildInputDecoration(
              'ZIP Code',
              '94102',
              Icons.pin_drop,
            ),
            keyboardType: TextInputType.number,
            validator: (value) => Validators.required(value, 'ZIP Code'),
          ),
        ),
        const SizedBox(height: 24),

        // Enhanced Map Section
        _buildSectionHeader('Map Location', Icons.map_outlined, fontSize: 18),
        const SizedBox(height: 16),

        // Location coordinates display
        if (_selectedLocation != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Interactive Google Map
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target:
                    _selectedLocation ??
                    const LatLng(
                      AppConstants.defaultLatitude,
                      AppConstants.defaultLongitude,
                    ),
                zoom: 15,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                // Move to selected location after map is created
                if (_selectedLocation != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
                  );
                }
              },
              onTap: (LatLng location) {
                setState(() {
                  _selectedLocation = location;
                  _updateMapMarker();
                });
                _reverseGeocode(location);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              mapType: MapType.normal,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Location Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon:
                    _isLoadingLocation
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.my_location, size: 18),
                label: Text(
                  _isLoadingLocation
                      ? 'Getting Location...'
                      : 'Use Current Location',
                ),
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _centerMapOnAddress,
                icon: const Icon(Icons.search_outlined, size: 18),
                label: const Text('Find Address'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        _buildInfoCard(
          'Location Accuracy',
          'Precise location helps buyers find your property easily and increases visibility by 75%.',
          Icons.location_searching,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Property Photos', Icons.photo_library),
        const SizedBox(height: 20),

        _buildAnimatedContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Add high-quality photos to showcase your property',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return _buildAddPhotoButton();
                  }
                  return _buildPhotoItem(index);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Cover Photo', Icons.image, fontSize: 18),
        const SizedBox(height: 16),

        _buildAnimatedContainer(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  child:
                      _selectedImages.isNotEmpty
                          ? Image.file(
                            File(_selectedImages.first.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          )
                          : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No cover photo selected',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
                if (_selectedImages.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
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
                        children: [
                          const Text(
                            'Cover Photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Change',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
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

        const SizedBox(height: 20),
        _buildInfoCard(
          'Photo Tips',
          'Properties with 5+ high-quality photos get 2x more interest from potential buyers.',
          Icons.photo_camera,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(File(_selectedImages[index].path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    double fontSize = 20,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(0),
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
      child: child,
    );
  }

  Widget _buildInfoCard(
    String title,
    String message,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: maxLines > 1 ? 16 : 0,
      ),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _selectedImages = picked;
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages(String propertyId) async {
    List<String> downloadUrls = [];
    for (var img in _selectedImages) {
      final ref = FirebaseStorage.instance.ref().child(
        'property_images/$propertyId/${DateTime.now().millisecondsSinceEpoch}_${img.name}',
      );
      final uploadTask = await ref.putData(await img.readAsBytes());
      final url = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(url);
    }
    return downloadUrls;
  }

  void _handleSubmit() async {
    if (!_formKeys[_currentStep].currentState!.validate()) {
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one property image.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final userProfile = UserProfile.currentUserProfile;
      final uid = userProfile != null ? userProfile['uid'] : null;
      final role = userProfile != null ? userProfile['role'] : null;
      if (uid == null) throw Exception('User not authenticated');
      // Create property doc first to get its ID
      final docRef = await FirebaseFirestore.instance
          .collection('properties')
          .add({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'type': _selectedType,
            'status': _selectedStatus,
            'price': num.tryParse(_priceController.text.trim()) ?? 0,
            'area': num.tryParse(_areaController.text.trim()) ?? 0,
            'bedrooms': num.tryParse(_bedroomsController.text.trim()) ?? 0,
            'bathrooms': num.tryParse(_bathroomsController.text.trim()) ?? 0,
            'parkingSpaces': num.tryParse(_parkingController.text.trim()) ?? 0,
            'address': _addressController.text.trim(),
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
            'zipCode': _zipCodeController.text.trim(),
            'amenities': _selectedAmenities,
            'ownerId': uid,
            'ownerRole': role,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'images': [], // Placeholder, will update after upload
            'isFeatured': false,
            'rating': 0.0,
            'reviews_count': 0,
          });
      print('Property created with ID: ${docRef.id}');
      // Upload images and update doc
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages(docRef.id);
        await docRef.update({'images': imageUrls});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error creating property: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add property: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper to update existing properties in Firestore to set missing or incorrect 'createdAt' fields
  debugUpdateCreatedAtForAllProperties() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('properties').get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['createdAt'] == null || data['createdAt'] is! Timestamp) {
        print('Fixing createdAt for property: ${doc.id}');
        await doc.reference.update({'createdAt': FieldValue.serverTimestamp()});
      }
    }
    print('Finished updating createdAt for all properties.');
  }

  Timer? _debounceTimer;

  void _updateMapMarker() {
    if (_selectedLocation != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('property_location'),
            position: _selectedLocation!,
            infoWindow: const InfoWindow(
              title: 'Property Location',
              snippet: 'Tap to move marker',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        };
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = newLocation;
        _updateMapMarker();
      });

      // Move camera to current location
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 16),
        );
      }

      // Reverse geocode to fill address fields
      await _reverseGeocode(newLocation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location obtained successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _geocodeAddress() async {
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();

    if (address.isEmpty) return;

    setState(() => _isGeocodingAddress = true);

    try {
      final fullAddress = '$address, $city, $state';
      List<Location> locations = await locationFromAddress(fullAddress);

      if (locations.isNotEmpty) {
        final location = locations.first;
        final newLocation = LatLng(location.latitude, location.longitude);

        setState(() {
          _selectedLocation = newLocation;
          _updateMapMarker();
        });

        // Move camera to geocoded location
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(newLocation, 16),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address located on map!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find address: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isGeocodingAddress = false);
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        setState(() {
          if (placemark.street != null && placemark.street!.isNotEmpty) {
            _addressController.text = placemark.street!;
          }
          if (placemark.locality != null && placemark.locality!.isNotEmpty) {
            _cityController.text = placemark.locality!;
          }
          if (placemark.administrativeArea != null &&
              placemark.administrativeArea!.isNotEmpty) {
            _stateController.text = placemark.administrativeArea!;
          }
          if (placemark.postalCode != null &&
              placemark.postalCode!.isNotEmpty) {
            _zipCodeController.text = placemark.postalCode!;
          }
        });
      }
    } catch (e) {
      print('Reverse geocoding failed: $e');
    }
  }

  Future<void> _centerMapOnAddress() async {
    await _geocodeAddress();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
