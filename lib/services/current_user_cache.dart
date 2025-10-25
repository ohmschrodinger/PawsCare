import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Singleton service to cache the current user's display name in memory
/// This prevents stale data issues when creating posts
class CurrentUserCache {
  static final CurrentUserCache _instance = CurrentUserCache._internal();
  factory CurrentUserCache() => _instance;
  CurrentUserCache._internal();

  String? _cachedDisplayName;
  String? _cachedUserId;

  /// Get the cached display name synchronously (may be null if not cached)
  String? get cachedName => _cachedDisplayName;

  /// Get the cached display name, or fetch it if not available
  Future<String> getDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';

    // If cached and user hasn't changed, return cached value
    if (_cachedDisplayName != null && _cachedUserId == user.uid) {
      return _cachedDisplayName!;
    }

    // Otherwise, fetch fresh data
    return await refreshDisplayName();
  }

  /// Force refresh the display name from Firestore
  Future<String> refreshDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _cachedDisplayName = 'User';
      _cachedUserId = null;
      return 'User';
    }

    _cachedUserId = user.uid;

    // First check Firebase Auth displayName
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      _cachedDisplayName = user.displayName!.trim();
      return _cachedDisplayName!;
    }

    // Fetch from Firestore with source set to SERVER to avoid cache
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      
      final data = doc.data();
      final candidate = data == null
          ? null
          : (data['fullName'] ?? data['name'] ?? data['displayName']);
      
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        _cachedDisplayName = candidate.toString().trim();
        return _cachedDisplayName!;
      }
    } catch (e) {
      print('Error fetching user display name: $e');
    }

    // Fallback
    _cachedDisplayName = 'User ${user.uid.substring(user.uid.length - 4)}';
    return _cachedDisplayName!;
  }

  /// Clear the cache (e.g., on logout)
  void clearCache() {
    _cachedDisplayName = null;
    _cachedUserId = null;
  }

  /// Update the cached name manually (e.g., after profile update)
  void updateCachedName(String newName) {
    if (newName.trim().isNotEmpty) {
      _cachedDisplayName = newName.trim();
    }
  }
}
