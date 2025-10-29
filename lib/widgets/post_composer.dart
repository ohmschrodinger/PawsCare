import 'dart:ui'; // Added for ImageFilter
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import '../services/current_user_cache.dart';
import '../constants/app_colors.dart';

class PostComposer extends StatefulWidget {
  const PostComposer({super.key});

  @override
  State<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> {
  final _storyController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isUploading = false;
  bool _isExpanded = false;

  String _selectedCategory = 'General';
  final List<String> _categories = [
    'Success Story',
    'Concern',
    'Question',
    'General',
  ];

  String _userName = 'User';
  String? _uid;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  @override
  void dispose() {
    _storyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _userName = 'User';
        _uid = null;
      });
      return 'User';
    }
    _uid = user.uid;

    // Use the cached user service to get the display name
    final name = await CurrentUserCache().refreshDisplayName();
    setState(() {
      _userName = name;
    });
    return name;
  }

  void _clearAndCollapse() {
    _storyController.clear();
    setState(() {
      _selectedImage = null;
      _isExpanded = false;
      _isUploading = false;
      _selectedCategory = 'General';
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1440,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _postStory() async {
    final text = _storyController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something to post.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _isUploading = true);

    final authorName = await _fetchUserName();

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('community_posts')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = await storageRef.putFile(_selectedImage!);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance.collection('community_posts').add({
        'author': authorName,
        'story': text,
        'imageUrl': imageUrl,
        'category': _selectedCategory,
        'postedAt': FieldValue.serverTimestamp(),
        'likes': <String>[],
        'commentCount': 0,
        'userId': uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post shared successfully!'),
          backgroundColor: Colors.green.shade800,
        ),
      );
      _clearAndCollapse();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: kCardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  if (!_isExpanded) setState(() => _isExpanded = true);
                },
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? _buildExpandedView()
                      : _buildCollapsedView(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedView() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: kAvatarAccentColor.withOpacity(0.2),
          child: Text(
            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: kAvatarAccentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Share your story as $_userName',
            style: const TextStyle(color: kSecondaryTextColor),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kPrimaryAccentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.send, color: kPrimaryAccentColor, size: 18),
        ),
      ],
    );
  }

  Widget _buildExpandedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- MODIFICATION: Header with Profile Picture and Name ---
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kAvatarAccentColor.withOpacity(0.2),
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: kAvatarAccentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryTextColor,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: kSecondaryTextColor),
              onPressed: _clearAndCollapse,
              tooltip: 'Close',
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _storyController,
          autofocus: true,
          maxLines: 5,
          minLines: 2,
          maxLength: 3000,
          style: const TextStyle(color: kPrimaryTextColor),
          keyboardType: TextInputType.multiline,
          cursorColor: kSuccessGreenColor, // Match the new theme color
          decoration: InputDecoration(
            hintText: 'What’s on your mind?',
            hintStyle: const TextStyle(color: kSecondaryTextColor),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),

            // --- MODIFICATION: Removed yellow border for a neutral one ---
          ),
        ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _selectedImage!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                      onPressed: () => setState(() => _selectedImage = null),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        // --- MODIFICATION: Category-specific Glassmorphic Chips ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((category) {
              final selected = _selectedCategory == category;

              // Category-specific colors
              Color categoryColor;
              switch (category) {
                case 'Success Story':
                  categoryColor = kFilterSuccessColor;
                  break;
                case 'Concern':
                  categoryColor = kFilterConcernColor;
                  break;
                case 'Question':
                  categoryColor = kFilterQuestionColor;
                  break;
                case 'General':
                default:
                  categoryColor = kFilterGeneralColor;
                  break;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? categoryColor.withOpacity(0.3)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: selected
                              ? categoryColor.withOpacity(0.6)
                              : Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedCategory = category),
                          borderRadius: BorderRadius.circular(20.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              category,
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
        Divider(height: 24, color: Colors.white.withOpacity(0.1)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => _pickImage(ImageSource.camera),
                  color: kCameraButtonColor,
                  tooltip: 'Camera',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  color: kGalleryButtonColor,
                  tooltip: 'Gallery',
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(50.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: kPostButtonColor.withOpacity(0.2), // Medium Blue
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(
                      color: kPostButtonColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPostButtonColor.withOpacity(0.2),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isUploading ? null : _postStory,
                      borderRadius: BorderRadius.circular(50.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.paperplane_fill,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Post',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
