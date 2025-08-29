// screens/my_applications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  final bool showAppBar;

  const MyApplicationsScreen({super.key, this.showAppBar = true});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  bool _isAdmin = false;

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
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: widget.showAppBar ? _buildAppBar() : null,
        body: const Center(
          child: Text('Please log in to view your applications.'),
        ),
      );
    }

    // Use DefaultTabController for tab management
    return DefaultTabController(
      length: _isAdmin ? 2 : 1, // Dynamic length based on role
      child: Scaffold(
        appBar: widget.showAppBar ? _buildAppBar() : null,
        body: Column(
          children: [
            // Modern TabBar that matches the Profile screen
            TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: [
                const Tab(text: 'My Applications'),
                if (_isAdmin) const Tab(text: 'All Applications'),
              ],
            ),
            // TabBarView to display content based on the selected tab
            Expanded(
              child: TabBarView(
                children: [
                  _buildApplicationsList(
                    key: const ValueKey('my_applications'),
                    userId: currentUser.uid,
                    isAdminView: false,
                  ),
                  if (_isAdmin)
                    _buildApplicationsList(
                      key: const ValueKey('all_applications'),
                      isAdminView: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appBarColor =
        isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey.shade50;
    final appBarTextColor = theme.textTheme.titleLarge?.color;

    return AppBar(
      systemOverlayStyle:
          isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      backgroundColor: appBarColor,
      elevation: 0,
      title: Text(
        'PawsCare',
        style: TextStyle(
          color: appBarTextColor,
          fontWeight: FontWeight.bold,
        ),
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
    );
  }

  Widget _buildApplicationsList({
    Key? key,
    String? userId,
    required bool isAdminView,
  }) {
    Query query = FirebaseFirestore.instance
        .collection('applications')
        .orderBy('appliedAt', descending: true);

    if (!isAdminView && userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    return StreamBuilder<QuerySnapshot>(
      key: key,
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              isAdminView
                  ? 'No applications found.'
                  : 'You have no adoption applications yet.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                margin:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(appData['petName'] ?? 'Unknown Pet'),
                  subtitle: const Text(
                      'Error: Application is not linked to a pet correctly.'),
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
                    height: 450,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!animalSnapshot.hasData || !animalSnapshot.data!.exists) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(appData['petName'] ?? 'Unknown Pet'),
                      subtitle: const Text('Could not load pet details.'),
                    ),
                  );
                }

                final animalData =
                    animalSnapshot.data!.data() as Map<String, dynamic>;
                return _StyledApplicationCard(
                  applicationData: appData,
                  animalData: animalData,
                  applicationId: applicationDoc.id,
                  showAdminActions: isAdminView,
                );
              },
            );
          },
        );
      },
    );
  }

  void _showApplicationDetails(
    BuildContext context,
    Map<String, dynamic> appData,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Application for ${appData['petName']}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Status: ${appData['status']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (appData['status'] == 'Rejected' &&
                    appData['adminMessage'] != null &&
                    appData['adminMessage'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Reason: ${appData['adminMessage']}'),
                  ),
                const Divider(),
                Text('Applicant Name: ${appData['applicantName']}'),
                Text('Email: ${appData['applicantEmail']}'),
                Text('Phone: ${appData['applicantPhone']}'),
                Text('Address: ${appData['applicantAddress']}'),
                const Divider(),
                Text(
                  'Current Pets: ${appData['hasCurrentPets'] == true ? "Yes" : "No"}',
                ),
                if (appData['currentPetsDetails']?.isNotEmpty == true)
                  Text(
                    'Current Pets Details: ${appData['currentPetsDetails']}',
                  ),
                Text(
                  'Past Pets: ${appData['hasPastPets'] == true ? "Yes" : "No"}',
                ),
                if (appData['pastPetsDetails']?.isNotEmpty == true)
                  Text('Past Pets Details: ${appData['pastPetsDetails']}'),
                const Divider(),
                if (appData['appliedAt'] != null)
                  Text(
                    'Applied On: ${DateFormat('MMM d, yyyy hh:mm a').format((appData['appliedAt'] as Timestamp).toDate())}',
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showApproveDialog(BuildContext context, String applicationId) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'This will mark the pet as "Adopted" and approve the application.'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Optional Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
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
                  await FirebaseFirestore.instance
                      .collection('animals')
                      .doc(appData['petId'])
                      .update({'status': 'Adopted'});
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application approved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
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
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will reject the adoption application.'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please provide a reason for rejection.')),
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

  @override
  Widget build(BuildContext context) {
    final imageUrls =
        (widget.animalData['imageUrls'] as List?)?.cast<String>() ?? [];
    final hasImages = imageUrls.isNotEmpty;

    final appStatus = widget.applicationData['status'] ?? 'Under Review';
    final petName = widget.animalData['name'] ?? 'Unknown Pet';
    final gender = widget.animalData['gender'] as String?;
    final applicantName = widget.applicationData['applicantName'];

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
        appStatusColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailScreen(petData: {
              'id': widget.applicationData['petId'],
              ...widget.animalData
            }),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.pets,
                                      size: 60, color: Colors.grey.shade400),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.pets,
                                size: 60, color: Colors.grey.shade400),
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
                              color: Colors.white.withOpacity(
                                  _currentPage == index ? 0.9 : 0.6),
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
                              fontSize: 22, fontWeight: FontWeight.bold),
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
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.showAdminActions
                        ? 'Applicant: $applicantName'
                        : 'Applied on: $appliedDate',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Application Status:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
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
                            _MyApplicationsScreenState()._showApplicationDetails(
                          context,
                          widget.applicationData,
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View Details',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.showAdminActions &&
                          appStatus == 'Under Review') ...[
                        ElevatedButton(
                          onPressed: () => _MyApplicationsScreenState()
                              ._showApproveDialog(context, widget.applicationId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Approve'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _MyApplicationsScreenState()
                              ._showRejectDialog(context, widget.applicationId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reject'),
                        ),
                      ],
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
