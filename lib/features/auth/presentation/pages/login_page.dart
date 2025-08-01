import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/user_profile.dart';
import '../../../chat/data/services/notification_service.dart';
import 'provider_registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 50),
                    _buildLoginForm(),
                    const SizedBox(height: 30),
                    _buildSocialLogin(),
                    const SizedBox(height: 40),
                    _buildFooterActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.asset(
              'assets/images/flutter_icon.jpg',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue to UpSpace',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmailField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildRememberMeRow(),
            const SizedBox(height: 30),
            _buildSignInButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
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
      validator: Validators.email,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
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
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
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
      validator: Validators.password,
    );
  }

  Widget _buildRememberMeRow() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Text('Remember me', style: TextStyle(color: Colors.grey[600])),
        const Spacer(),
        TextButton(
          onPressed: () {
            // TODO: Implement forgot password
            _showForgotPasswordDialog();
          },
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
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
        onPressed: _isLoading ? null : _handleLogin,
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
                : const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        const SizedBox(height: 24),
        _buildGoogleSignInButton(),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/google.png', height: 24, width: 24),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(color: Colors.grey[600]),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.register);
              },
              child: Text(
                'Sign Up',
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
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.business_center, color: Colors.blue[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Looking to provide services?',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProviderRegistrationPage(),
                    ),
                  );
                },
                child: Text(
                  'Join as Provider',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Reset Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (emailController.text.isNotEmpty) {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: emailController.text.trim(),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset email sent!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: const Text('Send Reset Link'),
              ),
            ],
          ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Add haptic feedback
      HapticFeedback.lightImpact();

      try {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        final user = userCredential.user;
        if (user != null) {
          // Save FCM token for notifications
          final notificationService = NotificationService();
          final fcmToken = await notificationService.getFcmToken();
          if (fcmToken != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'fcmToken': fcmToken});
          }

          // Always fetch the latest profile from Firestore
          final userDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);
          final userDocSnap = await userDocRef.get();
          if (!userDocSnap.exists ||
              !userDocSnap.data()!.containsKey('isOnline')) {
            await userDocRef.set({
              'isOnline': false,
              'lastSeen': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
          if (!userDocSnap.exists) {
            throw FirebaseAuthException(
              message: 'User profile not found. Please register again.',
              code: 'profile-not-found',
            );
          }
          UserProfile.currentUserProfile = userDocSnap.data();
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Login failed';
        switch (e.code) {
          case 'user-not-found':
            message = 'No user found with this email address.';
            break;
          case 'wrong-password':
            message = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            message = 'Please enter a valid email address.';
            break;
          case 'user-disabled':
            message = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            message = 'Too many failed attempts. Please try again later.';
            break;
          default:
            message = e.message ?? 'Login failed';
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
            content: Text('An unexpected error occurred: ${e.toString()}'),
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

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    HapticFeedback.lightImpact();

    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Force account picker
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return; // User canceled
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user != null) {
        // Save FCM token for notifications
        final notificationService = NotificationService();
        final fcmToken = await notificationService.getFcmToken();

        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final userDocSnap = await userDocRef.get();
        if (!userDocSnap.exists ||
            !userDocSnap.data()!.containsKey('isOnline')) {
          await userDocRef.set({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        if (!userDocSnap.exists) {
          // Prompt for role/profile completion
          String? selectedRole = await _showRoleDialog();
          if (selectedRole == null) {
            setState(() {
              _isLoading = false;
            });
            return;
          }
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'uid': user.uid,
                'email': user.email,
                'displayName': user.displayName ?? '',
                'role': selectedRole,
                'phone': user.phoneNumber ?? '',
                'createdAt': FieldValue.serverTimestamp(),
                'fcmToken': fcmToken,
              });
          final newUserDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
          UserProfile.currentUserProfile = newUserDoc.data();
        } else {
          // Update FCM token for existing user
          if (fcmToken != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'fcmToken': fcmToken});
          }
          UserProfile.currentUserProfile = userDocSnap.data();
        }
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Google sign-in failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Future<String?> _showRoleDialog() async {
    String? selectedRole = AppConstants.customer;
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Role Selection',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Material(
                color: Colors.transparent,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim1, curve: Curves.easeOut),
                  ),
                  child: FadeTransition(
                    opacity: anim1,
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Choose Your Role',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select how you\'ll be using Real Estate Pro',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          _roleOptionTile(
                            AppConstants.customer,
                            selectedRole,
                            (val) => setState(() => selectedRole = val),
                            icon: Icons.person_outline,
                            description: 'Browse and contact agents.',
                          ),
                          _roleOptionTile(
                            AppConstants.realtor,
                            selectedRole,
                            (val) => setState(() => selectedRole = val),
                            icon: Icons.business_center_outlined,
                            description: 'List and manage properties.',
                          ),
                          _roleOptionTile(
                            AppConstants.propertyOwner,
                            selectedRole,
                            (val) => setState(() => selectedRole = val),
                            icon: Icons.home_work_outlined,
                            description: 'Manage your own properties.',
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(null),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      () => Navigator.of(
                                        context,
                                      ).pop(selectedRole),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _roleOptionTile(
    String value,
    String? selectedRole,
    ValueChanged<String> onChanged, {
    required IconData icon,
    required String description,
  }) {
    final isSelected = value == selectedRole;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey[400],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          _roleLabel(value),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : Colors.grey[800],
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Radio<String>(
          value: value,
          groupValue: selectedRole,
          onChanged: (val) => onChanged(val!),
          activeColor: AppColors.primary,
        ),
        onTap: () => onChanged(value),
      ),
    );
  }

  String _roleLabel(String value) {
    switch (value) {
      case AppConstants.customer:
        return 'Customer';
      case AppConstants.realtor:
        return 'Realtor';
      case AppConstants.propertyOwner:
        return 'Property Owner';
      default:
        return value;
    }
  }
}
