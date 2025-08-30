import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google SMTP Configuration
  static const String _smtpServer = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  
  // You'll need to set these in your environment or Firebase config
  static const String _senderEmail = 'YOUR_GMAIL@gmail.com';
  static const String _senderPassword = 'YOUR_APP_PASSWORD'; // Use App Password, not regular password

  /// Send login notification email
  static Future<void> sendLoginNotification({
    required String userEmail,
    required String userName,
    String? deviceInfo,
    String? location,
  }) async {
    try {
      await _sendEmail(
        emailType: 'login_notification',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'loginTime': DateTime.now().toIso8601String(),
          'deviceInfo': deviceInfo ?? 'Unknown device',
          'location': location ?? 'Unknown location',
        },
      );
      
      // Log the notification
      await _logNotification(
        type: 'login_notification',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'deviceInfo': deviceInfo,
          'location': location,
        },
      );
    } catch (e) {
      print('Error sending login notification: $e');
      // Don't throw - login notifications shouldn't block login
    }
  }

  /// Send animal post notification
  static Future<void> sendAnimalPostNotification({
    required String userEmail,
    required String userName,
    required String animalName,
    required String animalSpecies,
    required String animalId,
  }) async {
    try {
      await _sendEmail(
        emailType: 'animal_posted',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'animalId': animalId,
          'postedAt': DateTime.now().toIso8601String(),
        },
      );
      
      await _logNotification(
        type: 'animal_posted',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'animalId': animalId,
        },
      );
    } catch (e) {
      print('Error sending animal post notification: $e');
      // Don't throw - post notifications shouldn't block posting
    }
  }

  /// Send animal approval notification
  static Future<void> sendAnimalApprovalNotification({
    required String userEmail,
    required String userName,
    required String animalName,
    required String animalSpecies,
    required String animalId,
    String? adminMessage,
  }) async {
    try {
      await _sendEmail(
        emailType: 'animal_approved',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'animalId': animalId,
          'adminMessage': adminMessage ?? '',
          'approvedAt': DateTime.now().toIso8601String(),
        },
      );
      
      await _logNotification(
        type: 'animal_approved',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'animalId': animalId,
          'adminMessage': adminMessage,
        },
      );
    } catch (e) {
      print('Error sending animal approval notification: $e');
    }
  }

  /// Send animal rejection notification
  static Future<void> sendAnimalRejectionNotification({
    required String userEmail,
    required String userName,
    required String animalName,
    required String animalSpecies,
    required String animalId,
    required String adminMessage,
  }) async {
    try {
      await _sendEmail(
        emailType: 'animal_rejected',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'animalId': animalId,
          'adminMessage': adminMessage,
          'rejectedAt': DateTime.now().toIso8601String(),
        },
      );
      
      await _logNotification(
        type: 'animal_rejected',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'animalId': animalId,
          'adminMessage': adminMessage,
        },
      );
    } catch (e) {
      print('Error sending animal rejection notification: $e');
    }
  }

  /// Send adoption application notification
  static Future<void> sendAdoptionApplicationNotification({
    required String userEmail,
    required String userName,
    required String animalName,
    required String animalSpecies,
    required String applicationId,
  }) async {
    try {
      await _sendEmail(
        emailType: 'adoption_applied',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'applicationId': applicationId,
          'appliedAt': DateTime.now().toIso8601String(),
        },
      );
      
      await _logNotification(
        type: 'adoption_applied',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'applicationId': applicationId,
        },
      );
    } catch (e) {
      print('Error sending adoption application notification: $e');
    }
  }

  /// Send adoption application approval notification
  static Future<void> sendAdoptionApprovalNotification({
    required String userEmail,
    required String userName,
    required String animalName,
    required String animalSpecies,
    required String applicationId,
    String? adminMessage,
  }) async {
    try {
      await _sendEmail(
        emailType: 'adoption_approved',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'applicationId': applicationId,
          'adminMessage': adminMessage ?? '',
          'approvedAt': DateTime.now().toIso8601String(),
        },
      );
      
      await _logNotification(
        type: 'adoption_approved',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'applicationId': applicationId,
          'adminMessage': adminMessage,
        },
      );
    } catch (e) {
      print('Error sending adoption approval notification: $e');
    }
  }

  /// Send adoption application rejection notification
  static Future<void> sendAdoptionRejectionNotification({
    required String userEmail,
    required String userName,
    required String animalName,
    required String animalSpecies,
    required String applicationId,
    required String adminMessage,
  }) async {
    try {
      await _sendEmail(
        emailType: 'adoption_rejected',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'applicationId': applicationId,
          'adminMessage': adminMessage,
          'rejectedAt': DateTime.now().toIso8601String(),
        },
      );
      
      await _logNotification(
        type: 'adoption_rejected',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'animalName': animalName,
          'animalSpecies': animalSpecies,
          'applicationId': applicationId,
          'adminMessage': adminMessage,
        },
      );
    } catch (e) {
      print('Error sending adoption rejection notification: $e');
    }
  }

  /// Send welcome email for new users
  static Future<void> sendWelcomeEmail({
    required String userEmail,
    required String userName,
  }) async {
    try {
      await _sendEmail(
        emailType: 'welcome',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'welcomeDate': DateTime.now().toIso8601String(),
        },
      );
      
      await _logNotification(
        type: 'welcome',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
        },
      );
    } catch (e) {
      print('Error sending welcome email: $e');
    }
  }

  /// Send password reset confirmation
  static Future<void> sendPasswordResetConfirmation({
    required String userEmail,
    required String userName,
  }) async {
    try {
      await _sendEmail(
        emailType: 'password_reset',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
          'resetDate': DateTime.now().toIso8601String(),
        },
      );
      
      await _logNotification(
        type: 'password_reset',
        recipientEmail: userEmail,
        data: {
          'userName': userName,
        },
      );
    } catch (e) {
      print('Error sending password reset confirmation: $e');
    }
  }

  /// Generic method to send emails via Firebase Cloud Function
  static Future<void> _sendEmail({
    required String emailType,
    required String recipientEmail,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get the Cloud Function URL from your Firebase project
      const String cloudFunctionUrl = 'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/sendEmail';
      
      print('📧 Attempting to send email: $emailType to $recipientEmail');
      print('🌐 Calling Cloud Function: $cloudFunctionUrl');
      
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'emailType': emailType,
          'recipientEmail': recipientEmail,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent successfully! Response: ${response.body}');
      } else {
        print('❌ Email service error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error calling email cloud function: $e');
      // Don't rethrow - just log the error to prevent app crashes
    }
  }

  /// Log notification to Firestore for tracking
  static Future<void> _logNotification({
    required String type,
    required String recipientEmail,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('email_notifications').add({
        'type': type,
        'recipientEmail': recipientEmail,
        'data': data,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });
    } catch (e) {
      print('Error logging notification: $e');
      // Don't rethrow - logging shouldn't break the main flow
    }
  }

  /// Get notification history for a user
  static Stream<QuerySnapshot> getNotificationHistory(String userEmail) {
    return _firestore
        .collection('email_notifications')
        .where('recipientEmail', isEqualTo: userEmail)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Check if user has email notifications enabled
  static Future<bool> isEmailNotificationsEnabled(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      return userData?['emailNotificationsEnabled'] ?? true; // Default to true
    } catch (e) {
      print('Error checking email notification settings: $e');
      return true; // Default to true if error
    }
  }

  /// Update user's email notification preferences
  static Future<void> updateEmailNotificationSettings({
    required String userId,
    required bool enabled,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'emailNotificationsEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating email notification settings: $e');
      rethrow;
    }
  }
}
