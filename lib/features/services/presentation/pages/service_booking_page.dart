import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/models/service_provider_model.dart';
import '../../domain/entities/service_booking.dart';
import '../../data/models/service_booking_model.dart';

class ServiceBookingPage extends StatefulWidget {
  final ServiceProviderModel provider;

  const ServiceBookingPage({super.key, required this.provider});

  @override
  State<ServiceBookingPage> createState() => _ServiceBookingPageState();
}

class _ServiceBookingPageState extends State<ServiceBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  BookingPriority _selectedPriority = BookingPriority.medium;
  String _selectedServiceType = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (widget.provider.serviceCategories.isNotEmpty) {
      _selectedServiceType = widget.provider.serviceCategories.first;
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
          final userData = userDoc.data()!;
          _phoneController.text = userData['phone'] ?? '';
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProviderInfo(),
              const SizedBox(height: 24),
              _buildServiceDetails(),
              const SizedBox(height: 24),
              _buildLocationDetails(),
              const SizedBox(height: 24),
              _buildSchedulingDetails(),
              const SizedBox(height: 24),
              _buildAdditionalDetails(),
              const SizedBox(height: 32),
              _buildBookButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child:
                  widget.provider.profileImage.isNotEmpty
                      ? ClipOval(
                        child: Image.network(
                          widget.provider.profileImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              widget.provider.name.isNotEmpty
                                  ? widget.provider.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      )
                      : Text(
                        widget.provider.name.isNotEmpty
                            ? widget.provider.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.provider.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.provider.primaryService,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.provider.rating.toStringAsFixed(1)} (${widget.provider.reviewsCount} reviews)',
                        style: const TextStyle(fontSize: 12),
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

  Widget _buildServiceDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _selectedServiceType.isEmpty ? null : _selectedServiceType,
          decoration: const InputDecoration(
            labelText: 'Service Type',
            prefixIcon: Icon(Icons.work),
          ),
          items:
              widget.provider.serviceCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(_getCategoryDisplayName(category)),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedServiceType = value!;
            });
          },
          validator:
              (value) => value == null ? 'Please select a service type' : null,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Service Title',
            prefixIcon: Icon(Icons.title),
            hintText: 'Brief title for your service request',
          ),
          validator: (value) => Validators.required(value, 'Service title'),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description',
            prefixIcon: Icon(Icons.description),
            hintText: 'Describe what you need in detail...',
          ),
          validator: (value) => Validators.required(value, 'Description'),
        ),
      ],
    );
  }

  Widget _buildLocationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Service Address',
            prefixIcon: Icon(Icons.location_on),
            hintText: 'Where should the service be performed?',
          ),
          validator: (value) => Validators.required(value, 'Service address'),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) => Validators.required(value, 'City'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  prefixIcon: Icon(Icons.map),
                ),
                validator: (value) => Validators.required(value, 'State'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSchedulingDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scheduling',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        ListTile(
          leading: const Icon(Icons.calendar_today, color: AppColors.primary),
          title: const Text('Preferred Date'),
          subtitle: Text(
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _selectDate,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<BookingPriority>(
          value: _selectedPriority,
          decoration: const InputDecoration(
            labelText: 'Priority',
            prefixIcon: Icon(Icons.priority_high),
          ),
          items:
              BookingPriority.values.map((priority) {
                return DropdownMenuItem<BookingPriority>(
                  value: priority,
                  child: Text(_getPriorityDisplayName(priority)),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPriority = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Contact Phone',
            prefixIcon: Icon(Icons.phone),
          ),
          validator: Validators.phone,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _specialInstructionsController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Special Instructions (Optional)',
            prefixIcon: Icon(Icons.note),
            hintText: 'Any special requirements or instructions...',
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'Book Service',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }

        // Get user data
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        final userData = userDoc.data() ?? {};
        final userName = userData['displayName'] ?? 'Unknown User';
        final userEmail = user.email ?? '';

        // Create booking
        final bookingRef =
            FirebaseFirestore.instance.collection('service_bookings').doc();

        final booking = ServiceBookingModel(
          id: bookingRef.id,
          customerId: user.uid,
          customerName: userName,
          customerPhone: _phoneController.text.trim(),
          customerEmail: userEmail,
          providerId: widget.provider.id,
          providerName: widget.provider.name,
          serviceCategory: _selectedServiceType,
          serviceType: _getCategoryDisplayName(_selectedServiceType),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: BookingStatus.pending,
          priority: _selectedPriority,
          requestedDate: _selectedDate,
          serviceAddress: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          serviceDetails: {
            'provider_service': widget.provider.primaryService,
            'provider_rating': widget.provider.rating,
          },
          depositPaid: false,
          attachments: [],
          specialInstructions:
              _specialInstructionsController.text.trim().isNotEmpty
                  ? _specialInstructionsController.text.trim()
                  : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await bookingRef.set(booking.toJson());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _getCategoryDisplayName(String categoryId) {
    final categoryMap = {
      'real_estate_agents': 'Real Estate Agent',
      'property_owners': 'Property Owner',
      'property_managers': 'Property Manager',
      'home_inspectors': 'Home Inspector',
      'mortgage_brokers': 'Mortgage Broker',
      'interior_designers': 'Interior Designer',
      'contractors': 'Contractor',
      'lawyers': 'Legal Services',
      'insurance_agents': 'Insurance Agent',
      'architects': 'Architect',
      'landscapers': 'Landscaper',
      'cleaners': 'Cleaning Services',
    };
    return categoryMap[categoryId] ?? categoryId;
  }

  String _getPriorityDisplayName(BookingPriority priority) {
    switch (priority) {
      case BookingPriority.low:
        return 'Low Priority';
      case BookingPriority.medium:
        return 'Medium Priority';
      case BookingPriority.high:
        return 'High Priority';
      case BookingPriority.urgent:
        return 'Urgent';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }
}
