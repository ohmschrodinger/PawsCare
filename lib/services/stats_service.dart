import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'adoption_counter_service.dart';

class StatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static StreamController<Map<String, int>>? _statsController;
  static Timer? _timer;
  static Map<String, int>? _cachedStats;

  /// Get adoption statistics - optimized version with permanent counter
  static Future<Map<String, int>> getAdoptionStats() async {
    try {
      // Run queries in parallel for better performance
      final futures = await Future.wait([
        // Get TOTAL adoptions from permanent counter (never decreases)
        AdoptionCounterService.getTotalAdoptions(),
        // Get adoptions this month
        AdoptionCounterService.getAdoptionsThisMonth(),
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

      final totalAdoptions = futures[0] as int;
      final adoptedThisMonth = futures[1] as int;
      final availableQuery = futures[2] as QuerySnapshot;
      final pendingQuery = futures[3] as QuerySnapshot;

      final activeRescues =
          availableQuery.docs.length + pendingQuery.docs.length;

      final stats = {
        'totalAdoptions': totalAdoptions, // This is the permanent counter
        'adoptedThisMonth': adoptedThisMonth,
        'activeRescues': activeRescues,
      };

      // Cache the results
      _cachedStats = stats;
      print(
        'DEBUG: Stats - Total adoptions: $totalAdoptions, This month: $adoptedThisMonth, Active rescues: $activeRescues',
      );

      return stats;
    } catch (e) {
      print('Error fetching adoption stats: $e');
      return {'totalAdoptions': 0, 'adoptedThisMonth': 0, 'activeRescues': 0};
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
