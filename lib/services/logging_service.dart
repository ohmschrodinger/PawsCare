import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple client-side logging service that writes events to a Firestore
/// `logs` collection. Each log contains an eventType, optional payload
/// and the current user (if available).
class LoggingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Log an event to Firestore. Keeps a small, consistent shape so you can
  /// query and filter logs easily.
  static Future<void> logEvent(
    String eventType, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final user = _auth.currentUser;
      final log = {
        'eventType': eventType,
        'userId': user?.uid,
        'userEmail': user?.email,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('logs').add(log);
    } catch (e) {
      // Don't throw from logging; just print so client continues to work.
      print('LoggingService: failed to write log: $e');
    }
  }
}
