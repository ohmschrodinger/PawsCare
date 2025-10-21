import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/services/logging_service.dart';
import 'package:pawscare/services/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pawscare/screens/view_details_screen.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -----------------------------------------

class PostAnimalScreen extends StatefulWidget {
  final bool showAppBar;
  final int initialTab;
  const PostAnimalScreen({
    super.key,
    this.initialTab = 0,
    this.showAppBar = true,
  });

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
  // replaced single age controller with two controllers for years and months
  final _ageYearsController = TextEditingController();
  final _ageMonthsController = TextEditingController();
  // dropdown selected values to drive UI while keeping controllers for existing logic
  int? _selectedAgeYears;
  int? _selectedAgeMonths;
  final _rescueStoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _medicalIssuesController = TextEditingController();

  // --- FORM STATE VARIABLES ---
  String? _species;
  String? _gender;
  String? _breedType;
  String? _motherStatus;
  bool? _isSterilized;
  bool? _isVaccinated;
  bool? _isDewormed;

  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

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
    _ageYearsController.dispose();
    _ageMonthsController.dispose();
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

  // --- 👇 UI CHANGES START HERE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'New Post',
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
      color: kBackgroundColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: kPrimaryAccentColor,
        labelColor: kPrimaryTextColor, // ensure labels are white
        unselectedLabelColor: kPrimaryTextColor,
        tabs: const [
          Tab(icon: Icon(Icons.pending_actions), text: 'Pending Requests'),
          Tab(icon: Icon(Icons.add_circle_outline), text: 'Post New Animal'),
        ],
      ),
    );
  }

  Widget _buildAddNewAnimalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Post a new pet',
              style: TextStyle(
                fontSize: 22, // changed from 28 to 22
                fontWeight: FontWeight.bold,
                color: kPrimaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your submission will be reviewed by an admin before going live.',
              style: TextStyle(fontSize: 14, color: kPrimaryTextColor),
            ),
            const SizedBox(height: 16),

            // --- Basic Information Section ---
            _buildSectionHeader('Basic Information'),
            _buildTextField(
              _nameController,
              'Name*',
              'e.g., Bruno, Kitty',
              validator: (v) => v!.isEmpty ? "Name is required" : null,
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildChoiceChipQuestion(
              question: 'Species*',
              options: ['Dog', 'Cat', 'Other'],
              selectedValue: _species,
              onSelected: (val) => setState(() => _species = val),
            ),
            if (_species == 'Other') ...[
              const Divider(color: Colors.white12, height: 1),
              _buildTextField(
                _breedController,
                'Species Name*',
                'e.g., Rabbit, Cow',
                validator: (v) => v!.isEmpty ? "Species is required" : null,
              ),
            ],
            const Divider(color: Colors.white12, height: 1),
            _buildChoiceChipQuestion(
              question: 'Breed Type*',
              options: ['Indie', 'Specific'],
              selectedValue: _breedType,
              onSelected: (val) => setState(() => _breedType = val),
            ),
            if (_breedType == 'Specific') ...[
              const Divider(color: Colors.white12, height: 1),
              _buildTextField(
                _breedController,
                'Breed Name*',
                'e.g., Labrador, Persian',
                validator: (v) => v!.isEmpty ? "Breed is required" : null,
              ),
            ],
            const Divider(color: Colors.white12, height: 1),

            // --- Age field (custom) ---
            _buildAgeField(),

            const Divider(color: Colors.white12, height: 1),
            _buildChoiceChipQuestion(
              question: 'Gender*',
              options: ['Male', 'Female'],
              selectedValue: _gender,
              onSelected: (val) => setState(() => _gender = val),
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildChoiceChipQuestion(
              question: 'Mother Status',
              options: ['Known', 'Unknown'],
              selectedValue: _motherStatus,
              onSelected: (val) => setState(() => _motherStatus = val),
            ),

            // --- Health & Wellness Section ---
            _buildSectionHeader('Health & Wellness'),
            _buildBinaryQuestion(
              'Sterilized (Neutered/Spayed)?*',
              _isSterilized,
              (val) => setState(() => _isSterilized = val),
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildBinaryQuestion(
              'Vaccinations up to date?*',
              _isVaccinated,
              (val) => setState(() => _isVaccinated = val),
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildBinaryQuestion(
              'Dewormed recently?*',
              _isDewormed,
              (val) => setState(() => _isDewormed = val),
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildTextField(
              _medicalIssuesController,
              'Known Medical Issues',
              'e.g., Skin allergy. Write "None" if not applicable.',
            ),

            // --- Location, Contact & Story Section ---
            _buildSectionHeader('Location, Contact & Story'),
            _buildTextField(
              _locationController,
              'Location of Animal*',
              'e.g., Koregaon Park, Pune',
              validator: (v) => v!.isEmpty ? "Location is required" : null,
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildTextField(
              _contactPhoneController,
              'Your Contact Number*',
              'Adopters will contact this number',
              isPhoneNumber: true,
              validator: (v) {
                if (v!.isEmpty) return "Phone number is required";
                if (v.length != 10) {
                  return "Please enter a valid 10-digit number";
                }
                return null;
              },
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildTextField(
              _rescueStoryController,
              'Rescue Story / About the Animal',
              'Share their story...',
              maxLines: 5,
            ),

            // --- Photos Section ---
            _buildSectionHeader('Photos*'),
            const SizedBox(height: 8),
            _buildImagePicker(),
            if (_images.isEmpty && _isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  'At least one photo is required.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            const SizedBox(height: 32),
            ClipRRect(
              borderRadius: BorderRadius.circular(50.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
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
                      onTap: _isSubmitting ? null : _submitForm,
                      borderRadius: BorderRadius.circular(50.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit for Review',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100), // increased page height by 100px
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: kPrimaryTextColor, // turned to white
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
        style: const TextStyle(fontSize: 16, color: kPrimaryTextColor),
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
          labelStyle: const TextStyle(color: kPrimaryTextColor), // label white
          hintStyle: TextStyle(color: kPrimaryTextColor.withOpacity(0.7)),
          filled: true,
          fillColor: kCardColor,
          prefixIcon: isPhoneNumber
              ? const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    '+91',
                    style: TextStyle(color: kPrimaryTextColor, fontSize: 16),
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(
              color: kPrimaryAccentColor,
              width: 1.5,
            ),
          ),
          errorStyle: const TextStyle(color: Colors.redAccent),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 4.0,
      ),
      title: Text(
        question,
        style: const TextStyle(fontSize: 16, color: kPrimaryTextColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = selectedValue == option;
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: isSelected
                          ? Colors.amber.withOpacity(0.4)
                          : Colors.white.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelected(option),
                      borderRadius: BorderRadius.circular(20.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : kPrimaryTextColor,
                            fontWeight: isSelected
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

  // custom age input widget
  Widget _buildAgeField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Age: ',
                style: TextStyle(fontSize: 16, color: kPrimaryTextColor),
              ),
              SizedBox(
                width: 80,
                child: DropdownButtonFormField<int>(
                  value:
                      _selectedAgeYears ??
                      int.tryParse(_ageYearsController.text) ??
                      0,
                  isExpanded: true,
                  itemHeight: 48,
                  // show 5 items then allow scrolling
                  menuMaxHeight: 48 * 5 + 8,
                  items: List.generate(
                    16,
                    (i) =>
                        DropdownMenuItem(value: i, child: Text(i.toString())),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _selectedAgeYears = val;
                      _ageYearsController.text = val?.toString() ?? '';
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Year',
                    labelStyle: const TextStyle(color: kPrimaryTextColor),
                    filled: true,
                    fillColor: kCardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if ((_ageYearsController.text.isEmpty) &&
                        (_ageMonthsController.text.isEmpty)) {
                      return 'Enter age';
                    }
                    return null;
                  },
                  dropdownColor: kCardColor,
                  style: const TextStyle(color: kPrimaryTextColor),
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: DropdownButtonFormField<int>(
                  value:
                      _selectedAgeMonths ??
                      int.tryParse(_ageMonthsController.text),
                  isExpanded: true,
                  itemHeight: 48,
                  menuMaxHeight: 48 * 5 + 8,
                  items: List.generate(
                    13,
                    (i) =>
                        DropdownMenuItem(value: i, child: Text(i.toString())),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _selectedAgeMonths = val;
                      _ageMonthsController.text = val?.toString() ?? '';
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Month',
                    labelStyle: const TextStyle(color: kPrimaryTextColor),
                    filled: true,
                    fillColor: kCardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if ((_ageMonthsController.text.isEmpty) &&
                        (_ageYearsController.text.isEmpty)) {
                      return 'Enter age';
                    }
                    return null;
                  },
                  dropdownColor: kCardColor,
                  style: const TextStyle(color: kPrimaryTextColor),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  // --- 👆 UI CHANGES END HERE ---

  // All other methods (_buildImagePicker, _submitForm, _buildPendingRequestsTab, etc.) remain unchanged.
  // ... (Paste the rest of your unchanged code here)
  Widget _buildPendingRequestsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'Please log in to view pending requests',
          style: TextStyle(color: kPrimaryTextColor),
        ),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: AnimalService.getPendingAnimals(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryAccentColor),
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

            List<DocumentSnapshot> animals = (role == 'admin')
                ? allAnimals
                : allAnimals.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['postedByEmail'] == user.email;
                  }).toList();

            if (animals.isEmpty) {
              return const Center(
                child: Text(
                  'No pending requests for now',
                  style: TextStyle(fontSize: 18, color: kPrimaryTextColor),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(50.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _pickImage(ImageSource.camera),
                      borderRadius: BorderRadius.circular(50.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Camera',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(50.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _pickImage(ImageSource.gallery),
                      borderRadius: BorderRadius.circular(50.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.photo_library,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Gallery',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
            const Spacer(),
            if (_images.isNotEmpty) ...[
              Text(
                '${_images.length}/5 selected',
                style: const TextStyle(color: kPrimaryTextColor),
              ),
              IconButton(
                onPressed: () => setState(() => _images.clear()),
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade800,
      ),
    );
  }

  Future<void> _submitForm() async {
    // Logic unchanged
    setState(() {});
    if (!_formKey.currentState!.validate() || _images.isEmpty) {
      _showSnackBar(
        'Please fill all required fields (*) and add at least one photo.',
        isError: true,
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final years = _ageYearsController.text.trim();
      final months = _ageMonthsController.text.trim();
      final ageString =
          '${years.isEmpty ? '0' : years} Years, ${months.isEmpty ? '0' : months} Months';

      final animalDoc = await AnimalService.postAnimal(
        name: _nameController.text.trim(),
        species: _species!,
        breedType: _breedType!,
        breed: _breedType == 'Indie' ? 'Indie' : _breedController.text.trim(),
        age: ageString,
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
      // Log that the user posted an animal
      await LoggingService.logEvent(
        'animal_posted_client',
        data: {'animalId': animalId, 'name': _nameController.text.trim()},
      );
      if (mounted) {
        _showSnackBar('Animal submitted for review!', isError: false);
        _formKey.currentState!.reset();
        _nameController.clear();
        _breedController.clear();
        _ageYearsController.clear();
        _ageMonthsController.clear();
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
          _selectedAgeYears = null;
          _selectedAgeMonths = null;
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

// The _PendingAnimalCard and its state remain unchanged.
// ... (Paste the _PendingAnimalCard widget code here)
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
      color: kCardColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
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
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.error_outline,
                              color: kSecondaryTextColor,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade900,
                          child: const Icon(
                            Icons.pets,
                            size: 60,
                            color: kSecondaryTextColor,
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
                            color: _currentPage == i
                                ? kPrimaryAccentColor
                                : kSecondaryTextColor.withOpacity(0.6),
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
                    color: kPrimaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Posted by: ${widget.animalData['postedByEmail'] ?? 'Unknown'} on $postedDate',
                  style: const TextStyle(
                    fontSize: 14,
                    color: kPrimaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50.0),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewDetailsScreen(
                                  animalData: widget.animalData,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(50.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
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
                if (widget.isAdmin) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50.0),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showRejectDialog(
                                    context,
                                    widget.animalId,
                                  ),
                                  borderRadius: BorderRadius.circular(50.0),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Reject',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
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
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50.0),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showApproveDialog(
                                    context,
                                    widget.animalId,
                                  ),
                                  borderRadius: BorderRadius.circular(50.0),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Approve',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
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
        backgroundColor: kCardColor,
        title: const Text(
          'Approve Animal',
          style: TextStyle(color: kPrimaryTextColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will make the animal visible for adoption.',
              style: TextStyle(color: kPrimaryTextColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              style: const TextStyle(color: kPrimaryTextColor),
              decoration: InputDecoration(
                labelText: 'Optional Message',
                hintText: 'Add any notes or comments (optional)',
                labelStyle: const TextStyle(color: kPrimaryTextColor),
                hintStyle: TextStyle(color: kPrimaryTextColor.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: kPrimaryAccentColor),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kPrimaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Logic Unchanged
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: const StadiumBorder(),
            ),
            child: const Text('Approve'),
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
        backgroundColor: kCardColor,
        title: const Text(
          'Reject Animal',
          style: TextStyle(color: kPrimaryTextColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejection. This will be visible to the person who posted the animal.',
              style: TextStyle(fontSize: 14, color: kPrimaryTextColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              style: const TextStyle(color: kPrimaryTextColor),
              decoration: InputDecoration(
                labelText: 'Reason for Rejection *',
                hintText: 'Explain why this post is being rejected',
                labelStyle: const TextStyle(color: kPrimaryTextColor),
                hintStyle: TextStyle(color: kPrimaryTextColor.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: kPrimaryAccentColor),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kPrimaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Logic Unchanged
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const StadiumBorder(),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

// -------------------------
// File completion note:
// I reviewed the file and appended the remaining widget implementations and ensured
// all classes and braces are properly closed. If you still see a specific missing
// section, tell me which line or function name and I'll edit that exact part.
// -------------------------
