import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GreetingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  static String getTimeBasedSubtext() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bet even the cats smiled thinking of you.';
    } else if (hour < 17) {
      return "How's it going?";
    } else {
      return "Stars are out, but you're still brighter.";
    }
  }

  static Future<String?> getUserFirstName() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final userData = doc.data();
      final firstName = userData?['firstName'] as String?;
      if (firstName == null || firstName.isEmpty) return null;

      return firstName;
    } catch (e) {
      print('Error getting user first name: $e');
      return null;
    }
  }

  static Stream<String> getGreetingStream() {
    return _auth.authStateChanges().asyncMap((user) async {
      final timeGreeting = getTimeBasedGreeting();
      if (user == null) return timeGreeting;

      final firstName = await getUserFirstName();
      return firstName != null ? '$timeGreeting, $firstName' : timeGreeting;
    });
  }
}
