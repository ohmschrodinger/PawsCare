import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'current_user_cache.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new user document in Firestore when a user signs up.
  static Future<void> createUserDocument({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? address,
    String signInMethod = 'email',
    bool isEmailVerified = false,
    bool isPhoneVerified = false,
  }) async {
    try {
      final userModel = UserModel(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        address: address,
        signInMethod: signInMethod,
        isEmailVerified: isEmailVerified,
        isPhoneVerified: isPhoneVerified,
        profileCompleted: false,
      );

      await _firestore.collection('users').doc(uid).set(userModel.toMap());
      print('User document created successfully for UID: $uid');
    } catch (e) {
      print('Error creating user document: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Get user data from Firestore.
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Get user model from Firestore
  static Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting user model: $e');
      return null;
    }
  }

  /// Check if phone number already exists in database
  static Future<bool> phoneNumberExists(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone number existence: $e');
      return false;
    }
  }

  /// Check if email already exists in database
  static Future<bool> emailExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  /// Update email verification status
  static Future<void> updateEmailVerificationStatus({
    required String uid,
    required bool isVerified,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isEmailVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Email verification status updated for UID: $uid');
    } catch (e) {
      print('Error updating email verification status: $e');
      throw Exception('Failed to update email verification status: $e');
    }
  }

  /// Update phone verification status
  static Future<void> updatePhoneVerificationStatus({
    required String uid,
    required bool isVerified,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isPhoneVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Phone verification status updated for UID: $uid');
    } catch (e) {
      print('Error updating phone verification status: $e');
      throw Exception('Failed to update phone verification status: $e');
    }
  }

  /// Update user profile data.
  /// This method is now corrected to handle dynamic data properly.
  static Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Create a mutable copy of the data map to avoid modifying the original.
      final Map<String, dynamic> updateData = Map<String, dynamic>.from(data);

      // Add the server timestamp for the 'updatedAt' field.
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      // The .update() method correctly handles the Map<String, dynamic> type.
      await _firestore.collection('users').doc(uid).update(updateData);

      // Update the cache if firstName or lastName was changed and it's the current user
      if (_auth.currentUser?.uid == uid) {
        String? newName;

        // Check if both firstName and lastName are in the update
        if (data.containsKey('firstName') && data.containsKey('lastName')) {
          final firstName = data['firstName']?.toString().trim() ?? '';
          final lastName = data['lastName']?.toString().trim() ?? '';
          newName = '$firstName $lastName'.trim();
        }
        // If only firstName, fetch lastName from Firestore
        else if (data.containsKey('firstName')) {
          final userData = await getUserData(uid);
          final firstName = data['firstName']?.toString().trim() ?? '';
          final lastName = userData?['lastName']?.toString().trim() ?? '';
          newName = '$firstName $lastName'.trim();
        }
        // If only lastName, fetch firstName from Firestore
        else if (data.containsKey('lastName')) {
          final userData = await getUserData(uid);
          final firstName = userData?['firstName']?.toString().trim() ?? '';
          final lastName = data['lastName']?.toString().trim() ?? '';
          newName = '$firstName $lastName'.trim();
        }

        if (newName != null && newName.isNotEmpty) {
          CurrentUserCache().updateCachedName(newName);
        }
      }
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Check if a user document exists in Firestore.
  static Future<bool> userDocumentExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking if user document exists: $e');
      return false;
    }
  }

  /// Ensure a user document exists, creating it if necessary.
  static Future<void> ensureUserDocumentExists({
    required String uid,
    required String email,
    String? fullName,
  }) async {
    try {
      final exists = await userDocumentExists(uid);
      if (!exists) {
        // Split fullName into firstName and lastName
        final nameParts = (fullName ?? '').trim().split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName = nameParts.length > 1
            ? nameParts.sublist(1).join(' ')
            : '';

        await createUserDocument(
          uid: uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          signInMethod:
              'google', // This method is typically called for Google sign-in
          isEmailVerified: true, // Google accounts come pre-verified
        );
        print('Created missing user document for existing user: $uid');
      }
    } catch (e) {
      print('Error ensuring user document exists: $e');
    }
  }
}
