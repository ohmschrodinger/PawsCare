import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/cupertino.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Color.fromARGB(255, 255, 193, 7);
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

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _userName = 'User';
        _uid = null;
      });
      return;
    }
    _uid = user.uid;
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      setState(() {
        _userName = user.displayName!.trim();
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      final candidate = data == null
          ? null
          : (data['fullName'] ?? data['name'] ?? data['displayName']);
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        setState(() {
          _userName = candidate.toString().trim();
        });
      } else {
        setState(() {
          _userName = 'User ${user.uid.substring(user.uid.length - 4)}';
        });
      }
    } catch (_) {
      setState(() {
        _userName = 'User ${user.uid.substring(user.uid.length - 4)}';
      });
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

    // Re-resolve name immediately before posting (ensures we have best value)
    await _fetchUserName();

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
        'author': _userName,
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
          backgroundColor: const Color.fromARGB(82, 7, 85, 255).withOpacity(0.2),
          child: Text(
            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
            style: const TextStyle(
                color: Color.fromARGB(149, 7, 168, 255), fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Share your story as $_userName',
            style: const TextStyle(color: kSecondaryTextColor),
          ),
        ),
        // small logo icon instead of generic icon:
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Posting as $_userName",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
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
        // === UPDATED TEXTFIELD: dark filled appearance ===
        TextField(
          controller: _storyController,
          autofocus: true,
          maxLines: 5,
          minLines: 2,
          maxLength: 3000,
          style: const TextStyle(color: kPrimaryTextColor),
          keyboardType: TextInputType.multiline,
          cursorColor: kPrimaryAccentColor,
          decoration: InputDecoration(
            hintText: 'What’s on your mind?',
            hintStyle: const TextStyle(color: kSecondaryTextColor),
            filled: true,
            fillColor: kCardColor, // matches card and dark theme
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            counterText: "",
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color.fromARGB(172, 255, 193, 7).withOpacity(0.6), width: 1.2),
            ),
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
                      icon: const Icon(Icons.close, color: Colors.white, size: 14),
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

            // === POST LOGO BUTTON (replace text button) ===
            // OPTION A: Simple built-in icon (no extra dependency)
// === POST LOGO BUTTON (Cupertino style) ===
GestureDetector(
  onTap: _isUploading ? null : _postStory,
  child: Container(
    width: 35,
    height: 35,
    decoration: BoxDecoration(
      color: kCardColor, // dark background, same as cards
      shape: BoxShape.circle,
      border: Border.all(color: kPrimaryAccentColor.withOpacity(0.8), width: 1.2),
    ),
    child: _isUploading
        ? const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color.fromARGB(181, 255, 193, 7),
              ),
            ),
          )
        : const Icon(
            CupertinoIcons.paperplane_fill,
            color: Color.fromARGB(188, 255, 193, 7),
            size: 18,
          ),
  ),
),
          ],
        ),
      ],
    );
  }
}
