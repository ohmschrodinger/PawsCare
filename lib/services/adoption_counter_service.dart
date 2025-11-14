import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing permanent adoption counter
/// This counter NEVER decreases, even if adopted animals are deleted
class AdoptionCounterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Document path for the counter
  static const String _countersCollection = 'app_statistics';
  static const String _counterDocId = 'adoption_counter';

  /// Initialize the counter document (run once during app setup)
  static Future<void> initializeCounter() async {
    try {
      final doc = await _firestore
          .collection(_countersCollection)
          .doc(_counterDocId)
          .get();

      if (!doc.exists) {
        // Counter doesn't exist, create it
        // Count existing adopted animals to set initial value
        final adoptedAnimals = await _firestore
            .collection('animals')
            .where('status', isEqualTo: 'Adopted')
            .get();

        await _firestore
            .collection(_countersCollection)
            .doc(_counterDocId)
            .set({
          'totalAdoptions': adoptedAnimals.docs.length,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'description': 'Permanent counter for total adoptions (never decreases)',
        });

        print('AdoptionCounter initialized with ${adoptedAnimals.docs.length} adoptions');
      } else {
        print('AdoptionCounter already exists: ${doc.data()}');
      }
    } catch (e) {
      print('Error initializing adoption counter: $e');
    }
  }

  /// Increment the adoption counter (call when an animal is adopted)
  static Future<void> incrementCounter() async {
    try {
      final docRef = _firestore
          .collection(_countersCollection)
          .doc(_counterDocId);

      // Use transaction to ensure atomic increment
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          // Counter doesn't exist, create it with 1
          transaction.set(docRef, {
            'totalAdoptions': 1,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'description': 'Permanent counter for total adoptions (never decreases)',
          });
        } else {
          // Increment the counter
          final currentCount = (doc.data()?['totalAdoptions'] ?? 0) as int;
          transaction.update(docRef, {
            'totalAdoptions': currentCount + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      print('Adoption counter incremented successfully');
    } catch (e) {
      print('Error incrementing adoption counter: $e');
      rethrow;
    }
  }

  /// Get the current total adoption count
  static Future<int> getTotalAdoptions() async {
    try {
      final doc = await _firestore
          .collection(_countersCollection)
          .doc(_counterDocId)
          .get();

      if (!doc.exists) {
        print('Counter document does not exist, initializing...');
        await initializeCounter();
        
        // Fetch again after initialization
        final newDoc = await _firestore
            .collection(_countersCollection)
            .doc(_counterDocId)
            .get();
        
        return (newDoc.data()?['totalAdoptions'] ?? 0) as int;
      }

      return (doc.data()?['totalAdoptions'] ?? 0) as int;
    } catch (e) {
      print('Error getting total adoptions: $e');
      return 0;
    }
  }

  /// Get stream of total adoptions for real-time updates
  static Stream<int> getTotalAdoptionsStream() {
    return _firestore
        .collection(_countersCollection)
        .doc(_counterDocId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            // Initialize if doesn't exist
            initializeCounter();
            return 0;
          }
          return (doc.data()?['totalAdoptions'] ?? 0) as int;
        });
  }

  /// Manual counter adjustment (admin only - for corrections)
  /// Use with caution!
  static Future<void> setCounterManually(int count) async {
    try {
      await _firestore
          .collection(_countersCollection)
          .doc(_counterDocId)
          .set({
        'totalAdoptions': count,
        'updatedAt': FieldValue.serverTimestamp(),
        'manuallyAdjusted': true,
        'description': 'Permanent counter for total adoptions (never decreases)',
      }, SetOptions(merge: true));

      print('Adoption counter manually set to $count');
    } catch (e) {
      print('Error setting counter manually: $e');
      rethrow;
    }
  }

  /// Get adoptions this month (still from animals collection)
  static Future<int> getAdoptionsThisMonth() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final snapshot = await _firestore
          .collection('animals')
          .where('status', isEqualTo: 'Adopted')
          .where('adoptedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting adoptions this month: $e');
      return 0;
    }
  }
}
