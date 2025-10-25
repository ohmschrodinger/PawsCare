import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Test function to send a test notification to the current user
  static Future<void> sendTestNotification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in');
      }

      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'];

      if (fcmToken == null) {
        throw Exception('No FCM token found for user');
      }

      // This would typically be done via Cloud Functions
      // For testing purposes, we'll just log the details
      print('Test notification would be sent to:');
      print('User ID: ${user.uid}');
      print('FCM Token: $fcmToken');
      print('Title: Test Notification');
      print('Body: This is a test notification from PawsCare');

      // You can call your Cloud Function here to send the actual notification
      // await _callCloudFunction('sendTestNotification', {
      //   'userId': user.uid,
      //   'title': 'Test Notification',
      //   'body': 'This is a test notification from PawsCare',
      // });

    } catch (e) {
      print('Error sending test notification: $e');
      rethrow;
    }
  }

  /// Check if user has notification permissions and FCM token
  static Future<Map<String, dynamic>> checkNotificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'isLoggedIn': false,
          'hasFCMToken': false,
          'notificationsEnabled': false,
        };
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        return {
          'isLoggedIn': true,
          'hasFCMToken': false,
          'notificationsEnabled': false,
        };
      }

      final userData = userDoc.data();
      return {
        'isLoggedIn': true,
        'hasFCMToken': userData?['fcmToken'] != null,
        'notificationsEnabled': userData?['notificationsEnabled'] ?? false,
        'adoptionNotifications': userData?['adoptionNotifications'] ?? false,
        'newAnimalNotifications': userData?['newAnimalNotifications'] ?? false,
        'generalNotifications': userData?['generalNotifications'] ?? false,
        'fcmToken': userData?['fcmToken'],
      };
    } catch (e) {
      print('Error checking notification status: $e');
      return {
        'error': e.toString(),
      };
    }
  }
}
