import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/screens/application_detail_screen.dart';
import 'dart:ui'; // For ImageFilter
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pawscare/widgets/animal_card.dart'; // For customCacheManager if needed
import 'package:pawscare/services/notification_badge_service.dart';
import 'package:pawscare/constants/app_colors.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    // Mark applications as seen when the screen is opened
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      NotificationBadgeService.markApplicationsAsSeen(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text('My Applications'),
          backgroundColor: kCardColor,
        ),
        body: const Center(
          child: Text(
            'Please log in to view your applications.',
            style: TextStyle(color: kSecondaryTextColor),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Applications',
          style: TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.2),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Filter buttons
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 4.0,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', null),
                        _buildFilterChip('Under Review', 'Under Review'),
                        _buildFilterChip('Accepted', 'Accepted'),
                        _buildFilterChip('Rejected', 'Rejected'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _buildApplicationsList(userId: currentUser.uid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? filterValue) {
    final selected = _statusFilter == filterValue;
    Color selectedColor;

    switch (filterValue) {
      case 'Accepted':
        selectedColor = Colors.green;
        break;
      case 'Rejected':
        selectedColor = Colors.red;
        break;
      default:
        selectedColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? selectedColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: selected
                    ? selectedColor.withOpacity(0.4)
                    : Colors.white.withOpacity(0.1),
                width: 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _statusFilter = filterValue);
                },
                borderRadius: BorderRadius.circular(20.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? selectedColor : kSecondaryTextColor,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationsList({required String userId}) {
    Query query = FirebaseFirestore.instance
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .orderBy('appliedAt', descending: true);

    if (_statusFilter != null) {
      query = query.where('status', isEqualTo: _statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: kSecondaryTextColor,
                ),
                SizedBox(height: 16),
                Text(
                  'You have no adoption applications yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
                ),
              ],
            ),
          );
        }

        final applications = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 90),
          itemCount: applications.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final applicationDoc = applications[index];
            final appData = applicationDoc.data() as Map<String, dynamic>;
            final petId = appData['petId'];

            if (petId == null) {
              return Card(
                color: kCardColor,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    appData['petName'] ?? 'Unknown Pet',
                    style: const TextStyle(color: kPrimaryTextColor),
                  ),
                  subtitle: const Text(
                    'Error: Application is not linked to a pet correctly.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              );
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('animals')
                  .doc(petId)
                  .get(),
              builder: (context, animalSnapshot) {
                if (animalSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: kPrimaryAccentColor,
                      ),
                    ),
                  );
                }

                if (!animalSnapshot.hasData || !animalSnapshot.data!.exists) {
                  return Card(
                    color: kCardColor,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: ListTile(
                      title: Text(
                        appData['petName'] ?? 'Unknown Pet',
                        style: const TextStyle(color: kPrimaryTextColor),
                      ),
                      subtitle: const Text(
                        'Could not load pet details.',
                        style: TextStyle(color: kSecondaryTextColor),
                      ),
                    ),
                  );
                }

                final animalData =
                    animalSnapshot.data!.data() as Map<String, dynamic>;
                return _StyledApplicationCard(
                  applicationData: appData,
                  animalData: animalData,
                  applicationId: applicationDoc.id,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StyledApplicationCard extends StatefulWidget {
  final Map<String, dynamic> applicationData;
  final Map<String, dynamic> animalData;
  final String applicationId;

  const _StyledApplicationCard({
    required this.applicationData,
    required this.animalData,
    required this.applicationId,
  });

  @override
  State<_StyledApplicationCard> createState() => __StyledApplicationCardState();
}

class __StyledApplicationCardState extends State<_StyledApplicationCard> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPetDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(
          petData: {
            'id': widget.applicationData['petId'],
            ...widget.animalData,
            'hideAdoptButton': true, // Add this flag
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls =
        (widget.animalData['imageUrls'] as List?)?.cast<String>() ?? [];
    final hasImages = imageUrls.isNotEmpty;
    final appStatus = widget.applicationData['status'] ?? 'Under Review';
    final petName = widget.animalData['name'] ?? 'Unknown Pet';
    final appliedAt = widget.applicationData['appliedAt'] as Timestamp?;
    final appliedDate = appliedAt != null
        ? DateFormat('MMM d, yyyy').format(appliedAt.toDate())
        : 'N/A';

    Color appStatusColor;
    switch (appStatus) {
      case 'Accepted':
        appStatusColor = Colors.green;
        break;
      case 'Rejected':
        appStatusColor = Colors.red;
        break;
      default:
        appStatusColor = kPrimaryAccentColor;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: () => _navigateToPetDetail(context),
          child: Stack(
            children: [
              // --- IMAGE LAYER ---
              SizedBox(
                height: 420,
                width: double.infinity,
                child: hasImages
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: imageUrls.length,
                        onPageChanged: (index) =>
                            setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            cacheManager: customCacheManager,
                            imageUrl: imageUrls[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade900,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kPrimaryAccentColor,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade900,
                              child: const Icon(
                                Icons.pets,
                                size: 60,
                                color: kSecondaryTextColor,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade900,
                        child: const Icon(
                          Icons.pets,
                          size: 60,
                          color: kSecondaryTextColor,
                        ),
                      ),
              ),

              // --- PAGE INDICATOR ---
              if (imageUrls.length > 1)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      imageUrls.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3.0),
                        height: 8.0,
                        width: _currentPage == i ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? kPrimaryAccentColor
                              : kSecondaryTextColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

              // --- GLASSMORPHIC INFO PANEL ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            petName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${widget.animalData['breed'] ?? 'Mixed Breed'} • ${widget.animalData['age'] ?? 'Unknown age'}",
                            style: const TextStyle(
                              fontSize: 15,
                              color: kSecondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: kSecondaryTextColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Applied on $appliedDate",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kSecondaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.white12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: appStatusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  appStatus,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: appStatusColor,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ApplicationDetailScreen(
                                            applicationData:
                                                widget.applicationData,
                                            applicationId: widget.applicationId,
                                            isAdmin: false,
                                          ),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'View Details →',
                                  style: TextStyle(
                                    color: kPrimaryTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
