// lib/screens/animal_adoption_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/widgets/paws_care_app_bar.dart';
import 'package:pawscare/widgets/animal_card.dart';
import '../main_navigation_screen.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kPrimaryAccentColor = Colors.amber;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -----------------------------------------

class AnimalAdoptionScreen extends StatelessWidget {
  const AnimalAdoptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor, // Set the dark background color
      appBar: buildPawsCareAppBar(
        context: context,
        onMenuSelected: (value) {
          // Navigation logic remains unchanged
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
                child: Text('Something went wrong',
                    style: TextStyle(color: Colors.redAccent)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryAccentColor));
          }

          final animals = snapshot.data?.docs ?? [];

          if (animals.isEmpty) {
            return const Center(
              child: Text(
                'No animals available for adoption right now.',
                style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animalDoc = animals[index];
              final animalData = {
                'id': animalDoc.id,
                ...(animalDoc.data() as Map<String, dynamic>),
              };

              // NOTE: This relies on `AnimalCard` also being styled for the dark theme.
              return AnimalCard(
                animal: animalData,
                isLiked: false, // This functionality remains as TODO
                isSaved: false, // This functionality remains as TODO
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