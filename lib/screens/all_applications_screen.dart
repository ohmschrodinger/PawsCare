import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/screens/application_detail_screen.dart';
import '../widgets/paws_care_app_bar.dart';
import '../../main_navigation_screen.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -----------------------------------------

class AllApplicationsScreen extends StatefulWidget {
  const AllApplicationsScreen({super.key});

  @override
  State<AllApplicationsScreen> createState() => _AllApplicationsScreenState();
}

class _AllApplicationsScreenState extends State<AllApplicationsScreen> {
  bool _isAdmin = false;
  bool _isLoading = true;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (mounted) {
        setState(() {
          _isAdmin = userDoc.data()?['role'] == 'admin';
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: kPrimaryAccentColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: buildPawsCareAppBar(
        context: context,
        onMenuSelected: (value) {
          if (value == 'profile') {
            mainNavKey.currentState?.selectTab(4);
          } else if (value == 'all_applications') {
            Navigator.of(context).pushNamed('/all-applications');
          } else if (value == 'my_applications') {
            Navigator.of(context).pushNamed('/my-applications');
          }
        },
      ),
      body: Column(
        children: [
          // Filter buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _statusFilter == null,
                    onSelected: (selected) {
                      setState(() => _statusFilter = null);
                    },
                    selectedColor: kPrimaryAccentColor.withOpacity(0.3),
                    checkmarkColor: kPrimaryAccentColor,
                    labelStyle: TextStyle(
                      color: _statusFilter == null ? kPrimaryAccentColor : kSecondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Under Review'),
                    selected: _statusFilter == 'Under Review',
                    onSelected: (selected) {
                      setState(() => _statusFilter = 'Under Review');
                    },
                    selectedColor: kPrimaryAccentColor.withOpacity(0.3),
                    checkmarkColor: kPrimaryAccentColor,
                    labelStyle: TextStyle(
                      color: _statusFilter == 'Under Review' ? kPrimaryAccentColor : kSecondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Accepted'),
                    selected: _statusFilter == 'Accepted',
                    onSelected: (selected) {
                      setState(() => _statusFilter = 'Accepted');
                    },
                    selectedColor: Colors.green.withOpacity(0.3),
                    checkmarkColor: Colors.green,
                    labelStyle: TextStyle(
                      color: _statusFilter == 'Accepted' ? Colors.green : kSecondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Rejected'),
                    selected: _statusFilter == 'Rejected',
                    onSelected: (selected) {
                      setState(() => _statusFilter = 'Rejected');
                    },
                    selectedColor: Colors.red.withOpacity(0.3),
                    checkmarkColor: Colors.red,
                    labelStyle: TextStyle(
                      color: _statusFilter == 'Rejected' ? Colors.red : kSecondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Applications list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _statusFilter == null
                  ? FirebaseFirestore.instance
                      .collection('applications')
                      .orderBy('appliedAt', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('applications')
                      .where('status', isEqualTo: _statusFilter)
                      .orderBy('appliedAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading applications',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryAccentColor),
                  );
                }

                final applications = snapshot.data?.docs ?? [];

                if (applications.isEmpty) {
                  return const Center(
                    child: Text(
                      'No applications found',
                      style: TextStyle(color: kSecondaryTextColor),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final applicationDoc = applications[index];
                    final appData = applicationDoc.data() as Map<String, dynamic>;
                    final petId = appData['petId'];

                    if (petId == null) return const SizedBox();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('animals')
                          .doc(petId)
                          .get(),
                      builder: (context, animalSnapshot) {
                        if (animalSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 150,
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: kPrimaryAccentColor)),
                          );
                        }

                        if (!animalSnapshot.hasData || !animalSnapshot.data!.exists) {
                          return const SizedBox();
                        }

                        final animalData =
                            animalSnapshot.data!.data() as Map<String, dynamic>;

                        return _StyledApplicationCard(
                          applicationData: appData,
                          animalData: animalData,
                          applicationId: applicationDoc.id,
                          showAdminActions: _isAdmin,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledApplicationCard extends StatefulWidget {
  final Map<String, dynamic> applicationData;
  final Map<String, dynamic> animalData;
  final String applicationId;
  final bool showAdminActions;

  const _StyledApplicationCard({
    required this.applicationData,
    required this.animalData,
    required this.applicationId,
    required this.showAdminActions,
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

  void _showApplicationDetails(
      BuildContext context, Map<String, dynamic> appData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationDetailScreen(
          applicationData: appData,
          applicationId: widget.applicationId,
          isAdmin: widget.showAdminActions,
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
    final gender = widget.animalData['gender'] as String?;
    final applicantName = widget.applicationData['applicantName'];

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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailScreen(
              petData: {
                'id': widget.applicationData['petId'],
                ...widget.animalData,
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: hasImages
                        ? PageView.builder(
                            controller: _pageController,
                            itemCount: imageUrls.length,
                            onPageChanged: (index) =>
                                setState(() => _currentPage = index),
                            itemBuilder: (context, index) {
                              return Image.network(
                                imageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey.shade900,
                                  child: const Icon(Icons.pets,
                                      size: 60, color: kSecondaryTextColor),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade900,
                            child: const Icon(Icons.pets,
                                size: 60, color: kSecondaryTextColor),
                          ),
                  ),
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 10.0,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imageUrls.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? kPrimaryAccentColor
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: appStatusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          petName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryTextColor,
                          ),
                        ),
                      ),
                      if (gender != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPrimaryAccentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            gender,
                            style: const TextStyle(
                              color: kPrimaryAccentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Applied by: $applicantName',
                    style: const TextStyle(
                      fontSize: 14,
                      color: kSecondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _showApplicationDetails(context, widget.applicationData),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryAccentColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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