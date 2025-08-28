import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send email verification link
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('sendEmailVerification_generic');
    }
  }

  /// Check if user's email is verified
  static bool isEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Reload user to get latest verification status
  static Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('sendPasswordResetEmail_generic');
    }
  }

  /// Create user with email verification requirement
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email immediately after account creation
      await sendEmailVerification();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('createUserWithEmailAndPassword_generic');
    }
  }

  /// Sign in with email and password (with verification check)
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Reload user to get latest verification status
      await userCredential.user?.reload();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('signInWithEmailAndPassword_generic');
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Get authentication state changes stream
  static Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}
