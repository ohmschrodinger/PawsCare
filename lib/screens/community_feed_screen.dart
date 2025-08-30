import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/post_composer.dart';
import '../widgets/post_card_widget.dart';

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
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data() ?? {},
          toFirestore: (m, _) => m,
        )
        .orderBy('postedAt', descending: true);

    if (_selectedFilter != 'All Posts') {
      query = query.where('category', isEqualTo: _selectedFilter);
    }
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data to ensure UI consistency
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appBarColor = isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey.shade50;
    final appBarTextColor = theme.textTheme.titleLarge?.color;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
      child: Scaffold(
        // Use theme's background color for consistency
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            'Community Feed',
            style: TextStyle(
              color: appBarTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Align AppBar with other screens
          centerTitle: false,
          backgroundColor: appBarColor,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: PostComposer(),
            ),
            
            // Filter chips row
            Container(
              color: theme.cardColor, // Use cardColor for better theme adaptability
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
                        // Use theme colors for chips
                        selectedColor: theme.primaryColor.withOpacity(0.2),
                        checkmarkColor: theme.primaryColor,
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final posts = snapshot.data?.docs ?? [];
                  if (posts.isEmpty) {
                    return const Center(
                      child: Text(
                        'No posts found for this category.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final data = posts[index].data();
                      final postId = posts[index].id;
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
