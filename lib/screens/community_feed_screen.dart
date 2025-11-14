// community_feed_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/post_composer.dart';
import '../widgets/post_card_widget.dart';
import '../constants/app_colors.dart';
import '../services/data_cache_service.dart';

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

  final ScrollController _scrollController = ScrollController();
  final DataCacheService _cacheService = DataCacheService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_cacheService.cachedPosts.isEmpty) {
      await _cacheService.loadInitialPosts(category: _selectedFilter);
    }
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_cacheService.isLoadingPosts && _cacheService.hasMorePosts) {
      await _cacheService.loadMorePosts(category: _selectedFilter);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _updateFilter(String filter) async {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
        _isInitialized = false;
      });

      // Clear and reload with new filter
      await _cacheService.refreshPosts(category: filter);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _cacheService.refreshPosts(category: _selectedFilter);
    if (mounted) {
      setState(() {});
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
                'assets/images/app_wallpaper_blurred.png',
                fit: BoxFit.cover,
              ),
            ),

            // --- LAYER 3: Your original screen content, now inside a SafeArea ---
            SafeArea(
              child: Column(
                children: [
                  // NOTE: Ensure your `PostComposer` widget is updated with the dark theme colors.
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PostComposer(),
                  ),

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

                          // Category-specific colors
                          Color filterColor;
                          switch (filter) {
                            case 'Success Story':
                              filterColor = kFilterSuccessColor;
                              break;
                            case 'Concern':
                              filterColor = kFilterConcernColor;
                              break;
                            case 'Question':
                              filterColor = kFilterQuestionColor;
                              break;
                            case 'General':
                              filterColor = kFilterGeneralColor;
                              break;
                            case 'All Posts':
                            default:
                              filterColor =
                                  kInteractiveIconColor; // Primary accent
                              break;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.0),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10.0,
                                  sigmaY: 10.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? filterColor.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20.0),
                                    border: Border.all(
                                      color: selected
                                          ? filterColor.withOpacity(0.6)
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
                    child: !_isInitialized
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: kPrimaryAccentColor,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _onRefresh,
                            color: kPrimaryAccentColor,
                            child: _cacheService.cachedPosts.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No posts found for this category.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: kSecondaryTextColor,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                      bottom: 90,
                                    ),
                                    physics: const BouncingScrollPhysics(),
                                    itemCount:
                                        _cacheService.cachedPosts.length +
                                        (_cacheService.hasMorePosts ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      // Show loading indicator at the end
                                      if (index ==
                                          _cacheService.cachedPosts.length) {
                                        return const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: kPrimaryAccentColor,
                                            ),
                                          ),
                                        );
                                      }

                                      final postDoc =
                                          _cacheService.cachedPosts[index];
                                      final data =
                                          postDoc.data()
                                              as Map<String, dynamic>;
                                      final postId = postDoc.id;

                                      return PostCardWidget(
                                        key: ValueKey(postId),
                                        postData: data,
                                        postId: postId,
                                      );
                                    },
                                  ),
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
