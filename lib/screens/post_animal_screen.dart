// screens/post_animal_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/services/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../widgets/paws_care_app_bar.dart';
import '../main_navigation_screen.dart';

// --- THEME CONSTANTS FOR A CLEAN UI ---
const Color kPrimaryColor = Colors.black;
const Color kSecondaryColor = Color(0xFF616161); // Dark grey
const Color kBackgroundColor = Color(0xFFF5F5F5); // Light grey background
const Color kCardColor = Colors.white;

class PostAnimalScreen extends StatefulWidget {
  final bool showAppBar;
  final int initialTab;
  const PostAnimalScreen({
    Key? key,
    this.initialTab = 0,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<PostAnimalScreen> createState() => _PostAnimalScreenState();
}

class _PostAnimalScreenState extends State<PostAnimalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // --- FORM CONTROLLERS ---
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _rescueStoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _medicalIssuesController = TextEditingController();

  // --- FORM STATE VARIABLES ---
  String? _species;
  String? _gender;
  String? _breedType; // "Indie" or "Specific Breed"
  String? _motherStatus; // Added for mother status
  bool? _isSterilized;
  bool? _isVaccinated;
  bool? _isDewormed;
  // REMOVED: Behavior and temperament state variables are no longer needed.

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
    _breedController.dispose();
    _ageController.dispose();
    _rescueStoryController.dispose();
    _locationController.dispose();
    _contactPhoneController.dispose();
    _medicalIssuesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 5) {
      _showSnackBar('You can upload a maximum of 5 photos.', isError: true);
      return;
    }
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1080,
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
      backgroundColor: kBackgroundColor,
      appBar: buildPawsCareAppBar(
        context: context,
        onLogout: _logout,
        onMenuSelected: (value) {
          if (value == 'profile') {
            if (mainNavKey.currentState != null) {
              mainNavKey.currentState!.selectTab(4);
            } else {
              Navigator.of(context).pushNamed('/main');
            }
          } else if (value == 'all_applications') {
            Navigator.of(context).pushNamed('/all-applications');
          } else if (value == 'my_applications') {
            Navigator.of(context).pushNamed('/my-applications');
          }
        },
      ),
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

  Widget _buildTabBar() {
    return Material(
      color: kCardColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: kPrimaryColor,
        labelColor: kPrimaryColor,
        unselectedLabelColor: kSecondaryColor,
        tabs: const [
          Tab(icon: Icon(Icons.pending_actions), text: 'Pending Requests'),
          Tab(icon: Icon(Icons.add_circle_outline), text: 'Add New Animal'),
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
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, roleSnapshot) {
            String role = (roleSnapshot.data?.get('role') ?? 'user');

            final allAnimals = snapshot.data?.docs ?? [];

            // Debug: Print all pending animals
            print('DEBUG: Found ${allAnimals.length} total pending animals');
            for (var doc in allAnimals) {
              final data = doc.data() as Map<String, dynamic>;
              print(
                'DEBUG: Animal: ${data['name']} - Posted by: ${data['postedByEmail']}',
              );
            }
            print('DEBUG: Current user email: ${user.email}');

            List<DocumentSnapshot> animals = (role == 'admin')
                ? allAnimals
                : allAnimals.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final matches = data['postedByEmail'] == user.email;
                    print(
                      'DEBUG: Checking ${data['name']} - Posted by ${data['postedByEmail']} - Matches current user? $matches',
                    );
                    return matches;
                  }).toList();

            print(
              'DEBUG: After filtering, found ${animals.length} animals for current user',
            );

            if (animals.isEmpty) {
              return const Center(
                child: Text(
                  'No pending requests for now',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add a New Friend',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your submission will be reviewed by an admin before going live.',
              style: TextStyle(fontSize: 14, color: kSecondaryColor),
            ),
            const SizedBox(height: 24),

            _buildFormSection(
              title: 'Basic Information',
              children: [
                _buildTextField(
                  _nameController,
                  'Name*',
                  'e.g., Bruno, Kitty',
                  validator: (v) => v!.isEmpty ? "Name is required" : null,
                ),
                _buildChoiceChipQuestion(
                  question: 'Species*',
                  options: ['Dog', 'Cat', 'Other'],
                  selectedValue: _species,
                  onSelected: (val) => setState(() => _species = val),
                ),
                if (_species == 'Other')
                  _buildTextField(
                    _breedController,
                    'Species Name*',
                    'e.g., Rabbit , Cow',
                    validator: (v) => v!.isEmpty ? "Species is required" : null,
                  ),
                _buildChoiceChipQuestion(
                  question: 'Is this a specific breed or an Indie?*',
                  options: ['Indie', 'Specific Breed'],
                  selectedValue: _breedType,
                  onSelected: (val) => setState(() => _breedType = val),
                ),
                if (_breedType == 'Specific Breed')
                  _buildTextField(
                    _breedController,
                    'Breed Name*',
                    'e.g., Labrador, Persian',
                    validator: (v) => v!.isEmpty ? "Breed is required" : null,
                  ),
                _buildTextField(
                  _ageController,
                  'Age*',
                  'e.g., 2 years, 5 months',
                  validator: (v) => v!.isEmpty ? "Age is required" : null,
                ),
                _buildChoiceChipQuestion(
                  question: 'Gender*',
                  options: ['Male', 'Female'],
                  selectedValue: _gender,
                  onSelected: (val) => setState(() => _gender = val),
                ),
                // Added Mother Status field
                _buildChoiceChipQuestion(
                  question: 'Mother Status',
                  options: ['Known', 'Unknown'],
                  selectedValue: _motherStatus,
                  onSelected: (val) => setState(() => _motherStatus = val),
                ),
              ],
            ),

            _buildFormSection(
              title: 'Health & Wellness',
              children: [
                _buildBinaryQuestion(
                  'Is the animal sterilized (neutered/spayed)?*',
                  _isSterilized,
                  (val) => setState(() => _isSterilized = val),
                ),
                _buildBinaryQuestion(
                  'Are vaccinations up to date?*',
                  _isVaccinated,
                  (val) => setState(() => _isVaccinated = val),
                ),
                _buildBinaryQuestion(
                  'Has the animal been dewormed recently?*',
                  _isDewormed,
                  (val) => setState(() => _isDewormed = val),
                ),
                _buildTextField(
                  _medicalIssuesController,
                  'Known Medical Issues',
                  'e.g., Skin allergy, missing a limb. Write "None" if not applicable.',
                ),
              ],
            ),

            // REMOVED: The "Behavior & Temperament" section has been removed as requested.
            _buildFormSection(
              title: 'Location, Contact & Story',
              children: [
                _buildTextField(
                  _locationController,
                  'Location of Animal*',
                  'e.g., Koregaon Park, Pune',
                  validator: (v) => v!.isEmpty ? "Location is required" : null,
                ),
                _buildTextField(
                  _contactPhoneController,
                  'Your Contact Number*',
                  'Adopters will contact this number',
                  isPhoneNumber: true,
                  validator: (v) {
                    if (v!.isEmpty) return "Phone number is required";
                    if (v.length != 10)
                      return "Please enter a valid 10-digit number";
                    return null;
                  },
                ),
                _buildTextField(
                  _rescueStoryController,
                  'Rescue Story / About the Animal',
                  'Share their story...',
                  maxLines: 5,
                ),
              ],
            ),

            _buildFormSection(
              title: 'Photos*',
              children: [
                _buildImagePicker(),
                if (_images.isEmpty && _isSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'At least one photo is required.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Submit for Review',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: kCardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    FormFieldValidator<String>? validator,
    int maxLines = 1,
    bool isPhoneNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isPhoneNumber ? TextInputType.phone : TextInputType.text,
        inputFormatters: isPhoneNumber
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
            : [],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: isPhoneNumber
              ? const Padding(padding: EdgeInsets.all(12.0), child: Text('+91'))
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kPrimaryColor, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildChoiceChipQuestion({
    required String question,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 16, color: kSecondaryColor),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: options.map((option) {
              final isSelected = selectedValue == option;
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) => onSelected(option),
                selectedColor: kPrimaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : kPrimaryColor,
                ),
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBinaryQuestion(
    String question,
    bool? value,
    ValueChanged<bool> onChanged,
  ) {
    return _buildChoiceChipQuestion(
      question: question,
      options: ['Yes', 'No'],
      selectedValue: value == null ? null : (value ? 'Yes' : 'No'),
      onSelected: (val) => onChanged(val == 'Yes'),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_images.length, (index) {
              return Stack(
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
                    top: -4,
                    right: -4,
                    child: IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        radius: 12,
                        child: Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                      onPressed: () => _removeImage(index),
                    ),
                  ),
                ],
              );
            }),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _images.length < 5
                  ? () => _pickImage(ImageSource.gallery)
                  : null,
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
              style: OutlinedButton.styleFrom(foregroundColor: kPrimaryColor),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _images.length < 5
                  ? () => _pickImage(ImageSource.camera)
                  : null,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
              style: OutlinedButton.styleFrom(foregroundColor: kPrimaryColor),
            ),
          ],
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() {});
    if (!_formKey.currentState!.validate() || _images.isEmpty) {
      _showSnackBar(
        'Please fill all required fields (*) and add at least one photo.',
        isError: true,
      );
      return;
    }

    // Debug: Print current user info
    final user = FirebaseAuth.instance.currentUser;
    print('DEBUG: Submitting form for user: ${user?.email}');

    // Debug: Check user role
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      print('DEBUG: User document exists: ${userDoc.exists}');
      if (userDoc.exists) {
        print('DEBUG: User data: ${userDoc.data()}');
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // We don't need to get the user here as the service handles it

      // Use the service method to create the animal
      final animalDoc = await AnimalService.postAnimal(
        name: _nameController.text.trim(),
        species: _species!,
        breedType: _breedType!,
        breed: _breedType == 'Indie' ? 'Indie' : _breedController.text.trim(),
        age: _ageController.text.trim(),
        gender: _gender!,
        sterilization: _isSterilized! ? 'Yes' : 'No',
        vaccination: _isVaccinated! ? 'Yes' : 'No',
        deworming: _isDewormed! ? 'Yes' : 'No',
        motherStatus: _motherStatus ?? 'Unknown',
        medicalIssues: _medicalIssuesController.text.trim(),
        location: _locationController.text.trim(),
        contactPhone: '+91${_contactPhoneController.text.trim()}',
        rescueStory: _rescueStoryController.text.trim(),
      );
      final animalId = animalDoc.id;

      List<String> imageUrls = [];
      for (int i = 0; i < _images.length; i++) {
        final url = await StorageService.uploadAnimalImage(
          File(_images[i].path),
          animalId,
          i,
        );
        imageUrls.add(url);
      }

      await animalDoc.update({'imageUrls': imageUrls});

      if (mounted) {
        _showSnackBar('Animal submitted for review!', isError: false);
        _formKey.currentState!.reset();
        _nameController.clear();
        _breedController.clear();
        _ageController.clear();
        _rescueStoryController.clear();
        _locationController.clear();
        _contactPhoneController.clear();
        _medicalIssuesController.clear();
        setState(() {
          _images.clear();
          _species = null;
          _gender = null;
          _breedType = null;
          _motherStatus = null;
          _isSterilized = null;
          _isVaccinated = null;
          _isDewormed = null;
          // REMOVED: Resetting behavior state variables is no longer needed.
          _tabController.animateTo(0);
        });
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
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
                          itemBuilder: (context, index) => Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.error, color: kSecondaryColor),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.pets,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                        ),
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
                            color: Colors.white.withOpacity(
                              _currentPage == i ? 0.9 : 0.6,
                            ),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Posted by: ${widget.animalData['postedByEmail'] ?? 'Unknown'} on $postedDate',
                  style: const TextStyle(fontSize: 14, color: kSecondaryColor),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDetailsDialog(context),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.isAdmin) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: () =>
                              _showApproveDialog(context, widget.animalId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: () =>
                              _showRejectDialog(context, widget.animalId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, String animalId) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Animal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will make the animal visible for adoption.'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Optional Message',
                hintText: 'Add any notes or comments (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await AnimalService.approveAnimal(
                  animalId: animalId,
                  adminMessage: messageController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Animal post approved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error approving animal: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Approve'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.animalData['name'] ?? 'Animal Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Species', widget.animalData['species']),
              _buildDetailItem('Breed', widget.animalData['breed']),
              _buildDetailItem('Age', widget.animalData['age']),
              _buildDetailItem('Gender', widget.animalData['gender']),
              _buildDetailItem(
                'Mother Status',
                widget.animalData['motherStatus'],
              ),
              _buildDetailItem(
                'Sterilization',
                widget.animalData['sterilization'],
              ),
              _buildDetailItem('Vaccination', widget.animalData['vaccination']),
              _buildDetailItem('Deworming', widget.animalData['deworming']),
              _buildDetailItem('Location', widget.animalData['location']),
              _buildDetailItem('Contact', widget.animalData['contactPhone']),
              if (widget.animalData['medicalIssues']?.isNotEmpty ?? false)
                _buildDetailItem(
                  'Medical Issues',
                  widget.animalData['medicalIssues'],
                ),
              if (widget.animalData['rescueStory']?.isNotEmpty ?? false) ...[
                const Divider(height: 24),
                const Text(
                  'Rescue Story',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(widget.animalData['rescueStory'] ?? ''),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kSecondaryColor,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejection. This will be visible to the person who posted the animal.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection *',
                hintText: 'Explain why this post is being rejected',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await AnimalService.rejectAnimal(
                  animalId: animalId,
                  adminMessage: messageController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Animal post rejected'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error rejecting animal: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Reject'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
