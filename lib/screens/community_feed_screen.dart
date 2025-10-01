// community_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/post_composer.dart';
import '../widgets/post_card_widget.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -----------------------------------------

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  String _selectedFilter = 'All Posts';
  final List<String> _filters = [
    'All Posts',
    'Success Story',
    'Concern',
    'Question',
    'General',
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>> _getPostsStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('community_posts')
        .orderBy('postedAt', descending: true);

    if (_selectedFilter != 'All Posts') {
      query = query.where('category', isEqualTo: _selectedFilter);
    }
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text(
            'Community Feed',
            style: TextStyle(
              color: kPrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          backgroundColor: kBackgroundColor,
          elevation: 0,
        ),
        body: Column(
          children: [
            // NOTE: Ensure your `PostComposer` widget is updated with the dark theme colors.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: PostComposer(),
            ),

            // Filter chips row
            Container(
              color: kBackgroundColor, // Seamless with the background
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final selected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        label: Text(filter),
                        selected: selected,
                        onSelected: (bool s) {
                          if (s) setState(() => _selectedFilter = filter);
                        },
                        // --- 👇 THESE ARE THE CHANGES ---
                        showCheckmark: false, // Hides the checkmark icon
                        visualDensity: VisualDensity.compact, // Makes the chip smaller
                        // -----------------------------
                        labelStyle: TextStyle(
                          color: selected ? Colors.black : kPrimaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: kCardColor,
                        selectedColor: kPrimaryAccentColor,
                        side: BorderSide(
                          color: selected ? kPrimaryAccentColor : Colors.grey.shade800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Post list
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getPostsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kPrimaryAccentColor));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                  }

                  final posts = snapshot.data?.docs ?? [];
                  if (posts.isEmpty) {
                    return const Center(
                      child: Text(
                        'No posts found for this category.',
                        style: TextStyle(fontSize: 18, color: kSecondaryTextColor),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final data = posts[index].data();
                      final postId = posts[index].id;
                      // NOTE: Ensure your `PostCardWidget` is updated with the dark theme colors.
                      return PostCardWidget(postData: data, postId: postId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}