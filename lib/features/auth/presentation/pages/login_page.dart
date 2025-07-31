import 'package:flutter/material.dart';
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

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.home_work, size: 80, color: AppColors.primary),
                const SizedBox(height: 24),
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Sign In'),
                ),
                const SizedBox(height: 16),
                // Google Sign-In Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/google.png', height: 24),
                      const SizedBox(width: 12),
                      const Text('Sign in with Google'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.register);
                      },
                      child: const Text('Sign Up as Customer'),
                    ),
                    const Text(' | '),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const ProviderRegistrationPage(),
                          ),
                        );
                      },
                      child: const Text('Become a Provider'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });
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
        SnackBar(content: Text(e.message ?? 'Google sign-in failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in failed')));
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
                    child: AlertDialog(
                      title: const Text('Select Your Role'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _roleOptionTile(
                            AppConstants.customer,
                            selectedRole,
                            (val) => setState(() => selectedRole = val),
                            icon: Icons.person,
                            description: 'Browse and contact agents.',
                          ),
                          _roleOptionTile(
                            AppConstants.realtor,
                            selectedRole,
                            (val) => setState(() => selectedRole = val),
                            icon: Icons.business_center,
                            description: 'List and manage properties.',
                          ),
                          _roleOptionTile(
                            AppConstants.propertyOwner,
                            selectedRole,
                            (val) => setState(() => selectedRole = val),
                            icon: Icons.home_work,
                            description: 'Manage your own properties.',
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed:
                              selectedRole == null
                                  ? null
                                  : () =>
                                      Navigator.of(context).pop(selectedRole),
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: FadeTransition(opacity: anim1, child: child),
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
    return ListTile(
      leading: Icon(
        icon,
        color: value == selectedRole ? AppColors.primary : Colors.grey,
      ),
      title: Text(_roleLabel(value)),
      subtitle: Text(description),
      trailing: Radio<String>(
        value: value,
        groupValue: selectedRole,
        onChanged: (val) => onChanged(val!),
        activeColor: AppColors.primary,
      ),
      onTap: () => onChanged(value),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
