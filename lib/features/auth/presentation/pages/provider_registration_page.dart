import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/service_categories.dart';
import '../../../../core/models/user_profile.dart';

class ProviderRegistrationPage extends StatefulWidget {
  const ProviderRegistrationPage({super.key});

  @override
  State<ProviderRegistrationPage> createState() =>
      _ProviderRegistrationPageState();
}

class _ProviderRegistrationPageState extends State<ProviderRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _primaryService = '';
  List<String> _selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Service Provider'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join Our Network',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your professional profile and start connecting with clients',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Basic Information
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => Validators.required(value, 'Full name'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Professional Information
                _buildSectionTitle('Professional Information'),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _primaryService.isEmpty ? null : _primaryService,
                  decoration: const InputDecoration(
                    labelText: 'Primary Service',
                    prefixIcon: Icon(Icons.work),
                  ),
                  items:
                      ServiceCategories.categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['id'] as String,
                          child: Text(category['name'] as String),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _primaryService = value!;
                      if (!_selectedCategories.contains(value)) {
                        _selectedCategories.add(value);
                      }
                    });
                  },
                  validator:
                      (value) =>
                          value == null
                              ? 'Please select your primary service'
                              : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    prefixIcon: Icon(Icons.timeline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Years of experience is required';
                    }
                    final years = int.tryParse(value);
                    if (years == null || years < 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Professional Bio',
                    prefixIcon: Icon(Icons.description),
                    hintText:
                        'Tell clients about your expertise and experience...',
                  ),
                  validator: (value) => Validators.required(value, 'Bio'),
                ),

                const SizedBox(height: 32),

                // Location Information
                _buildSectionTitle('Location Information'),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) => Validators.required(value, 'Address'),
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
                        validator:
                            (value) => Validators.required(value, 'City'),
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
                        validator:
                            (value) => Validators.required(value, 'State'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Service Categories
                _buildSectionTitle('Service Categories'),
                const SizedBox(height: 16),
                _buildServiceCategoriesSelection(),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleProviderRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create Provider Account'),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Already have an account? Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildServiceCategoriesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select all services you provide:',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              ServiceCategories.categories.map((category) {
                final categoryId = category['id'] as String;
                final categoryName = category['name'] as String;
                final isSelected = _selectedCategories.contains(categoryId);
                return FilterChip(
                  label: Text(categoryName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(categoryId);
                      } else {
                        _selectedCategories.remove(categoryId);
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
        ),
      ],
    );
  }

  void _handleProviderRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one service category'),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Create Firebase Auth user
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        final user = userCredential.user;
        if (user != null) {
          // Create user profile in users collection
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'uid': user.uid,
                'email': user.email,
                'displayName': _nameController.text.trim(),
                'role': 'service_provider',
                'phone': _phoneController.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
                'isOnline': false,
                'lastSeen': FieldValue.serverTimestamp(),
              });

          // Create service provider profile
          await _createServiceProviderProfile(user.uid);

          // Set user profile
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
          UserProfile.currentUserProfile = userDoc.data();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Provider account created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _createServiceProviderProfile(String userId) async {
    final primaryServiceCategory = ServiceCategories.getCategoryById(
      _primaryService,
    );

    await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(userId)
        .set({
          'id': userId,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'profile_image': '',
          'bio': _bioController.text.trim(),
          'service_categories': _selectedCategories,
          'primary_service': primaryServiceCategory?['name'] ?? '',
          'rating': 0.0,
          'reviews_count': 0,
          'total_rating': 0.0,
          'location': _locationController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'latitude': 0.0, // TODO: Get from geocoding
          'longitude': 0.0, // TODO: Get from geocoding
          'portfolio_images': [],
          'certifications': [],
          'years_of_experience': int.parse(_experienceController.text.trim()),
          'is_verified': false, // Admin verification required
          'is_online': true,
          'is_featured': false,
          'availability': 'available',
          'pricing': {},
          'service_areas': [
            _cityController.text.trim(),
            _stateController.text.trim(),
          ],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active': FieldValue.serverTimestamp(),
        });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _experienceController.dispose();
    super.dispose();
  }
}
