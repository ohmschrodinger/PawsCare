import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/user_favorites_service.dart';
import '../screens/gallery_screen.dart';
import '../screens/pet_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -----------------------------------------

// Custom cache manager (unchanged)
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
    Key? key,
    required this.animal,
    this.onTap,
    this.onLike,
    this.onSave,
    this.isLiked = false,
    this.isSaved = false,
    this.likeCount = 0,
  }) : super(key: key);

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
  }

  @override
  void didUpdateWidget(covariant AnimalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != _isLiked) setState(() => _isLiked = widget.isLiked);
    if (widget.isSaved != _isSaved) setState(() => _isSaved = widget.isSaved);
    if (widget.likeCount != _likeCount)
      setState(() => _likeCount = widget.likeCount);
  }

  Future<void> _initializeFavoriteStatus() async {
    // Functionality remains the same
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

  // --- All backend and logic methods remain unchanged ---
  void _handleDoubleTap() {
    setState(() => _isHeartAnimating = true);
    _heartAnimationController.forward(from: 0);
    if (!_isLiked) _toggleLike();
  }

  void _toggleLike() async {
    try {
      final newLikeStatus =
          await UserFavoritesService.toggleLike(widget.animal['id']);
      if (mounted) {
        setState(() {
          _isLiked = newLikeStatus;
          _likeCount += newLikeStatus ? 1 : -1;
          if (newLikeStatus) {
            _likeAnimationController
                .forward()
                .then((_) => _likeAnimationController.reverse());
          }
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
    widget.onLike?.call();
  }

  void _toggleSave() async {
    try {
      final newSaveStatus =
          await UserFavoritesService.toggleSave(widget.animal['id']);
      if (mounted) {
        setState(() => _isSaved = newSaveStatus);
      }
    } catch (e) {
      print('Error toggling save: $e');
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
      if (postedAt is Timestamp) {
        postedDate = postedAt.toDate();
      }
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

  @override
  Widget build(BuildContext context) {
    final imageUrls =
        (widget.animal['imageUrls'] as List?)?.cast<String>() ?? [];
    final hasImages = imageUrls.isNotEmpty;

    return GestureDetector(
      onTap: () => _navigateToPetDetail(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              onTap: hasImages
                  ? () => _openGallery(context, imageUrls)
                  : () => _navigateToPetDetail(context),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 300,
                      width: double.infinity,
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
                                            color: kPrimaryAccentColor)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
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
                    if (_isHeartAnimating)
                      FadeTransition(
                        opacity: _heartAnimation,
                        child: ScaleTransition(
                          scale: _heartAnimation.drive(Tween(begin: 0.5, end: 1.2)),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 80,
                            shadows: [
                              Shadow(color: Colors.black38, blurRadius: 10)
                            ],
                          ),
                        ),
                      ),
                    if (imageUrls.length > 1)
                      Positioned(
                        bottom: 10.0,
                        child: Row(
                          children: List.generate(
                            imageUrls.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3.0),
                              height: 8.0,
                              width: _currentPage == index ? 24.0 : 8.0,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? kPrimaryAccentColor
                                    : kSecondaryTextColor.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
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
                                widget.animal['name'] as String? ??
                                    'Unknown Pet',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _getGenderIcon(
                                  widget.animal['gender'] as String?),
                              color: _getGenderColor(
                                  widget.animal['gender'] as String?),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: IconButton(
                                  onPressed: _toggleLike,
                                  icon: Icon(
                                    _isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _isLiked
                                        ? kPrimaryAccentColor
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
                                  color: kPrimaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _toggleSave,
                            icon: Icon(
                              _isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: _isSaved
                                  ? kPrimaryAccentColor
                                  : kSecondaryTextColor,
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
                    style: const TextStyle(
                        fontSize: 15, color: kSecondaryTextColor),
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
                          style: const TextStyle(
                              fontSize: 14, color: kSecondaryTextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.animal['vaccination'] != null ||
                      widget.animal['sterilization'] != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (widget.animal['vaccination'] == 'Yes')
                          _buildInfoChip(
                              Icons.vaccines, 'Vaccinated', Colors.green.shade400),
                        if (widget.animal['sterilization'] == 'Yes')
                          _buildInfoChip(
                              Icons.healing, 'Sterilized', Colors.blue.shade400),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}