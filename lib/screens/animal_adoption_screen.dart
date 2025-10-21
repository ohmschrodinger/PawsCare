// lib/screens/animal_adoption_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/widgets/animal_card.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kPrimaryAccentColor = Colors.amber;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
const Color kCardColor = Color(0xFF1E1E1E);
// -----------------------------------------

class AnimalAdoptionScreen extends StatefulWidget {
  const AnimalAdoptionScreen({super.key});

  @override
  State<AnimalAdoptionScreen> createState() => _AnimalAdoptionScreenState();
}

class _AnimalAdoptionScreenState extends State<AnimalAdoptionScreen> {
  String _sortBy = 'postedAt';
  String _speciesFilter = 'All';
  String _genderFilter = 'All';

  void _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            String localSort = _sortBy;
            String localSpecies = _speciesFilter;
            String localGender = _genderFilter;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.45,
              maxChildSize: 0.9,
              builder: (_, controller) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kCardColor.withOpacity(0.25),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: ListView(
                        controller: controller,
                        children: [
                          const Text(
                            'Filter & Sort',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Sort by',
                            style: TextStyle(color: kSecondaryTextColor),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: DropdownButtonFormField<String>(
                                value: localSort,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'postedAt',
                                    child: Text('Recently Added'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'name',
                                    child: Text('Name (A-Z)'),
                                  ),
                                ],
                                onChanged: (v) => setModalState(
                                  () => localSort = v ?? 'postedAt',
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Species',
                            style: TextStyle(color: kSecondaryTextColor),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: DropdownButtonFormField<String>(
                                value: localSpecies,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'All',
                                    child: Text('All Species'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Dog',
                                    child: Text('Dogs'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Cat',
                                    child: Text('Cats'),
                                  ),
                                ],
                                onChanged: (v) => setModalState(
                                  () => localSpecies = v ?? 'All',
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Gender',
                            style: TextStyle(color: kSecondaryTextColor),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: DropdownButtonFormField<String>(
                                value: localGender,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'All',
                                    child: Text('Any Gender'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Female',
                                    child: Text('Female'),
                                  ),
                                ],
                                onChanged: (v) => setModalState(
                                  () => localGender = v ?? 'All',
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(50),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.of(ctx).pop({
                                              'sortBy': 'postedAt',
                                              'species': 'All',
                                              'gender': 'All',
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Clear',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
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
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                          50.0,
                                        ),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.of(ctx).pop({
                                              'sortBy': localSort,
                                              'species': localSpecies,
                                              'gender': localGender,
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(
                                            50.0,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12.0,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Apply',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
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
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _sortBy = result['sortBy'] ?? _sortBy;
        _speciesFilter = result['species'] ?? _speciesFilter;
        _genderFilter = result['gender'] ?? _genderFilter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- CHANGE 1: Allow the body to extend behind the AppBar ---
      extendBodyBehindAppBar: true,

      // --- CHANGE 2: Make the AppBar transparent ---
      appBar: AppBar(
        title: const Text(
          'Adopt Love',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent, // Set to transparent
        elevation: 0, // Remove shadow
      ),

      // --- CHANGE 3: Use a Stack for the layered background effect ---
      body: Stack(
        children: [
          // --- LAYER 1: The background image ---
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.2),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // --- LAYER 2: The blur overlay ---
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),

          // --- LAYER 3: Your original screen content, now inside a SafeArea ---
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: AnimalService.getAvailableAnimals(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Something went wrong',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryAccentColor),
                  );
                }

                List<QueryDocumentSnapshot> animals = snapshot.data?.docs ?? [];
                final List<Map<String, dynamic>> animalList = animals.map((doc) {
                  return {'id': doc.id, ...(doc.data() as Map<String, dynamic>)};
                }).toList();

                // Apply filters
                List<Map<String, dynamic>> filtered = animalList.where((a) {
                  final speciesMatch =
                      _speciesFilter == 'All' ||
                      (a['species'] ?? '').toString().toLowerCase() ==
                          _speciesFilter.toLowerCase();
                  final genderMatch =
                      _genderFilter == 'All' ||
                      (a['gender'] ?? '').toString().toLowerCase() ==
                          _genderFilter.toLowerCase();
                  return speciesMatch && genderMatch;
                }).toList();

                // Apply sorting
                if (_sortBy == 'name') {
                  filtered.sort(
                    (a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo(
                          (b['name'] ?? '').toString().toLowerCase(),
                        ),
                  );
                } else {
                  filtered.sort((a, b) {
                    final aTime = a['postedAt'] as Timestamp?;
                    final bTime = b['postedAt'] as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime); // Descending
                  });
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Waiting For a Home',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _openFilterSheet,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                backgroundColor: Colors.black.withOpacity(0.25),
                              ),
                              icon: const Icon(Icons.filter_list, size: 20),
                              label: const Text('Filter'),
                            ),
                          ],
                        ),
                      ),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 48.0),
                          child: Center(
                            child: Text(
                              'No animals match your filters.',
                              style: TextStyle(
                                fontSize: 16,
                                color: kSecondaryTextColor,
                              ),
                            ),
                          ),
                        )
                      else
                        ...filtered.map((animalData) {
                          return AnimalCard(
                            animal: animalData,
                            isLiked:
                                false, // You'll likely connect this to a state management solution
                            isSaved:
                                false, // You'll likely connect this to a state management solution
                            likeCount: (animalData['likeCount'] as int?) ?? 0,
                            onLike: () {},
                            onSave: () {},
                          );
                        }).toList(),
                      const SizedBox(
                        height: 90,
                      ), // Padding for floating navigation bar if any
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}