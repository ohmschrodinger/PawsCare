import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawscare/screens/my_applications_screen.dart';
import '../services/user_service.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -----------------------------------------

class AdoptionFormScreen extends StatefulWidget {
  final Map<String, dynamic> petData;
  const AdoptionFormScreen({super.key, required this.petData});
  @override
  State<AdoptionFormScreen> createState() => _AdoptionFormScreenState();
}

class _AdoptionFormScreenState extends State<AdoptionFormScreen> {
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

  Future<void> _loadUserData() async {
    // Functionality is unchanged
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await UserService.getUserData(user.uid);
        if (userData != null && mounted) {
          setState(() {
            _fullNameController.text = userData['fullName'] ?? '';
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
        try {
          await UserService.updateUserProfile(
            uid: user.uid,
            data: {
              'fullName': _fullNameController.text.trim(),
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
          'petId': widget.petData['id'] ?? widget.petData['name'],
          'petName': widget.petData['name'],
          'petImage': widget.petData['image'],
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
        _showSnackBar('Application submitted successfully!', isError: false);
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyApplicationsScreen()),
        );
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

  void _showSnackBar(String message, {bool isError = true}) {
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
        appBar: AppBar(
          title: const Text('Adoption Application', style: TextStyle(color: kPrimaryTextColor)),
          backgroundColor: kBackgroundColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: kPrimaryAccentColor),
        ),
      );
    }
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Adoption Application', style: TextStyle(color: kPrimaryTextColor)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                    icon: Icons.person,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please enter your full name' : null,
                  ),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  _buildTextField(
                    controller: _phoneNumberController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    maxLines: 3,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please enter your address' : null,
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
                      hint: 'List species, age, and spayed/neutered status',
                      maxLines: 3,
                      validator: (value) => (value == null || value.isEmpty)
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
                      hint: 'Provide details (species, what happened to them?)',
                      maxLines: 3,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please provide details for your past pets'
                          : null,
                    ),
                  _buildYesNoQuestion(
                    'Have you ever surrendered a pet?',
                    _hasSurrenderedPets,
                    (value) => setState(() => _hasSurrenderedPets = value),
                  ),
                  if (_hasSurrenderedPets == true)
                    _buildTextField(
                      controller: _surrenderedPetsController,
                      label: 'Circumstance of Surrender',
                      hint: 'Please explain the circumstance',
                      maxLines: 3,
                      validator: (value) => (value == null || value.isEmpty)
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
                    icon: Icons.house,
                    onChanged: (value) => setState(() => _homeOwnership = value),
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
                title: 'Pet Preferences',
                icon: Icons.favorite_outline,
                children: [
                  _buildTextField(
                    controller: _petTypeLookingForController,
                    label: 'What type of animal are you looking to adopt?',
                    hint: 'e.g., Dog, Cat, Bird, etc.',
                    icon: Icons.pets,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please specify type of animal'
                        : null,
                  ),
                  _buildDropdownQuestion(
                    label: 'Do you have a preference for breed, age, or gender?',
                    value: _preferenceForBreedAgeGender,
                    items: ['Yes', 'No'],
                    icon: Icons.tune,
                    onChanged: (value) =>
                        setState(() => _preferenceForBreedAgeGender = value),
                    validator: (value) =>
                        value == null ? 'Please select an option' : null,
                  ),
                  _buildTextField(
                    controller: _whyAdoptPetController,
                    label: 'Why do you want to adopt a pet?',
                    icon: Icons.volunteer_activism,
                    maxLines: 3,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please state your reason for adoption'
                        : null,
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
                    label: 'How many hours will the animal be left alone?',
                    icon: Icons.timer_off_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please provide the hours' : null,
                  ),
                  _buildTextField(
                    controller: _whereKeptWhenAloneController,
                    label:
                        'Where will the animal be kept when you are not home?',
                    icon: Icons.home_outlined,
                    maxLines: 2,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please specify where the animal will be kept'
                        : null,
                  ),
                  _buildYesNoQuestion(
                    'Are you financially prepared for the animal’s needs?',
                    _financiallyPrepared,
                    (value) => setState(() => _financiallyPrepared = value),
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
                      icon: Icons.contact_mail_outlined,
                      maxLines: 2,
                      validator: (value) => (value == null || value.isEmpty)
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
                    (value) =>
                        setState(() => _preparedForLifetimeCommitment = value),
                  ),
                  _buildTextField(
                    controller: _ifCannotKeepCareController,
                    label:
                        'What will you do if you can no longer care for the animal?',
                    icon: Icons.crisis_alert_outlined,
                    maxLines: 3,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please explain your plan' : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _agreedToTerms = newValue ?? false;
                      });
                    },
                    activeColor: kPrimaryAccentColor,
                    checkColor: Colors.black,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _showSnackBar('Terms & Conditions page coming soon!',
                            isError: false);
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(color: kPrimaryTextColor),
                          children: [
                            TextSpan(
                              text: 'terms and conditions',
                              style: TextStyle(
                                color: kPrimaryAccentColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'privacy policy',
                              style: TextStyle(
                                color: kPrimaryAccentColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryAccentColor))
                  : Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: ElevatedButton(
                          onPressed: _agreedToTerms ? _submitApplication : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryAccentColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'Submit Application',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildPetInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryAccentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.petData['image'] ?? '',
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 80,
                width: 80,
                color: Colors.grey.shade900,
                child: const Icon(Icons.pets, color: kSecondaryTextColor),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applying for:',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: kSecondaryTextColor.withOpacity(0.8)),
                ),
                Text(
                  widget.petData['name'] ?? 'Unknown Pet',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryAccentColor),
                ),
                Text(
                  '${widget.petData['species'] ?? 'N/A'} • ${widget.petData['age'] ?? 'N/A'}',
                  style: const TextStyle(color: kSecondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: kCardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kPrimaryAccentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryAccentColor),
                ),
              ],
            ),
            const Divider(height: 24, color: kBackgroundColor),
            ...children.map((child) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: child,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: kPrimaryTextColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kSecondaryTextColor),
        hintText: hint,
        hintStyle: TextStyle(color: kSecondaryTextColor.withOpacity(0.5)),
        prefixIcon: icon != null ? Icon(icon, color: kSecondaryTextColor) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimaryAccentColor, width: 2),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildYesNoQuestion(
      String question, bool? currentValue, ValueChanged<bool?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kPrimaryTextColor),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onChanged(true),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      currentValue == true ? kPrimaryAccentColor : Colors.transparent,
                  side: BorderSide(
                      color: currentValue == true
                          ? kPrimaryAccentColor
                          : kSecondaryTextColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Yes',
                  style: TextStyle(
                    color:
                        currentValue == true ? Colors.black : kPrimaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onChanged(false),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      currentValue == false ? kPrimaryAccentColor : Colors.transparent,
                  side: BorderSide(
                      color: currentValue == false
                          ? kPrimaryAccentColor
                          : kSecondaryTextColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'No',
                  style: TextStyle(
                    color:
                        currentValue == false ? Colors.black : kPrimaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownQuestion({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: kCardColor),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kSecondaryTextColor),
          prefixIcon: Icon(icon, color: kSecondaryTextColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimaryAccentColor, width: 2),
          ),
        ),
        items: items.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(color: kPrimaryTextColor)),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildNumberInput(
      String label, int currentValue, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kPrimaryTextColor),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade800),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: kPrimaryAccentColor),
                onPressed: () {
                  if (currentValue > 1) onChanged(currentValue - 1);
                },
              ),
              Text(
                currentValue.toString(),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryTextColor),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: kPrimaryAccentColor),
                onPressed: () {
                  onChanged(currentValue + 1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}