// community_feed_screen.dart

import 'dart:ui';
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

  late Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = _getPostsStream();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getPostsStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('community_posts')
        .orderBy('postedAt', descending: true);

    if (_selectedFilter != 'All Posts') {
      query = query.where('category', isEqualTo: _selectedFilter);
    }
    return query.snapshots();
  }

  void _updateFilter(String filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
        _postsStream = _getPostsStream();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
      child: Scaffold(
        // --- CHANGE 1: Remove the solid background color to allow the Stack to be visible ---
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        // --- CHANGE 2: Allow the body to extend behind the AppBar ---
        extendBodyBehindAppBar: true,

        // --- CHANGE 3: Make the AppBar transparent ---
        appBar: AppBar(
          title: const Text(
            'Community Feed',
            style: TextStyle(
              color: kPrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent, // Set to transparent
          elevation: 0, // Remove shadow
        ),

        // --- CHANGE 4: Use a Stack for the layered background effect ---
        body: Stack(
          children: [
            // --- LAYER 1: The background image ---
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.2),
                colorBlendMode: BlendMode.darken,
              ),
            ),

            // --- LAYER 2: The blur overlay ---
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

            // --- LAYER 3: Your original screen content, now inside a SafeArea ---
            SafeArea(
              child: Column(
                children: [
                  // NOTE: Ensure your `PostComposer` widget is updated with the dark theme colors.
                  Padding(padding: const EdgeInsets.all(8.0), child: PostComposer()),

                  // Filter chips row
                  Container(
                    // --- CHANGE 5: Make the filter container transparent ---
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final selected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.0),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20.0),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.blue.withOpacity(0.4)
                                          : Colors.white.withOpacity(0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _updateFilter(filter),
                                      borderRadius: BorderRadius.circular(20.0),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          filter,
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : kSecondaryTextColor,
                                            fontWeight: selected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
                      stream: _postsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: kPrimaryAccentColor,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          );
                        }

                        final posts = snapshot.data?.docs ?? [];
                        if (posts.isEmpty) {
                          return const Center(
                            child: Text(
                              'No posts found for this category.',
                              style: TextStyle(
                                fontSize: 18,
                                color: kSecondaryTextColor,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 90),
                          physics: const BouncingScrollPhysics(),
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
          ],
        ),
      ),
    );
  }
}