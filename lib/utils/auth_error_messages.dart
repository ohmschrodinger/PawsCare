import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorMessages {
  static String fromFirebaseAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'user-not-found':
        return 'We couldn\'t find an account with that email.';
      case 'wrong-password':
        return 'Login credentials are incorrect, try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account is currently disabled.';
      case 'email-already-in-use':
        return 'There\'s already an account with this email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many tries. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please try again later.';
      case 'invalid-credential':
        return 'Login credentials are incorrect, try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not available right now.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static String general(Object error) {
    if (error is FirebaseAuthException) {
      return fromFirebaseAuthException(error);
    }
    return 'Something went wrong. Please try again.';
  }
}


