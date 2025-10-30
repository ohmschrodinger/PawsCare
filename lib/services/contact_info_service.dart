import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact_info_model.dart';

/// Service to fetch contact information from Firestore
class ContactInfoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'contact_info';
  static const String _documentId = 'info';

  /// Cache the contact info to avoid repeated fetches
  static ContactInfo? _cachedContactInfo;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Fetch contact information from Firestore
  /// Uses caching to reduce Firestore reads
  static Future<ContactInfo> getContactInfo() async {
    // Return cached data if available and not expired
    if (_cachedContactInfo != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge < _cacheDuration) {
        return _cachedContactInfo!;
      }
    }

    try {
      final docSnapshot = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Contact info document not found in Firestore');
      }

      final data = docSnapshot.data();
      if (data == null) {
        throw Exception('Contact info data is null');
      }

      _cachedContactInfo = ContactInfo.fromMap(data);
      _cacheTimestamp = DateTime.now();

      return _cachedContactInfo!;
    } catch (e) {
      // If fetching fails, return default values
      throw Exception('Failed to fetch contact info: $e');
    }
  }

  /// Clear the cache (useful when you know the data has been updated)
  static void clearCache() {
    _cachedContactInfo = null;
    _cacheTimestamp = null;
  }

  /// Create or update contact info document in Firestore
  /// This is typically done from an admin panel or Firebase Console
  static Future<void> setContactInfo(ContactInfo contactInfo) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set(contactInfo.toMap());

      // Clear cache after update
      clearCache();
    } catch (e) {
      throw Exception('Failed to set contact info: $e');
    }
  }

  /// Listen to contact info changes in real-time
  static Stream<ContactInfo> contactInfoStream() {
    return _firestore
        .collection(_collectionName)
        .doc(_documentId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            throw Exception('Contact info document not found');
          }
          return ContactInfo.fromMap(snapshot.data()!);
        });
  }
}
