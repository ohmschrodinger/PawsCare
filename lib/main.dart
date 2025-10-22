import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import your screen files
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart'; // Import the new sign-up screen
import 'screens/firestore_recovery_screen.dart';
import 'screens/admin_animal_approval_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/email_verification_screen.dart';
import 'main_navigation_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/notification_service.dart';

// main.dart
// This file initializes Firebase and handles the main app routing based on authentication state.

void main() async {
  // Ensure that Flutter is initialized before calling Firebase.initializeApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: "assets/.env");

  try {
    await Firebase.initializeApp();

    // Initialize notification service
    await NotificationService.initialize();
  } catch (e) {
    // If Firebase is already initialized, ignore the error
    if (e.toString().contains('duplicate-app')) {
      print('Firebase already initialized, continuing...');
    } else {
      print('Firebase initialization error: $e');
    }
  }

  runApp(const PawsCareApp());
}

class PawsCareApp extends StatelessWidget {
  const PawsCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5AC8F2);

    return MaterialApp(
      title: 'PawsCare Adoption',
      // Define a centralized theme for a consistent, modern UI
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor:
            Colors.grey[50], // Light background for all screens
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(), // Added signup route
        '/main': (context) => MainNavigationScreen(key: mainNavKey),
        '/recovery': (context) => const FirestoreRecoveryScreen(),
        '/admin-animal-approval': (context) =>
            const AdminAnimalApprovalScreen(),
        '/password-reset': (context) => const PasswordResetScreen(),
        '/email-verification': (context) => const EmailVerificationScreen(),
      },
    );
  }
}
