import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -----------------------------------------

class PostComposer extends StatefulWidget {
  const PostComposer({Key? key}) : super(key: key);

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
    'General'
  ];
  String _userName = 'Anonymous';

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

  void _fetchUserName() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName;
    if (name != null && name.trim().isNotEmpty) {
      _userName = name.trim();
    }
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
    // Functionality remains the same
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
            backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _postStory() async {
    // Functionality remains the same
    final text = _storyController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please write something to post.'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() => _isUploading = true);
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

      await FirebaseFirestore.instance.collection('community_posts').add({
        'author': _userName,
        'story': text,
        'imageUrl': imageUrl,
        'category': _selectedCategory,
        'postedAt': FieldValue.serverTimestamp(),
        'likes': <String>[],
        'commentCount': 0,
        'userId': FirebaseAuth.instance.currentUser?.uid,
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
            backgroundColor: Colors.redAccent),
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
      child: Card(
        color: kCardColor,
        margin: const EdgeInsets.all(0),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              if (!_isExpanded) setState(() => _isExpanded = true);
            },
            child: _isExpanded ? _buildExpandedView() : _buildCollapsedView(),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedView() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: kPrimaryAccentColor.withOpacity(0.2),
          child: Text(
            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
            style: const TextStyle(
                color: kPrimaryAccentColor, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Share your story...',
            style: TextStyle(color: kSecondaryTextColor),
          ),
        ),
        const Icon(Icons.add_photo_alternate_outlined,
            color: kSecondaryTextColor),
      ],
    );
  }

  Widget _buildExpandedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Posting as $_userName",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryTextColor),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: kSecondaryTextColor),
              onPressed: _clearAndCollapse,
              tooltip: 'Close',
            ),
          ],
        ),
        const Divider(color: kBackgroundColor),
        TextField(
          controller: _storyController,
          autofocus: true,
          maxLines: 5,
          minLines: 2,
          maxLength: 3000,
          style: const TextStyle(color: kPrimaryTextColor),
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: 'What’s on your mind?',
            hintStyle: TextStyle(color: kSecondaryTextColor),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            counterText: "",
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
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 14),
                      onPressed: () => setState(() => _selectedImage = null),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _categories.map((category) {
            final selected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(category),
              labelStyle: TextStyle(
                color: selected ? Colors.black : kPrimaryTextColor,
                fontWeight: FontWeight.w600,
              ),
              selected: selected,
              onSelected: (s) {
                if (s) setState(() => _selectedCategory = category);
              },
              selectedColor: kPrimaryAccentColor,
              backgroundColor: Colors.grey.shade800,
              showCheckmark: false,
              side: BorderSide.none,
            );
          }).toList(),
        ),
        const Divider(height: 24, color: kBackgroundColor),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_camera_outlined),
                  onPressed: () => _pickImage(ImageSource.camera),
                  color: kSecondaryTextColor,
                  tooltip: 'Camera',
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  color: kSecondaryTextColor,
                  tooltip: 'Gallery',
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _isUploading ? null : _postStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryAccentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Post',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}