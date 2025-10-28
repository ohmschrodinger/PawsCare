import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../constants/verification_constants.dart';

/// Navigation Guard Service
/// Determines where users should be redirected based on their authentication
/// and verification status
class NavigationGuard {
  /// Check user's verification status and return appropriate route
  /// Returns null if user can access the requested route
  /// Returns a route name if user should be redirected
  static Future<String?> checkAccessAndGetRedirect({
    required String requestedRoute,
  }) async {
    final user = AuthService.getCurrentUser();

    // If no user, redirect to entry point (unless already going there)
    if (user == null) {
      if (requestedRoute == '/entry-point' ||
          requestedRoute == '/get-started' ||
          requestedRoute == '/signin') {
        return null; // Allow access to auth screens
      }
      return '/entry-point';
    }

    // User is authenticated, reload to get latest verification status
    await AuthService.reloadUser();

    // Get fresh user reference after reload
    final freshUser = AuthService.getCurrentUser();
    if (freshUser == null) {
      await AuthService.signOut();
      return '/entry-point';
    }

    final userData = await UserService.getUserModel(freshUser.uid);

    if (userData == null) {
      // User document doesn't exist, sign out and redirect to entry point
      await AuthService.signOut();
      return '/entry-point';
    }

    // Sync Firebase Auth email verification status with Firestore
    if (freshUser.emailVerified && !userData.isEmailVerified) {
      await UserService.updateEmailVerificationStatus(
        uid: freshUser.uid,
        isVerified: true,
      );
      // Refresh userData after update
      final updatedUserData = await UserService.getUserModel(freshUser.uid);
      if (updatedUserData != null) {
        // Continue with updated data
        return _checkUserDataAccess(updatedUserData, requestedRoute);
      }
    }

    return _checkUserDataAccess(userData, requestedRoute);
  }

  /// Helper method to check user data access
  static String? _checkUserDataAccess(dynamic userData, String requestedRoute) {
    // Check if user can access the app
    if (!userData.canAccessApp) {
      // User needs verification
      if (!userData.isEmailVerified) {
        if (requestedRoute == '/email-verification') {
          return null; // Allow access to email verification screen
        }
        return '/email-verification';
      }

      if (!userData.isPhoneVerified &&
          userData.signInMethod != VerificationConstants.signInMethodGoogle) {
        // Phone verification required (implement when needed)
        // For now, we'll allow access since phone verification is done during signup
        return null;
      }

      if (!userData.isActive) {
        AuthService.signOut();
        return '/entry-point';
      }
    }

    // User is fully verified, check if trying to access auth screens
    if (requestedRoute == '/entry-point' ||
        requestedRoute == '/get-started' ||
        requestedRoute == '/signin' ||
        requestedRoute == '/email-verification') {
      // Redirect verified users away from auth screens to main
      return '/main';
    }

    // Allow access to requested route
    return null;
  }

  /// Check if user can access the main app
  static Future<bool> canAccessMain() async {
    final user = AuthService.getCurrentUser();
    if (user == null) return false;

    final userData = await UserService.getUserModel(user.uid);
    if (userData == null) return false;

    return userData.canAccessApp;
  }

  /// Check if user needs email verification
  static Future<bool> needsEmailVerification() async {
    final user = AuthService.getCurrentUser();
    if (user == null) return false;

    final userData = await UserService.getUserModel(user.uid);
    if (userData == null) return false;

    return !userData.isEmailVerified;
  }

  /// Check if user needs phone verification
  static Future<bool> needsPhoneVerification() async {
    final user = AuthService.getCurrentUser();
    if (user == null) return false;

    final userData = await UserService.getUserModel(user.uid);
    if (userData == null) return false;

    // Google users don't need phone verification
    if (userData.signInMethod == VerificationConstants.signInMethodGoogle) {
      return false;
    }

    return !userData.isPhoneVerified;
  }

  /// Get the appropriate initial route for a user
  static Future<String> getInitialRoute() async {
    final user = AuthService.getCurrentUser();

    if (user == null) {
      return '/entry-point';
    }

    // Reload user to get latest verification status from Firebase Auth
    await AuthService.reloadUser();

    // Get fresh user reference after reload
    final freshUser = AuthService.getCurrentUser();
    if (freshUser == null) {
      return '/entry-point';
    }

    final userData = await UserService.getUserModel(freshUser.uid);

    if (userData == null) {
      await AuthService.signOut();
      return '/entry-point';
    }

    // Sync Firebase Auth email verification status with Firestore
    if (freshUser.emailVerified && !userData.isEmailVerified) {
      await UserService.updateEmailVerificationStatus(
        uid: freshUser.uid,
        isVerified: true,
      );
      // Refresh userData after update
      final updatedUserData = await UserService.getUserModel(freshUser.uid);
      if (updatedUserData != null && updatedUserData.canAccessApp) {
        return '/main';
      }
    }

    // Check email verification status
    if (!userData.isEmailVerified && !freshUser.emailVerified) {
      return '/email-verification';
    }

    if (!userData.isPhoneVerified &&
        userData.signInMethod != VerificationConstants.signInMethodGoogle) {
      // If phone not verified but they're signed in, allow access
      // (phone verification happens during signup)
      return '/main';
    }

    if (!userData.isActive) {
      await AuthService.signOut();
      return '/entry-point';
    }

    return '/main';
  }

  /// Perform post-authentication checks and navigate accordingly
  /// Returns the route to navigate to, or null if no navigation needed
  static Future<String?> handlePostAuthentication(User user) async {
    await AuthService.reloadUser();

    // Get fresh user reference after reload
    final freshUser = AuthService.getCurrentUser();
    if (freshUser == null) {
      await AuthService.signOut();
      return '/entry-point';
    }

    final userData = await UserService.getUserModel(freshUser.uid);

    if (userData == null) {
      await AuthService.signOut();
      return '/entry-point';
    }

    // Sync Firebase Auth email verification status with Firestore
    if (freshUser.emailVerified && !userData.isEmailVerified) {
      await UserService.updateEmailVerificationStatus(
        uid: freshUser.uid,
        isVerified: true,
      );
      // Refresh userData after update
      final updatedUserData = await UserService.getUserModel(freshUser.uid);
      if (updatedUserData != null && updatedUserData.canAccessApp) {
        return '/main';
      }
    }

    // Check email verification status
    if (!userData.isEmailVerified && !freshUser.emailVerified) {
      return '/email-verification';
    }

    if (!userData.isPhoneVerified &&
        userData.signInMethod != VerificationConstants.signInMethodGoogle) {
      // Phone verification was done during signup
      // If somehow they're not verified, send them to main anyway
      // as we don't have a separate phone verification screen for sign-in
      return '/main';
    }

    if (!userData.isActive) {
      await AuthService.signOut();
      return '/entry-point';
    }

    return '/main';
  }

  /// Check if route requires authentication
  static bool requiresAuth(String route) {
    const publicRoutes = [
      '/entry-point',
      '/get-started',
      '/signin',
      '/password-reset',
    ];

    return !publicRoutes.contains(route);
  }

  /// Check if route is an auth screen
  static bool isAuthScreen(String route) {
    const authRoutes = [
      '/entry-point',
      '/get-started',
      '/signin',
      '/email-verification',
    ];

    return authRoutes.contains(route);
  }
}
