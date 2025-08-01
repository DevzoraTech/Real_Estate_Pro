import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _progressAnimation;

  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthStatus();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
    _progressController.repeat();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
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
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
              Colors.purple.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedLogo(),
                      const SizedBox(height: 40),
                      _buildAnimatedText(),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLoadingIndicator(),
                    const SizedBox(height: 20),
                    _buildLoadingMessage(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Transform.rotate(
            angle: _logoRotationAnimation.value * 0.1,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText() {
    return FadeTransition(
      opacity: _textFadeAnimation,
      child: SlideTransition(
        position: _textSlideAnimation,
        child: Column(
          children: [
            Text(
              'UpSpace',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Choices Start Here',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Stack(
            children: [
              Container(
                width: 200 * _progressAnimation.value,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _loadingMessage,
        key: ValueKey(_loadingMessage),
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _updateLoadingMessage(String message) {
    if (mounted) {
      setState(() {
        _loadingMessage = message;
      });
    }
  }

  void _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    _updateLoadingMessage('Checking authentication...');
    await Future.delayed(const Duration(milliseconds: 500));

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _updateLoadingMessage('Loading your profile...');
      await Future.delayed(const Duration(milliseconds: 300));

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        _updateLoadingMessage('Welcome back!');
        UserProfile.currentUserProfile = userDoc.data();
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } else {
        _updateLoadingMessage('Profile not found, signing out...');
        await FirebaseAuth.instance.signOut();
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }
    } else {
      _updateLoadingMessage('Ready to get started!');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }
}
