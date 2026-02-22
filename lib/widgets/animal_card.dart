import 'dart:ui'; // <-- For ImageFilter
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/user_favorites_service.dart';
import '../screens/pet_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';

// Custom cache manager
final customCacheManager = CacheManager(
  Config(
    'animalImageCache',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 200,
  ),
);

class AnimalCard extends StatefulWidget {
  final Map<String, dynamic> animal;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final bool isLiked;
  final bool isSaved;
  final int likeCount;

  const AnimalCard({
    super.key,
    required this.animal,
    this.onTap,
    this.onLike,
    this.onSave,
    this.isLiked = false,
    this.isSaved = false,
    this.likeCount = 0,
  });

  @override
  State<AnimalCard> createState() => _AnimalCardState();
}

class _AnimalCardState extends State<AnimalCard> with TickerProviderStateMixin {
  int _currentPage = 0;
  late final PageController _pageController;
  late final AnimationController _likeAnimationController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _heartAnimationController;
  late final Animation<double> _heartAnimation;
  bool _isHeartAnimating = false;

  // Optimistic UI state
  bool? _optimisticIsLiked;
  bool? _optimisticIsSaved;
  int? _optimisticLikeCount;

  String _city = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.easeOut),
    );

    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heartAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _heartAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isHeartAnimating = false);
      }
    });

    _getCityFromLocation();
    _preloadAllImages();
  }

  @override
  void didUpdateWidget(AnimalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload location if the animal data has changed
    if (oldWidget.animal != widget.animal) {
      _getCityFromLocation();
      _preloadAllImages();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimationController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  // Preload all images in background for smooth swiping
  void _preloadAllImages() {
    final imageUrls = (widget.animal['imageUrls'] as List?)?.cast<String>() ?? [];
    
    if (imageUrls.length <= 1) return; // No need to preload if only one image
    
    for (int i = 1; i < imageUrls.length; i++) { // Start from index 1, since 0 loads immediately
      customCacheManager.downloadFile(imageUrls[i]).catchError((error) {
        print('Error preloading image ${imageUrls[i]}: $error');
        return null;
      });
    }
    
    print('Preloading ${imageUrls.length - 1} additional images for ${widget.animal['name']}');
  }

  Future<void> _getCityFromLocation() async {
    if (!mounted) return;

    // Default to a loading or placeholder text
    setState(() {
      _city = 'Loading location...';
    });

    try {
      // Case 1: Modern format with 'locationData' map
      if (widget.animal['locationData'] != null &&
          widget.animal['locationData'] is Map) {
        final locationData = widget.animal['locationData'];
        final lat = locationData['latitude'] as double?;
        final lng = locationData['longitude'] as double?;

        if (lat != null && lng != null) {
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
          if (mounted && placemarks.isNotEmpty) {
            setState(() {
              _city = placemarks.first.locality ?? 'Unknown City';
            });
            return;
          }
        }
      }

      // Case 2: Fallback for older data with just a 'location' string
      if (widget.animal['location'] is String) {
        final locationString = widget.animal['location'] as String;
        // Attempt to parse city from string "City, State"
        final parts = locationString.split(',');
        if (parts.isNotEmpty) {
          if (mounted) {
            setState(() {
              _city = parts.first.trim();
            });
            return;
          }
        }
      }

      // If all else fails
      if (mounted) {
        setState(() {
          _city = 'Pune, Maharashtra'; // Final fallback
        });
      }
    } catch (e) {
      print('Error getting city from location: $e');
      if (mounted) {
        setState(() {
          _city = 'Location unavailable'; // Error state
        });
      }
    }
  }

  // ================= LOGIC METHODS =================
  Future<void> _handleDoubleTap(
    bool currentIsLiked,
    int currentLikeCount,
  ) async {
    setState(() => _isHeartAnimating = true);
    _heartAnimationController.forward(from: 0);

    // Only like if not already liked (Instagram behavior)
    if (!currentIsLiked) {
      await _toggleLike(currentIsLiked, currentLikeCount);
    }
  }

  Future<void> _toggleLike(bool currentIsLiked, int currentLikeCount) async {
    // OPTIMISTIC UI UPDATE - Instant feedback like Instagram
    final newIsLiked = !currentIsLiked;
    final newLikeCount = currentIsLiked
        ? currentLikeCount - 1
        : currentLikeCount + 1;

    setState(() {
      _optimisticIsLiked = newIsLiked;
      _optimisticLikeCount = newLikeCount;
    });

    // Trigger animation
    _likeAnimationController.forward().then(
      (_) => _likeAnimationController.reverse(),
    );

    // Background sync with Firestore
    try {
      await UserFavoritesService.toggleLike(widget.animal['id']);
      widget.onLike?.call();

      // Clear optimistic state after successful sync
      // The StreamBuilder will now show the real data
      if (mounted) {
        setState(() {
          _optimisticIsLiked = null;
          _optimisticLikeCount = null;
        });
      }
    } catch (e) {
      print('Error toggling like: $e');

      // REVERT optimistic update on error
      if (mounted) {
        setState(() {
          _optimisticIsLiked = null;
          _optimisticLikeCount = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update like. Please try again.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleSave(bool currentIsSaved) async {
    // OPTIMISTIC UI UPDATE
    final newIsSaved = !currentIsSaved;

    setState(() {
      _optimisticIsSaved = newIsSaved;
    });

    // Background sync
    try {
      await UserFavoritesService.toggleSave(widget.animal['id']);
      widget.onSave?.call();

      // Clear optimistic state after successful sync
      if (mounted) {
        setState(() {
          _optimisticIsSaved = null;
        });
      }
    } catch (e) {
      print('Error toggling save: $e');

      // REVERT on error
      if (mounted) {
        setState(() {
          _optimisticIsSaved = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update bookmark. Please try again.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareAnimal() async {
    try {
      // Start all async operations in parallel for better performance
      final appLinkFuture = _getAppLink();
      final petName = widget.animal['name']?.toString() ?? 'This pet';
      final age = widget.animal['age']?.toString() ?? 'Unknown age';
      final breed = widget.animal['breed']?.toString() ?? 'Mixed Breed';
      final location = _city.isNotEmpty
          ? _city
          : (widget.animal['location']?.toString() ?? 'Unknown location');
      final description =
          widget.animal['description']?.toString() ??
          widget.animal['personality']?.toString() ??
          'A wonderful companion waiting for a loving home';

      // Wait for app link (this is usually quick)
      final appLink = await appLinkFuture;

      // Create share content
      final shareText =
          '''$petName is a $age $breed looking for love 💕
📍 Location: $location

$description

If you or someone you know can give $petName a forever home, don't miss this chance 🏡✨

View full profile & adopt here:
🔗 $appLink

Let's help $petName find their perfect human 🤍''';

      // Try to share with cached image first (much faster)
      final imageUrls = widget.animal['imageUrls'] as List<dynamic>?;
      final imageUrl = imageUrls?.isNotEmpty == true
          ? imageUrls!.first.toString()
          : null;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // Check if image is in cache first
          final cachedFile = await customCacheManager.getFileFromCache(
            imageUrl,
          );

          if (cachedFile != null) {
            // Use cached image - much faster!
            final xFile = XFile(cachedFile.file.path);
            await Share.shareXFiles([xFile], text: shareText);
            return;
          } else {
            // Download and cache image in background, but share text immediately
            _downloadImageForFutureSharing(imageUrl, petName);
          }
        } catch (e) {
          print('Error sharing cached image: $e');
          // Fall through to text-only sharing
        }
      }

      // Share text only - much faster fallback
      await Share.share(shareText);
    } catch (e) {
      print('Error sharing animal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Helper method to get app link with caching
  Future<String> _getAppLink() async {
    try {
      final appLinkDoc = await FirebaseFirestore.instance
          .collection('contact_info')
          .doc('app_link')
          .get();
      if (appLinkDoc.exists && appLinkDoc.data()?['link'] != null) {
        String link = appLinkDoc.data()!['link'].toString();
        // Ensure the link has a proper protocol
        if (!link.startsWith('http://') && !link.startsWith('https://')) {
          link = 'https://$link';
        }
        return link;
      }
    } catch (e) {
      print('Error fetching app link: $e');
    }
    return 'https://pawscare.app'; // fallback
  }

  // Background method to download and cache image for future shares
  void _downloadImageForFutureSharing(String imageUrl, String petName) async {
    try {
      // Download image in background and store in cache
      await customCacheManager.downloadFile(imageUrl);
      print('Image cached for future sharing: $petName');
    } catch (e) {
      print('Error caching image for future sharing: $e');
    }
  }

  void _navigateToPetDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(petData: widget.animal),
      ),
    );
  }

  String _getTimeAgo() {
    final postedAt = widget.animal['postedAt'];
    DateTime? postedDate;
    try {
      if (postedAt is Timestamp) postedDate = postedAt.toDate();
    } catch (_) {}
    if (postedDate == null) return 'recently';
    final difference = DateTime.now().difference(postedDate);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    return 'just now';
  }

  // Helper to combine Firestore data with optimistic updates
  Stream<Map<String, dynamic>> _getLikeStatusStream(String? animalId) async* {
    if (animalId == null) {
      yield {'isLiked': false, 'likeCount': 0, 'isSaved': false};
      return;
    }

    await for (final animalSnapshot
        in FirebaseFirestore.instance
            .collection('animals')
            .doc(animalId)
            .snapshots()) {
      final animalData = animalSnapshot.data();
      final firestoreLikeCount = animalData?['likeCount'] ?? 0;

      final isLiked = await UserFavoritesService.isLiked(animalId);
      final isSaved = await UserFavoritesService.isSaved(animalId);

      yield {
        'isLiked': _optimisticIsLiked ?? isLiked,
        'likeCount': _optimisticLikeCount ?? firestoreLikeCount,
        'isSaved': _optimisticIsSaved ?? isSaved,
      };
    }
  }

  // ================= BUILD METHOD =================
  @override
  Widget build(BuildContext context) {
    final imageUrls =
        (widget.animal['imageUrls'] as List?)?.cast<String>() ?? [];
    final hasImages = imageUrls.isNotEmpty;
    final animalId = widget.animal['id'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: StreamBuilder<Map<String, dynamic>>(
          // Move StreamBuilder to top level to prevent rebuilds on page changes
          stream: animalId != null ? _getLikeStatusStream(animalId) : null,
          builder: (context, snapshot) {
            final data = snapshot.data ?? {'isLiked': false, 'likeCount': 0, 'isSaved': false};
            final isLiked = data['isLiked'] ?? false;
            final likeCount = data['likeCount'] ?? 0;
            final isSaved = data['isSaved'] ?? false;

            return GestureDetector(
              onTap: () => _navigateToPetDetail(context),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // IMAGE LAYER
                  SizedBox(
                    height: 420,
                    width: double.infinity,
                    child: GestureDetector(
                      onDoubleTap: () => _handleDoubleTap(isLiked as bool, likeCount as int),
                      onTap: () => _navigateToPetDetail(context),
                      child: hasImages
                          ? PageView.builder(
                              controller: _pageController,
                              itemCount: imageUrls.length,
                              onPageChanged: (index) =>
                                  setState(() => _currentPage = index),
                              itemBuilder: (context, index) {
                                return CachedNetworkImage(
                                  cacheManager: customCacheManager,
                                  imageUrl: imageUrls[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade900,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: kPrimaryAccentColor,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey.shade900,
                                        child: const Icon(
                                          Icons.pets,
                                          size: 60,
                                          color: kSecondaryTextColor,
                                        ),
                                      ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade900,
                              child: const Icon(
                                Icons.pets,
                                size: 60,
                                color: kSecondaryTextColor,
                              ),
                            ),
                    ),
                  ),

              // DOUBLE TAP HEART ANIMATION
              if (_isHeartAnimating)
                FadeTransition(
                  opacity: _heartAnimation,
                  child: ScaleTransition(
                    scale: _heartAnimation.drive(Tween(begin: 0.5, end: 1.2)),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 80,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 10)],
                    ),
                  ),
                ),

              // LEFT & RIGHT ARROWS FOR MULTIPLE IMAGES
              // LEFT & RIGHT ARROWS FOR MULTIPLE IMAGES (no outer circle, dynamic)
              if (imageUrls.length > 1) ...[
                // Left arrow: only when previous page exists
                if (_currentPage > 0)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(
                            8.0,
                          ), // increases touch target
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Right arrow: only when next page exists
                if (_currentPage < imageUrls.length - 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(
                            8.0,
                          ), // increases touch target
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],

              // GLASSMORPHIC INFO PANEL
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                      child: _buildInfoContent(isLiked, isSaved, likeCount),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
        ))
    );
  }

  Widget _buildInfoContent(bool isLiked, bool isSaved, int likeCount) {

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.animal['name'] as String? ?? 'Unknown Pet',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: IconButton(
                        onPressed: () => _toggleLike(isLiked, likeCount),
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked
                              ? const Color.fromARGB(255, 255, 7, 7)
                              : kSecondaryTextColor,
                          size: 24,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Text(
                      '$likeCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kPrimaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _shareAnimal,
                      icon: const Icon(
                        Icons.share_outlined,
                        color: kSecondaryTextColor,
                        size: 24,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _toggleSave(isSaved),
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Colors.white : kSecondaryTextColor,
                        size: 24,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "${widget.animal['breed'] ?? 'Mixed Breed'} • ${widget.animal['age'] ?? 'Unknown age'}",
              style: const TextStyle(fontSize: 15, color: kSecondaryTextColor),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: kSecondaryTextColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "$_city • Posted ${_getTimeAgo()}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: kSecondaryTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        );
  }
}
