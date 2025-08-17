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

      final animalData = {
        'name': name,
        'species': species,
        'age': age,
        'status': 'Available for Adoption',
        'image': 'https://via.placeholder.com/150/FF5733/FFFFFF?text=$species', // Placeholder image
        'gender': gender,
        'sterilization': sterilization,
        'vaccination': vaccination,
        'rescueStory': rescueStory,
        'motherStatus': motherStatus,
        'postedBy': user.uid,
        'postedByEmail': user.email,
        'postedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      final docRef = await _firestore.collection('animals').add(animalData);
      print('Animal posted successfully: $name with ID: ${docRef.id}');
      print('Animal data: $animalData');
    } catch (e) {
      print('Error posting animal: $e');
      throw Exception('Failed to post animal: $e');
    }
  }

  /// Get all active animals for adoption
  static Stream<QuerySnapshot> getActiveAnimals() {
    print('DEBUG: Starting getActiveAnimals query');
    return _firestore
        .collection('animals')
        .snapshots();
  }

  /// Get all animals without filters (for debugging)
  static Stream<QuerySnapshot> getAllAnimals() {
    print('DEBUG: Starting getAllAnimals query');
    return _firestore
        .collection('animals')
        .snapshots();
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

  /// Get animals posted by a specific user
  static Stream<QuerySnapshot> getAnimalsByUser(String userId) {
    return _firestore
        .collection('animals')
        .where('postedBy', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('postedAt', descending: true)
        .snapshots();
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
}
