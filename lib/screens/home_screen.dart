// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/screens/my_applications_screen.dart'; // Import the new screen

// Mock data for pets (retained from previous sprint)
final List<Map<String, String>> mockPets = [
  {
    'name': 'Buddy',
    'species': 'Dog',
    'age': '2 years',
    'status': 'Available for Adoption',
    'image': 'https://via.placeholder.com/150/FF5733/FFFFFF?text=Dog', // Placeholder image
    'gender': 'Male',
    'sterilization': 'Yes',
    'vaccination': 'Up-to-date',
    'rescueStory': 'Buddy was found wandering near a park, playful and friendly. He loves walks and cuddles.',
    'motherStatus': 'Unknown',
  },
  {
    'name': 'Whiskers',
    'species': 'Cat',
    'age': '1 year',
    'status': 'Available for Adoption',
    'image': 'https://via.placeholder.com/150/33FF57/FFFFFF?text=Cat',
    'gender': 'Female',
    'sterilization': 'Yes',
    'vaccination': 'Up-to-date',
    'rescueStory': 'Whiskers was rescued from a busy street. She is shy at first but very affectionate once she trusts you.',
    'motherStatus': 'Unknown',
  },
  {
    'name': 'Captain',
    'species': 'Parrot',
    'age': '3 years',
    'status': 'Available for Adoption',
    'image': 'https://via.placeholder.com/150/3357FF/FFFFFF?text=Bird',
    'gender': 'Male',
    'sterilization': 'N/A',
    'vaccination': 'Up-to-date',
    'rescueStory': 'Captain was surrendered by his previous owner who could no longer care for him. He loves to mimic sounds.',
    'motherStatus': 'Unknown',
  },
  {
    'name': 'Bubbles',
    'species': 'Fish',
    'age': '6 months',
    'status': 'Available for Adoption',
    'image': 'https://via.placeholder.com/150/F0FF33/FFFFFF?text=Fish',
    'gender': 'Unknown',
    'sterilization': 'N/A',
    'vaccination': 'N/A',
    'rescueStory': 'Bubbles was part of an overcrowded aquarium. He is now looking for a spacious new home.',
    'motherStatus': 'Unknown',
  },
  {
    'name': 'Shadow',
    'species': 'Dog',
    'age': '4 years',
    'status': 'Available for Adoption',
    'image': 'https://via.placeholder.com/150/8A2BE2/FFFFFF?text=Dog',
    'gender': 'Female',
    'sterilization': 'Yes',
    'vaccination': 'Up-to-date',
    'rescueStory': 'Shadow is a loyal companion, found abandoned but quick to trust. She is great with children and other pets.',
    'motherStatus': 'Unknown',
  },
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // For Bottom Navigation Bar

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
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality (placeholder)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two cards per row
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75, // Adjust to make cards look good
          ),
          itemCount: mockPets.length,
          itemBuilder: (context, index) {
            final pet = mockPets[index];
            return PetCard(pet: pet);
          },
        ),
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

class PetCard extends StatelessWidget {
  final Map<String, String> pet;

  const PetCard({Key? key, required this.pet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to PetDetailScreen, passing the pet data
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
                pet['image']!,
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
                    pet['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet['species']} • ${pet['age']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA), // Light blue background
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pet['status']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00796B), // Darker green text
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