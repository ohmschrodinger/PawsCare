import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationBadgeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if there are any applications with "Under Review" status for admins
  static Stream<bool> hasUnderReviewApplications() {
    return _firestore
        .collection('applications')
        .where('status', isEqualTo: 'Under Review')
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Check if there are any pending animal posts for admins
  static Stream<bool> hasPendingAnimals() {
    return _firestore
        .collection('animals')
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Check if the current user has any application status updates they haven't seen
  static Stream<bool> hasNewApplicationUpdates(String userId) {
    return _firestore
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return false;

          // Get the user's last seen timestamp
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          final lastSeen =
              userDoc.data()?['lastSeenApplications'] as Timestamp?;

          if (lastSeen == null) return snapshot.docs.isNotEmpty;

          // Check if any application was updated after last seen
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final updatedAt = data['updatedAt'] as Timestamp?;
            final appliedAt = data['appliedAt'] as Timestamp?;

            // If there's an updatedAt field and it's newer than lastSeen
            if (updatedAt != null &&
                updatedAt.toDate().isAfter(lastSeen.toDate())) {
              return true;
            }
            // Or if the application was just created and is newer than lastSeen
            if (appliedAt != null &&
                appliedAt.toDate().isAfter(lastSeen.toDate())) {
              return true;
            }
          }

          return false;
        });
  }

  /// Mark all applications as seen for the current user
  static Future<void> markApplicationsAsSeen(String userId) async {
    await _firestore.collection('users').doc(userId).set({
      'lastSeenApplications': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update the application's updatedAt timestamp when status changes
  static Future<void> updateApplicationTimestamp(String applicationId) async {
    await _firestore.collection('applications').doc(applicationId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
