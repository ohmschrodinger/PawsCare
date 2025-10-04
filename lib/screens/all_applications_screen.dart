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
  final bool showAppBar;

  const AllApplicationsScreen({super.key, this.showAppBar = true});

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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: widget.showAppBar ? _buildAppBar() : null,
        body: const Center(
            child: CircularProgressIndicator(color: kPrimaryAccentColor)),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: widget.showAppBar ? _buildAppBar() : null,
        body: const Center(
          child: Text('You do not have permission to view this page.',
              style: TextStyle(color: kSecondaryTextColor)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: widget.showAppBar
          ? buildPawsCareAppBar(
              context: context,
          
              onMenuSelected: (value) {
                if (value == 'profile') {
                  mainNavKey.currentState?.selectTab(4);
                } else if (value == 'my_applications') {
                  Navigator.of(context).pushNamed('/my-applications');
                }
              },
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Applications',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryTextColor),
                ),
                Theme(
                  data: Theme.of(context).copyWith(canvasColor: kCardColor),
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    hint: const Text('Filter by Status',
                        style: TextStyle(color: kSecondaryTextColor)),
                    icon:
                        const Icon(Icons.filter_list, color: kSecondaryTextColor),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                          value: null,
                          child: Text('All Status',
                              style: TextStyle(color: kPrimaryTextColor))),
                      DropdownMenuItem(
                          value: 'Under Review',
                          child: Text('Under Review',
                              style: TextStyle(color: kPrimaryTextColor))),
                      DropdownMenuItem(
                          value: 'Accepted',
                          child: Text('Accepted',
                              style: TextStyle(color: kPrimaryTextColor))),
                      DropdownMenuItem(
                          value: 'Rejected',
                          child: Text('Rejected',
                              style: TextStyle(color: kPrimaryTextColor))),
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
          ),
          Expanded(child: _buildApplicationsList(isAdminView: true)),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: kBackgroundColor,
      elevation: 0,
      title: const Text(
        'PawsCare - Admin',
        style:
            TextStyle(color: kPrimaryTextColor, fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
    );
  }

  Widget _buildApplicationsList({required bool isAdminView}) {
    Query query = FirebaseFirestore.instance
        .collection('applications')
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
              'No applications found.',
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
                    height: 150, // Reduced height for faster loading perception
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
                  showAdminActions: true,
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
          isAdmin: widget.showAdminActions,
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, String applicationId) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text('Approve Application',
            style: TextStyle(color: kPrimaryTextColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will mark the pet as "Adopted" and approve the application.',
              style: TextStyle(color: kSecondaryTextColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              style: const TextStyle(color: kPrimaryTextColor),
              decoration: InputDecoration(
                labelText: 'Optional Message',
                labelStyle: const TextStyle(color: kSecondaryTextColor),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade800)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: kPrimaryAccentColor)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: kPrimaryTextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close the dialog immediately, then process approval
              Navigator.pop(context);
              // Approve selected application, mark pet as adopted, and auto-reject others
              try {
                final appRef = FirebaseFirestore.instance
                    .collection('applications')
                    .doc(applicationId);
                final appSnap = await appRef.get();
                final appData = appSnap.data();
                await appRef.update({
                  'status': 'Accepted',
                  'adminMessage': messageController.text.trim(),
                  'reviewedAt': FieldValue.serverTimestamp(),
                });

                if (appData != null && appData['petId'] != null) {
                  final String petId = appData['petId'];

                  // Update the animal as adopted with adoptedAt timestamp
                  await FirebaseFirestore.instance
                      .collection('animals')
                      .doc(petId)
                      .update({
                    'status': 'Adopted',
                    'adoptedAt': FieldValue.serverTimestamp(),
                  });

                  // Auto-reject all other applications for this pet that are still under review
                  final QuerySnapshot others = await FirebaseFirestore.instance
                      .collection('applications')
                      .where('petId', isEqualTo: petId)
                      .where('status', isEqualTo: 'Under Review')
                      .get();

                  final WriteBatch batch = FirebaseFirestore.instance.batch();
                  for (final doc in others.docs) {
                    if (doc.id == applicationId) continue;
                    batch.update(doc.reference, {
                      'status': 'Rejected',
                      'adminMessage': (messageController.text.trim().isNotEmpty)
                          ? messageController.text.trim()
                          : 'Auto-rejected: another application was approved for this pet.',
                      'reviewedAt': FieldValue.serverTimestamp(),
                    });
                  }
                  await batch.commit();
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application approved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String applicationId) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text('Reject Application',
            style: TextStyle(color: kPrimaryTextColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will reject the adoption application.',
                style: TextStyle(color: kSecondaryTextColor)),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              style: const TextStyle(color: kPrimaryTextColor),
              decoration: InputDecoration(
                labelText: 'Reason for Rejection *',
                labelStyle: const TextStyle(color: kSecondaryTextColor),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade800)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: kPrimaryAccentColor)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: kPrimaryTextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Logic Unchanged
              if (messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection.'),
                  ),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('applications')
                    .doc(applicationId)
                    .update({
                  'status': 'Rejected',
                  'adminMessage': messageController.text.trim(),
                  'reviewedAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
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
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3.0),
                            height: 8.0,
                            width: _currentPage == index ? 24.0 : 8.0,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? kPrimaryAccentColor
                                  : kSecondaryTextColor.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                    'Applicant: $applicantName',
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
                  Row(
                    children: [
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
                      const Spacer(),
                      if (widget.showAdminActions &&
                          appStatus == 'Under Review') ...[
                        ElevatedButton(
                          onPressed: () =>
                              _showApproveDialog(context, widget.applicationId),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade800,
                              foregroundColor: Colors.white),
                          child: const Text('Approve'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _showRejectDialog(context, widget.applicationId),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade800,
                              foregroundColor: Colors.white),
                          child: const Text('Reject'),
                        ),
                      ],
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