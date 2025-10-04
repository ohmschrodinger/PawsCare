import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            // Animated pet icon
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blueAccent.shade200, Colors.blueAccent.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: const Icon(
                Icons.pets,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // App Name
            const Text(
              "PAWS CARE",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            const Text(
              "Connecting Pets to Forever Homes",
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            // Progress Indicator
            SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent.shade200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
