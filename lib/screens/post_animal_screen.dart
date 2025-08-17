import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/animal_service.dart';

class PostAnimalScreen extends StatefulWidget {
  const PostAnimalScreen({Key? key}) : super(key: key);

  @override
  State<PostAnimalScreen> createState() => _PostAnimalScreenState();
}

class _PostAnimalScreenState extends State<PostAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _rescueStoryController = TextEditingController();
  
  // Form values
  String _selectedSpecies = 'Dog';
  String _selectedGender = 'Male';
  String _selectedSterilization = 'Yes';
  String _selectedVaccination = 'Up-to-date';
  String _selectedMotherStatus = 'Unknown';

  // Available options
  final List<String> _speciesOptions = ['Dog', 'Cat', 'Bird', 'Fish', 'Rabbit', 'Hamster', 'Other'];
  final List<String> _genderOptions = ['Male', 'Female', 'Unknown'];
  final List<String> _sterilizationOptions = ['Yes', 'No', 'N/A'];
  final List<String> _vaccinationOptions = ['Up-to-date', 'Partial', 'None', 'N/A'];
  final List<String> _motherStatusOptions = ['Unknown', 'Alive', 'Deceased', 'Separated'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _rescueStoryController.dispose();
    super.dispose();
  }

  Future<void> _postAnimal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('You must be logged in to post an animal.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Use the AnimalService to post the animal
      await AnimalService.postAnimal(
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        age: _ageController.text.trim(),
        gender: _selectedGender,
        sterilization: _selectedSterilization,
        vaccination: _selectedVaccination,
        rescueStory: _rescueStoryController.text.trim(),
        motherStatus: _selectedMotherStatus,
      );

      _showSnackBar('Animal posted successfully!', isError: false);
      
      // Clear form
      _formKey.currentState?.reset();
      _nameController.clear();
      _ageController.clear();
      _rescueStoryController.clear();
      
      // Reset dropdowns to default values
      setState(() {
        _selectedSpecies = 'Dog';
        _selectedGender = 'Male';
        _selectedSterilization = 'Yes';
        _selectedVaccination = 'Up-to-date';
        _selectedMotherStatus = 'Unknown';
      });

    } catch (e) {
      _showSnackBar('Failed to post animal: $e');
      print('Error posting animal: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        title: const Text('Post Animal'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5AC8F2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Post an Animal for Adoption',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5AC8F2),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Help an animal find their forever home by posting their details.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Animal Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Animal Name *',
                  prefixIcon: Icon(Icons.pets),
                  hintText: 'Enter the animal\'s name',
                ),
                validator: (value) => value!.isEmpty ? 'Please enter the animal\'s name' : null,
              ),
              const SizedBox(height: 16),

              // Species
              DropdownButtonFormField<String>(
                value: _selectedSpecies,
                decoration: const InputDecoration(
                  labelText: 'Species *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _speciesOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSpecies = newValue!;
                  });
                },
                validator: (value) => value == null ? 'Please select a species' : null,
              ),
              const SizedBox(height: 16),

              // Age
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age *',
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'e.g., 2 years, 6 months, 1 year',
                ),
                validator: (value) => value!.isEmpty ? 'Please enter the animal\'s age' : null,
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  prefixIcon: Icon(Icons.person),
                ),
                items: _genderOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                  });
                },
                validator: (value) => value == null ? 'Please select a gender' : null,
              ),
              const SizedBox(height: 16),

              // Sterilization
              DropdownButtonFormField<String>(
                value: _selectedSterilization,
                decoration: const InputDecoration(
                  labelText: 'Sterilization Status *',
                  prefixIcon: Icon(Icons.medical_services),
                ),
                items: _sterilizationOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSterilization = newValue!;
                  });
                },
                validator: (value) => value == null ? 'Please select sterilization status' : null,
              ),
              const SizedBox(height: 16),

              // Vaccination
              DropdownButtonFormField<String>(
                value: _selectedVaccination,
                decoration: const InputDecoration(
                  labelText: 'Vaccination Status *',
                  prefixIcon: Icon(Icons.vaccines),
                ),
                items: _vaccinationOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedVaccination = newValue!;
                  });
                },
                validator: (value) => value == null ? 'Please select vaccination status' : null,
              ),
              const SizedBox(height: 16),

              // Mother Status
              DropdownButtonFormField<String>(
                value: _selectedMotherStatus,
                decoration: const InputDecoration(
                  labelText: 'Mother Status *',
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                items: _motherStatusOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMotherStatus = newValue!;
                  });
                },
                validator: (value) => value == null ? 'Please select mother status' : null,
              ),
              const SizedBox(height: 16),

              // Rescue Story
              TextFormField(
                controller: _rescueStoryController,
                decoration: const InputDecoration(
                  labelText: 'Rescue Story *',
                  prefixIcon: Icon(Icons.menu_book),   // book icon
                  hintText: 'Tell us about how this animal was found or their background...',
                ),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Please enter the rescue story' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _postAnimal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5AC8F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Post Animal',
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
}
