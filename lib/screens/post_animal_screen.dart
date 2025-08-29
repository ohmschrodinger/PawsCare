// screens/post_animal_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/services/storage_service.dart';
import 'package:pawscare/utils/constants.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PostAnimalScreen extends StatefulWidget {
  final bool showAppBar;
  final int initialTab;
  const PostAnimalScreen(
      {Key? key, this.initialTab = 0, this.showAppBar = true})
      : super(key: key);

  @override
  State<PostAnimalScreen> createState() => _PostAnimalScreenState();
}

class _PostAnimalScreenState extends State<PostAnimalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _sterilizationController = TextEditingController();
  final _vaccinationController = TextEditingController();
  final _rescueStoryController = TextEditingController();
  final _motherStatusController = TextEditingController();
  final _otherSpeciesController = TextEditingController();

  // Form state
  String _selectedGender = 'Male';
  String _selectedSterilization = 'Yes';
  String _selectedVaccination = 'Yes';
  String _selectedMotherStatus = 'Unknown';
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _speciesController.dispose();
    _otherSpeciesController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _sterilizationController.dispose();
    _vaccinationController.dispose();
    _rescueStoryController.dispose();
    _motherStatusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 4) return;
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _images.add(pickedFile);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? _buildAppBar() : null,
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPendingRequestsTab(), _buildAddNewAnimalTab()],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appBarColor =
        isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey.shade50;
    final appBarTextColor = theme.textTheme.titleLarge?.color;

    return AppBar(
      systemOverlayStyle:
          isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      backgroundColor: appBarColor,
      elevation: 0,
      title: Text(
        'PawsCare',
        style: TextStyle(
          color: appBarTextColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(Icons.chat_bubble_outline, color: appBarTextColor),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chat feature coming soon!')),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.notifications_none, color: appBarTextColor),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.account_circle, color: appBarTextColor),
          onSelected: (value) {
            if (value == 'logout') _logout();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Theme.of(context).primaryColor,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        tabs: const [
          Tab(icon: Icon(Icons.pending_actions), text: 'Pending Requests'),
          Tab(icon: Icon(Icons.add_circle), text: 'Add New Animal'),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please log in to view pending requests'),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: AnimalService.getPendingAnimals(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, roleSnapshot) {
            String role = 'user';
            if (roleSnapshot.connectionState == ConnectionState.done &&
                roleSnapshot.hasData) {
              role = roleSnapshot.data?.data() != null
                  ? (roleSnapshot.data!.get('role') ?? 'user')
                  : 'user';
            }

            final allAnimals = snapshot.data?.docs ?? [];
            List<DocumentSnapshot> animals;
            if (role == 'admin') {
              animals = allAnimals;
            } else {
              animals = allAnimals
                  .where((doc) =>
                      (doc.data() as Map<String, dynamic>)['postedByEmail'] ==
                      user.email)
                  .toList();
            }

            return animals.isEmpty
                ? Center(
                    child: Text(
                      'No pending requests for now',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animalData =
                          animals[index].data() as Map<String, dynamic>;
                      final animalId = animals[index].id;
                      return _PendingAnimalCard(
                        animalData: animalData,
                        animalId: animalId,
                        isAdmin: role == 'admin',
                      );
                    },
                  );
          },
        );
      },
    );
  }

  Widget _buildAddNewAnimalTab() {
    // This form tab remains unchanged as it is already well-structured.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5AC8F2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5AC8F2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.pets, size: 48, color: const Color(0xFF5AC8F2)),
                  const SizedBox(height: 8),
                  Text(
                    'Add New Animal for Adoption',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5AC8F2),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill out the form below. Your post will be reviewed by an admin before it goes live.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Animal Name *'),
              validator: (v) =>
                  v!.isEmpty ? "Name is required" : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _speciesController.text.isNotEmpty
                  ? _speciesController.text
                  : null,
              decoration: const InputDecoration(labelText: 'Species *'),
              items: AppConstants.speciesOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _speciesController.text = v!),
              validator: (v) => v == null ? "Species is required" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Age *'),
              validator: (v) => v!.isEmpty ? "Age is required" : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Gender *'),
              items: ['Male', 'Female']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedGender = v!),
            ),
            const SizedBox(height: 16),
            // ... Other form fields remain the same
            Text(
              'Upload Photos (1-4 required)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _images.length < 4
                      ? () => _pickImage(ImageSource.gallery)
                      : null,
                  icon: Icon(Icons.photo_library),
                  label: Text('Gallery'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _images.length < 4
                      ? () => _pickImage(ImageSource.camera)
                      : null,
                  icon: Icon(Icons.camera_alt),
                  label: Text('Camera'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _images.isEmpty
                ? Text('No images selected.', style: TextStyle(color: Colors.red))
                : SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      itemBuilder: (context, index) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_images[index].path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5AC8F2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : const Text('Post Animal', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and add photos.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final animalDoc =
          await FirebaseFirestore.instance.collection('animals').add({
        'name': _nameController.text.trim(),
        'species': _speciesController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _selectedGender,
        'sterilization': _selectedSterilization,
        'vaccination': _selectedVaccination,
        'rescueStory': _rescueStoryController.text.trim(),
        'motherStatus': _selectedMotherStatus,
        'postedBy': user.uid,
        'postedByEmail': user.email,
        'postedAt': FieldValue.serverTimestamp(),
        'approvalStatus': 'pending',
        'imageUrls': [],
      });
      final animalId = animalDoc.id;

      List<String> imageUrls = [];
      for (int i = 0; i < _images.length; i++) {
        final url = await StorageService.uploadAnimalImage(
            File(_images[i].path), animalId, i);
        imageUrls.add(url);
      }

      await animalDoc.update({'imageUrls': imageUrls});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Animal posted for review!'),
              backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _nameController.clear();
        _speciesController.clear();
        _ageController.clear();
        _rescueStoryController.clear();
        setState(() {
          _images.clear();
          _tabController.animateTo(0);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

// A new styled card for pending animal requests
class _PendingAnimalCard extends StatefulWidget {
  final Map<String, dynamic> animalData;
  final String animalId;
  final bool isAdmin;

  const _PendingAnimalCard({
    required this.animalData,
    required this.animalId,
    required this.isAdmin,
  });

  @override
  State<_PendingAnimalCard> createState() => __PendingAnimalCardState();
}

class __PendingAnimalCardState extends State<_PendingAnimalCard> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls =
        (widget.animalData['imageUrls'] as List?)?.cast<String>() ?? [];
    final hasImages = imageUrls.isNotEmpty;

    final postedAt = widget.animalData['postedAt'] as Timestamp?;
    final postedDate = postedAt != null
        ? DateFormat('MMM d, yyyy').format(postedAt.toDate())
        : 'N/A';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: hasImages
                      ? PageView.builder(
                          controller: _pageController,
                          itemCount: imageUrls.length,
                          onPageChanged: (index) =>
                              setState(() => _currentPage = index),
                          itemBuilder: (context, index) {
                            return Image.network(
                              imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.error),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.pets,
                              size: 60, color: Colors.grey.shade400)),
                ),
                if (imageUrls.length > 1)
                  Positioned(
                    bottom: 10.0,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imageUrls.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3.0),
                          height: 8.0,
                          width: _currentPage == i ? 24.0 : 8.0,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(_currentPage == i ? 0.9 : 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.animalData['name'] ?? 'No Name',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Posted by: ${widget.animalData['postedByEmail'] ?? 'Unknown'} on $postedDate',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const Divider(height: 24),
                if (widget.isAdmin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showApproveDialog(context, widget.animalId),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showRejectDialog(context, widget.animalId),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, String animalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Animal'),
        content: const Text('This will make the animal visible for adoption.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await AnimalService.approveAnimal(animalId: animalId);
              Navigator.pop(context);
            },
            child: const Text('Approve'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String animalId) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Animal'),
        content: TextField(
          controller: messageController,
          decoration:
              const InputDecoration(labelText: 'Reason for Rejection *'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isEmpty) return;
              await AnimalService.rejectAnimal(
                  animalId: animalId,
                  adminMessage: messageController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Reject'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
