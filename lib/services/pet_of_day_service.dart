import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to interact with Pet of the Day feature
class PetOfTheDayService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the current Pet of the Day
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getPetOfTheDayStream() {
    return _firestore
        .collection('app_config')
        .doc('pet_of_the_day')
        .snapshots();
  }

  /// Get the current Pet of the Day (one-time fetch)
  static Future<Map<String, dynamic>?> getPetOfTheDay() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('pet_of_the_day')
          .get();

      if (!doc.exists) {
        return null;
      }

      return doc.data();
    } catch (e) {
      print('Error getting Pet of the Day: $e');
      return null;
    }
  }

  /// Check if Pet of the Day has been set
  static Future<bool> isPetOfTheDaySet() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('pet_of_the_day')
          .get();

      return doc.exists && (doc.data()?['hasPet'] ?? false);
    } catch (e) {
      print('Error checking Pet of the Day: $e');
      return false;
    }
  }

  /// Select a new Pet of the Day from available animals
  static Future<bool> selectNewPetOfTheDay() async {
    try {
      // Query for available pets
      final availablePetsSnapshot = await _firestore
          .collection('animals')
          .where('status', isEqualTo: 'Available for Adoption')
          .where('approvalStatus', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true)
          .get();

      if (availablePetsSnapshot.docs.isEmpty) {
        // No available pets, set placeholder
        await _firestore.collection('app_config').doc('pet_of_the_day').set({
          'selectedAt': FieldValue.serverTimestamp(),
          'hasPet': false,
          'message': 'No pets available at the moment. Check back soon!',
        });
        return false;
      }

      // Get random pet from available pets
      final availablePets = availablePetsSnapshot.docs;
      final randomIndex =
          (DateTime.now().millisecondsSinceEpoch % availablePets.length);
      final selectedPet = availablePets[randomIndex];
      final petData = selectedPet.data();

      // Determine the best image to use
      String petImage = '';
      if (petData['imageUrls'] != null &&
          petData['imageUrls'] is List &&
          (petData['imageUrls'] as List).isNotEmpty) {
        petImage = (petData['imageUrls'] as List)[0];
      }

      // Store the pet of the day with complete data
      await _firestore.collection('app_config').doc('pet_of_the_day').set({
        'petId': selectedPet.id,
        'petName': petData['name'] ?? 'Unknown',
        'petSpecies': petData['species'] ?? 'Pet',
        'petAge': petData['age'] ?? 'Unknown',
        'petGender': petData['gender'] ?? 'Unknown',
        'petBreed': petData['breed'] ?? 'Mixed',
        'petImage': petImage,
        'petDescription':
            petData['rescueStory'] ??
            'Meet ${petData['name'] ?? 'this adorable pet'}!',
        'petLocation': petData['location'] ?? 'Unknown',
        'selectedAt': FieldValue.serverTimestamp(),
        'hasPet': true,
        // Store full pet data for easy access in the app
        'fullPetData': {
          'id': selectedPet.id,
          'name': petData['name'] ?? '',
          'species': petData['species'] ?? '',
          'age': petData['age'] ?? '',
          'gender': petData['gender'] ?? '',
          'breed': petData['breed'] ?? '',
          'breedType': petData['breedType'] ?? '',
          'imageUrls': petData['imageUrls'] ?? [],
          'status': petData['status'] ?? '',
          'location': petData['location'] ?? '',
          'contactPhone': petData['contactPhone'] ?? '',
          'rescueStory': petData['rescueStory'] ?? '',
          'sterilization': petData['sterilization'] ?? '',
          'vaccination': petData['vaccination'] ?? '',
          'deworming': petData['deworming'] ?? '',
          'motherStatus': petData['motherStatus'] ?? '',
          'medicalIssues': petData['medicalIssues'] ?? '',
          'postedBy': petData['postedBy'] ?? '',
          'postedAt': petData['postedAt'],
        },
      });

      return true;
    } catch (e) {
      print('Error selecting new Pet of the Day: $e');
      return false;
    }
  }
}
