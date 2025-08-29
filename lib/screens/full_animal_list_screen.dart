// lib/screens/full_animal_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import '../utils/constants.dart';

class FullAnimalListScreen extends StatefulWidget {
  final String title;
  final String animalStatus; // 'Available' or 'Adopted'

  const FullAnimalListScreen({
    Key? key,
    required this.title,
    required this.animalStatus,
  }) : super(key: key);

  @override
  State<FullAnimalListScreen> createState() => _FullAnimalListScreenState();
}

class _FullAnimalListScreenState extends State<FullAnimalListScreen> {
  // Filters
  String? _filterSpecies;
  String? _filterGender;
  String? _filterSterilization;
  String? _filterVaccination;

  Stream<QuerySnapshot> _getAnimalsStream() {
    return FirebaseFirestore.instance.collection('animals').snapshots();
  }

  void _likeAnimal(BuildContext context, String animalId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('favorites').add({
      'userId': user.uid,
      'animalId': animalId,
      'likedAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to favorites!'),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        // Using a StatefulBuilder to manage the state of the modal sheet locally
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Animals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _filterSpecies,
                    decoration: const InputDecoration(
                      labelText: 'Species',
                      border: OutlineInputBorder(),
                    ),
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
                  const SizedBox(height: 12),
                  // ... other filter dropdowns ...
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Apply filters by updating the main screen's state
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appBarColor = isDarkMode
        ? theme.scaffoldBackgroundColor
        : Colors.grey.shade50;
    final appBarTextColor = theme.textTheme.titleLarge?.color;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: Text(
          widget.title,
          style: TextStyle(color: appBarTextColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: appBarTextColor),
            tooltip: 'Filter Animals',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _getAnimalsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading animals.'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
              // 'Adopted'
              filteredAnimals = animals.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'Adopted';
              }).toList();
            }

            // Apply client-side filters
            filteredAnimals = filteredAnimals.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              bool matches = true;
              if (_filterSpecies != null) {
                matches = matches && (data['species'] == _filterSpecies);
              }
              if (_filterGender != null) {
                matches = matches && (data['gender'] == _filterGender);
              }
              // ... add other filters
              return matches;
            }).toList();

            if (filteredAnimals.isEmpty) {
              return const Center(child: Text('No animals found.'));
            }

            return ListView.builder(
              itemCount: filteredAnimals.length,
              itemBuilder: (context, index) {
                final animalData =
                    filteredAnimals[index].data() as Map<String, dynamic>;
                final imageUrls =
                    animalData['imageUrls'] as List<dynamic>? ?? [];
                final imageUrl =
                    (imageUrls.isNotEmpty ? imageUrls.first : null) ??
                    (animalData['image'] ?? 'https://via.placeholder.com/150');
                final pet = {
                  'id': filteredAnimals[index].id,
                  ...animalData,
                  'image': imageUrl,
                };
                return PetCard(
                  pet: pet,
                  onLike: () => _likeAnimal(context, pet['id']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetDetailScreen(petData: pet),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ------------------- PET CARD WIDGET -------------------
// This is used by the FullAnimalListScreen.
// You can also move this to its own file e.g. `lib/widgets/pet_card.dart`

class PetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onTap;

  const PetCard({
    Key? key,
    required this.pet,
    this.onLike,
    this.onSave,
    this.onTap,
  }) : super(key: key);

  IconData _getGenderIcon(String? gender) =>
      gender?.toLowerCase() == 'male' ? Icons.male : Icons.female;
  Color _getGenderColor(String? gender) =>
      gender?.toLowerCase() == 'male' ? Colors.blue : Colors.pink;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              pet['image'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Icon(Icons.pets, color: Colors.grey, size: 60),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pet['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _getGenderIcon(pet['gender']),
                        color: _getGenderColor(pet['gender']),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet['species'] ?? 'N/A'} • ${pet['age'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pet['location'] ?? 'Not specified',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: onLike,
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.pinkAccent,
                    ),
                    tooltip: 'Like',
                  ),
                  IconButton(
                    onPressed: onSave,
                    icon: const Icon(Icons.bookmark_border, color: Colors.grey),
                    tooltip: 'Save',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
