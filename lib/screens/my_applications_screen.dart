import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/screens/application_detail_screen.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -----------------------------------------

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: const Center(
          child: Text(
            'Please log in to view your applications.',
            style: TextStyle(color: kSecondaryTextColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: kCardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'My Applications',
              style: TextStyle(
                  color: kPrimaryTextColor, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // FILTER DROPDOWN on the right
            Theme(
              data: Theme.of(context).copyWith(
                canvasColor: kCardColor, // popup background color dark
              ),
              child: DropdownButton<String>(
                value: _statusFilter,
                hint: const Text('Filter by Status',
                    style: TextStyle(color: kSecondaryTextColor)),
                icon: const Icon(Icons.filter_list, color: kSecondaryTextColor),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('All Status',
                        style: TextStyle(color: kPrimaryTextColor)),
                  ),
                  DropdownMenuItem(
                    value: 'Under Review',
                    child: Text('Under Review',
                        style: TextStyle(color: kPrimaryTextColor)),
                  ),
                  DropdownMenuItem(
                    value: 'Accepted',
                    child: Text('Accepted',
                        style: TextStyle(color: kPrimaryTextColor)),
                  ),
                  DropdownMenuItem(
                    value: 'Rejected',
                    child: Text('Rejected',
                        style: TextStyle(color: kPrimaryTextColor)),
                  ),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _statusFilter = newValue;
                  });
                },
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _buildApplicationsList(userId: currentUser.uid),
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
              child: CircularProgressIndicator(color: kPrimaryAccentColor));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'You have no adoption applications yet.',
              style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
            ),
          );
        }

        final applications = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final applicationDoc = applications[index];
            final appData = applicationDoc.data() as Map<String, dynamic>;
            final petId = appData['petId'];

            if (petId == null) {
              return Card(
                color: kCardColor,
                margin:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(appData['petName'] ?? 'Unknown Pet',
                      style: const TextStyle(color: kPrimaryTextColor)),
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
                        child:
                            CircularProgressIndicator(color: kPrimaryAccentColor)),
                  );
                }

                if (!animalSnapshot.hasData || !animalSnapshot.data!.exists) {
                  return Card(
                    color: kCardColor,
                    margin: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(appData['petName'] ?? 'Unknown Pet',
                          style: const TextStyle(color: kPrimaryTextColor)),
                      subtitle: const Text('Could not load pet details.',
                          style: TextStyle(color: kSecondaryTextColor)),
                    ),
                  );
                }

                final animalData =
                    animalSnapshot.data!.data() as Map<String, dynamic>;
                return _StyledApplicationCard(
                  applicationData: appData,
                  animalData: animalData,
                  applicationId: applicationDoc.id,
                  showAdminActions: false,
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
          isAdmin: false,
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
              child: SizedBox(
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryTextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (gender != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          gender.toLowerCase() == 'male'
                              ? Icons.male
                              : Icons.female,
                          color: gender.toLowerCase() == 'male'
                              ? Colors.blue
                              : Colors.pink,
                          size: 24,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applied on: $appliedDate',
                    style: const TextStyle(
                        fontSize: 15, color: kSecondaryTextColor),
                  ),
                  const Divider(height: 24, color: kBackgroundColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Application Status:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kPrimaryTextColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        _showApplicationDetails(context, widget.applicationData),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: kPrimaryAccentColor,
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
