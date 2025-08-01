import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ProviderRegistrationPageState extends State<ProviderRegistrationPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Controllers
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
  int _currentStep = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              Colors.white,
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildProgressIndicator(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildBasicInfoStep(),
                        _buildProfessionalInfoStep(),
                        _buildLocationStep(),
                        _buildServicesStep(),
                      ],
                    ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.business_center_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Join Our Network',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your professional profile and start connecting with clients',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              isCompleted
                                  ? AppColors.primary
                                  : isActive
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child:
                            isCompleted
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                                : isActive
                                ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                                : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepTitle('Basic Information', 'Tell us about yourself'),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (value) => Validators.required(value, 'Full name'),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _passwordController,
              label: 'Password',
              obscureText: _obscurePassword,
              onToggle:
                  () => setState(() => _obscurePassword = !_obscurePassword),
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              obscureText: _obscureConfirmPassword,
              onToggle:
                  () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Professional Information', 'Share your expertise'),
          const SizedBox(height: 24),
          _buildDropdownField(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _experienceController,
            label: 'Years of Experience',
            icon: Icons.timeline_outlined,
            keyboardType: TextInputType.number,
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
          _buildTextField(
            controller: _bioController,
            label: 'Professional Bio',
            icon: Icons.description_outlined,
            maxLines: 4,
            hintText: 'Tell clients about your expertise and experience...',
            validator: (value) => Validators.required(value, 'Bio'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Location Information', 'Where do you operate?'),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _locationController,
            label: 'Street Address',
            icon: Icons.location_on_outlined,
            validator: (value) => Validators.required(value, 'Address'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  validator: (value) => Validators.required(value, 'City'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _stateController,
                  label: 'State',
                  icon: Icons.map_outlined,
                  validator: (value) => Validators.required(value, 'State'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Service Categories',
            'What services do you provide?',
          ),
          const SizedBox(height: 24),
          _buildServiceCategoriesSelection(),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey[600],
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _primaryService.isEmpty ? null : _primaryService,
      decoration: InputDecoration(
        labelText: 'Primary Service',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.work_outline, color: AppColors.primary, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
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
              value == null ? 'Please select your primary service' : null,
    );
  }

  Widget _buildServiceCategoriesSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Choose all services you provide',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                ServiceCategories.categories.map((category) {
                  final categoryId = category['id'] as String;
                  final categoryName = category['name'] as String;
                  final isSelected = _selectedCategories.contains(categoryId);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: FilterChip(
                      label: Text(
                        categoryName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
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
                      backgroundColor: Colors.grey[100],
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : Colors.grey[300]!,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppColors.primary),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: Container(
              height: 56,
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
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : (_currentStep == 3
                            ? _handleProviderRegistration
                            : _nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          _currentStep == 3 ? 'Create Account' : 'Continue',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 3) {
      // Validate current step
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        HapticFeedback.lightImpact();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState!.validate();
      case 1:
        return _primaryService.isNotEmpty &&
            _experienceController.text.isNotEmpty &&
            _bioController.text.isNotEmpty;
      case 2:
        return _locationController.text.isNotEmpty &&
            _cityController.text.isNotEmpty &&
            _stateController.text.isNotEmpty;
      case 3:
        if (_selectedCategories.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Please select at least one service category',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _handleProviderRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select at least one service category'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      HapticFeedback.lightImpact();

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
              SnackBar(
                content: const Text('Provider account created successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Registration failed';
        switch (e.code) {
          case 'email-already-in-use':
            message = 'An account with this email already exists.';
            break;
          case 'weak-password':
            message =
                'Password is too weak. Please choose a stronger password.';
            break;
          case 'invalid-email':
            message = 'Please enter a valid email address.';
            break;
          default:
            message = e.message ?? 'Registration failed';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
}
