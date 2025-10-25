import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        final User? currentUser = AuthService.getCurrentUser();

        if (currentUser != null) {
          try {
            await currentUser.getIdToken(true);

            if (currentUser.emailVerified) {
              Navigator.of(context).pushReplacementNamed('/main');
            } else {
              await AuthService.signOut();
              Navigator.of(context).pushReplacementNamed('/welcome');
            }
          } catch (e) {
            await AuthService.signOut();
            Navigator.of(context).pushReplacementNamed('/login');
          }
        } else {
          Navigator.of(context).pushReplacementNamed('/welcome');
        }
      }
    } catch (e) {
      try {
        await AuthService.signOut();
      } catch (_) {}
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PawsCare Logo
            SvgPicture.asset(
              'assets/images/pawscarelogo.svg',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            // Animated App Name with Borel font
            _AnimatedWriteText(
              text: 'PawsCare',
              duration: const Duration(seconds: 2),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to animate text as if being written
class _AnimatedWriteText extends StatefulWidget {
  final String text;
  final Duration duration;
  const _AnimatedWriteText({
    required this.text,
    required this.duration,
    Key? key,
  }) : super(key: key);

  @override
  State<_AnimatedWriteText> createState() => _AnimatedWriteTextState();
}

class _AnimatedWriteTextState extends State<_AnimatedWriteText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _charCount = StepTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charCount,
      builder: (context, child) {
        String visibleText = widget.text.substring(0, _charCount.value);
        return Text(
          visibleText,
          style: const TextStyle(
            fontFamily: 'Borel',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        );
      },
    );
  }
}
