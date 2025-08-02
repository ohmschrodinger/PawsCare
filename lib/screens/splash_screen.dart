import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _navigateToAuth();
//   }

//   _navigateToAuth() async {
//     // Implement a delay to simulate loading
//     await Future.delayed(const Duration(seconds: 3), () {});

//     // Navigate to the Unified Login/Sign-up Screen
//     if (mounted) {
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (context) => const AuthScreen(), // AuthScreen will be built in Phase 2
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       backgroundColor: Colors.blueAccent, // Choose a background color that fits your brand
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // 1. Display your App Logo/Icon (centered).
//             // For a real app, you'd use Image.asset('assets/images/app_logo.png')
//             // For now, let's use a simple icon.
//             Icon(
//               Icons.pets,
//               size: 100,
//               color: Colors.white,
//             ),
//             SizedBox(height: 20),
//             // 2. Display your App Name (e.g., "PAWS CARE").
//             Text(
//               "PAWS CARE",
//               style: TextStyle(
//                 fontSize: 40,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             SizedBox(height: 10),
//             // 3. Add a Brief Tagline (e.g., "Connecting Pets to Forever Homes").
//             Text(
//               "Connecting Pets to Forever Homes",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontStyle: FontStyle.italic,
//                 color: Colors.white70,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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
    // For now, just navigate to login screen
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // A simple loading screen while we check the auth state.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
