import 'dart:ui'; // Added for ImageFilter
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/current_user_cache.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// New avatar accent for anonymous/profile fallback (blueish)
const Color kAvatarAccentColor = Colors.blueAccent;
// -----------------------------------------

class PostCardWidget extends StatefulWidget {
  final Map<String, dynamic> postData;
  final String postId;

  const PostCardWidget({
    super.key,
    required this.postData,
    required this.postId,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

// NOTE: added TickerProviderStateMixin to power the icon animation
class _PostCardWidgetState extends State<PostCardWidget>
    with TickerProviderStateMixin {
  User? currentUser;
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  bool _isCommentSectionVisible = false;

  bool _isExpanded = false;
  static const int _maxLinesCollapsed = 4;
  static const int _minCharsForReadMore = 200;

  // New: resolved author display name
  String? _resolvedAuthorName;
  bool _resolvingAuthor = false;

  // New: role state
  bool _isAdmin = false;
  bool _roleLoaded = false;

  // Animation controller for the comment icon (pop / rotate)
  late final AnimationController _iconController;
  late final Animation<double> _iconScaleAnimation;
  late final Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    _commentFocusNode.addListener(_onFocusChange);
    currentUser = FirebaseAuth.instance.currentUser;
    _loadUserRole();
    
    // Pre-set the resolved name synchronously if it's the current user
    final userId = (widget.postData['userId'] ?? '').toString();
    if (currentUser != null && userId == currentUser!.uid) {
      // Try to use cached name first (synchronous) to prevent flickering
      final cachedName = CurrentUserCache().cachedName;
      if (cachedName != null && cachedName.isNotEmpty) {
        _resolvedAuthorName = cachedName;
      }
    }
    
    // Then fetch the full name asynchronously
    _resolveAuthorNameIfNeeded();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // scale: 1.0 -> 1.08 -> 1.0 (via CurvedAnimation)
    _iconScaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeOut));

    // rotation: small rotation when opening (turns). 0 -> 0.06 turns (~21 deg)
    _iconRotationAnimation = Tween(begin: 0.0, end: 0.06).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    _commentFocusNode.removeListener(_onFocusChange);
    _commentFocusNode.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PostCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the postId changed, we have a completely different post
    if (oldWidget.postId != widget.postId) {
      _resolvedAuthorName = null;
      
      // Pre-set the resolved name synchronously if it's the current user
      final userId = (widget.postData['userId'] ?? '').toString();
      if (currentUser != null && userId == currentUser!.uid) {
        final cachedName = CurrentUserCache().cachedName;
        if (cachedName != null && cachedName.isNotEmpty) {
          _resolvedAuthorName = cachedName;
        }
      }
      
      _resolveAuthorNameIfNeeded();
    }
  }

  void _onFocusChange() {
    if (_commentFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          alignment: 0.1,
          duration: const Duration(milliseconds: 200),
        );
      });
    }
  }

  Future<void> _loadUserRole() async {
    if (currentUser == null) {
      setState(() {
        _isAdmin = false;
        _roleLoaded = true;
      });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final data = doc.data();
      final role = data != null && data['role'] != null
          ? data['role'].toString().toLowerCase()
          : 'user';
      setState(() {
        _isAdmin = role == 'admin' || role == 'superadmin';
        _roleLoaded = true;
      });
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _roleLoaded = true;
      });
    }
  }

  /// Always fetch the current name from Firestore using userId to ensure 
  /// the most up-to-date name is displayed, preventing glitches when users post.
  Future<void> _resolveAuthorNameIfNeeded() async {
    final userId = (widget.postData['userId'] ?? '').toString();
    
    if (userId.isEmpty) {
      // No userId, try to use author field as fallback
      final author = (widget.postData['author'] ?? '').toString();
      setState(() => _resolvedAuthorName = author.isNotEmpty ? author.trim() : 'User');
      return;
    }

    setState(() => _resolvingAuthor = true);
    try {
      // Check if it's the current user - use cache for instant results
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        final name = await CurrentUserCache().getDisplayName();
        setState(() => _resolvedAuthorName = name);
        setState(() => _resolvingAuthor = false);
        return;
      }

      // For other users, fetch from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final data = doc.data();
      final candidate = data == null
          ? null
          : (data['fullName'] ?? data['name'] ?? data['displayName']);
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        setState(() => _resolvedAuthorName = candidate.toString().trim());
      } else {
        // If user doc doesn't contain a name, try to fallback to auth user displayName
        try {
          final authUser = await FirebaseAuth.instance
              .authStateChanges()
              .firstWhere(
                (u) => true,
                orElse: () => FirebaseAuth.instance.currentUser,
              );
          final authName = authUser?.displayName;
          if (authName != null && authName.trim().isNotEmpty) {
            setState(() => _resolvedAuthorName = authName.trim());
          } else {
            setState(
              () => _resolvedAuthorName =
                  'User ${userId.substring(userId.length - 4)}',
            );
          }
        } catch (_) {
          setState(
            () => _resolvedAuthorName =
                'User ${userId.substring(userId.length - 4)}',
          );
        }
      }
    } catch (e) {
      setState(() => _resolvedAuthorName = 'User');
    } finally {
      setState(() => _resolvingAuthor = false);
    }
  }

  Future<String> _getCurrentUserName() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return 'User';
    if (authUser.displayName != null && authUser.displayName!.trim().isNotEmpty)
      return authUser.displayName!.trim();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();
      final data = doc.data();
      final candidate = data == null
          ? null
          : (data['fullName'] ?? data['name'] ?? data['displayName']);
      if (candidate != null && candidate.toString().trim().isNotEmpty)
        return candidate.toString().trim();
    } catch (_) {}
    return 'User ${authUser.uid.substring(authUser.uid.length - 4)}';
  }

  Future<void> _toggleLike() async {
    if (currentUser == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId);
    final likes = List<String>.from(widget.postData['likes'] ?? []);
    final isLiked = likes.contains(currentUser!.uid);

    await docRef.update({
      'likes': isLiked
          ? FieldValue.arrayRemove([currentUser!.uid])
          : FieldValue.arrayUnion([currentUser!.uid]),
    });
  }

  Future<void> _sharePost() async {
    final String author =
        (_resolvedAuthorName ?? widget.postData['author'] ?? 'User').toString();
    final String story = (widget.postData['story'] ?? '').toString();
    final String? imageUrl = (widget.postData['imageUrl'] as String?);

    final text = 'Check out this post from PawsCare:\n\n"$story"\n- $author';

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/paws_post.jpg';
        await File(path).writeAsBytes(bytes);
        final xFile = XFile(path);
        await Share.shareXFiles([xFile], text: text);
        return;
      } catch (_) {
        // Fall through to text-only sharing
      }
    }
    await Share.share(text);
  }

  Future<void> _deletePost() async {
    final ownerId = widget.postData['userId'] as String?;
    final allowed =
        (currentUser != null && currentUser!.uid == ownerId) || _isAdmin;

    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to delete this post.'),
          ),
        );
      }
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text(
          'Delete Post?',
          style: TextStyle(color: kPrimaryTextColor),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: kSecondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kPrimaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (widget.postData['imageUrl'] != null &&
          (widget.postData['imageUrl'] as String).isNotEmpty) {
        try {
          await FirebaseStorage.instance
              .refFromURL(widget.postData['imageUrl'])
              .delete();
        } catch (_) {}
      }
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post deleted successfully.'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;
    final commentText = _commentController.text.trim();
    _commentController.clear();
    _commentFocusNode.unfocus();

    final authorName = await _getCurrentUserName();

    final postRef = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId);
    final commentRef = postRef.collection('comments').doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(commentRef, {
        'author': authorName,
        'text': commentText,
        'postedAt': FieldValue.serverTimestamp(),
        'userId': currentUser!.uid,
      });
      transaction.update(postRef, {'commentCount': FieldValue.increment(1)});
    });

    // Ensure comments are visible after posting
    if (!mounted) return;
    setState(() => _isCommentSectionVisible = true);
    _iconController.forward();
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  // Toggle comment visibility with animations
  void _toggleCommentSection() {
    setState(() {
      _isCommentSectionVisible = !_isCommentSectionVisible;
      // animate icon: forward when opening, reverse when closing
      if (_isCommentSectionVisible) {
        _iconController.forward();
        // small delay then scroll into view
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 200),
            alignment: 0.1,
          );
        });
      } else {
        _iconController.reverse();
      }
    });
  }

  @override
 @override
Widget build(BuildContext context) {
  final timestamp =
      (widget.postData['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
  final timeAgo = _getTimeAgo(timestamp);
  final likes = List<String>.from(widget.postData['likes'] ?? []);
  final isLiked = currentUser != null && likes.contains(currentUser!.uid);
  final int commentCount = (widget.postData['commentCount'] ?? 0) as int;
  final String storyText = widget.postData['story'] ?? '';
  final bool isLongText = storyText.length > _minCharsForReadMore;

  final displayAuthor =
      _resolvedAuthorName ?? (widget.postData['author'] ?? 'User').toString();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Stack(
        children: [
          // NOTE: Background image removed as requested.
          // Keep only the glassmorphism layer (blur + semi-transparent black card)

          // Glassmorphism effect layer (with requested blur and color)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              decoration: BoxDecoration(
                // Use black with 25% opacity as requested
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15), // subtle border
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPostHeader(displayAuthor, timeAgo),
                    const SizedBox(height: 12),
                    if (storyText.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storyText,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: kPrimaryTextColor,
                            ),
                            maxLines: _isExpanded ? null : _maxLinesCollapsed,
                            overflow: _isExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                          if (isLongText)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isExpanded = !_isExpanded),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  _isExpanded ? 'Read less' : 'Read more...',
                                  style: const TextStyle(
                                    color: kPrimaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    if ((widget.postData['imageUrl'] ?? '').toString().isNotEmpty)
                      _buildPostImage(widget.postData['imageUrl']),
                    const SizedBox(height: 8),
                    _buildActionButtons(isLiked, likes.length, commentCount),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildCommentSection(),
                      ),
                      crossFadeState: _isCommentSectionVisible
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                      firstCurve: Curves.easeOut,
                      secondCurve: Curves.easeIn,
                      sizeCurve: Curves.easeInOut,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPostHeader(String displayAuthor, String timeAgo) {
    final bool isAuthor = currentUser?.uid == widget.postData['userId'];
    final String? profileImageUrl = widget.postData['profilePicUrl'] as String?;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: kAvatarAccentColor.withOpacity(0.2),
          backgroundImage:
              (profileImageUrl != null && profileImageUrl.isNotEmpty)
                  ? NetworkImage(profileImageUrl)
                  : null,
          child: (profileImageUrl == null || profileImageUrl.isEmpty)
              ? Text(
                  displayAuthor.isNotEmpty
                      ? displayAuthor[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: kAvatarAccentColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayAuthor,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kPrimaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· $timeAgo',
                    style: const TextStyle(
                      color: kSecondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if ((widget.postData['category'] ?? '').toString().isNotEmpty)
                Text(
                  widget.postData['category'],
                  style: const TextStyle(
                    color: kSecondaryTextColor,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        if (_roleLoaded && (isAuthor || _isAdmin))
          PopupMenuTheme(
            data: PopupMenuThemeData(
              color: kCardColor.withOpacity(0.75),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deletePost();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_horiz, color: kSecondaryTextColor),
            ),
          )
        else
          const SizedBox(width: 48), // Keep alignment consistent
      ],
    );
  }

  Widget _buildPostImage(String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, __) => Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: CircularProgressIndicator(color: kPrimaryAccentColor),
              ),
            ),
            errorWidget: (context, __, ___) => Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: Icon(Icons.broken_image, color: kSecondaryTextColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isLiked, int likeCount, int commentCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          text: '$likeCount',
          color: isLiked
              ? Colors.redAccent
              : kSecondaryTextColor, // like button red when liked
          onTap: _toggleLike,
        ),
        // Comment button: wrapped with animation widgets
        InkWell(
          onTap: _toggleCommentSection,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Animated icon (rotation + scale)
                AnimatedBuilder(
                  animation: _iconController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _iconRotationAnimation.value,
                      child: Transform.scale(
                        scale: _iconScaleAnimation.value,
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: kSecondaryTextColor,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  '$commentCount',
                  style: const TextStyle(
                      color: kSecondaryTextColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        _buildActionButton(
          icon: Icons.share_outlined,
          text: 'Share',
          color: kSecondaryTextColor,
          onTap: _sharePost,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('community_posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .orderBy('postedAt', descending: true)
                    .limit(3)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: kPrimaryAccentColor,
                        ),
                      ),
                    );
                  }
                  final comments = snapshot.data?.docs ?? [];
                  if (comments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No comments yet.',
                        style: TextStyle(color: kSecondaryTextColor),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final commentData = comments[index].data();
                      final author = (commentData['author'] ?? '').toString();
                      final text = (commentData['text'] ?? '').toString();
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 15,
                          backgroundColor:
                              kAvatarAccentColor.withOpacity(0.2),
                          child: Text(
                            author.isNotEmpty ? author[0] : 'U',
                            style: const TextStyle(color: kAvatarAccentColor),
                          ),
                        ),
                        title: Text(
                          author.isNotEmpty ? author : 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: kPrimaryTextColor,
                          ),
                        ),
                        subtitle: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kSecondaryTextColor,
                          ),
                        ),
                        dense: true,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: _commentFocusNode,
                      controller: _commentController,
                      style: const TextStyle(color: kPrimaryTextColor),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: const TextStyle(
                          color: kSecondaryTextColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _postComment,
                          tooltip: 'Post comment',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
