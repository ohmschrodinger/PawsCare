import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class StatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static StreamController<Map<String, int>>? _statsController;
  static Timer? _timer;
  static Map<String, int>? _cachedStats;

  /// Get adoption statistics - optimized version
  static Future<Map<String, int>> getAdoptionStats() async {
    try {
      final now = DateTime.now();
      
      // Run queries in parallel for better performance
      final futures = await Future.wait([
        // Get all adopted animals
        _firestore
            .collection('animals')
            .where('status', isEqualTo: 'Adopted')
            .get(),
        // Get available animals
        _firestore
            .collection('animals')
            .where('approvalStatus', isEqualTo: 'approved')
            .where('isActive', isEqualTo: true)
            .where('status', isEqualTo: 'Available for Adoption')
            .get(),
        // Get pending animals
        _firestore
            .collection('animals')
            .where('approvalStatus', isEqualTo: 'approved')
            .where('isActive', isEqualTo: true)
            .where('status', isEqualTo: 'Pending Adoption')
            .get(),
      ]);

      final adoptedQuery = futures[0];
      final availableQuery = futures[1];
      final pendingQuery = futures[2];

      // Count adopted this month - optimized filtering
      int adoptedThisMonth = 0;
      for (final doc in adoptedQuery.docs) {
        final adoptedAt = doc.data()['adoptedAt'];
        if (adoptedAt != null) {
          DateTime adoptedDate;
          if (adoptedAt is Timestamp) {
            adoptedDate = adoptedAt.toDate();
          } else if (adoptedAt is DateTime) {
            adoptedDate = adoptedAt;
          } else {
            continue;
          }
          
          // Quick month check
          if (adoptedDate.year == now.year && adoptedDate.month == now.month) {
            adoptedThisMonth++;
          }
        }
      }

      final activeRescues = availableQuery.docs.length + pendingQuery.docs.length;

      final stats = {
        'adoptedThisMonth': adoptedThisMonth,
        'activeRescues': activeRescues,
      };

      // Cache the results
      _cachedStats = stats;
      print('DEBUG: Stats - Adopted this month: $adoptedThisMonth, Active rescues: $activeRescues');

      return stats;
    } catch (e) {
      print('Error fetching adoption stats: $e');
      return {
        'adoptedThisMonth': 0,
        'activeRescues': 0,
      };
    }
  }

  /// Get stream of adoption statistics for real-time updates
  static Stream<Map<String, int>> getAdoptionStatsStream() {
    print('DEBUG: StatsService.getAdoptionStatsStream() called');
    
    // Create broadcast stream controller if it doesn't exist
    _statsController ??= StreamController<Map<String, int>>.broadcast();
    
    // Send cached data immediately if available
    if (_cachedStats != null) {
      print('DEBUG: Sending cached stats immediately: $_cachedStats');
      _statsController!.add(_cachedStats!);
    }
    
    // Start timer if not already running - reduced interval for faster updates
    _timer ??= Timer.periodic(const Duration(seconds: 15), (_) async {
      print('DEBUG: Timer triggered - fetching stats');
      final stats = await getAdoptionStats();
      if (!_statsController!.isClosed) {
        print('DEBUG: Timer - adding stats to stream: $stats');
        _statsController!.add(stats);
      }
    });

    // Send fresh data immediately
    getAdoptionStats().then((stats) {
      if (!_statsController!.isClosed) {
        print('DEBUG: Initial - adding stats to stream: $stats');
        _statsController!.add(stats);
      }
    });

    print('DEBUG: Returning stream with ${_statsController!.stream}');
    return _statsController!.stream;
  }

  /// Dispose resources when no longer needed
  static void dispose() {
    _timer?.cancel();
    _timer = null;
    _statsController?.close();
    _statsController = null;
    _cachedStats = null;
  }
}