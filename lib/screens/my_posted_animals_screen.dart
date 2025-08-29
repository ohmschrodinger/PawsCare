import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/widgets/animal_card.dart';
import '../utils/constants.dart';

// Key Change: Renamed widget to MyPostedAnimalsScreen
class MyPostedAnimalsScreen extends StatefulWidget {
  const MyPostedAnimalsScreen({Key? key}) : super(key: key);

  @override
  // Key Change: Renamed state class to _MyPostedAnimalsScreenState
  State<MyPostedAnimalsScreen> createState() => _MyPostedAnimalsScreenState();
}

// Key Change: Renamed state class
class _MyPostedAnimalsScreenState extends State<MyPostedAnimalsScreen> {
  // Filters remain the same
  String? _filterSpecies;
  String? _filterGender;
  String? _filterSterilization;
  String? _filterVaccination;

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

    final favoritesSnapshot = await FirebaseFirestore.instance.collection('favorites').where('userId', isEqualTo: user.uid).get();
    final likedIds = favoritesSnapshot.docs.map((doc) => doc.data()['animalId'] as String).toSet();

    final savedSnapshot = await FirebaseFirestore.instance.collection('saved_animals').where('userId', isEqualTo: user.uid).get();
    final savedIds = savedSnapshot.docs.map((doc) => doc.data()['animalId'] as String).toSet();

    if (mounted) {
      setState(() {
        _likedAnimals = likedIds;
        _savedAnimals = savedIds;
      });
    }
  }

  // Key Change: This stream now filters for the current user's posts
  Stream<QuerySnapshot> _getAnimalsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Return an empty stream if the user is not logged in
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('animals')
        .where('postedByUserId', isEqualTo: user.uid) // This is the crucial filter!
        .snapshots();
  }

  // Like and Save logic remains the same as in FullAnimalListScreen
  void _likeAnimal(BuildContext context, String animalId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final animalRef = FirebaseFirestore.instance.collection('animals').doc(animalId);
    if (_likedAnimals.contains(animalId)) {
      _likedAnimals.remove(animalId);
      animalRef.update({'likeCount': FieldValue.increment(-1)});
      final favoritesSnapshot = await FirebaseFirestore.instance.collection('favorites').where('userId', isEqualTo: user.uid).where('animalId', isEqualTo: animalId).get();
      for (var doc in favoritesSnapshot.docs) {
        await doc.reference.delete();
      }
    } else {
      _likedAnimals.add(animalId);
      animalRef.update({'likeCount': FieldValue.increment(1)});
      await FirebaseFirestore.instance.collection('favorites').add({'userId': user.uid, 'animalId': animalId, 'likedAt': FieldValue.serverTimestamp()});
    }
  }

  void _saveAnimal(BuildContext context, String animalId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_savedAnimals.contains(animalId)) {
      _savedAnimals.remove(animalId);
      final savedSnapshot = await FirebaseFirestore.instance.collection('saved_animals').where('userId', isEqualTo: user.uid).where('animalId', isEqualTo: animalId).get();
      for (var doc in savedSnapshot.docs) {
        await doc.reference.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from saved items.'), duration: Duration(seconds: 1)));
    } else {
      _savedAnimals.add(animalId);
      await FirebaseFirestore.instance.collection('saved_animals').add({'userId': user.uid, 'animalId': animalId, 'savedAt': FieldValue.serverTimestamp()});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved for later!'), duration: Duration(seconds: 1)));
    }
  }

  // _openFilterSheet is identical to FullAnimalListScreen, no changes needed.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posted Animals'),
        // You might want to remove actions if filtering isn't needed here
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getAnimalsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final animals = snapshot.data?.docs ?? [];
          
          // Key Change: The filtering logic is now inside the builder scope
          // This ensures the `filteredAnimals` variable is always available.
          List<DocumentSnapshot> filteredAnimals = animals.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            bool matches = true;
            if (_filterSpecies != null) {
              matches = matches && (data['species'] == _filterSpecies);
            }
            if (_filterGender != null) {
              matches = matches && (data['gender'] == _filterGender);
            }
            // Add other filters if needed
            return matches;
          }).toList();

          if (filteredAnimals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'You have not posted any animals yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Key Change: Now correctly uses the `filteredAnimals` variable
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: filteredAnimals.length,
            itemBuilder: (context, index) {
              final animalDoc = filteredAnimals[index];
              final animalData = animalDoc.data() as Map<String, dynamic>;
              final animalId = animalDoc.id;
              final animal = {'id': animalId, ...animalData};
              final likeCount = (animalData['likeCount'] ?? 0) as int;

              return AnimalCard(
                animal: animal,
                isLiked: _likedAnimals.contains(animalId),
                isSaved: _savedAnimals.contains(animalId),
                likeCount: likeCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PetDetailScreen(petData: animal)),
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