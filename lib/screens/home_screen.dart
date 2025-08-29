// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/screens/full_animal_list_screen.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';

// NOTE: PostAnimalScreen import removed as FAB was removed, but you can add it back if needed.
// import 'package:pawscare/screens/post_animal_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool showAppBar;
  
  const HomeScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;

  late PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _infoPages = [
    {
      'title': 'A Winning Team',
      'text':
          'Our amazing team of volunteers are committed to helping animals in our community. We take our convictions and turn them into action. Think you would be a good fit? See our contact page for more information!',
    },
    {
      'title': 'Our History',
      'text':
          "Seeing a nonprofit to support our community's animals, we formed our organization to provide sensible solutions. We've grown considerably since then, all thanks to the helping hands of this amazing community!",
    },
    {
      'title': 'Animals Are Our Mission',
      'text':
          'We focus on making the maximum positive effect. Our members and volunteers provide the momentum we need. Using community driven models, we take actions that make a long-lasting difference.',
    },
    {
      'title': 'Mission',
      'text':
          'Our Mission is to “Make a Difference in the life of street animal”',
    },
    {
      'title': 'Vision',
      'text':
          'Our Vision is to provide world’s most successful onsite treatment service for street animals free of cost. Introducing new technology projects that will help street animals and to educate society for a good cause.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getAnimalsStream() {
    return FirebaseFirestore.instance.collection('animals').snapshots();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
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
      appBar: widget.showAppBar ? AppBar(
        systemOverlayStyle: isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        backgroundColor: appBarColor,
        elevation: 0,
        title: Text(
          'PawsCare',
          style: TextStyle(color: appBarTextColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: appBarTextColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_none, color: appBarTextColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.account_circle, color: appBarTextColor),
            onSelected: (value) {
              if (value == 'logout') _logout();
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
      ) : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildAnimalSection(
              title: "Adopt these Animals",
              subtitle: "Look at these poor pets and adopt them",
              statusFilter: 'Available',
              emptyMessage: "No animals available right now",
            ),
            const SizedBox(height: 16),
            _buildAnimalSection(
              title: "Previously Adopted",
              subtitle: "Happy pets who found their forever homes",
              statusFilter: 'Adopted',
              emptyMessage: "No animals adopted yet",
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          height: 250,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _infoPages.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildInfoPage(
                      title: _infoPages[index]['title'],
                      text: _infoPages[index]['text'],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              _buildPageIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPage({required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_infoPages.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: _currentPage == index ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Theme.of(context).primaryColor
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          leading: Icon(Icons.bar_chart, color: Theme.of(context).primaryColor),
          title: const Text(
            'Pet Adoption Stats',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          children: const [
            ListTile(
              title: Text('Pets Adopted this Month'),
              trailing: Text(
                '14',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: Text('Active Rescues'),
              trailing: Text(
                '32',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MODIFIED: The ListView.builder no longer has the problematic PageController.
  Widget _buildAnimalSection({
    required String title,
    required String subtitle,
    required String statusFilter,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: false).push(
                    MaterialPageRoute(
                      builder: (context) => FullAnimalListScreen(
                        title: title,
                        animalStatus: statusFilter,
                      ),
                      fullscreenDialog: false,
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Text("See More"),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: StreamBuilder<QuerySnapshot>(
            stream: _getAnimalsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final animals = snapshot.data?.docs ?? [];
              List filteredAnimals;

              if (statusFilter == 'Available') {
                filteredAnimals = animals.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['approvalStatus'] == 'approved' &&
                      data['status'] != 'Adopted';
                }).toList();
              } else {
                filteredAnimals = animals.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'Adopted';
                }).toList();
              }

              if (filteredAnimals.isEmpty) {
                return Center(child: Text(emptyMessage));
              }

              final previewAnimals = filteredAnimals.take(10).toList();

              // FIX: Removed the PageController from the ListView. The card width is
              // now controlled in the HorizontalPetCard widget itself.
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: previewAnimals.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final animalData =
                      previewAnimals[index].data() as Map<String, dynamic>;
                  final imageUrls =
                      animalData['imageUrls'] as List<dynamic>? ?? [];
                  final imageUrl =
                      (imageUrls.isNotEmpty ? imageUrls.first : null) ??
                      (animalData['image'] ??
                          'https://via.placeholder.com/150');
                  final pet = {
                    'id': previewAnimals[index].id,
                    ...animalData,
                    'image': imageUrl,
                  };
                  return HorizontalPetCard(
                    pet: pet,
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
      ],
    );
  }
}

// MODIFIED: Card width is now explicitly set to a fraction of the screen width.
class HorizontalPetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final VoidCallback onTap;

  const HorizontalPetCard({Key? key, required this.pet, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FIX: Set a fixed width as a percentage of the screen width. This is a
    // more reliable way to achieve the "1.x card" look without layout errors.
    final cardWidth = MediaQuery.of(context).size.width * 0.75;

    return SizedBox(
      width: cardWidth,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Image.network(
                  pet['image'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.pets, color: Colors.grey, size: 50),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pet['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pet['species'] ?? 'N/A'} • ${pet['age'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
