import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserFavoritesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Toggle like status for an animal
  static Future<bool> toggleLike(String animalId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User must be logged in');

      // References
      final userLikesRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('likes')
          .doc(animalId);
      final animalRef = _firestore.collection('animals').doc(animalId);

      // Check current like status
      final likeDoc = await userLikesRef.get();
      final isCurrentlyLiked = likeDoc.exists;

      // First, make sure the animal document has the required fields
      final animalDoc = await animalRef.get();
      if (!animalDoc.exists) {
        throw Exception('Animal document not found');
      }

      final animalData = animalDoc.data() as Map<String, dynamic>;
      if (!animalData.containsKey('likeCount')) {
        await animalRef.set({
          'likeCount': 0,
          'likedBy': [],
        }, SetOptions(merge: true));
      }

      // Use a transaction to update both documents atomically
      await _firestore.runTransaction((transaction) async {
        if (isCurrentlyLiked) {
          // Unlike: Remove from user's likes and decrement animal's like count
          transaction.delete(userLikesRef);
          transaction.set(animalRef, {
            'likeCount': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([user.uid]),
          }, SetOptions(merge: true));
        } else {
          // Like: Add to user's likes and increment animal's like count
          transaction.set(userLikesRef, {
            'timestamp': FieldValue.serverTimestamp(),
          });
          transaction.set(animalRef, {
            'likeCount': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([user.uid]),
          }, SetOptions(merge: true));
        }
      });

      return !isCurrentlyLiked; // Return new like status
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  /// Toggle save/bookmark status for an animal
  static Future<bool> toggleSave(String animalId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User must be logged in');

      // References
      final userSavesRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saves')
          .doc(animalId);
      final animalRef = _firestore.collection('animals').doc(animalId);

      // Check current save status
      final saveDoc = await userSavesRef.get();
      final isCurrentlySaved = saveDoc.exists;

      // First, make sure the animal document has the required fields
      final animalDoc = await animalRef.get();
      if (!animalDoc.exists) {
        throw Exception('Animal document not found');
      }

      final animalData = animalDoc.data() as Map<String, dynamic>;
      if (!animalData.containsKey('savedBy')) {
        await animalRef.set({'savedBy': []}, SetOptions(merge: true));
      }

      // Use a transaction to update both documents atomically
      await _firestore.runTransaction((transaction) async {
        if (isCurrentlySaved) {
          // Unsave: Remove from user's saves
          transaction.delete(userSavesRef);
          transaction.set(animalRef, {
            'savedBy': FieldValue.arrayRemove([user.uid]),
          }, SetOptions(merge: true));
        } else {
          // Save: Add to user's saves
          transaction.set(userSavesRef, {
            'timestamp': FieldValue.serverTimestamp(),
          });
          transaction.set(animalRef, {
            'savedBy': FieldValue.arrayUnion([user.uid]),
          }, SetOptions(merge: true));
        }
      });

      return !isCurrentlySaved; // Return new save status
    } catch (e) {
      print('Error toggling save: $e');
      rethrow;
    }
  }

  /// Check if user has liked an animal
  static Future<bool> isLiked(String animalId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('likes')
          .doc(animalId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  /// Check if user has saved an animal
  static Future<bool> isSaved(String animalId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saves')
          .doc(animalId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking save status: $e');
      return false;
    }
  }

  /// Get user's liked animals
  static Stream<QuerySnapshot> getLikedAnimals() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('likes')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get user's saved animals
  static Stream<QuerySnapshot> getSavedAnimals() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saves')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get liked animal details (for profile page)
  static Stream<QuerySnapshot> getLikedAnimalDetails() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('animals')
        .where('likedBy', arrayContains: user.uid)
        .snapshots();
  }

  /// Get saved animal details (for profile page)
  static Stream<QuerySnapshot> getSavedAnimalDetails() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('animals')
        .where('savedBy', arrayContains: user.uid)
        .snapshots();
  }
}
