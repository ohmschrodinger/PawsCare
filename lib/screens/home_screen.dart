// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/screens/my_applications_screen.dart';
import 'package:pawscare/screens/post_animal_screen.dart';
import '../services/animal_service.dart';

// Mock data removed - now using Firestore data

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // For Bottom Navigation Bar
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigate based on selected tab
    if (index == 0) {
      // Already on Home, or pop until home if somehow navigated deeper
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    } else if (index == 1) {
      // Navigate to My History / My Applications
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyApplicationsScreen()),
      );
    } else if (index == 2) {
      // Navigate to Post Animal
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PostAnimalScreen()),
      );
    } else {
      // For other tabs, you might show a snackbar or navigate to placeholder screens
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation to Tab ${index + 1} (Coming Soon!)'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAWS CARE'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality (placeholder)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              await AnimalService.testAnimalsCollection();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Check console for debug info')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality (placeholder)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter coming soon!')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: AnimalService.getAllAnimals(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('DEBUG: Firestore error: ${snapshot.error}');
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              print('DEBUG: Waiting for Firestore connection...');
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final animals = snapshot.data?.docs ?? [];
            
            print('DEBUG: Found ${animals.length} animals');
            if (animals.isNotEmpty) {
              print('DEBUG: First animal data: ${animals.first.data()}');
            }

            if (animals.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pets,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No animals available for adoption yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to post an animal!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                                         ElevatedButton(
                       onPressed: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (context) => const PostAnimalScreen()),
                         );
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF5AC8F2),
                         foregroundColor: Colors.white,
                       ),
                       child: const Text('Post Animal'),
                     ),
                     const SizedBox(height: 16),
                     ElevatedButton(
                       onPressed: () async {
                         await AnimalService.testAnimalsCollection();
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.orange,
                         foregroundColor: Colors.white,
                       ),
                       child: const Text('Test Collection'),
                     ),
                  ],
                ),
              );
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two cards per row
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75, // Adjust to make cards look good
              ),
              itemCount: animals.length,
              itemBuilder: (context, index) {
                                 final animalData = animals[index].data() as Map<String, dynamic>;
                 print('DEBUG: Processing animal ${index + 1}: $animalData');
                 
                 final pet = <String, String>{
                   'id': animals[index].id,
                   'name': animalData['name']?.toString() ?? '',
                   'species': animalData['species']?.toString() ?? '',
                   'age': animalData['age']?.toString() ?? '',
                   'status': animalData['status']?.toString() ?? 'Available for Adoption',
                   'image': animalData['image']?.toString() ?? 'https://via.placeholder.com/150/FF5733/FFFFFF?text=Animal',
                   'gender': animalData['gender']?.toString() ?? '',
                   'sterilization': animalData['sterilization']?.toString() ?? '',
                   'vaccination': animalData['vaccination']?.toString() ?? '',
                   'rescueStory': animalData['rescueStory']?.toString() ?? '',
                   'motherStatus': animalData['motherStatus']?.toString() ?? '',
                 };
                 
                 print('DEBUG: Created pet object: $pet');
                 return PetCard(pet: pet);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostAnimalScreen()),
          );
        },
        backgroundColor: const Color(0xFF5AC8F2),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Post Animal',
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'My History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Post Animal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF5AC8F2),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are shown
      ),
    );
  }
}

// PetDetailScreen removed - importing from separate file


class PetCard extends StatelessWidget {
  final Map<String, String> pet;

  const PetCard({Key? key, required this.pet}) : super(key: key);

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
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                pet['image'] ?? '',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet['species'] ?? ''} • ${pet['age'] ?? ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pet['status'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00796B),
                        fontWeight: FontWeight.bold,
                      ),
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
