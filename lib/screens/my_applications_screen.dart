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
  int _selectedTabIndex = 0; // 0 for My Applications, 1 for My Listings (inactive)

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My History'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Please log in to view your applications.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab/Segmented Control
          Padding(
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
                          borderRadius: BorderRadius.circular(10)),
                      elevation: _selectedTabIndex == 0 ? 3 : 0,
                    ),
                    child: const Text('My Applications'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('My Listings coming soon!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTabIndex == 1
                          ? const Color(0xFF5AC8F2)
                          : Colors.grey[200],
                      foregroundColor: _selectedTabIndex == 1
                          ? Colors.white
                          : Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: _selectedTabIndex == 1 ? 3 : 0,
                    ),
                    child: const Text('My Listings'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildMyApplicationsList(currentUser.uid)
                : _buildMyListingsPlaceholder(), // Placeholder for future
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'My History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Post Animal',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'My Posts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 1, // 'My History' is the active tab
        selectedItemColor: const Color(0xFF5AC8F2),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, ModalRoute.withName('/home'));
          } else if (index == 1) {
            // Already on My History
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PostAnimalScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyPostedAnimalsScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
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
          return const Center(child: Text('You have no adoption applications yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final appData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                            appData['petImage'] ?? 'https://via.placeholder.com/60/CCCCCC/FFFFFF?text=Pet',
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 60,
                              width: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.pets, color: Colors.grey),
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
                          'Current Status:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appData['status'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (appData['status'] == 'Rejected' && appData['adminMessage'] != null && appData['adminMessage'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reason for Rejection:',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.red),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appData['adminMessage'],
                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Expand to show more details (read-only)
                          _showApplicationDetails(context, appData);
                        },
                        child: const Text('View Details'),
                      ),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'My Listings section coming in Sprint 3!',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showApplicationDetails(BuildContext context, Map<String, dynamic> appData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Application for ${appData['petName']}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Status: ${appData['status']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (appData['status'] == 'Rejected' && appData['adminMessage'] != null && appData['adminMessage'].isNotEmpty)
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
                Text('Experience: ${appData['experienceWithPets']}'),
                Text('Dwelling Type: ${appData['dwellingType']}'),
                Text('Yard Fenced: ${appData['isYardFenced'] ? 'Yes' : 'No'}'),
                Text('Adults: ${appData['numAdults']}'),
                Text('Children: ${appData['numChildren']}'),
                Text('Time Commitment: ${appData['timeCommitment']}'),
                Text('Reason for Adoption: ${appData['reasonForAdoption']}'),
                const Divider(),
                if (appData['appliedAt'] != null)
                  Text('Applied On: ${DateFormat('MMM d, yyyy hh:mm a').format((appData['appliedAt'] as Timestamp).toDate())}'),
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