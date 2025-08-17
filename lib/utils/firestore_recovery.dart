import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class FirestoreRecovery {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Recreate user documents for all existing Firebase Auth users
  /// This is useful when the users collection was accidentally deleted
  static Future<void> recreateUsersCollection() async {
    try {
      print('Starting users collection recovery...');
      
      // Get all users from Firebase Auth (this requires admin privileges)
      // For now, we'll create a document for the current user if they exist
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await UserService.ensureUserDocumentExists(
          uid: currentUser.uid,
          email: currentUser.email ?? '',
          fullName: currentUser.displayName,
        );
        print('Created/recovered user document for current user: ${currentUser.uid}');
      }

      // Note: To recover ALL users, you would need to use Firebase Admin SDK
      // This is a client-side solution that only handles the current user
      print('Users collection recovery completed for current user.');
      print('To recover ALL users, use Firebase Admin SDK or manually recreate from backup.');
      
    } catch (e) {
      print('Error during users collection recovery: $e');
      throw Exception('Failed to recover users collection: $e');
    }
  }

  /// Check the status of the users collection
  static Future<Map<String, dynamic>> checkUsersCollectionStatus() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'status': 'no_current_user',
          'message': 'No user is currently signed in',
        };
      }

      final userDocExists = await UserService.userDocumentExists(currentUser.uid);
      final userData = await UserService.getUserData(currentUser.uid);

      return {
        'status': 'success',
        'currentUserUid': currentUser.uid,
        'currentUserEmail': currentUser.email,
        'userDocumentExists': userDocExists,
        'userData': userData,
        'message': userDocExists 
          ? 'User document exists and is accessible'
          : 'User document does not exist and needs to be created',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Error checking users collection: $e',
      };
    }
  }

  /// Manually create a user document (for testing purposes)
  static Future<void> createTestUserDocument({
    required String uid,
    required String email,
    String? fullName,
  }) async {
    try {
      await UserService.createUserDocument(
        uid: uid,
        email: email,
        fullName: fullName,
      );
      print('Test user document created successfully');
    } catch (e) {
      print('Error creating test user document: $e');
      throw Exception('Failed to create test user document: $e');
    }
  }
}
