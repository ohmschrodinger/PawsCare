import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../services/navigation_guard.dart';
import '../services/data_cache_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 2 seconds total animation
    );

    // 2. Define Animations (Staggered)
    
    // Logo appears from 0.0s to 1.0s
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Text slides up and fades in from 0.5s to 1.0s
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Start Animation
    _controller.forward();

    // Start Logic
    _checkAuthState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAuthState() async {
    try {
      // Start preloading data in background
      final preloadFuture = DataCacheService().preloadData();
      
      // Ensure the animation has time to finish visually (at least 2.5 seconds total)
      final minWaitFuture = Future.delayed(const Duration(milliseconds: 2500));

      await Future.wait([minWaitFuture, preloadFuture]);

      if (mounted) {
        final initialRoute = await NavigationGuard.getInitialRoute();
        _navigateToNext(initialRoute);
      }
    } catch (e) {
      debugPrint('Error in splash screen: $e');
      try {
        await AuthService.signOut();
      } catch (_) {}
      if (mounted) {
        _navigateToNext('/entry-point');
      }
    }
  }

  // 3. Smooth Transition to Next Screen
  void _navigateToNext(String routeName) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          // You need to resolve the route name to a widget here. 
          // Assuming you have a route generator or named routes map.
          // For now, I will use Navigator.pushReplacementNamed with a custom transition
          // But PageRouteBuilder is best if you return the actual Widget class.
          
          // Since we are using named routes, we stick to named push 
          // but we can wrap it in a custom transition if your app structure allows.
          // For simplicity in this snippet, let's just push named:
          return const SizedBox(); // Placeholder
        },
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    
    // NOTE: Since you are using Named Routes, standard pushReplacementNamed 
    // uses the default OS transition. To force a fade, you usually need to 
    // define the transition in your main.dart 'onGenerateRoute'.
    // 
    // However, simplest fix for now:
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: SvgPicture.asset(
                      'assets/images/pawscarelogo.svg',
                      width: 150,
                      height: 150,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Animated Text
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: const Text(
                      'PawsCare',
                      style: TextStyle(
                        fontFamily: 'Borel',
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}