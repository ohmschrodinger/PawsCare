import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../constants/app_colors.dart';
import '../services/current_user_cache.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  User? currentUser;
  String? _resolvedAuthorName;
  bool _sensitiveContentRevealed = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _resolveAuthorName();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _resolveAuthorName() async {
    final userId = (widget.postData['userId'] ?? '').toString();

    if (userId.isEmpty) {
      final author = (widget.postData['author'] ?? '').toString();
      setState(
        () => _resolvedAuthorName = author.isNotEmpty ? author.trim() : 'User',
      );
      return;
    }

    try {
      // Check if it's the current user - use cache for instant results
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        final name = await CurrentUserCache().getDisplayName();
        setState(() => _resolvedAuthorName = name);
        return;
      }

      // For other users, fetch from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final data = doc.data();

      String? candidate;
      if (data != null) {
        final firstName = data['firstName']?.toString().trim() ?? '';
        final lastName = data['lastName']?.toString().trim() ?? '';
        final fullName = '$firstName $lastName'.trim();

        if (fullName.isNotEmpty) {
          candidate = fullName;
        } else {
          candidate =
              data['name']?.toString() ?? data['displayName']?.toString();
        }
      }

      if (candidate != null && candidate.trim().isNotEmpty) {
        setState(() => _resolvedAuthorName = candidate!.trim());
      } else {
        setState(
          () => _resolvedAuthorName =
              'User ${userId.substring(userId.length - 4)}',
        );
      }
    } catch (e) {
      setState(() => _resolvedAuthorName = 'User');
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

      if (data != null) {
        final firstName = data['firstName']?.toString().trim() ?? '';
        final lastName = data['lastName']?.toString().trim() ?? '';
        final fullName = '$firstName $lastName'.trim();

        if (fullName.isNotEmpty) {
          return fullName;
        }

        final candidate =
            data['name']?.toString() ?? data['displayName']?.toString();
        if (candidate != null && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
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

    try {
      await docRef.update({
        'likes': isLiked
            ? FieldValue.arrayRemove([currentUser!.uid])
            : FieldValue.arrayUnion([currentUser!.uid]),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating like: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  void _showFullImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? null
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                color: kPrimaryAccentColor,
              ),
            ),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.error, color: Colors.white, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp =
        (widget.postData['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeAgo = _getTimeAgo(timestamp);
    final displayAuthor =
        _resolvedAuthorName ?? (widget.postData['author'] ?? 'User').toString();
    final String? profileImageUrl = widget.postData['profilePicUrl'] as String?;
    final String storyText = widget.postData['story'] ?? '';
    final String? imageUrl = widget.postData['imageUrl'] as String?;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post', style: TextStyle(color: kPrimaryTextColor)),
      ),
      body: Stack(
        children: [
          // Background image layer
          Positioned.fill(
            child: Image.asset(
              'assets/images/app_wallpaper_blurred.png',
              fit: BoxFit.cover,
            ),
          ),

          // Content layer
          SafeArea(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .doc(widget.postId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: kPrimaryAccentColor,
                    ),
                  );
                }

                final postData = snapshot.data!.data() ?? widget.postData;
                final likes = List<String>.from(postData['likes'] ?? []);
                final isLiked =
                    currentUser != null && likes.contains(currentUser!.uid);
                final int commentCount = (postData['commentCount'] ?? 0) as int;

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Header
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: kAvatarAccentColor
                                        .withOpacity(0.2),
                                    backgroundImage:
                                        (profileImageUrl != null &&
                                            profileImageUrl.isNotEmpty)
                                        ? NetworkImage(profileImageUrl)
                                        : null,
                                    child:
                                        (profileImageUrl == null ||
                                            profileImageUrl.isEmpty)
                                        ? Text(
                                            displayAuthor.isNotEmpty
                                                ? displayAuthor[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              color: kAvatarAccentColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayAuthor,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: kPrimaryTextColor,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if ((postData['category'] ?? '')
                                                .toString()
                                                .isNotEmpty) ...[
                                              Text(
                                                postData['category'],
                                                style: const TextStyle(
                                                  color: kSecondaryTextColor,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const Text(
                                                ' · ',
                                                style: TextStyle(
                                                  color: kSecondaryTextColor,
                                                ),
                                              ),
                                            ],
                                            Text(
                                              timeAgo,
                                              style: const TextStyle(
                                                color: kSecondaryTextColor,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Full Image with tap to zoom or reveal if sensitive
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  final isSensitive =
                                      postData['isSensitive'] ?? false;
                                  if (isSensitive &&
                                      !_sensitiveContentRevealed) {
                                    setState(
                                      () => _sensitiveContentRevealed = true,
                                    );
                                  } else {
                                    _showFullImage(imageUrl);
                                  }
                                },
                                child: Stack(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      placeholder: (context, __) => Container(
                                        height: 300,
                                        color: Colors.grey.shade900,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: kPrimaryAccentColor,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, __, ___) =>
                                          Container(
                                            height: 300,
                                            color: Colors.grey.shade900,
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: kSecondaryTextColor,
                                                size: 48,
                                              ),
                                            ),
                                          ),
                                    ),
                                    if ((postData['isSensitive'] ?? false) &&
                                        !_sensitiveContentRevealed)
                                      Positioned.fill(
                                        child: ClipRRect(
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 25.0,
                                              sigmaY: 25.0,
                                            ),
                                            child: Container(
                                              color: Colors.black.withOpacity(
                                                0.4,
                                              ),
                                              child: const Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.visibility_off,
                                                      color: Colors.white,
                                                      size: 48,
                                                    ),
                                                    SizedBox(height: 12),
                                                    Text(
                                                      'Sensitive Content',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'Tap to reveal',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            // Action Buttons
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: _toggleLike,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isLiked
                                                ? Colors.redAccent
                                                : kSecondaryTextColor,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${likes.length}',
                                            style: TextStyle(
                                              color: isLiked
                                                  ? Colors.redAccent
                                                  : kPrimaryTextColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline,
                                        color: kSecondaryTextColor,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$commentCount',
                                        style: const TextStyle(
                                          color: kPrimaryTextColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Story Text
                            if (storyText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Text(
                                  storyText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: kPrimaryTextColor,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),
                            const Divider(
                              color: kSecondaryTextColor,
                              height: 1,
                            ),
                            const SizedBox(height: 16),

                            // Comments Section
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Text(
                                'Comments ($commentCount)',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('community_posts')
                                  .doc(widget.postId)
                                  .collection('comments')
                                  .orderBy('postedAt', descending: false)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(24.0),
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
                                    padding: EdgeInsets.all(24.0),
                                    child: Center(
                                      child: Text(
                                        'No comments yet. Be the first to comment!',
                                        style: TextStyle(
                                          color: kSecondaryTextColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: comments.length,
                                  itemBuilder: (context, index) {
                                    final commentData = comments[index].data();
                                    final author = (commentData['author'] ?? '')
                                        .toString();
                                    final text = (commentData['text'] ?? '')
                                        .toString();
                                    final timestamp =
                                        (commentData['postedAt'] as Timestamp?)
                                            ?.toDate() ??
                                        DateTime.now();
                                    final commentTimeAgo = _getTimeAgo(
                                      timestamp,
                                    );

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: kAvatarAccentColor
                                                .withOpacity(0.2),
                                            child: Text(
                                              author.isNotEmpty
                                                  ? author[0]
                                                  : 'U',
                                              style: const TextStyle(
                                                color: kAvatarAccentColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      author.isNotEmpty
                                                          ? author
                                                          : 'User',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color:
                                                            kPrimaryTextColor,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      commentTimeAgo,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            kSecondaryTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  text,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: kPrimaryTextColor,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 80), // Space for input field
                          ],
                        ),
                      ),
                    ),

                    // Comment Input with glassmorphic effect
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                          ),
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 12,
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  focusNode: _commentFocusNode,
                                  controller: _commentController,
                                  style: const TextStyle(
                                    color: kPrimaryTextColor,
                                  ),
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _postComment(),
                                  decoration: InputDecoration(
                                    hintText: 'Write a comment...',
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
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: kPrimaryAccentColor,
                                ),
                                onPressed: _postComment,
                                tooltip: 'Post comment',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
