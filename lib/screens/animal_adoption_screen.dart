// lib/screens/animal_adoption_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/widgets/paws_care_app_bar.dart';
import 'package:pawscare/widgets/animal_card.dart';
import '../main_navigation_screen.dart';

class AnimalAdoptionScreen extends StatelessWidget {
  const AnimalAdoptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPawsCareAppBar(
        context: context,
        onMenuSelected: (value) {
          if (value == 'profile') {
            mainNavKey.currentState?.selectTab(4); // Navigate to profile tab
          } else if (value == 'all_applications') {
            mainNavKey.currentState?.selectTab(0); // Go to home tab
            Navigator.of(context).pushNamed('/all-applications');
          } else if (value == 'my_applications') {
            mainNavKey.currentState?.selectTab(0); // Go to home tab
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
            padding: EdgeInsets
                .zero, // Remove padding as AnimalCard has its own margins
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animalDoc = animals[index];
              final animalData = {
                'id': animalDoc.id,
                ...(animalDoc.data() as Map<String, dynamic>),
              };

              return AnimalCard(
                animal: animalData,
                isLiked: false, // TODO: Implement like status from user data
                isSaved: false, // TODO: Implement save status from user data
                likeCount: (animalData['likeCount'] as int?) ?? 0,
                onLike: () {
                  // TODO: Implement like functionality
                },
                onSave: () {
                  // TODO: Implement save functionality
                },
              );
            },
          );
        },
      ),
    );
  }
}
