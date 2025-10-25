// lib/screens/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/services/greeting_service.dart';
import 'package:pawscare/services/stats_service.dart';
import 'package:pawscare/theme/typography.dart';
import '../widgets/paws_care_app_bar.dart';
import '../../main_navigation_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// -------------------- Color Palette --------------------
// Note: kBackgroundColor is no longer used for the Scaffold background
// but might be used by other components.
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
      appBar: buildPawsCareAppBar(context: context) as AppBar,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WelcomeSection(),
            const SizedBox(height: 24),
            _buildPetOfTheDay(),
            const SizedBox(height: 24),
            _buildQuickActionsSection(),
            const SizedBox(height: 24),
            _buildAnimalSection(
              title: "Available for Adoption",
              subtitle: "Pets waiting for a loving home",
              statusFilter: 'Available',
              emptyMessage: "No pets available for adoption right now",
            ),
            const SizedBox(height: 24),
            _buildAnimalSection(
              title: "Previously Adopted",
              subtitle: "Happy pets who found their forever homes",
              statusFilter: 'Adopted',
              emptyMessage: "No animals adopted yet",
            ),
            const SizedBox(height: 24),
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
          // Header with title and menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: AppTypography.title3.copyWith(
                      color: kPrimaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Small ways to help pets',
                    style: AppTypography.subhead.copyWith(
                      color: kSecondaryTextColor,
                    ),
                  ),
                ],
              ),
              PopupMenuTheme(
                data: PopupMenuThemeData(
                  color: kCardColor.withOpacity(0.75),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: kPrimaryTextColor),
                  tooltip: "More actions",
                  onSelected: (value) {
                    if (value == 'post') {
                      mainNavKey.currentState?.selectTab(2);
                    } else if (value == 'adopt') {
                      mainNavKey.currentState?.selectTab(1);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'post',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 22, color: kPrimaryTextColor),
                          SizedBox(width: 12),
                          Text(
                            'Post New Pet',
                            style: TextStyle(color: kPrimaryTextColor),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'adopt',
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 20,
                            color: kPrimaryTextColor,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Adopt Pet',
                            style: TextStyle(color: kPrimaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Glassmorphic section
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Bottom layer: background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/statsbg.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // Middle layer: outer glassmorphic card
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      height: 200, // Adjust outer card height
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                // Top layer: two inner stats cards
                Positioned.fill(
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

                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
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

                        return Row(
                          children: [
                            // First stats card
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.08),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Second stats card
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.08),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          'Pets\nposted so far',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: kSecondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
              Text(
                'Pet of the Day',
                style: AppTypography.title3.copyWith(
                  color: kPrimaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stack: Bottom image + Glassmorphic Card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Bottom-most layer: Pet image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/background.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // Glassmorphic Card on top
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: 190,
                    decoration: BoxDecoration(
                      color: kCardColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        // Left Side: Image
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1574144611937-0df059b5ef3e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1964&q=80',
                              fit: BoxFit.cover,
                              height: double.infinity,
                            ),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Meet Billi',
                                      style: AppTypography.headline.copyWith(
                                        color: kPrimaryTextColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'This playful cutie loves belly rubs and what not.',
                                      style: AppTypography.subhead.copyWith(
                                        color: kSecondaryTextColor,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            60,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PetDetailScreen(
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
                                            borderRadius: BorderRadius.circular(
                                              60,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 10,
                                              ),
                                              child: Text(
                                                'See More',
                                                style: AppTypography.callout
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: kPrimaryTextColor,
                                                    ),
                                              ),
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
          ),
        ],
      ),
    );
  }

  // -------------------- Animal Section --------------------
  // lib/screens/home_screen.dart -> inside _HomeScreenState

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
                      style: AppTypography.title3.copyWith(
                        color: kPrimaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.subhead.copyWith(
                        color: kSecondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // --- THIS WIDGET IS NOW UPDATED ---
              if (statusFilter == 'Available')
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(
                          0.25,
                        ), // Consistent glass tint
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            0.12,
                          ), // Consistent glass outline
                          width: 1.25,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            mainNavKey.currentState?.selectTab(1); // Adopt tab
                          },
                          borderRadius: BorderRadius.circular(60),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'See More',
                                style: AppTypography.callout.copyWith(
                                  color: kPrimaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                            ],
                          ),
                        ),
                      ),
                    ),
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
      height: 320,
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.data ?? GreetingService.getTimeBasedGreeting(),
                      style: AppTypography.title2.copyWith(
                        color: kPrimaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      GreetingService.getTimeBasedSubtext(),
                      style: AppTypography.body.copyWith(
                        color: kPrimaryTextColor.withOpacity(0.7),
                      ),
                    ),
                  ],
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
            // --- LAYER 1: BACKGROUND IMAGE ---
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

            // --- LAYER 2: GLASSMORPHIC OVERLAY ---
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),

            // --- LAYER 3: TEXT CONTENT ---
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
                    style: AppTypography.title3.copyWith(
                      color: kPrimaryTextColor,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black54),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    text,
                    textAlign: TextAlign.start,
                    style: AppTypography.subhead.copyWith(
                      color: kPrimaryTextColor,
                      height: 1.4,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black54),
                      ],
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

// -------------------- Horizontal Pet Card (UNIFIED STYLE) --------------------
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          elevation: 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- LAYER 1: THE FULL BACKGROUND IMAGE ---
              Image.network(
                pet['image'],
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

              // --- LAYER 2: LAYOUT AND BLUR ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOP: A transparent spacer that reveals the crisp image.
                  const Expanded(flex: 3, child: SizedBox.expand()),

                  // BOTTOM: The blurred info panel with UNIFIED styling.
                  Expanded(
                    flex: 2,
                    child: ClipRRect(
                      // BackdropFilter needs a clipping boundary
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  pet['name'] ?? 'Unknown',
                                  style: AppTypography.headline.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryTextColor,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${pet['species'] ?? 'N/A'} • ${pet['age'] ?? 'N/A'}',
                                  style: AppTypography.subhead.copyWith(
                                    color: kPrimaryTextColor,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
