import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'pet_detail_screen.dart';
import 'package:pawscare/constants/app_colors.dart';

class MyPostedAnimalsScreen extends StatefulWidget {
  const MyPostedAnimalsScreen({super.key});

  @override
  State<MyPostedAnimalsScreen> createState() => _MyPostedAnimalsScreenState();
}

class _MyPostedAnimalsScreenState extends State<MyPostedAnimalsScreen> {
  Stream<QuerySnapshot> _getAnimalsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('animals')
        .where('postedBy', isEqualTo: user.uid)
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'My Posted Animals',
          style: TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getAnimalsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Something went wrong.',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryAccentColor),
            );
          }

          final animals = snapshot.data?.docs ?? [];

          if (animals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: 64,
                    color: kSecondaryTextColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "You haven't posted any animals yet.",
                    style: TextStyle(fontSize: 18, color: kSecondaryTextColor),
                  ),
                ],
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
              final animalId = doc.id;
              final petData = {
                'id': animalId,
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
          MaterialPageRoute(builder: (_) => PetDetailScreen(petData: pet)),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: kCardColor,
        elevation: 2,
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
