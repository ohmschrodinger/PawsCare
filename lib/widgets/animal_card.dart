import 'dart:ui'; // <-- For ImageFilter
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/user_favorites_service.dart';
import '../screens/gallery_screen.dart';
import '../screens/pet_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- THEME CONSTANTS ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);

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
  late bool _isLiked;
  late bool _isSaved;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isLiked = widget.isLiked;
    _isSaved = widget.isSaved;
    _likeCount = widget.likeCount;

    _initializeFavoriteStatus();

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
      CurvedAnimation(parent: _heartAnimationController, curve: Curves.easeInOut),
    );

    _heartAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isHeartAnimating = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != _isLiked) setState(() => _isLiked = widget.isLiked);
    if (widget.isSaved != _isSaved) setState(() => _isSaved = widget.isSaved);
    if (widget.likeCount != _likeCount) setState(() => _likeCount = widget.likeCount);
  }

  Future<void> _initializeFavoriteStatus() async {
    try {
      final isLiked = await UserFavoritesService.isLiked(widget.animal['id']);
      final isSaved = await UserFavoritesService.isSaved(widget.animal['id']);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _isSaved = isSaved;
        });
      }
    } catch (e) {
      print('Error initializing favorite status: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimationController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  // ================= LOGIC METHODS =================
  void _handleDoubleTap() {
    setState(() => _isHeartAnimating = true);
    _heartAnimationController.forward(from: 0);

    // Optimistic UI update
    if (!_isLiked) _toggleLike();
  }

  void _toggleLike() async {
    // Optimistic UI: immediate update
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    if (_isLiked) {
      _likeAnimationController
          .forward()
          .then((_) => _likeAnimationController.reverse());
    }

    try {
      await UserFavoritesService.toggleLike(widget.animal['id']);
    } catch (e) {
      print('Error toggling like: $e');
      // Revert UI if backend fails
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    }

    widget.onLike?.call();
  }

  void _toggleSave() async {
    // Optimistic UI: immediate update
    setState(() => _isSaved = !_isSaved);

    try {
      await UserFavoritesService.toggleSave(widget.animal['id']);
    } catch (e) {
      print('Error toggling save: $e');
      if (mounted) setState(() => _isSaved = !_isSaved);
    }

    widget.onSave?.call();
  }

  void _openGallery(BuildContext context, List<String> imageUrls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GalleryScreen(imageUrls: imageUrls, initialIndex: _currentPage),
      ),
    );
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

  IconData _getGenderIcon(String? gender) =>
      gender?.toLowerCase() == 'male' ? Icons.male : Icons.female;

  Color _getGenderColor(String? gender) =>
      gender?.toLowerCase() == 'male' ? Colors.blue : Colors.pink;

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUILD METHOD =================
  @override
  Widget build(BuildContext context) {
    final imageUrls =
        (widget.animal['imageUrls'] as List?)?.cast<String>() ?? [];
    final hasImages = imageUrls.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: () => _navigateToPetDetail(context),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // IMAGE LAYER
              SizedBox(
                height: 420,
                width: double.infinity,
                child: GestureDetector(
                  onDoubleTap: _handleDoubleTap,
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
                                      color: kPrimaryAccentColor),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade900,
                                child: const Icon(Icons.pets,
                                    size: 60, color: kSecondaryTextColor),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade900,
                          child: const Icon(Icons.pets,
                              size: 60, color: kSecondaryTextColor),
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
            padding: EdgeInsets.all(8.0), // increases touch target
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
            padding: EdgeInsets.all(8.0), // increases touch target
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
                      child: _buildInfoContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoContent() {
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
                        fontSize: 22,
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
                    onPressed: _toggleLike,
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked
                          ? const Color.fromARGB(255, 255, 7, 7)
                          : kSecondaryTextColor,
                      size: 24,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Text(
                  '$_likeCount',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kPrimaryTextColor),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _toggleSave,
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? Colors.white : kSecondaryTextColor,
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
            const Icon(Icons.location_on_outlined,
                size: 16, color: kSecondaryTextColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                "${widget.animal['location'] ?? 'Pune, Maharashtra'} • Posted ${_getTimeAgo()}",
                style: const TextStyle(fontSize: 14, color: kSecondaryTextColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}