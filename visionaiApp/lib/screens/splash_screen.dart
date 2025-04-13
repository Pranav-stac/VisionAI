import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:visionai/widgets/base_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Use a slightly longer delay to ensure animations complete
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Navigate directly to home screen, skipping onboarding and login
        GoRouter.of(context).go('/home');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      builder: (context, localizedStrings) {
        return Container(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF121212),
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // You can add Lottie animation or your app logo here
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Lottie.network(
                            'https://assets1.lottiefiles.com/packages/lf20_rhnmhzwj.json',
                            repeat: true,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          localizedStrings['appTitle'] ?? 'Vision AI',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizedStrings['welcome'] ?? 'Welcome',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.light
                                ? Colors.black.withOpacity(0.6)
                                : Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
} 