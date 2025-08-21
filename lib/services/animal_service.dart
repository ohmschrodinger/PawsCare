import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnimalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Post a new animal for adoption
  static Future<void> postAnimal({
    required String name,
    required String species,
    required String age,
    required String gender,
    required String sterilization,
    required String vaccination,
    required String rescueStory,
    required String motherStatus,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to post an animal');
      }

      // Check user role
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userRole = userDoc.data()?['role'] ?? 'user';

      // Determine approval status based on role
      final approvalStatus = userRole == 'admin' ? 'approved' : 'pending';
      final isActive =
          userRole == 'admin'; // Only admin posts are active immediately

      final animalData = {
        'name': name,
        'species': species,
        'age': age,
        'status': 'Available for Adoption',
        'image':
            'https://via.placeholder.com/150/FF5733/FFFFFF?text=$species', // Placeholder image
        'gender': gender,
        'sterilization': sterilization,
        'vaccination': vaccination,
        'rescueStory': rescueStory,
        'motherStatus': motherStatus,
        'postedBy': user.uid,
        'postedByEmail': user.email,
        'postedAt': FieldValue.serverTimestamp(),
        'isActive': isActive,
        'approvalStatus': approvalStatus,
        'approvedAt': userRole == 'admin' ? FieldValue.serverTimestamp() : null,
        'approvedBy': userRole == 'admin' ? user.uid : null,
        'adminMessage': '',
      };

      final docRef = await _firestore.collection('animals').add(animalData);
      print('Animal posted successfully: $name with ID: ${docRef.id}');
      print('Animal data: $animalData');
      print('Approval status: $approvalStatus');
    } catch (e) {
      print('Error posting animal: $e');
      throw Exception('Failed to post animal: $e');
    }
  }

  /// Get all active animals for adoption (only approved ones) - WITH FALLBACK
  static Stream<QuerySnapshot> getActiveAnimals() {
    print('DEBUG: Starting getActiveAnimals query');
    try {
      return _firestore
          .collection('animals')
          .where('approvalStatus', isEqualTo: 'approved')
          .orderBy('postedAt', descending: true)
          .snapshots();
    } catch (e) {
      print('Index error, falling back to simple query: $e');
      return _firestore
          .collection('animals')
          .where('approvalStatus', isEqualTo: 'approved')
          .snapshots();
    }
  }

  /// Fallback method for active animals without ordering
  static Stream<QuerySnapshot> getActiveAnimalsSimple() {
    print('DEBUG: Using simple getActiveAnimals query (no ordering)');
    return _firestore
        .collection('animals')
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots();
  }

  /// Get all animals for admin users (including pending ones)
  static Stream<QuerySnapshot> getAllAnimalsForAdmin() {
    print('DEBUG: Starting getAllAnimalsForAdmin query');
    return _firestore
        .collection('animals')
        .orderBy('postedAt', descending: true)
        .snapshots();
  }

  /// Get all animals without filters (for debugging)
  static Stream<QuerySnapshot> getAllAnimals() {
    print('DEBUG: Starting getAllAnimals query');
    return _firestore.collection('animals').snapshots();
  }

  /// Get animal by ID
  static Future<Map<String, dynamic>?> getAnimalById(String animalId) async {
    try {
      final doc = await _firestore.collection('animals').doc(animalId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting animal by ID: $e');
      return null;
    }
  }

  /// Update animal status (e.g., mark as adopted)
  static Future<void> updateAnimalStatus({
    required String animalId,
    required String status,
  }) async {
    try {
      await _firestore.collection('animals').doc(animalId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Animal status updated successfully: $animalId -> $status');
    } catch (e) {
      print('Error updating animal status: $e');
      throw Exception('Failed to update animal status: $e');
    }
  }

  /// Deactivate animal (remove from adoption list)
  static Future<void> deactivateAnimal(String animalId) async {
    try {
      await _firestore.collection('animals').doc(animalId).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
      print('Animal deactivated successfully: $animalId');
    } catch (e) {
      print('Error deactivating animal: $e');
      throw Exception('Failed to deactivate animal: $e');
    }
  }

  /// Search animals by species
  static Stream<QuerySnapshot> searchAnimalsBySpecies(String species) {
    return _firestore
        .collection('animals')
        .where('species', isEqualTo: species)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  /// Test method to check if we can read from animals collection
  static Future<void> testAnimalsCollection() async {
    try {
      print('Testing animals collection...');
      final snapshot = await _firestore.collection('animals').get();
      print('Total animals in collection: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        print('Animal ID: ${doc.id}, Data: ${doc.data()}');
      }
    } catch (e) {
      print('Error testing animals collection: $e');
    }
  }

  /// Get pending animals for admin approval - FIXED VERSION
  static Stream<QuerySnapshot> getPendingAnimals() {
    try {
      print('DEBUG: Starting getPendingAnimals query');

      // Simple query first - if this works, your index should be created
      return _firestore
          .collection('animals')
          .where('approvalStatus', isEqualTo: 'pending')
          .snapshots();

      // If you want ordering (requires the index), uncomment below after creating index:
      /*
      return _firestore
          .collection('animals')
          .where('approvalStatus', isEqualTo: 'pending')
          .orderBy('postedAt', descending: true)
          .snapshots();
      */
    } catch (e) {
      print('Error in getPendingAnimals: $e');
      // Fallback to simpler query
      return _firestore
          .collection('animals')
          .where('approvalStatus', isEqualTo: 'pending')
          .snapshots();
    }
  }

  /// Alternative method with better error handling
  static Stream<QuerySnapshot> getPendingAnimalsWithFallback() {
    return _firestore
        .collection('animals')
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots()
        .handleError((error) {
          print('Error in getPendingAnimalsWithFallback: $error');
          // You could return an empty stream or retry
          return const Stream.empty();
        });
  }

  /// Approve an animal
  static Future<void> approveAnimal({
    required String animalId,
    String? adminMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to approve animals');
      }
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userRole = userDoc.data()?['role'] ?? 'user';
      if (userRole != 'admin') {
        throw Exception('Only admins can approve animals');
      }

      await _firestore.collection('animals').doc(animalId).update({
        'approvalStatus': 'approved',
        'isActive': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': user.uid,
        'adminMessage': adminMessage ?? '',
      });
      print('Animal approved successfully: $animalId');
    } catch (e) {
      print('Error approving animal: $e');
      throw Exception('Failed to approve animal: $e');
    }
  }

  /// Reject an animal
  static Future<void> rejectAnimal({
    required String animalId,
    required String adminMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to reject animals');
      }
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userRole = userDoc.data()?['role'] ?? 'user';
      if (userRole != 'admin') {
        throw Exception('Only admins can reject animals');
      }

      await _firestore.collection('animals').doc(animalId).update({
        'approvalStatus': 'rejected',
        'isActive': false,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': user.uid,
        'adminMessage': adminMessage,
      });
      print('Animal rejected successfully: $animalId');
    } catch (e) {
      print('Error rejecting animal: $e');
      throw Exception('Failed to reject animal: $e');
    }
  }

  /// Get animals posted by a specific user (including approval status)
  static Stream<QuerySnapshot> getAnimalsByUser(String userId) {
    return _firestore
        .collection('animals')
        .where('postedBy', isEqualTo: userId)
        .orderBy('postedAt', descending: true)
        .snapshots();
  }

  /// Get pending animals count (for admin dashboard)
  static Stream<int> getPendingAnimalsCount() {
    return _firestore
        .collection('animals')
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Batch approve multiple animals (admin feature)
  static Future<void> batchApproveAnimals(List<String> animalIds) async {
    try {
      final batch = _firestore.batch();
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('User must be logged in');
      }

      for (String animalId in animalIds) {
        final docRef = _firestore.collection('animals').doc(animalId);
        batch.update(docRef, {
          'approvalStatus': 'approved',
          'isActive': true,
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': user.uid,
        });
      }

      await batch.commit();
      print('Batch approved ${animalIds.length} animals');
    } catch (e) {
      print('Error batch approving animals: $e');
      throw Exception('Failed to batch approve animals: $e');
    }
  }
}
