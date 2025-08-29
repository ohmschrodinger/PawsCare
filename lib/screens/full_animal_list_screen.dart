// lib/screens/full_animal_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/widgets/animal_card.dart';
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

  // Liked animals tracking
  Set<String> _likedAnimals = {};
  Set<String> _savedAnimals = {};

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  void _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Load liked animals
    final favoritesSnapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .get();
    
    setState(() {
      _likedAnimals = favoritesSnapshot.docs
          .map((doc) => doc.data()['animalId'] as String)
          .toSet();
    });
  }

  Stream<QuerySnapshot> _getAnimalsStream() {
    return FirebaseFirestore.instance.collection('animals').snapshots();
  }

  void _likeAnimal(BuildContext context, String animalId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (_likedAnimals.contains(animalId)) {
        // Unlike
        final favoritesSnapshot = await FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user.uid)
            .where('animalId', isEqualTo: animalId)
            .get();
        
        for (var doc in favoritesSnapshot.docs) {
          await doc.reference.delete();
        }
        
        setState(() {
          _likedAnimals.remove(animalId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites!'),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        // Like
        await FirebaseFirestore.instance.collection('favorites').add({
          'userId': user.uid,
          'animalId': animalId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _likedAnimals.add(animalId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites!'),
            backgroundColor: Colors.pinkAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating favorites. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveAnimal(String animalId) {
    setState(() {
      if (_savedAnimals.contains(animalId)) {
        _savedAnimals.remove(animalId);
      } else {
        _savedAnimals.add(animalId);
      }
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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
                  DropdownButtonFormField<String>(
                    value: _filterGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _filterVaccination,
                    decoration: const InputDecoration(
                      labelText: 'Vaccination',
                      border: OutlineInputBorder(),
                    ),
                    items: [null, 'Yes', 'No', 'Partial']
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e ?? 'Any'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        modalState(() => _filterVaccination = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _filterSterilization,
                    decoration: const InputDecoration(
                      labelText: 'Sterilization',
                      border: OutlineInputBorder(),
                    ),
                    items: [null, 'Yes', 'No']
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e ?? 'Any'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        modalState(() => _filterSterilization = value),
                  ),
                  const SizedBox(height: 20),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _getAnimalsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading animals.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final animals = snapshot.data?.docs ?? [];
          List filteredAnimals;

          // Filter by status
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
            if (_filterVaccination != null) {
              matches = matches && (data['vaccination'] == _filterVaccination);
            }
            if (_filterSterilization != null) {
              matches = matches && (data['sterilization'] == _filterSterilization);
            }
            
            return matches;
          }).toList();

          if (filteredAnimals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No animals found.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_filterSpecies != null ||
                      _filterGender != null ||
                      _filterVaccination != null ||
                      _filterSterilization != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your filters.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
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
              
              final animal = {
                'id': animalId,
                ...animalData,
              };

              return AnimalCard(
                animal: animal,
                isLiked: _likedAnimals.contains(animalId),
                isSaved: _savedAnimals.contains(animalId),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PetDetailScreen(petData: animal),
                    ),
                  );
                },
                onLike: () => _likeAnimal(context, animalId),
                onSave: () => _saveAnimal(animalId),
              );
            },
          );
        },
      ),
    );
  }
}