// lib/screens/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/services/greeting_service.dart';
import 'package:pawscare/services/stats_service.dart';
import 'package:pawscare/services/pet_of_day_service.dart';
import 'package:pawscare/theme/typography.dart';
import '../widgets/paws_care_app_bar.dart';
import '../../main_navigation_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:pawscare/constants/app_colors.dart';
import 'package:pawscare/constants/animal_status.dart';
import 'package:pawscare/screens/animal_map_screen.dart';

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

  // -------------------- Quick Actions Section (Corrected) --------------------
  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Header with title and menu (No changes here)
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
                    } else if (value == 'find') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnimalMapScreen(),
                        ),
                      );
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
                    const PopupMenuItem<String>(
                      value: 'find',
                      child: Row(
                        children: [
                          Icon(Icons.map, size: 20, color: kPrimaryTextColor),
                          SizedBox(width: 12),
                          Text(
                            'Find Pets',
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
                // Bottom layer: background image (This will now be clearly visible)
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/statsbg_blurred.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // --- CHANGE IS HERE ---
                // Middle layer: This is now just a semi-transparent overlay,
                // NOT a blur filter. The BackdropFilter has been removed.
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25), // The dark tint
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                ),

                // Top layer: two inner stats cards (These still have their blur)
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
                            {'totalAdoptions': 0, 'activeRescues': 0};

                        return Row(
                          children: [
                            // First stats card - Total Adoptions (Permanent Counter)
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
                                          '${stats['totalAdoptions']}',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: kLegacyAccentColor,
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

                            // Second stats card (still has its own BackdropFilter)
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
                                            color: kLegacyAccentColor,
                                          ),
                                        ),
                                        const Text(
                                          'Pets\nAvailable for Adoption',
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
          // Header with "Pet of the Day"
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

          // Fetch Pet of the Day from Firestore
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('app_config')
                .doc('pet_of_the_day')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildPetOfTheDayLoading();
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return _buildPetOfTheDayPlaceholder();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final hasPet = data?['hasPet'] ?? false;

              if (!hasPet) {
                return _buildPetOfTheDayPlaceholder(
                  message:
                      data?['message'] ?? 'No pets available at the moment',
                );
              }

              // Validate that the animal still exists
              final petId = data?['petId'] as String?;
              if (petId == null) {
                return _buildPetOfTheDayPlaceholder(
                  message: 'No pets available at the moment',
                );
              }

              // Check if the animal document still exists
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('animals')
                    .doc(petId)
                    .get(),
                builder: (context, animalSnapshot) {
                  if (animalSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildPetOfTheDayLoading();
                  }

                  // If animal doesn't exist or is not available, select a new pet
                  if (!animalSnapshot.hasData ||
                      !animalSnapshot.data!.exists ||
                      (animalSnapshot.data!.data()
                              as Map<String, dynamic>?)?['status'] !=
                          'Available for Adoption') {
                    // Trigger selection of a new pet (fire and forget)
                    Future.microtask(() async {
                      try {
                        await PetOfTheDayService.selectNewPetOfTheDay();
                      } catch (e) {
                        // Silently fail - the scheduled function will handle it eventually
                      }
                    });

                    return _buildPetOfTheDayPlaceholder(
                      message: 'Selecting a new pet for you...',
                    );
                  }

                  // Extract pet data
                  final petImage = data?['petImage'] ?? '';
                  final petName = data?['petName'] ?? 'Unknown Pet';
                  final petSpecies = data?['petSpecies'] ?? 'Pet';
                  final petAge = data?['petAge'] ?? '';
                  final fullPetData =
                      data?['fullPetData'] as Map<String, dynamic>?;

                  // Use rescue story from fullPetData if available, otherwise use petDescription
                  final rescueStory =
                      fullPetData?['rescueStory'] ??
                      data?['petDescription'] ??
                      'Meet this adorable pet!';

                  return _buildPetOfTheDayCard(
                    petImage: petImage,
                    petName: petName,
                    petSpecies: petSpecies,
                    petAge: petAge,
                    rescueStory: rescueStory,
                    fullPetData: fullPetData,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPetOfTheDayLoading() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: kCardColor.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: kPrimaryAccentColor),
        ),
      ),
    );
  }

  Widget _buildPetOfTheDayPlaceholder({String? message}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            color: kCardColor.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 50, color: kSecondaryTextColor),
                  const SizedBox(height: 12),
                  Text(
                    message ?? 'No pets available at the moment',
                    style: AppTypography.subhead.copyWith(
                      color: kSecondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetOfTheDayCard({
    required String petImage,
    required String petName,
    required String petSpecies,
    required String petAge,
    required String rescueStory,
    Map<String, dynamic>? fullPetData,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Bottom-most layer: Pet image or fallback
          Positioned.fill(
            child: petImage.isNotEmpty
                ? Image.network(
                    petImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/background.png',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
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
                  if (petImage.isNotEmpty)
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Image.network(
                          petImage,
                          fit: BoxFit.cover,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: kCardColor,
                              child: const Icon(
                                Icons.pets,
                                color: kSecondaryTextColor,
                                size: 50,
                              ),
                            );
                          },
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
                                'Meet $petName',
                                style: AppTypography.headline.copyWith(
                                  color: kPrimaryTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                rescueStory,
                                style: AppTypography.subhead.copyWith(
                                  color: kSecondaryTextColor,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                                    borderRadius: BorderRadius.circular(60),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        if (fullPetData != null) {
                                          Map<String, dynamic> latestData =
                                              Map<String, dynamic>.from(
                                                fullPetData,
                                              );

                                          final String? petId =
                                              fullPetData['id']?.toString();
                                          if (petId != null &&
                                              petId.isNotEmpty) {
                                            try {
                                              final doc =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('animals')
                                                      .doc(petId)
                                                      .get();
                                              if (doc.exists) {
                                                final Map<String, dynamic> db =
                                                    (doc.data()
                                                        as Map<
                                                          String,
                                                          dynamic
                                                        >);
                                                latestData = {
                                                  ...latestData,
                                                  ...db,
                                                  'id': petId,
                                                };
                                              }
                                            } catch (_) {}
                                          }

                                          final String status =
                                              latestData['status']
                                                  ?.toString() ??
                                              '';
                                          final bool isAdopted =
                                              status.toLowerCase() ==
                                              AnimalStatus.adopted
                                                  .toLowerCase();

                                          final Map<String, dynamic>
                                          petForDetails = {
                                            ...latestData,
                                            if (isAdopted)
                                              'hideAdoptButton': true,
                                          };

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PetDetailScreen(
                                                    petData: petForDetails,
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(60),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        child: Text(
                                          'See More',
                                          style: AppTypography.callout.copyWith(
                                            fontWeight: FontWeight.w600,
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

  // Info pages data structure - simplified
  final List<Map<String, dynamic>> _infoPages = [
    {
      'title': 'Welcome to PawsCare',
      'text':
          'Every pet deserves a story that ends with love. With PawsCare, you can help pets find homes or bring one home yourself.',
      'imagePath': 'assets/images/beach_blurred.png',
    },
    {
      'title': 'About PawsCare',
      'text':
          "Founded in 2022, PawsCare began with a mission to provide onsite care for pets. Want to join us? Visit our contact page for more info!",
      'imagePath': 'assets/images/welcome2.png',
    },
    {
      'title': 'What You Can Do in the App',
      'text':
          'Find pets looking for homes, share your rescue stories, and connect with fellow animal lovers by posting animals in need.',
      'imagePath': 'assets/images/t_blurred.png',
    },
    {
      'title': 'Meet our Happy Trails',
      'text':
          'Thanks to our community, countless pets have found homes and care. Be part of the change, every action matters.',
      'imagePath': 'assets/images/t2_blurred.png',
    },
    {
      'title': 'Join the Mission',
      'text':
          'Adopt, volunteer, or spread the word,every small action makes a big difference. Together, we can create a world where every animal is cared for and loved.',
      'imagePath': 'assets/images/background_blurred.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentPageValue = _pageController.page!;
        });
      }
    });
    _preloadImages();
  }

  // Preload all carousel images in the background
  Future<void> _preloadImages() async {
    for (var page in _infoPages) {
      final imagePath = page['imagePath'] as String;
      await precacheImage(AssetImage(imagePath), context);
    }
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

                final pageData = _infoPages[index];

                return Transform.scale(
                  scale: scale,
                  child: _buildInfoPage(
                    title: pageData['title'],
                    text: pageData['text'],
                    imagePath: pageData['imagePath'],
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

  // Simplified widget method - just image and text, no glassmorphism
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
            // LAYER 1: BACKGROUND IMAGE
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

            // LAYER 2: TEXT CONTENT (directly on top)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 10.0,
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
                    style: AppTypography.welcomeSubtext,
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
          activeDotColor: Colors.amber,
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

              // --- LAYER 2: INFO OVERLAY AT BOTTOM ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pet['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                          color: kPrimaryTextColor,
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
