import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'current_user_cache.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new user document in Firestore when a user signs up.
  static Future<void> createUserDocument({
    required String uid,
    required String email,
    String? fullName,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName ?? '',
        'phoneNumber': phoneNumber ?? '',
        'address': address ?? '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileCompleted': false,
      });
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
      // This is the operation that caused the original type error.
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      // The .update() method correctly handles the Map<String, dynamic> type.
      await _firestore.collection('users').doc(uid).update(updateData);
      
      // Update the cache if fullName was changed and it's the current user
      if (data.containsKey('fullName') && _auth.currentUser?.uid == uid) {
        final newName = data['fullName']?.toString().trim();
        if (newName != null && newName.isNotEmpty) {
          CurrentUserCache().updateCachedName(newName);
        }
      }
    } catch (e) {
      print('Error updating user profile: $e');
      // The original error message you saw was thrown from here.
      // This exception will now be avoided.
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
        await createUserDocument(
          uid: uid,
          email: email,
          fullName: fullName,
        );
        print('Created missing user document for existing user: $uid');
      }
    } catch (e) {
      print('Error ensuring user document exists: $e');
    }
  }
}
