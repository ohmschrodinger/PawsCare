import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/animal_status.dart';
import 'logging_service.dart';
import '../models/animal_location.dart';

class AnimalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Post a new animal for adoption
  static Future<DocumentReference> postAnimal({
    required String name,
    required String species,
    required String age,
    required String gender,
    required String breedType,
    required String breed,
    required String sterilization,
    required String vaccination,
    required String deworming,
    required String motherStatus,
    String? medicalIssues,
    required String location,
    AnimalLocation? locationData,
    required String contactPhone,
    String? rescueStory,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to post an animal');
      }

      // Check user role
      print('DEBUG: Fetching user role for uid: ${user.uid}');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      // Check if user document exists
      if (!userDoc.exists) {
        print('DEBUG: User document does not exist!');
        throw Exception('User document not found');
      }

      final userData = userDoc.data();
      print('DEBUG: User data: ${userData.toString()}');

      // All posts start as pending and inactive, regardless of user role
      const approvalStatus = 'pending';
      const isActive = false;
      print('DEBUG: Setting approval status to: pending');

      // Prepare location data for Firestore
      Map<String, dynamic> locationMap = {};
      if (locationData != null && locationData.hasCoordinates) {
        locationMap = locationData.toMap();
      }

      final animalData = {
        'name': name,
        'species': species,
        'breedType': breedType,
        'breed': breed,
        'age': age,
        'status': 'Available for Adoption', // Changed to match the document
        'gender': gender,
        'sterilization': sterilization,
        'vaccination': vaccination,
        'deworming': deworming,
        'motherStatus': motherStatus,
        'medicalIssues': medicalIssues ?? '',
        'location': location,
        ...locationMap, // Spread location data (includes latitude, longitude, geopoint, etc.)
        'contactPhone': contactPhone,
        'rescueStory': rescueStory ?? '',
        'postedBy': user.uid,
        'postedByEmail': user.email,
        'postedAt': FieldValue.serverTimestamp(),
        'isActive': isActive,
        'approvalStatus': approvalStatus,
        'approvedAt': null, // Will be set when approved
        'approvedBy': null, // Will be set when approved
        'adminMessage': '',
        'imageUrls': [], // Will be updated after images are uploaded
      };

      print(
        'DEBUG: About to create animal with data: ${animalData.toString()}',
      );

      // Add the animal document and return its reference
      final docRef = await _firestore.collection('animals').add(animalData);
      // Log the event client-side
      await LoggingService.logEvent(
        'animal_posted',
        data: {
          'animalId': docRef.id,
          'name': name,
          'approvalStatus': approvalStatus,
        },
      );
      print('DEBUG: Created animal document with ID: ${docRef.id}');
      return docRef;
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

  /// Get available animals for adoption
  static Stream<QuerySnapshot> getAvailableAnimals() {
    print('DEBUG: Fetching available animals...');
    return _firestore
        .collection('animals')
        .where('approvalStatus', isEqualTo: 'approved')
        .where(
          'status',
          isEqualTo: AnimalStatus.available,
        ) // Use the constant that matches DB
        .where('isActive', isEqualTo: true)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('DEBUG: Found ${snapshot.docs.length} available animals');
          return snapshot;
        });
  }

  /// Get adopted animals
  static Stream<QuerySnapshot> getAdoptedAnimals() {
    print('DEBUG: Fetching adopted animals...');
    return _firestore
        .collection('animals')
        .where('approvalStatus', isEqualTo: 'approved')
        .where('status', isEqualTo: 'Adopted')
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('DEBUG: Found ${snapshot.docs.length} adopted animals');
          return snapshot;
        });
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
  /// Valid status values are:
  /// - "Available" (for animals available for adoption)
  /// - "Adopted" (for animals that have been adopted)
  /// - "Pending" (for animals with pending adoption applications)
  static Future<void> updateAnimalStatus({
    required String animalId,
    required String status,
  }) async {
    // Validate status
    final validStatuses = [
      AnimalStatus.available,
      AnimalStatus.adopted,
      AnimalStatus.pending,
    ];
    if (!validStatuses.contains(status)) {
      throw Exception(
        'Invalid status. Must be one of: ${validStatuses.join(", ")}',
      );
    }

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

  /// Delete animal post
  /// Only allows deletion if:
  /// 1. User is the owner of the post
  /// 2. Animal is still available for adoption (not adopted)
  static Future<void> deleteAnimalPost(String animalId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to delete an animal post');
      }

      // Get the animal document
      final animalDoc = await _firestore
          .collection('animals')
          .doc(animalId)
          .get();

      if (!animalDoc.exists) {
        throw Exception('Animal not found');
      }

      final animalData = animalDoc.data()!;

      // Check if user is the owner
      if (animalData['postedBy'] != user.uid) {
        throw Exception('You can only delete your own posts');
      }

      // Check if animal is already adopted
      final status = animalData['status'] as String?;
      if (status == AnimalStatus.adopted) {
        throw Exception('Cannot delete an adopted animal');
      }

      // Delete the document
      await _firestore.collection('animals').doc(animalId).delete();

      // Log the deletion
      await LoggingService.logEvent(
        'animal_deleted',
        data: {
          'animalId': animalId,
          'name': animalData['name'],
          'status': status,
        },
      );

      print('Animal deleted successfully: $animalId');
    } catch (e) {
      print('Error deleting animal: $e');
      rethrow;
    }
  }

  /// Check if an animal can be deleted
  /// Returns a map with 'canDelete' (bool) and 'reason' (String)
  static Future<Map<String, dynamic>> canDeleteAnimal(String animalId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'canDelete': false, 'reason': 'You must be logged in'};
      }

      final animalDoc = await _firestore
          .collection('animals')
          .doc(animalId)
          .get();

      if (!animalDoc.exists) {
        return {'canDelete': false, 'reason': 'Animal not found'};
      }

      final animalData = animalDoc.data()!;

      // Check if user is the owner
      if (animalData['postedBy'] != user.uid) {
        return {
          'canDelete': false,
          'reason': 'You can only delete your own posts',
        };
      }

      // Check if animal is already adopted
      final status = animalData['status'] as String?;
      if (status == AnimalStatus.adopted) {
        return {
          'canDelete': false,
          'reason':
              'This animal has already been adopted and cannot be withdrawn',
        };
      }

      return {'canDelete': true, 'reason': ''};
    } catch (e) {
      return {
        'canDelete': false,
        'reason': 'Error checking delete permission: $e',
      };
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

      if (snapshot.docs.isEmpty) {
        print('No animals found in the collection!');
        return;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('\nAnimal ID: ${doc.id}');
        print('Status: ${data['status']}');
        print('Approval Status: ${data['approvalStatus']}');
        print('Name: ${data['name']}');
        print('Posted By: ${data['postedByEmail']}');
        print('Posted At: ${data['postedAt']}');
        print('Full Data: $data');
      }
    } catch (e) {
      print('Error testing animals collection: $e');
    }
  }

  /// Get pending animals for admin approval - FIXED VERSION
  static Stream<QuerySnapshot> getPendingAnimals() {
    try {
      print('DEBUG: Starting getPendingAnimals query');

      // First, let's check what documents exist
      _firestore.collection('animals').get().then((snapshot) {
        print(
          'DEBUG: Total documents in animals collection: ${snapshot.docs.length}',
        );
        for (var doc in snapshot.docs) {
          final data = doc.data();
          print(
            'DEBUG: Document ${doc.id} - approvalStatus: ${data['approvalStatus']}, postedByEmail: ${data['postedByEmail']}',
          );
        }
      });

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
      await LoggingService.logEvent(
        'animal_approved',
        data: {'animalId': animalId, 'adminMessage': adminMessage ?? ''},
      );
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
      await LoggingService.logEvent(
        'animal_rejected',
        data: {'animalId': animalId, 'adminMessage': adminMessage},
      );
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
