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
}
