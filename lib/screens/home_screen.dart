// lib/screens/home_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/services/animal_service.dart';
import '../widgets/paws_care_app_bar.dart';
import '../../main_navigation_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Define the new color palette for easy access and consistency
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber; // Vibrant yellow accent
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);

class HomeScreen extends StatefulWidget {
  final bool showAppBar;

  const HomeScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor, // Set the main background color
      appBar: widget.showAppBar
          ? buildPawsCareAppBar(
              context: context,
              onLogout: _logout,
              onMenuSelected: (value) {
                if (value == 'profile') {
                  mainNavKey.currentState?.selectTab(4);
                } else if (value == 'all_applications') {
                  Navigator.of(context).pushNamed('/all-applications');
                } else if (value == 'my_applications') {
                  Navigator.of(context).pushNamed('/my-applications');
                }
              },
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WelcomeSection(),
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

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        color: kCardColor, // Dark card background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          iconColor: kPrimaryAccentColor,
          collapsedIconColor: kSecondaryTextColor,
          leading: const Icon(Icons.bar_chart, color: kPrimaryAccentColor),
          title: const Text(
            'Pet Adoption Stats',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kPrimaryTextColor,
            ),
          ),
          children: const [
            ListTile(
              title: Text(
                'Pets Adopted this Month',
                style: TextStyle(color: kSecondaryTextColor),
              ),
              trailing: Text(
                '14',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryAccentColor,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              title: Text(
                'Active Rescues',
                style: TextStyle(color: kSecondaryTextColor),
              ),
              trailing: Text(
                '32',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryAccentColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                        color: kPrimaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: kSecondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (statusFilter == 'Available')
                TextButton(
                  onPressed: () {
                    mainNavKey.currentState?.selectTab(1);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: kPrimaryAccentColor,
                  ),
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
            stream: statusFilter == 'Available'
                ? AnimalService.getAvailableAnimals()
                : AnimalService.getAdoptedAnimals(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error loading animals',
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
                return Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(color: kSecondaryTextColor),
                  ),
                );
              }

              final previewAnimals = animals.take(10).toList();

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

class WelcomeSection extends StatefulWidget {
  const WelcomeSection({Key? key}) : super(key: key);

  @override
  _WelcomeSectionState createState() => _WelcomeSectionState();
}

class _WelcomeSectionState extends State<WelcomeSection> {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        color: kCardColor, // Dark background for the welcome section
        height: 250,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _infoPages.length,
                // Note: The onPageChanged callback is no longer needed
                // because the SmoothPageIndicator handles this automatically.
                itemBuilder: (context, index) {
                  return _buildInfoPage(
                    title: _infoPages[index]['title'],
                    text: _infoPages[index]['text'],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _buildPageIndicator(), // This now calls the updated widget
          ],
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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kPrimaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 15,
              color: kSecondaryTextColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- 👇 THIS IS THE UPDATED WIDGET ---
  Widget _buildPageIndicator() {
    return SmoothPageIndicator(
      controller: _pageController,
      count: _infoPages.length,
      effect: WormEffect( // This provides the smooth "worm-like" animation
        dotHeight: 8.0,
        dotWidth: 8.0,
        activeDotColor: kPrimaryAccentColor,
        dotColor: Colors.grey.shade800,
      ),
    );
  }
}




class HorizontalPetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final VoidCallback onTap;

  const HorizontalPetCard({Key? key, required this.pet, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.75;

    return SizedBox(
      width: cardWidth,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: kCardColor, // Dark card background
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
                    color: Colors.black.withOpacity(0.5),
                    child: const Icon(Icons.pets,
                        color: kSecondaryTextColor, size: 50),
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
                          color: kPrimaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pet['species'] ?? 'N/A'} • ${pet['age'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: kSecondaryTextColor,
                        ),
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