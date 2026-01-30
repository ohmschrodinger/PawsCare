import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawscare/screens/my_applications_screen.dart';
import 'package:pawscare/screens/terms_and_service.dart';
import 'dart:ui'; // Import for ImageFilter
import '../services/user_service.dart';
import '../services/logging_service.dart';
import '../constants/app_colors.dart';

class AdoptionFormScreen extends StatefulWidget {
  final Map<String, dynamic> petData;
  const AdoptionFormScreen({super.key, required this.petData});
  @override
  State<AdoptionFormScreen> createState() => _AdoptionFormScreenState();
}

class _AdoptionFormScreenState extends State<AdoptionFormScreen> {
  // --- All state variables and controllers remain the same ---
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingUserData = true;

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _currentPetsController = TextEditingController();
  final TextEditingController _pastPetsController = TextEditingController();
  final TextEditingController _surrenderedPetsController =
      TextEditingController();
  bool? _hasCurrentPets;
  bool? _hasPastPets;
  bool? _hasSurrenderedPets;
  String? _homeOwnership;
  int _householdMembers = 1;
  bool? _hasAllergies;
  bool? _allMembersAgree;
  final TextEditingController _petTypeLookingForController =
      TextEditingController();
  String? _preferenceForBreedAgeGender;
  final TextEditingController _whyAdoptPetController = TextEditingController();
  final TextEditingController _hoursAloneController = TextEditingController();
  final TextEditingController _whereKeptWhenAloneController =
      TextEditingController();
  bool? _financiallyPrepared;
  bool? _hasVeterinarian;
  final TextEditingController _vetContactController = TextEditingController();
  bool? _willingToProvideVetCare;
  bool? _preparedForLifetimeCommitment;
  final TextEditingController _ifCannotKeepCareController =
      TextEditingController();
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _loadUserData();
  }

  // --- All logic functions (_loadUserData, _submitApplication, etc.) remain unchanged ---
  Future<void> _loadUserData() async {
    // Functionality is unchanged
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await UserService.getUserData(user.uid);
        if (userData != null && mounted) {
          // Combine firstName and lastName for the full name field
          final firstName = userData['firstName'] ?? '';
          final lastName = userData['lastName'] ?? '';
          final fullName = '$firstName $lastName'.trim();

          setState(() {
            _fullNameController.text = fullName;
            _emailController.text = userData['email'] ?? '';
            _phoneNumberController.text = userData['phoneNumber'] ?? '';
            _addressController.text = userData['address'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _currentPetsController.dispose();
    _pastPetsController.dispose();
    _surrenderedPetsController.dispose();
    _petTypeLookingForController.dispose();
    _whyAdoptPetController.dispose();
    _hoursAloneController.dispose();
    _whereKeptWhenAloneController.dispose();
    _vetContactController.dispose();
    _ifCannotKeepCareController.dispose();
    super.dispose();
  }

  void _submitApplication() async {
    // Functionality is unchanged
    if ((_formKey.currentState?.validate() ?? false) && _agreedToTerms) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('You must be logged in to apply.');
        setState(() => _isLoading = false);
        return;
      }

      try {
        // Check if there are existing applications for this pet
        final petId = widget.petData['id'] ?? widget.petData['name'];
        final existingApplicationsQuery = await FirebaseFirestore.instance
            .collection('applications')
            .where('petId', isEqualTo: petId)
            .where('status', isEqualTo: 'Under Review')
            .get();

        final hasExistingApplications =
            existingApplicationsQuery.docs.isNotEmpty;

        try {
          // Split the full name from the form into first and last name
          final fullNameParts = _fullNameController.text.trim().split(' ');
          final firstName = fullNameParts.isNotEmpty ? fullNameParts.first : '';
          final lastName = fullNameParts.length > 1
              ? fullNameParts.sublist(1).join(' ')
              : '';

          await UserService.updateUserProfile(
            uid: user.uid,
            data: {
              'firstName': firstName,
              'lastName': lastName,
              'phoneNumber': _phoneNumberController.text.trim(),
              'address': _addressController.text.trim(),
              'profileCompleted': true,
            },
          );
        } catch (e) {
          print('Warning: Failed to update user profile: $e');
        }

        await FirebaseFirestore.instance.collection('applications').add({
          'userId': user.uid,
          'petId': petId,
          'petName': widget.petData['name'],
          'petImage': widget.petData['imageUrls']?.isNotEmpty ?? false
              ? widget.petData['imageUrls'][0]
              : '',
          'applicantName': _fullNameController.text.trim(),
          'applicantEmail': _emailController.text.trim(),
          'applicantPhone': _phoneNumberController.text.trim(),
          'applicantAddress': _addressController.text.trim(),
          'hasCurrentPets': _hasCurrentPets,
          'currentPetsDetails': _currentPetsController.text.trim(),
          'hasPastPets': _hasPastPets,
          'pastPetsDetails': _pastPetsController.text.trim(),
          'hasSurrenderedPets': _hasSurrenderedPets,
          'surrenderedPetsCircumstance': _surrenderedPetsController.text.trim(),
          'homeOwnership': _homeOwnership,
          'householdMembers': _householdMembers,
          'hasAllergies': _hasAllergies,
          'allMembersAgree': _allMembersAgree,
          'petTypeLookingFor': _petTypeLookingForController.text.trim(),
          'preferenceForBreedAgeGender': _preferenceForBreedAgeGender,
          'whyAdoptPet': _whyAdoptPetController.text.trim(),
          'hoursLeftAlone': _hoursAloneController.text.trim(),
          'whereKeptWhenAlone': _whereKeptWhenAloneController.text.trim(),
          'financiallyPrepared': _financiallyPrepared,
          'hasVeterinarian': _hasVeterinarian,
          'vetContactInfo': _vetContactController.text.trim(),
          'willingToProvideVetCare': _willingToProvideVetCare,
          'preparedForLifetimeCommitment': _preparedForLifetimeCommitment,
          'ifCannotKeepCare': _ifCannotKeepCareController.text.trim(),
          'status': 'Under Review',
          'appliedAt': FieldValue.serverTimestamp(),
          'adminMessage': '',
        });

        // Log the application submission
        await LoggingService.logEvent(
          'adoption_application_submitted',
          data: {'petId': petId, 'petName': widget.petData['name']},
        );

        // Show appropriate message based on existing applications
        if (hasExistingApplications) {
          _showHeadsUpDialog();
        } else {
          _showSnackBar('Application submitted successfully!', isError: false);
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyApplicationsScreen(),
            ),
          );
        }
      } catch (e) {
        _showSnackBar('Failed to submit application: $e');
        print('Error submitting application: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (!_agreedToTerms) {
      _showSnackBar('Please agree to the terms and conditions.');
    }
  }

  void _showHeadsUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: const Text(
            'Application Submitted!',
            style: TextStyle(color: kPrimaryTextColor),
          ),
          content: Text(
            "We've received your request for ${widget.petData['name']}. Since others have applied too, you can explore more pets in the meantime.",
            style: const TextStyle(color: kSecondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pop(context); // Close adoption form
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyApplicationsScreen(),
                  ),
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(color: kPrimaryAccentColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: kPrimaryAccentColor),
        ),
      );
    }
    return Scaffold(
      // --- CHANGE 1: Apply Glassmorphism Background ---
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Adoption Application',
          style: TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.2),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          // Blur Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          // Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPetInfoSection(),
                    const SizedBox(height: 24),
                    _buildInfoCard(
                      title: 'Your Information',
                      icon: Icons.person_outline,
                      children: [
                        _buildTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Please enter your full name'
                              : null,
                        ),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email address',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              (value == null || !value.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Number',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: kPrimaryTextColor,
                              ),
                              softWrap: true,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _phoneNumberController.text.isEmpty
                                    ? 'Not set'
                                    : _phoneNumberController.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: kSecondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                          hint: 'Enter your full address',
                          maxLines: 3,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Please enter your address'
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoCard(
                      title: 'Pet History',
                      icon: Icons.history,
                      children: [
                        _buildYesNoQuestion(
                          'Do you currently have any pets?',
                          _hasCurrentPets,
                          (value) => setState(() => _hasCurrentPets = value),
                        ),
                        if (_hasCurrentPets == true)
                          _buildTextField(
                            controller: _currentPetsController,
                            label: 'Current Pets Details',
                            hint:
                                'List species, age, and spayed/neutered status',
                            maxLines: 3,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Please provide details for your current pets'
                                : null,
                          ),
                        _buildYesNoQuestion(
                          'Have you had pets in the past?',
                          _hasPastPets,
                          (value) => setState(() => _hasPastPets = value),
                        ),
                        if (_hasPastPets == true)
                          _buildTextField(
                            controller: _pastPetsController,
                            label: 'Past Pets Details',
                            hint:
                                'Provide details (species, what happened to them?)',
                            maxLines: 3,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Please provide details for your past pets'
                                : null,
                          ),
                        _buildYesNoQuestion(
                          'Have you ever surrendered a pet?',
                          _hasSurrenderedPets,
                          (value) =>
                              setState(() => _hasSurrenderedPets = value),
                        ),
                        if (_hasSurrenderedPets == true)
                          _buildTextField(
                            controller: _surrenderedPetsController,
                            label: 'Circumstance of Surrender',
                            hint: 'Please explain the circumstance',
                            maxLines: 3,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Please explain the circumstance'
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoCard(
                      title: 'Household Information',
                      icon: Icons.group_outlined,
                      children: [
                        _buildDropdownQuestion(
                          label: 'Do you own or rent your home?',
                          value: _homeOwnership,
                          items: ['Own', 'Rent'],
                          onChanged: (value) =>
                              setState(() => _homeOwnership = value),
                          validator: (value) =>
                              value == null ? 'Please select an option' : null,
                        ),
                        _buildNumberInput(
                          'How many people live in your household?',
                          _householdMembers,
                          (value) => setState(() => _householdMembers = value),
                        ),
                        _buildYesNoQuestion(
                          'Does anyone have allergies to animals?',
                          _hasAllergies,
                          (value) => setState(() => _hasAllergies = value),
                        ),
                        _buildYesNoQuestion(
                          'Do all household members agree to the adoption?',
                          _allMembersAgree,
                          (value) => setState(() => _allMembersAgree = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoCard(
                      title: 'Care and Responsibility',
                      icon: Icons.handshake_outlined,
                      children: [
                        _buildTextField(
                          controller: _hoursAloneController,
                          label:
                              'How many hours daily will the animal be alone?',
                          hint: 'e.g., 4',
                          keyboardType: TextInputType.number,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Please provide the hours'
                              : null,
                        ),
                        _buildTextField(
                          controller: _whereKeptWhenAloneController,
                          label:
                              'Where will the animal be kept when you are not home?',
                          hint: 'e.g., Indoors, backyard, crate',
                          maxLines: 2,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Please specify where the animal will be kept'
                              : null,
                        ),
                        _buildYesNoQuestion(
                          'Are you financially prepared for the animal’s needs?',
                          _financiallyPrepared,
                          (value) =>
                              setState(() => _financiallyPrepared = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoCard(
                      title: 'Vet Care',
                      icon: Icons.local_hospital_outlined,
                      children: [
                        _buildYesNoQuestion(
                          'Do you have a veterinarian?',
                          _hasVeterinarian,
                          (value) => setState(() => _hasVeterinarian = value),
                        ),
                        if (_hasVeterinarian == true)
                          _buildTextField(
                            controller: _vetContactController,
                            label: 'Veterinarian Name and Contact',
                            hint: 'e.g., Dr. Smith, 555-123-4567',
                            maxLines: 2,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Please provide vet contact information'
                                : null,
                          ),
                        _buildYesNoQuestion(
                          'Are you willing to provide regular vet care?',
                          _willingToProvideVetCare,
                          (value) =>
                              setState(() => _willingToProvideVetCare = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoCard(
                      title: 'Commitment',
                      icon: Icons.volunteer_activism_outlined,
                      children: [
                        _buildYesNoQuestion(
                          'Are you prepared for a lifetime commitment?',
                          _preparedForLifetimeCommitment,
                          (value) => setState(
                            () => _preparedForLifetimeCommitment = value,
                          ),
                        ),
                        _buildTextField(
                          controller: _ifCannotKeepCareController,
                          label:
                              'What will you do if you can no longer care for the animal?',
                          hint:
                              'e.g., Return to shelter, give to a trusted friend',
                          maxLines: 3,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Please explain your plan'
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTermsAndConditions(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildPetInfoSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.petData['imageUrls']?.isNotEmpty ?? false
                      ? widget.petData['imageUrls'][0]
                      : '',
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80,
                    width: 80,
                    color: Colors.black.withOpacity(0.3),
                    child: const Icon(Icons.pets, color: kSecondaryTextColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Applying for:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: kSecondaryTextColor,
                      ),
                    ),
                    Text(
                      widget.petData['name'] ?? 'Unknown Pet',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryTextColor,
                      ),
                    ),
                    Text(
                      '${widget.petData['breed'] ?? 'N/A'} • ${widget.petData['age'] ?? 'N/A'}',
                      style: const TextStyle(color: kSecondaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: kCardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: kPrimaryAccentColor),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryTextColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.white12),
                ...children.map(
                  (child) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kPrimaryTextColor,
          ),
          softWrap: true,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 16, color: kPrimaryTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: kSecondaryTextColor.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
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
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildYesNoQuestion(
    String question,
    bool? currentValue,
    ValueChanged<bool?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kPrimaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildGlassmorphicChoiceChip(
              label: 'Yes',
              isSelected: currentValue == true,
              onTap: () => onChanged(true),
            ),
            const SizedBox(width: 12),
            _buildGlassmorphicChoiceChip(
              label: 'No',
              isSelected: currentValue == false,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassmorphicChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? kPrimaryAccentColor.withOpacity(0.25)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: isSelected
                  ? kPrimaryAccentColor.withOpacity(0.4)
                  : Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : kPrimaryTextColor.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownQuestion({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kPrimaryTextColor,
          ),
          softWrap: true,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: kCardColor,
          style: const TextStyle(color: kPrimaryTextColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
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
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildNumberInput(
    String label,
    int currentValue,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kPrimaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: kPrimaryAccentColor,
                    ),
                    onPressed: () {
                      if (currentValue > 1) onChanged(currentValue - 1);
                    },
                  ),
                  Text(
                    currentValue.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryTextColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: kPrimaryAccentColor,
                    ),
                    onPressed: () {
                      onChanged(currentValue + 1);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Theme(
          data: ThemeData(unselectedWidgetColor: kSecondaryTextColor),
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (bool? newValue) {
              setState(() {
                _agreedToTerms = newValue ?? false;
              });
            },
            activeColor: kPrimaryAccentColor,
            checkColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsAndServiceScreen(),
                ),
              );
            },
            child: const Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: TextStyle(color: kSecondaryTextColor, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'terms and conditions',
                    style: TextStyle(
                      color: kPrimaryAccentColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: kPrimaryAccentColor),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(50.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _agreedToTerms
                      ? kSubmitApplicationButtonColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1), // Green
                  borderRadius: BorderRadius.circular(50.0),
                  border: Border.all(
                    color: _agreedToTerms
                        ? kSubmitApplicationButtonColor.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _agreedToTerms ? _submitApplication : null,
                    borderRadius: BorderRadius.circular(50.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Text(
                        'Submit Application',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _agreedToTerms
                              ? Colors.white
                              : kSecondaryTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
