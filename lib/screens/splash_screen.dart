import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// screens/splash_screen.dart
// This screen handles the initial routing logic. It checks if a user is
// already logged in and redirects them accordingly.

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

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
      // Show splash for 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Check if user is already signed in
        final User? currentUser = AuthService.getCurrentUser();

        print('Current user: ${currentUser?.uid ?? 'null'}'); // Debug log

        // Force logout if there are any issues with the current user
        if (currentUser != null) {
          try {
            // Verify the user token is still valid
            await currentUser.getIdToken(true);
            
            // Check if email is verified
            if (currentUser.emailVerified) {
              // If successful and verified, navigate to main
              Navigator.of(context).pushReplacementNamed('/main');
            } else {
              // For unverified sessions, sign out and send to welcome for a clean start
              await AuthService.signOut();
              Navigator.of(context).pushReplacementNamed('/welcome');
            }
          } catch (e) {
            print('Token verification failed, logging out: $e');
            // If token verification fails, logout and go to login
            await AuthService.signOut();
            Navigator.of(context).pushReplacementNamed('/login');
          }
        } else {
          // User is not signed in, navigate to welcome screen
          Navigator.of(context).pushReplacementNamed('/welcome');
        }
      }
    } catch (e) {
      print('Error in _checkAuthState: $e'); // Debug log
      // If there's an error, force logout and go to login screen
      try {
        await AuthService.signOut();
      } catch (signOutError) {
        print('Error signing out: $signOutError');
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF5AC8F2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "PAWS CARE",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Connecting Pets to Forever Homes",
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
