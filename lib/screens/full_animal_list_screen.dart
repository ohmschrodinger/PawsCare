import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/widgets/animal_card.dart';
import 'package:pawscare/services/user_favorites_service.dart';
import '../utils/constants.dart';

// --- Re-using the color palette for consistency ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -------------------------------------------------

class FullAnimalListScreen extends StatefulWidget {
  final String title;
  final String animalStatus; // 'Available' or 'Adopted'

  const FullAnimalListScreen({
    super.key,
    required this.title,
    required this.animalStatus,
  });

  @override
  State<FullAnimalListScreen> createState() => _FullAnimalListScreenState();
}

class _FullAnimalListScreenState extends State<FullAnimalListScreen> {
  // Filters
  String? _filterSpecies;
  String? _filterGender;
  String? _filterSterilization;
  String? _filterVaccination;

  @override
  void initState() {
    super.initState();
  }

  Stream<QuerySnapshot> _getAnimalsStream() {
    return FirebaseFirestore.instance.collection('animals').snapshots();
  }

  void _likeAnimal(BuildContext context, String animalId) async {
    try {
      await UserFavoritesService.toggleLike(animalId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _saveAnimal(BuildContext context, String animalId) async {
    try {
      await UserFavoritesService.toggleSave(animalId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openFilterSheet() {
    // Reusable input decoration for dark theme dropdowns
    final darkInputDecoration = InputDecoration(
      labelStyle: const TextStyle(color: kSecondaryTextColor),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: kPrimaryAccentColor),
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor, // Dark background for the sheet
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalState) {
            return Theme(
              // Apply dark theme specifically to the dropdown menus
              data: Theme.of(context).copyWith(
                canvasColor: kCardColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Animals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _filterSpecies,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: kSecondaryTextColor),
                      decoration:
                          darkInputDecoration.copyWith(labelText: 'Species'),
                      style: const TextStyle(color: kPrimaryTextColor),
                      items: [null, ...AppConstants.speciesOptions]
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e ?? 'Any'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          modalState(() => _filterSpecies = value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _filterGender,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: kSecondaryTextColor),
                      decoration:
                          darkInputDecoration.copyWith(labelText: 'Gender'),
                      style: const TextStyle(color: kPrimaryTextColor),
                      items: [null, 'Male', 'Female']
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e ?? 'Any'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          modalState(() => _filterGender = value),
                    ),
                    // You can add the other filters here following the same pattern
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryTextColor,
                              side: const BorderSide(color: kSecondaryTextColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              setState(() {
                                _filterSpecies = null;
                                _filterGender = null;
                                _filterSterilization = null;
                                _filterVaccination = null;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryAccentColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
              color: kPrimaryTextColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: kPrimaryTextColor),
            tooltip: 'Filter Animals',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getAnimalsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading animals.',
                style: TextStyle(fontSize: 16, color: Colors.redAccent),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryAccentColor));
          }

          final animals = snapshot.data?.docs ?? [];
          List filteredAnimals;

          if (widget.animalStatus == 'Available') {
            filteredAnimals = animals.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['approvalStatus'] == 'approved' &&
                  data['status'] != 'Adopted';
            }).toList();
          } else {
            filteredAnimals = animals.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'Adopted';
            }).toList();
          }

          filteredAnimals = filteredAnimals.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (_filterSpecies != null && data['species'] != _filterSpecies) {
              return false;
            }
            if (_filterGender != null && data['gender'] != _filterGender) {
              return false;
            }
            return true;
          }).toList();

          if (filteredAnimals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.pets_outlined,
                    size: 64,
                    color: kSecondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No animals found.',
                    style: TextStyle(
                      fontSize: 18,
                      color: kSecondaryTextColor,
                    ),
                  ),
                  if (_filterSpecies != null || _filterGender != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your filters.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: filteredAnimals.length,
            itemBuilder: (context, index) {
              final animalDoc = filteredAnimals[index];
              final animalData = animalDoc.data() as Map<String, dynamic>;
              final animalId = animalDoc.id;
              final animal = {'id': animalId, ...animalData};

              // NOTE: Ensure your 'AnimalCard' widget is also styled with a dark theme,
              // for example, by giving it a background color of `kCardColor`.
              return AnimalCard(
                animal: animal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PetDetailScreen(petData: animal),
                    ),
                  );
                },
                onLike: () => _likeAnimal(context, animalId),
                onSave: () => _saveAnimal(context, animalId),
              );
            },
          );
        },
      ),
    );
  }
}