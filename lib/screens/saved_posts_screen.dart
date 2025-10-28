import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_favorites_service.dart';
import 'pet_detail_screen.dart';
import '../constants/app_colors.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Saved Posts',
            style: TextStyle(
              color: kPrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Please log in to view your saved posts.',
            style: TextStyle(color: kSecondaryTextColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Posts',
          style: TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: UserFavoritesService.getSavedAnimalDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryAccentColor),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final animals = snapshot.data?.docs ?? [];
          if (animals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "You haven't saved any animals yet.",
                  style: TextStyle(color: kSecondaryTextColor, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final doc = animals[index];
              final data = doc.data() as Map<String, dynamic>;
              final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];
              final petData = {
                'id': doc.id,
                ...data,
                'image': imageUrls.isNotEmpty ? imageUrls.first : null,
              };

              return _AnimalGridCard(pet: petData);
            },
          );
        },
      ),
    );
  }
}

class _AnimalGridCard extends StatelessWidget {
  final Map<String, dynamic> pet;

  const _AnimalGridCard({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailScreen(petData: pet),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        color: kCardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: pet['image'] != null
                  ? Image.network(
                      pet['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(
                          Icons.pets,
                          color: kSecondaryTextColor,
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade900,
                      child: const Icon(
                        Icons.pets,
                        color: kSecondaryTextColor,
                        size: 40,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kPrimaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pet['species'] ?? 'N/A'} • ${pet['age'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: kSecondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
