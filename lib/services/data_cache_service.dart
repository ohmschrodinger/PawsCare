import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for caching and paginating Firestore data
class DataCacheService {
  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();

  // Cache for animals
  final List<DocumentSnapshot> _cachedAnimals = [];
  DocumentSnapshot? _lastAnimalDoc;
  bool _hasMoreAnimals = true;
  bool _isLoadingAnimals = false;

  // Cache for community posts
  final List<DocumentSnapshot> _cachedPosts = [];
  DocumentSnapshot? _lastPostDoc;
  bool _hasMorePosts = true;
  bool _isLoadingPosts = false;

  // Constants
  static const int _pageSize = 15;

  // Getters
  List<DocumentSnapshot> get cachedAnimals => List.unmodifiable(_cachedAnimals);
  List<DocumentSnapshot> get cachedPosts => List.unmodifiable(_cachedPosts);
  bool get hasMoreAnimals => _hasMoreAnimals;
  bool get hasMorePosts => _hasMorePosts;
  bool get isLoadingAnimals => _isLoadingAnimals;
  bool get isLoadingPosts => _isLoadingPosts;

  /// Pre-load initial data (called during splash screen)
  Future<void> preloadData() async {
    print('DataCacheService: Starting preload...');
    await Future.wait([loadInitialAnimals(), loadInitialPosts()]);
    print('DataCacheService: Preload complete');
  }

  /// Load initial animals (first 15)
  Future<void> loadInitialAnimals({
    String status = 'Available',
    String species = 'All',
    String gender = 'All',
    String age = 'All',
  }) async {
    if (_isLoadingAnimals) return;

    _isLoadingAnimals = true;
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('animals')
          .where('status', isEqualTo: status)
          .orderBy('postedAt', descending: true)
          .limit(_pageSize);

      // Apply filters
      if (species != 'All') {
        query = query.where('species', isEqualTo: species);
      }
      if (gender != 'All') {
        query = query.where('gender', isEqualTo: gender);
      }

      final snapshot = await query.get();

      _cachedAnimals.clear();
      _cachedAnimals.addAll(snapshot.docs);
      _lastAnimalDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMoreAnimals = snapshot.docs.length == _pageSize;

      print(
        'DataCacheService: Loaded ${_cachedAnimals.length} initial animals',
      );
    } catch (e) {
      print('Error loading initial animals: $e');
    } finally {
      _isLoadingAnimals = false;
    }
  }

  /// Load more animals (next page)
  Future<void> loadMoreAnimals({
    String status = 'Available',
    String species = 'All',
    String gender = 'All',
    String age = 'All',
  }) async {
    if (_isLoadingAnimals || !_hasMoreAnimals || _lastAnimalDoc == null) {
      return;
    }

    _isLoadingAnimals = true;
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('animals')
          .where('status', isEqualTo: status)
          .orderBy('postedAt', descending: true)
          .startAfterDocument(_lastAnimalDoc!)
          .limit(_pageSize);

      // Apply filters
      if (species != 'All') {
        query = query.where('species', isEqualTo: species);
      }
      if (gender != 'All') {
        query = query.where('gender', isEqualTo: gender);
      }

      final snapshot = await query.get();

      _cachedAnimals.addAll(snapshot.docs);
      _lastAnimalDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMoreAnimals = snapshot.docs.length == _pageSize;

      print(
        'DataCacheService: Loaded ${snapshot.docs.length} more animals. Total: ${_cachedAnimals.length}',
      );
    } catch (e) {
      print('Error loading more animals: $e');
    } finally {
      _isLoadingAnimals = false;
    }
  }

  /// Load initial community posts (first 15)
  Future<void> loadInitialPosts({String category = 'All Posts'}) async {
    if (_isLoadingPosts) return;

    _isLoadingPosts = true;
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('community_posts')
          .orderBy('postedAt', descending: true)
          .limit(_pageSize);

      if (category != 'All Posts') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();

      _cachedPosts.clear();
      _cachedPosts.addAll(snapshot.docs);
      _lastPostDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMorePosts = snapshot.docs.length == _pageSize;

      print('DataCacheService: Loaded ${_cachedPosts.length} initial posts');
    } catch (e) {
      print('Error loading initial posts: $e');
    } finally {
      _isLoadingPosts = false;
    }
  }

  /// Load more community posts (next page)
  Future<void> loadMorePosts({String category = 'All Posts'}) async {
    if (_isLoadingPosts || !_hasMorePosts || _lastPostDoc == null) {
      return;
    }

    _isLoadingPosts = true;
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('community_posts')
          .orderBy('postedAt', descending: true)
          .startAfterDocument(_lastPostDoc!)
          .limit(_pageSize);

      if (category != 'All Posts') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();

      _cachedPosts.addAll(snapshot.docs);
      _lastPostDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMorePosts = snapshot.docs.length == _pageSize;

      print(
        'DataCacheService: Loaded ${snapshot.docs.length} more posts. Total: ${_cachedPosts.length}',
      );
    } catch (e) {
      print('Error loading more posts: $e');
    } finally {
      _isLoadingPosts = false;
    }
  }

  /// Refresh animals (pull-to-refresh)
  Future<void> refreshAnimals({
    String status = 'Available',
    String species = 'All',
    String gender = 'All',
    String age = 'All',
  }) async {
    _lastAnimalDoc = null;
    _hasMoreAnimals = true;
    await loadInitialAnimals(
      status: status,
      species: species,
      gender: gender,
      age: age,
    );
  }

  /// Refresh posts (pull-to-refresh)
  Future<void> refreshPosts({String category = 'All Posts'}) async {
    _lastPostDoc = null;
    _hasMorePosts = true;
    await loadInitialPosts(category: category);
  }

  /// Clear all cache
  void clearCache() {
    _cachedAnimals.clear();
    _cachedPosts.clear();
    _lastAnimalDoc = null;
    _lastPostDoc = null;
    _hasMoreAnimals = true;
    _hasMorePosts = true;
    print('DataCacheService: Cache cleared');
  }

  /// Clear only animals cache
  void clearAnimalsCache() {
    _cachedAnimals.clear();
    _lastAnimalDoc = null;
    _hasMoreAnimals = true;
    print('DataCacheService: Animals cache cleared');
  }

  /// Clear only posts cache
  void clearPostsCache() {
    _cachedPosts.clear();
    _lastPostDoc = null;
    _hasMorePosts = true;
    print('DataCacheService: Posts cache cleared');
  }
}
