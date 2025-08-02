import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawscare/screens/my_applications_screen.dart';

class AdoptionFormScreen extends StatefulWidget {
  final Map<String, String> petData;

  const AdoptionFormScreen({Key? key, required this.petData}) : super(key: key);

  @override
  State<AdoptionFormScreen> createState() => _AdoptionFormScreenState();
}

class _AdoptionFormScreenState extends State<AdoptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Hardcoded User Details for now
  final String _userFullName = 'John Doe';
  final String _userEmail = 'john.doe@example.com';
  final String _userPhoneNumber = '123-456-7890';

  // Controllers for pre-filled applicant information
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  final TextEditingController _addressController = TextEditingController();

  // New Questionnaire Controllers and Variables
  // Pet History
  final TextEditingController _currentPetsController = TextEditingController();
  final TextEditingController _pastPetsController = TextEditingController();
  final TextEditingController _surrenderedPetsController = TextEditingController();
  bool _hasCurrentPets = false;
  bool _hasPastPets = false;
  bool _hasSurrenderedPets = false;

  // Household Info
  String? _homeOwnership; // Own / Rent
  int _householdMembers = 1;
  bool _hasAllergies = false;
  bool _allMembersAgree = false;

  // Pet Preferences
  final TextEditingController _petTypeLookingForController = TextEditingController();
  String? _preferenceForBreedAgeGender; // Yes / No for preferences
  final TextEditingController _whyAdoptPetController = TextEditingController();

  // Care and Responsibility
  final TextEditingController _hoursAloneController = TextEditingController();
  final TextEditingController _whereKeptWhenAloneController = TextEditingController();
  bool _financiallyPrepared = false;

  // Vet Care
  bool _hasVeterinarian = false;
  final TextEditingController _vetContactController = TextEditingController();
  bool _willingToProvideVetCare = false;

  // Commitment
  bool _preparedForLifetimeCommitment = false;
  final TextEditingController _ifCannotKeepCareController = TextEditingController();

  // Terms and Conditions
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: _userFullName);
    _emailController = TextEditingController(text: _userEmail);
    _phoneNumberController = TextEditingController(text: _userPhoneNumber);
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
    if (_formKey.currentState!.validate() && _agreedToTerms) {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('You must be logged in to apply.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('applications').add({
          'userId': user.uid,
          'petId': widget.petData['name'], // Using pet name as ID for mock data
          'petName': widget.petData['name'],
          'petImage': widget.petData['image'],
          'applicantName': _fullNameController.text.trim(),
          'applicantEmail': _emailController.text.trim(),
          'applicantPhone': _phoneNumberController.text.trim(),
          'applicantAddress': _addressController.text.trim(),
          // New Questionnaire Data
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

          'status': 'Under Review', // Initial status
          'appliedAt': FieldValue.serverTimestamp(),
          'adminMessage': '', // For admin rejection messages
        });

        _showSnackBar('Application submitted successfully!', isError: false);
        // Navigate to My Applications screen after successful submission
        Navigator.pop(context); // Pop adoption form
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyApplicationsScreen()),
        );
      } catch (e) {
        _showSnackBar('Failed to submit application: $e');
        print('Error submitting application: $e'); // For debugging
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (!_agreedToTerms) {
      _showSnackBar('Please agree to the terms and conditions.');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption Application'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet Information (unchanged)
              _buildSectionHeader('Applying for: ${widget.petData['name']!}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.petData['image']!,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 60,
                        width: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.pets, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.petData['name']!,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.petData['species']} • ${widget.petData['age']}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),

              // Applicant Information (unchanged)
              _buildSectionHeader('Your Information'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.isEmpty || !value.contains('@') ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your address' : null,
              ),
              const SizedBox(height: 32),

              // --- New Questionnaire Sections ---
              // Pet History
              _buildSectionHeader('Pet History'),
              const SizedBox(height: 16),
              _buildBooleanQuestion(
                'Do you currently have any pets?',
                _hasCurrentPets,
                (bool? value) {
                  setState(() {
                    _hasCurrentPets = value!;
                  });
                },
              ),
              if (_hasCurrentPets)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _currentPetsController,
                    decoration: const InputDecoration(
                      labelText: 'Current Pets Details',
                      hintText:
                          'List species, age, and if they are spayed/neutered',
                    ),
                    maxLines: 3,
                    validator: (value) => _hasCurrentPets && value!.isEmpty
                        ? 'Please provide details for your current pets'
                        : null,
                  ),
                ),
              const SizedBox(height: 16),
              _buildBooleanQuestion(
                'Have you had pets in the past?',
                _hasPastPets,
                (bool? value) {
                  setState(() {
                    _hasPastPets = value!;
                  });
                },
              ),
              if (_hasPastPets)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _pastPetsController,
                    decoration: const InputDecoration(
                      labelText: 'Past Pets Details',
                      hintText: 'Provide details (species, what happened to them?)',
                    ),
                    maxLines: 3,
                    validator: (value) => _hasPastPets && value!.isEmpty
                        ? 'Please provide details for your past pets'
                        : null,
                  ),
                ),
              const SizedBox(height: 16),
              _buildBooleanQuestion(
                'Have you ever surrendered a pet to a shelter or rehomed a pet?',
                _hasSurrenderedPets,
                (bool? value) {
                  setState(() {
                    _hasSurrenderedPets = value!;
                  });
                },
              ),
              if (_hasSurrenderedPets)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _surrenderedPetsController,
                    decoration: const InputDecoration(
                      labelText: 'Circumstance of Surrender/Rehoming',
                      hintText: 'Please explain the circumstance',
                    ),
                    maxLines: 3,
                    validator: (value) => _hasSurrenderedPets && value!.isEmpty
                        ? 'Please explain the circumstance'
                        : null,
                  ),
                ),
              const SizedBox(height: 32),

              // Household Info
              _buildSectionHeader('Household Information'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _homeOwnership,
                decoration: const InputDecoration(
                  labelText: 'Do you own or rent your home?',
                  prefixIcon: Icon(Icons.house),
                ),
                hint: const Text('Select an option'),
                items: <String>['Own', 'Rent'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _homeOwnership = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select an option' : null,
              ),
              const SizedBox(height: 16),
              _buildNumberInput(
                'How many people live in your household?',
                _householdMembers,
                (value) {
                  setState(() {
                    _householdMembers = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildBooleanQuestion(
                'Does anyone in your household have allergies to animals?',
                _hasAllergies,
                (bool? value) {
                  setState(() {
                    _hasAllergies = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildBooleanQuestion(
                'Do all household members agree to the adoption?',
                _allMembersAgree,
                (bool? value) {
                  setState(() {
                    _allMembersAgree = value!;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Pet Preferences
              _buildSectionHeader('Pet Preferences'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _petTypeLookingForController,
                decoration: const InputDecoration(
                  labelText: 'What type of animal are you looking to adopt?',
                  hintText: 'e.g., Dog, Cat, Bird, etc.',
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) => value!.isEmpty ? 'Please specify type of animal' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _preferenceForBreedAgeGender,
                decoration: const InputDecoration(
                  labelText: 'Do you have a preference for the breed, age, or gender of the animal?',
                  prefixIcon: Icon(Icons.tune),
                ),
                hint: const Text('Select an option'),
                items: <String>['Yes', 'No'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _preferenceForBreedAgeGender = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select an option' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whyAdoptPetController,
                decoration: const InputDecoration(
                  labelText: 'Why do you want to adopt a pet?',
                  prefixIcon: Icon(Icons.volunteer_activism),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Please state your reason for adoption' : null,
              ),
              const SizedBox(height: 32),

              // Care and Responsibility
              _buildSectionHeader('Care and Responsibility'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hoursAloneController,
                decoration: const InputDecoration(
                  labelText: 'How many hours per day will the animal be left alone?',
                  prefixIcon: Icon(Icons.timer_off),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please provide the hours' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whereKeptWhenAloneController,
                decoration: const InputDecoration(
                  labelText: 'Where will the animal be kept when you are not home?',
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 2,
                validator: (value) => value!.isEmpty ? 'Please specify where the animal will be kept' : null,
              ),
              const SizedBox(height: 16),
              _buildBooleanQuestion(
                'Are you financially prepared to provide for the animal’s needs, including food, veterinary care, grooming, and other expenses?',
                _financiallyPrepared,
                (bool? value) {
                  setState(() {
                    _financiallyPrepared = value!;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Vet Care
              _buildSectionHeader('Vet Care'),
              const SizedBox(height: 16),
              _buildBooleanQuestion(
                'Do you have a veterinarian?',
                _hasVeterinarian,
                (bool? value) {
                  setState(() {
                    _hasVeterinarian = value!;
                  });
                },
              ),
              if (_hasVeterinarian)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _vetContactController,
                    decoration: const InputDecoration(
                      labelText: 'Veterinarian Name and Contact',
                      hintText: 'e.g., Dr. Smith, 555-123-4567',
                    ),
                    maxLines: 2,
                    validator: (value) => _hasVeterinarian && value!.isEmpty
                        ? 'Please provide vet contact information'
                        : null,
                  ),
                ),
              const SizedBox(height: 16),
              _buildBooleanQuestion(
                'Are you willing to provide regular vet care, including vaccinations, flea/tick prevention, and routine check-ups?',
                _willingToProvideVetCare,
                (bool? value) {
                  setState(() {
                    _willingToProvideVetCare = value!;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Commitment
              _buildSectionHeader('Commitment'),
              const SizedBox(height: 16),
              _buildBooleanQuestion(
                'Are you prepared to commit to this pet for its entire lifetime?',
                _preparedForLifetimeCommitment,
                (bool? value) {
                  setState(() {
                    _preparedForLifetimeCommitment = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ifCannotKeepCareController,
                decoration: const InputDecoration(
                  labelText: 'What will you do if you can no longer keep care of the animal?',
                  prefixIcon: Icon(Icons.crisis_alert),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Please explain your plan' : null,
              ),
              const SizedBox(height: 32),

              // Terms and Conditions (unchanged)
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _agreedToTerms = newValue!;
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Navigate to Terms and Conditions/Privacy Policy page
                        _showSnackBar('Terms & Conditions page coming soon!');
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          children: [
                            TextSpan(
                              text: 'terms and conditions',
                              style: TextStyle(
                                color: Color(0xFF5AC8F2),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'privacy policy',
                              style: TextStyle(
                                color: Color(0xFF5AC8F2),
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

              // Submit Button (unchanged)
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _agreedToTerms ? _submitApplication : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5AC8F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Submit Application',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  // Helper widgets (unchanged, but added for completeness here)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5AC8F2),
        ),
      ),
    );
  }

  // Modified _buildBooleanQuestion to support leading text and then radio buttons
  Widget _buildBooleanQuestion(
      String question, bool currentValue, ValueChanged<bool?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Yes'),
                value: true,
                groupValue: currentValue,
                onChanged: onChanged,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('No'),
                value: false,
                groupValue: currentValue,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberInput(
      String label, int currentValue, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (currentValue > 0) onChanged(currentValue - 1);
              },
            ),
            Text(
              currentValue.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                onChanged(currentValue + 1);
              },
            ),
          ],
        ),
      ],
    );
  }
}