// screens/my_applications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:pawscare/screens/post_animal_screen.dart';
import 'package:pawscare/screens/my_posted_animals_screen.dart';
import 'package:pawscare/screens/profile_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  // Placeholder for future 'My Listings' functionality
  int _selectedTabIndex =
      0; // 0 for My Applications, 1 for My Listings (inactive)

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My History'), centerTitle: true),
        body: const Center(
          child: Text('Please log in to view your applications.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My History'), centerTitle: true),
      body: Column(
        children: [
          // Tab/Segmented Control
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get(),
            builder: (context, snapshot) {
              final bool isAdmin = snapshot.data?.get('role') == 'admin';

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTabIndex = 0;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTabIndex == 0
                              ? const Color(0xFF5AC8F2)
                              : Colors.grey[200],
                          foregroundColor: _selectedTabIndex == 0
                              ? Colors.white
                              : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: _selectedTabIndex == 0 ? 3 : 0,
                        ),
                        child: const Text('My Applications'),
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedTabIndex = 1;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedTabIndex == 1
                                ? const Color(0xFF5AC8F2)
                                : Colors.grey[200],
                            foregroundColor: _selectedTabIndex == 1
                                ? Colors.white
                                : Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: _selectedTabIndex == 1 ? 3 : 0,
                          ),
                          child: const Text('All Applications'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildMyApplicationsList(currentUser.uid)
                : _buildMyListingsPlaceholder(), // Placeholder for future
          ),
        ],
      ),
    );
  }

Widget _buildMyApplicationsList(String userId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .orderBy('appliedAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(
          child: Text('You have no adoption applications yet.'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          final appData =
              snapshot.data!.docs[index].data() as Map<String, dynamic>;
          final timestamp = appData['appliedAt'] as Timestamp?;
          final formattedDate = timestamp != null
              ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
              : 'N/A';

          Color statusColor;
          switch (appData['status']) {
            case 'Accepted':
              statusColor = Colors.green;
              break;
            case 'Rejected':
              statusColor = Colors.red;
              break;
            default:
              statusColor = Colors.orange; // Under Review
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          appData['petImage'] ??
                              'https://via.placeholder.com/60/CCCCCC/FFFFFF?text=Pet',
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 60,
                            width: 60,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.pets,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appData['petName'] ?? 'Unknown Pet',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Applied on: $formattedDate',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appData['status'] ?? 'Under Review',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _showApplicationDetails(context, appData),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5AC8F2),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (appData['status'] == 'Under Review') ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showApproveDialog(
                              context,
                              snapshot.data!.docs[index].id,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showRejectDialog(
                              context,
                              snapshot.data!.docs[index].id,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget _buildMyListingsPlaceholder() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .orderBy('appliedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No adoption applications yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final appData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final timestamp = appData['appliedAt'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                : 'N/A';

            Color statusColor;
            switch (appData['status']) {
              case 'Accepted':
                statusColor = Colors.green;
                break;
              case 'Rejected':
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.orange; // Under Review
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            appData['petImage'] ??
                                'https://via.placeholder.com/60/CCCCCC/FFFFFF?text=Pet',
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 60,
                                  width: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.pets,
                                    color: Colors.grey,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appData['petName'] ?? 'Unknown Pet',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'By: ${appData['applicantName'] ?? 'Unknown'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Applied on: $formattedDate',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appData['status'] ?? 'Under Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _showApplicationDetails(context, appData),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5AC8F2),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('View Details'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (appData['status'] == 'Under Review') ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showApproveDialog(
                                context,
                                snapshot.data!.docs[index].id,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showRejectDialog(
                                context,
                                snapshot.data!.docs[index].id,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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
            const Text('This will approve the adoption application.'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Optional Message (for applicant)',
                hintText:
                    'e.g., Congratulations! Your application has been approved.',
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
                await FirebaseFirestore.instance
                    .collection('applications')
                    .doc(applicationId)
                    .update({
                      'status': 'Accepted',
                      'adminMessage': messageController.text.trim(),
                      'reviewedAt': FieldValue.serverTimestamp(),
                    });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application approved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error approving application: $e'),
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
                hintText: 'Please provide a reason for rejection',
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
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.orange,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application rejected successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error rejecting application: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
                Text(
                  'Home Ownership: ${appData['homeOwnership'] ?? "Not specified"}',
                ),
                Text(
                  'Household Members: ${appData['householdMembers'] ?? "Not specified"}',
                ),
                Text(
                  'All Members Agree: ${appData['allMembersAgree'] == true ? "Yes" : "No"}',
                ),
                Text(
                  'Hours Alone: ${appData['hoursLeftAlone'] ?? "Not specified"}',
                ),
                Text(
                  'Where Kept When Alone: ${appData['whereKeptWhenAlone'] ?? "Not specified"}',
                ),
                Text(
                  'Financially Prepared: ${appData['financiallyPrepared'] == true ? "Yes" : "No"}',
                ),
                Text(
                  'Has Veterinarian: ${appData['hasVeterinarian'] == true ? "Yes" : "No"}',
                ),
                if (appData['vetContactInfo']?.isNotEmpty == true)
                  Text('Vet Contact: ${appData['vetContactInfo']}'),
                Text(
                  'Will Provide Vet Care: ${appData['willingToProvideVetCare'] == true ? "Yes" : "No"}',
                ),
                Text(
                  'Lifetime Commitment: ${appData['preparedForLifetimeCommitment'] == true ? "Yes" : "No"}',
                ),
                if (appData['ifCannotKeepCare']?.isNotEmpty == true)
                  Text('If Cannot Keep: ${appData['ifCannotKeepCare']}'),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
