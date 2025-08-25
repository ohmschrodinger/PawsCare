import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this import

// Removed firebase_options.dart to use platform-native configs (google-services.json / plist)

// Import your screen files
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/firestore_recovery_screen.dart';
import 'screens/admin_animal_approval_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/email_verification_screen.dart';
import 'main_navigation_screen.dart';

// main.dart
// This file initializes Firebase and handles the main app routing based on authentication state.

void main() async {
  // Ensure that Flutter is initialized before calling Firebase.initializeApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  // await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp();
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
  const PawsCareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawsCare Adoption',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5AC8F2),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainNavigationScreen(),
        '/recovery': (context) => const FirestoreRecoveryScreen(),
        '/admin-animal-approval': (context) =>
            const AdminAnimalApprovalScreen(),
        '/password-reset': (context) => const PasswordResetScreen(),
        '/email-verification': (context) => const EmailVerificationScreen(),
      },
    );
  }
}
