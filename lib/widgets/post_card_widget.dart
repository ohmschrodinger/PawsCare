import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
    if (currentUser == null) return;
    final docRef = FirebaseFirestore.instance.collection('community_posts').doc(widget.postId);
    final likes = List<String>.from(widget.postData['likes'] ?? []);
    final isLiked = likes.contains(currentUser!.uid);

    await docRef.update({
      'likes': isLiked
          ? FieldValue.arrayRemove([currentUser!.uid])
          : FieldValue.arrayUnion([currentUser!.uid])
    });
  }

  Future<void> _sharePost() async {
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
        await Share.shareXFiles([XFile(path)], text: text);
        return;
      } catch (_) {
        // fall through to text only
      }
    }
    await Share.share(text);
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;

    final commentText = _commentController.text.trim();
    _commentController.clear();
    _commentFocusNode.unfocus();

    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(widget.postId);
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
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = (widget.postData['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeAgo = _getTimeAgo(timestamp);
    final likes = List<String>.from(widget.postData['likes'] ?? []);
    final isLiked = currentUser != null && likes.contains(currentUser!.uid);
    final int commentCount = (widget.postData['commentCount'] ?? 0) as int;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(timeAgo),
            const SizedBox(height: 12),
            if ((widget.postData['story'] ?? '').toString().isNotEmpty)
              Text(
                widget.postData['story'],
                style: const TextStyle(fontSize: 15, height: 1.4),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF5AC8F2),
          child: Text(
            author.isNotEmpty ? author[0].toUpperCase() : 'A',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('· $timeAgo', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
              if ((widget.postData['category'] ?? '').toString().isNotEmpty)
                Text(widget.postData['category'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.more_horiz, color: Colors.grey),
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
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, __, ___) => Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.broken_image)),
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
          color: isLiked ? Colors.red : Colors.grey,
          onTap: _toggleLike,
        ),
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          text: '$commentCount',
          color: Colors.grey,
          onTap: () => setState(() {
            _isCommentSectionVisible = !_isCommentSectionVisible;
            if (_isCommentSectionVisible) {
              // slight delay for smooth scroll into view
              Future.delayed(const Duration(milliseconds: 50), () {
                if (!mounted) return;
                Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 200));
              });
            }
          }),
        ),
        _buildActionButton(
          icon: Icons.share_outlined,
          text: 'Share',
          color: Colors.grey,
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
            Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
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
          const Divider(),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('community_posts')
                .doc(widget.postId)
                .collection('comments')
                .orderBy('postedAt', descending: true)
                .limit(3)
                .withConverter<Map<String, dynamic>>(
                  fromFirestore: (s, _) => s.data() ?? {},
                  toFirestore: (m, _) => m,
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final comments = snapshot.data?.docs ?? [];
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No comments yet.'),
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
                    leading: CircleAvatar(radius: 15, child: Text(author.isNotEmpty ? author[0] : 'A')),
                    title: Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(text, style: const TextStyle(fontSize: 14)),
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
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _postComment(),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF5AC8F2)),
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
