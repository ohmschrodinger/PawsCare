// lib/screens/animal_adoption_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/widgets/paws_care_app_bar.dart';

class AnimalAdoptionScreen extends StatelessWidget {
  const AnimalAdoptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPawsCareAppBar(
        context: context,
        onMenuSelected: (value) {
          if (value == 'profile') {
            Navigator.of(context).pushNamed('/profile');
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
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final animals = snapshot.data?.docs ?? [];

          if (animals.isEmpty) {
            return const Center(
              child: Text(
                'No animals available for adoption right now.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animalDoc = animals[index];
              final animalData = animalDoc.data() as Map<String, dynamic>;
              final imageUrls = animalData['imageUrls'] as List<dynamic>? ?? [];
              final imageUrl =
                  (imageUrls.isNotEmpty ? imageUrls.first : null) ??
                  (animalData['image'] ?? 'https://via.placeholder.com/150');

              final pet = {
                'id': animalDoc.id,
                ...animalData,
                'image': imageUrl,
              };

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  leading: Image.network(
                    pet['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.pets, size: 50),
                  ),
                  title: Text(
                    pet['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${pet['species'] ?? 'N/A'} • ${pet['breed'] ?? 'N/A'}',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetDetailScreen(petData: pet),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
