import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -----------------------------------------

class PostCardWidget extends StatefulWidget {
  final Map<String, dynamic> postData;
  final String postId;

  const PostCardWidget({
    Key? key,
    required this.postData,
    required this.postId,
  }) : super(key: key);

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  bool _isCommentSectionVisible = false;

  bool _isExpanded = false;
  static const int _maxLinesCollapsed = 4;
  static const int _minCharsForReadMore = 200;

  @override
  void initState() {
    super.initState();
    _commentFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _commentFocusNode.removeListener(_onFocusChange);
    _commentFocusNode.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Functionality remains the same
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

  Future<void> _toggleLike() async {
    // Functionality remains the same
    if (currentUser == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId);
    final likes = List<String>.from(widget.postData['likes'] ?? []);
    final isLiked = likes.contains(currentUser!.uid);

    await docRef.update({
      'likes': isLiked
          ? FieldValue.arrayRemove([currentUser!.uid])
          : FieldValue.arrayUnion([currentUser!.uid])
    });
  }

  Future<void> _sharePost() async {
    // Functionality remains the same
    final String author = (widget.postData['author'] ?? 'Anonymous').toString();
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
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text('Delete Post?', style: TextStyle(color: kPrimaryTextColor)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: kSecondaryTextColor)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: kPrimaryTextColor))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (widget.postData['imageUrl'] != null) {
        await FirebaseStorage.instance
            .refFromURL(widget.postData['imageUrl'])
            .delete();
      }
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Post deleted successfully.'),
              backgroundColor: Colors.green.shade800),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error deleting post: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _postComment() async {
    // Functionality remains the same
    if (_commentController.text.trim().isEmpty || currentUser == null) return;
    final commentText = _commentController.text.trim();
    _commentController.clear();
    _commentFocusNode.unfocus();

    final postRef = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId);
    final commentRef = postRef.collection('comments').doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(commentRef, {
        'author': currentUser!.displayName?.trim().isNotEmpty == true
            ? currentUser!.displayName
            : 'Anonymous',
        'text': commentText,
        'postedAt': FieldValue.serverTimestamp(),
        'userId': currentUser!.uid,
      });
      transaction.update(postRef, {'commentCount': FieldValue.increment(1)});
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    // Functionality remains the same
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

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

    return Card(
      color: kCardColor,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(timeAgo),
            const SizedBox(height: 12),
            if (storyText.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storyText,
                    style: const TextStyle(
                        fontSize: 15, height: 1.4, color: kPrimaryTextColor),
                    maxLines: _isExpanded ? null : _maxLinesCollapsed,
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (isLongText)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _isExpanded ? 'Read less' : 'Read more...',
                          style: const TextStyle(
                              color: kPrimaryAccentColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            if ((widget.postData['imageUrl'] ?? '').toString().isNotEmpty)
              _buildPostImage(widget.postData['imageUrl']),
            const SizedBox(height: 8),
            _buildActionButtons(isLiked, likes.length, commentCount),
            if (_isCommentSectionVisible) _buildCommentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(String timeAgo) {
    final String author = (widget.postData['author'] ?? 'Anonymous').toString();
    final bool isAuthor = currentUser?.uid == widget.postData['userId'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: kPrimaryAccentColor.withOpacity(0.2),
          child: Text(
            author.isNotEmpty ? author[0].toUpperCase() : 'A',
            style: const TextStyle(
                color: kPrimaryAccentColor, fontWeight: FontWeight.bold),
          ),
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
                      author,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kPrimaryTextColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('· $timeAgo',
                      style: const TextStyle(
                          color: kSecondaryTextColor, fontSize: 14)),
                ],
              ),
              if ((widget.postData['category'] ?? '').toString().isNotEmpty)
                Text(widget.postData['category'],
                    style: const TextStyle(
                        color: kSecondaryTextColor, fontSize: 12)),
            ],
          ),
        ),
        if (isAuthor)
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: const PopupMenuThemeData(
                color: kCardColor, // Dark background for the menu
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
                  child: CircularProgressIndicator(color: kPrimaryAccentColor)),
            ),
            errorWidget: (context, __, ___) => Container(
              color: Colors.grey.shade900,
              child: const Center(
                  child: Icon(Icons.broken_image, color: kSecondaryTextColor)),
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
          color: isLiked ? kPrimaryAccentColor : kSecondaryTextColor,
          onTap: _toggleLike,
        ),
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          text: '$commentCount',
          color: kSecondaryTextColor,
          onTap: () => setState(() {
            _isCommentSectionVisible = !_isCommentSectionVisible;
            if (_isCommentSectionVisible) {
              Future.delayed(const Duration(milliseconds: 50), () {
                if (!mounted) return;
                Scrollable.ensureVisible(context,
                    duration: const Duration(milliseconds: 200));
              });
            }
          }),
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
            Text(text,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: [
          Divider(color: Colors.grey.shade800),
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
                      child:
                          CircularProgressIndicator(color: kPrimaryAccentColor)),
                );
              }
              final comments = snapshot.data?.docs ?? [];
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child:
                      Text('No comments yet.', style: TextStyle(color: kSecondaryTextColor)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final commentData = comments[index].data();
                  final author = (commentData['author'] ?? 'A').toString();
                  final text = (commentData['text'] ?? '').toString();
                  return ListTile(
                    leading: CircleAvatar(
                        radius: 15,
                        backgroundColor: kPrimaryAccentColor.withOpacity(0.2),
                        child: Text(author.isNotEmpty ? author[0] : 'A', style: const TextStyle(color: kPrimaryAccentColor))),
                    title: Text(author,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: kPrimaryTextColor)),
                    subtitle: Text(text,
                        style: const TextStyle(
                            fontSize: 14, color: kSecondaryTextColor)),
                    dense: true,
                  );
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
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
                      hintStyle: const TextStyle(color: kSecondaryTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: kBackgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 0),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: kPrimaryAccentColor),
                  onPressed: _postComment,
                  tooltip: 'Post comment',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}