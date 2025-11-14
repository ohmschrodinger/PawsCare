import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';
import 'current_user_cache.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send email verification link
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException {
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
    } on FirebaseAuthException {
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
    } on FirebaseAuthException {
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

      // Initialize the user cache
      await CurrentUserCache().refreshDisplayName();

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('signInWithEmailAndPassword_generic');
    }
  }

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Create a single client and ensure we disconnect/sign out first so the chooser appears
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

      try {
        // Best effort: disconnect clears the current account selection on some platforms
        await googleSignIn.disconnect();
      } catch (_) {}
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Check if we got the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get authentication tokens from Google');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Ensure Firestore user document exists/created for Google sign-in
      final user = userCredential.user;
      if (user != null) {
        final String email = user.email ?? googleUser.email;
        final String? fullName = user.displayName;
        try {
          await UserService.ensureUserDocumentExists(
            uid: user.uid,
            email: email,
            fullName: fullName,
          );
        } catch (_) {
          // Soft-fail to avoid blocking sign-in
        }

        // Initialize the user cache
        await CurrentUserCache().refreshDisplayName();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Google Sign-In Error: $e');
      throw Exception('signInWithGoogle_generic: $e');
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign out
  static Future<void> signOut() async {
    // Clear the user cache on sign out
    CurrentUserCache().clearCache();
    await _auth.signOut();
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Clear the user cache before deleting
      CurrentUserCache().clearCache();

      // Delete the user account from Firebase Auth
      await user.delete();

      // Explicitly sign out to ensure auth state is cleared
      await _auth.signOut();
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('deleteAccount_generic: $e');
    }
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Get authentication state changes stream
  static Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // ==================== PHONE AUTHENTICATION ====================

  /// Verify phone number and send SMS code
  /// Returns verification ID to be used with verifyPhoneCode
  static Future<String> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    String verificationIdResult = '';

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),

      // Called when SMS code is automatically verified (Android only)
      verificationCompleted: (PhoneAuthCredential credential) async {
        print('Phone verification completed automatically');
        if (onAutoVerified != null) {
          onAutoVerified(credential);
        }
      },

      // Called when verification fails
      verificationFailed: (FirebaseAuthException e) {
        print('Phone verification failed: ${e.code} - ${e.message}');
        if (e.code == 'invalid-phone-number') {
          onError('The phone number entered is invalid.');
        } else if (e.code == 'too-many-requests') {
          onError('Too many requests. Please try again later.');
        } else if (e.code == 'quota-exceeded') {
          onError('SMS quota exceeded. Please try again later.');
        } else {
          onError('Phone verification failed: ${e.message ?? e.code}');
        }
      },

      // Called when SMS code is sent
      codeSent: (String verificationId, int? resendToken) {
        print('SMS code sent. Verification ID: $verificationId');
        verificationIdResult = verificationId;
        onCodeSent(verificationId);
      },

      // Called when SMS code auto-retrieval times out
      codeAutoRetrievalTimeout: (String verificationId) {
        print('Code auto-retrieval timeout. Verification ID: $verificationId');
        verificationIdResult = verificationId;
      },
    );

    return verificationIdResult;
  }

  /// Verify the SMS code entered by user
  static Future<PhoneAuthCredential> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return credential;
    } catch (e) {
      print('Error creating phone credential: $e');
      throw Exception('Invalid verification code');
    }
  }

  /// Sign in with phone credential
  static Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);

      // Initialize the user cache
      await CurrentUserCache().refreshDisplayName();

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('signInWithPhoneCredential_generic: $e');
    }
  }

  /// Link phone number to existing account (for users who signed up with email)
  static Future<UserCredential> linkPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final userCredential = await user.linkWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        throw Exception(
          'This phone number is already linked to another account',
        );
      } else if (e.code == 'provider-already-linked') {
        throw Exception('Phone number is already linked to this account');
      }
      rethrow;
    } catch (e) {
      throw Exception('linkPhoneCredential_generic: $e');
    }
  }

  /// Update phone number for existing user
  static Future<void> updatePhoneNumber(PhoneAuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      await user.updatePhoneNumber(credential);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('updatePhoneNumber_generic: $e');
    }
  }

  /// Unlink phone number from account
  static Future<User?> unlinkPhoneNumber() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final updatedUser = await user.unlink('phone');
      return updatedUser;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('unlinkPhoneNumber_generic: $e');
    }
  }
}
