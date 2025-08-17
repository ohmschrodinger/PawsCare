import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new user document in Firestore when a user signs up
  static Future<void> createUserDocument({
    required String uid,
    required String email,
    String? fullName,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      // Create the user document in the 'users' collection
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName ?? '',
        'phoneNumber': phoneNumber ?? '',
        'address': address ?? '',
        'role': 'user', // Default role for new users
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

  /// Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Update user profile data
  static Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Check if user document exists
  static Future<bool> userDocumentExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking if user document exists: $e');
      return false;
    }
  }

  /// Create user document if it doesn't exist (for existing users)
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
