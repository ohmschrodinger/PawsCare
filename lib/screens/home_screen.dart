// lib/screens/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/services/greeting_service.dart';
import 'package:pawscare/services/stats_service.dart';
import '../widgets/paws_care_app_bar.dart';
import '../../main_navigation_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// -------------------- Color Palette --------------------
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);

// -------------------- HomeScreen --------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: buildPawsCareAppBar(context: context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WelcomeSection(),
            const SizedBox(height: 24),
            _buildPetOfTheDay(),
            const SizedBox(height: 24),
            _buildQuickActionsSection(),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            _buildAnimalSection(
              title: "Previously Adopted",
              subtitle: "Happy pets who found their forever homes",
              statusFilter: 'Adopted',
              emptyMessage: "No animals adopted yet",
            ),
            const SizedBox(height: 24),
            // Extra padding at bottom to account for floating navbar
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  // -------------------- Quick Actions Section --------------------
  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Header with title and menu (OUTSIDE the card)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryTextColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Small ways to help pets',
                    style: TextStyle(fontSize: 14, color: kSecondaryTextColor),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: kPrimaryTextColor),
                onSelected: (value) {
                  if (value == 'post') {
                    Navigator.pushNamed(context, '/post-pet');
                  } else if (value == 'adopt') {
                    mainNavKey.currentState?.selectTab(1); // Adopt tab
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'post',
                    child: Row(
                      children: [
                        Icon(Icons.pets, size: 20),
                        SizedBox(width: 8),
                        Text('Post New Pet'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'adopt',
                    child: Row(
                      children: [
                        Icon(Icons.favorite, size: 20),
                        SizedBox(width: 8),
                        Text('Adopt Pet'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Card containing the stats
          Card(
            clipBehavior: Clip.antiAlias,
            color: kCardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<Map<String, int>>(
                stream: StatsService.getAdoptionStatsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading stats',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: kPrimaryAccentColor,
                      ),
                    );
                  }

                  final stats =
                      snapshot.data ??
                      {'adoptedThisMonth': 0, 'activeRescues': 0};

                  // HORIZONTAL layout for the original stats
                  return Row(
                    children: [
                      // Pets Adopted
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stats['adoptedThisMonth']}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryAccentColor,
                                ),
                              ),
                              const Text(
                                'Pets\nAdopted so Far',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: kSecondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Active Rescues
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stats['activeRescues']}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryAccentColor,
                                ),
                              ),
                              const Text(
                                'Active\nRescues so Far',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: kSecondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- Pet of the Day Section --------------------
  Widget _buildPetOfTheDay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Header with "Pet of the Day" and "See More"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Pet of the Day',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700, // HIG: Bold for section headers
                  color: kPrimaryTextColor,
                  letterSpacing: 0.35,
                ),
              ),
              // Rounded "See More" button with lighter yellow color
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    192,
                    255,
                    204,
                    0,
                  ), // Lighter, more iOS-like yellow
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      mainNavKey.currentState?.selectTab(
                        1,
                      ); // Navigate to Adopt tab
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'See More',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13, // HIG: Smaller button text
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.08,
                            ),
                          ),
                          SizedBox(width: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Card containing pet content
          Card(
            clipBehavior: Clip.antiAlias,
            color: kCardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              height: 190, // Increased height for the card
              child: Row(
                children: [
                  // Left Side: Image
                  Expanded(
                    flex: 2,
                    child: Image.network(
                      // Using a cat image to match the provided UI
                      'https://images.unsplash.com/photo-1574144611937-0df059b5ef3e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1964&q=80',
                      fit: BoxFit.cover,
                      height: double.infinity,
                    ),
                  ),
                  // Right Side: Text and Button
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top part with Title and Description
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Meet Rocky!',
                                style: TextStyle(
                                  fontSize: 20, // HIG: Title 2
                                  fontWeight: FontWeight.w700,
                                  color: kPrimaryTextColor,
                                  letterSpacing: 0.38,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'This playful pup loves belly rubs.',
                                style: TextStyle(
                                  fontSize: 15, // HIG: Body
                                  fontWeight: FontWeight.w400,
                                  color: kSecondaryTextColor,
                                  letterSpacing: -0.24,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                          // Bottom part with Centered Rounded Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFCC00,
                                ), // Lighter yellow
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFFCC00,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PetDetailScreen(
                                          petData: {
                                            'name': 'Rocky',
                                            'species': 'Cat',
                                            'age': '2 years',
                                            'image':
                                                'https://images.unsplash.com/photo-1574144611937-0df059b5ef3e',
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(60),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 7.5,
                                    ),
                                    child: const Text(
                                      'Learn More',
                                      style: TextStyle(
                                        fontSize: 15, // HIG: Body/Button text
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- Animal Section --------------------
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
                    mainNavKey.currentState?.selectTab(1); // Adopt tab
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

// -------------------- Welcome Section --------------------
class WelcomeSection extends StatefulWidget {
  const WelcomeSection({super.key});

  @override
  _WelcomeSectionState createState() => _WelcomeSectionState();
}

class _WelcomeSectionState extends State<WelcomeSection> {
  final PageController _pageController;
  double _currentPageValue = 0.0;

  _WelcomeSectionState()
    : _pageController = PageController(viewportFraction: 1.00);

  final List<Map<String, dynamic>> _infoPages = [
    {
      'title': 'Welcome to PawsCare',
      'text':
          'Your one-stop app for adopting, rescuing, and caring for animals in need. Whether you’re looking to adopt or just spread love, PawsCare connects you with pets who need a home.',
    },
    {
      'title': 'About PawsCare Animal Resq',
      'text':
          "PawsCare is a passionate NGO dedicated to rescuing, rehabilitating, and rehoming stray animals.",
    },
    {
      'title': 'What You Can Do in the App',
      'text':
          'Discover animals up for adoption, share stories, or post your own rescues. PawsCare isn’t just an app it’s a community for animal lovers.',
    },
    {
      'title': 'Meet Our Happy Tails',
      'text':
          'Over 100 pets have already found loving homes through PawsCare. Every adoption story inspires the next.\nyours could be next!',
    },
    {
      'title': 'Join the Mission',
      'text':
          'Adopt, volunteer, or spread the word — every small action makes a big difference. Together, we can create a world where every animal is cared for and loved.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 290,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: StreamBuilder<String>(
              stream: GreetingService.getGreetingStream(),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? GreetingService.getTimeBasedGreeting(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryTextColor,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _infoPages.length,
              itemBuilder: (context, index) {
                double delta = index - _currentPageValue;
                double scale = (1 - (delta.abs() * 0.15)).clamp(0.85, 1.0);

                return Transform.scale(
                  scale: scale,
                  child: _buildInfoPage(
                    title: _infoPages[index]['title'],
                    text: _infoPages[index]['text'],
                    imagePath: 'assets/images/welcome${index + 1}.png',
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildInfoPage({
    required String title,
    required String text,
    required String imagePath,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade800,
                  alignment: Alignment.center,
                  child: const Text(
                    'Image not found',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
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
                      color: kPrimaryTextColor,
                      height: 1.4,
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

  Widget _buildPageIndicator() {
    return Center(
      child: SmoothPageIndicator(
        controller: _pageController,
        count: _infoPages.length,
        effect: WormEffect(
          dotHeight: 8.0,
          dotWidth: 8.0,
          activeDotColor: kPrimaryAccentColor,
          dotColor: Colors.grey.shade800,
        ),
      ),
    );
  }
}

// -------------------- Horizontal Pet Card --------------------
class HorizontalPetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final VoidCallback onTap;

  const HorizontalPetCard({super.key, required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.75;

    return SizedBox(
      width: cardWidth,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: kCardColor,
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
                    child: const Icon(
                      Icons.pets,
                      color: kSecondaryTextColor,
                      size: 50,
                    ),
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
