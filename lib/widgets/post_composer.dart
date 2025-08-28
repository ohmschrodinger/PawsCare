import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

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
  final List<String> _categories = ['Success Story', 'Concern', 'Question', 'General'];
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
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _postStory() async {
    final text = _storyController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something to post.')),
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
        const SnackBar(
          content: Text('Post shared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _clearAndCollapse();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting: $e'), backgroundColor: Colors.red),
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
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
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
        CircleAvatar(child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'A')),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Share your story...',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
      ],
    );
  }

  Widget _buildExpandedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Posting as $_userName",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearAndCollapse,
              tooltip: 'Close',
            ),
          ],
        ),
        const Divider(),
        TextField(
          controller: _storyController,
          autofocus: true,
          maxLines: null,
          minLines: 2,
          maxLength: 300,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration.collapsed(
            hintText: 'What’s on your mind?',
          ),
        ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _selectedImage!,
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6.0,
          runSpacing: 3.0,
          children: _categories.map((category) {
            final selected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(category),
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
              selected: selected,
              onSelected: (s) {
                if (s) setState(() => _selectedCategory = category);
              },
              selectedColor: const Color(0xFF5AC8F2),
              backgroundColor: Colors.grey[200],
              showCheckmark: false,
            );
          }).toList(),
        ),
        const Divider(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_camera_outlined),
                  onPressed: () => _pickImage(ImageSource.camera),
                  color: Colors.grey[600],
                  tooltip: 'Camera',
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  color: Colors.grey[600],
                  tooltip: 'Gallery',
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _isUploading ? null : _postStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5AC8F2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post'),
            ),
          ],
        ),
      ],
    );
  }
}
