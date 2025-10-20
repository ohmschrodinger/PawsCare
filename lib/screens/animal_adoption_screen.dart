// lib/screens/animal_adoption_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/widgets/paws_care_app_bar.dart';
import 'package:pawscare/widgets/animal_card.dart';
import '../main_navigation_screen.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kPrimaryAccentColor = Colors.amber;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -----------------------------------------

class AnimalAdoptionScreen extends StatefulWidget {
  const AnimalAdoptionScreen({super.key});

  @override
  State<AnimalAdoptionScreen> createState() => _AnimalAdoptionScreenState();
}

class _AnimalAdoptionScreenState extends State<AnimalAdoptionScreen> {
  // Filter / sort state
  String _sortBy = 'postedAt'; // 'postedAt' or 'name'
  String _speciesFilter = 'All'; // 'All', 'Dog', 'Cat'
  String _genderFilter = 'All'; // 'All', 'Male', 'Female'

  void _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String localSort = _sortBy;
        String localSpecies = _speciesFilter;
        String localGender = _genderFilter;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
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
                  DropdownButtonFormField<String>(
                    value: localSort,
                    items: const [
                      DropdownMenuItem(
                        value: 'postedAt',
                        child: Text('Posted At'),
                      ),
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                    ],
                    onChanged: (v) => localSort = v ?? 'postedAt',
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Species',
                    style: TextStyle(color: kSecondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: localSpecies,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                      DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                    ],
                    onChanged: (v) => localSpecies = v ?? 'All',
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gender',
                    style: TextStyle(color: kSecondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: localGender,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (v) => localGender = v ?? 'All',
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // clear
                            Navigator.of(ctx).pop({
                              'sortBy': 'postedAt',
                              'species': 'All',
                              'gender': 'All',
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop({
                              'sortBy': localSort,
                              'species': localSpecies,
                              'gender': localGender,
                            });
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
      backgroundColor: kBackgroundColor, // Set the dark background color
      appBar: buildPawsCareAppBar(
        context: context,
        onMenuSelected: (value) {
          if (value == 'profile') {
            mainNavKey.currentState?.selectTab(4);
          } else if (value == 'all_applications') {
            Navigator.of(context).pushNamed('/all-applications');
          } else if (value == 'my_applications') {
            Navigator.of(context).pushNamed('/my-applications');
          }
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          // Convert to list of maps for easier filtering/sorting
          final List<Map<String, dynamic>> animalList = animals.map((doc) {
            return {'id': doc.id, ...(doc.data() as Map<String, dynamic>)};
          }).toList();

          // Apply species/gender filters
          List<Map<String, dynamic>> filtered = animalList.where((a) {
            if (_speciesFilter != 'All') {
              final species = (a['species'] ?? '').toString().toLowerCase();
              if (!species.contains(_speciesFilter.toLowerCase())) return false;
            }
            if (_genderFilter != 'All') {
              final gender = (a['gender'] ?? '').toString().toLowerCase();
              if (!gender.contains(_genderFilter.toLowerCase())) return false;
            }
            return true;
          }).toList();

          // Sorting
          if (_sortBy == 'name') {
            filtered.sort((x, y) {
              final a = (x['name'] ?? '').toString();
              final b = (y['name'] ?? '').toString();
              return a.toLowerCase().compareTo(b.toLowerCase());
            });
          } else {
            // postedAt descending
            filtered.sort((x, y) {
              final aTime = x['postedAt'];
              final bTime = y['postedAt'];
              try {
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                final aMillis = (aTime is int)
                    ? aTime
                    : (aTime.millisecondsSinceEpoch ?? 0);
                final bMillis = (bTime is int)
                    ? bTime
                    : (bTime.millisecondsSinceEpoch ?? 0);
                return bMillis.compareTo(aMillis);
              } catch (e) {
                return 0;
              }
            });
          }

          // Build a ListView where the first item is the header (so it scrolls with content)
          if (filtered.isEmpty) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // Header as first child
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Animals Available for Adoption',
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
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Filter'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'No animals available for adoption right now.',
                    style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: filtered.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                // Header
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Animals Available for Adoption',
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
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Filter'),
                      ),
                    ],
                  ),
                );
              }

              final animalData = filtered[index - 1];

              return AnimalCard(
                animal: animalData,
                isLiked: false,
                isSaved: false,
                likeCount: (animalData['likeCount'] as int?) ?? 0,
                onLike: () {},
                onSave: () {},
              );
            },
          );
        },
      ),
    );
  }
}
