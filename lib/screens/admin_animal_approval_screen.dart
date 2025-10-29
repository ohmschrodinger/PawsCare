import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/animal_service.dart';
import '../screens/pet_detail_screen.dart';
import '../constants/app_colors.dart';

class AdminAnimalApprovalScreen extends StatelessWidget {
  const AdminAnimalApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Animal Approvals',
          style: TextStyle(color: kPrimaryTextColor),
        ),
        centerTitle: true,
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryTextColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AnimalService.getPendingAnimals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No pending approvals!',
                    style: TextStyle(fontSize: 18, color: kSecondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All animals have been reviewed',
                    style: TextStyle(fontSize: 14, color: kSecondaryTextColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animalData = animals[index].data() as Map<String, dynamic>;
              final animalId = animals[index].id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PetDetailScreen(
                        petData: {...animalData, 'id': animalId},
                      ),
                    ),
                  );
                },
                child: Card(
                  color: kCardColor,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: Image.network(
                          (animalData['imageUrls'] as List?)?.isNotEmpty == true
                              ? animalData['imageUrls'][0]
                              : 'https://via.placeholder.com/150',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey.shade900,
                              child: const Icon(
                                Icons.pets,
                                color: kSecondaryTextColor,
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              animalData['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${animalData['species'] ?? ''} • ${animalData['age'] ?? ''} • ${animalData['gender'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: kSecondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Posted by: ${animalData['postedByEmail'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: kSecondaryTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Posted on: ${_formatDate(animalData['postedAt'])}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: kSecondaryTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (animalData['rescueStory']?.isNotEmpty ==
                                true) ...[
                              const Text(
                                'Rescue Story:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kSecondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                animalData['rescueStory'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kSecondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoChip(
                                    'Sterilization: ${animalData['sterilization'] ?? 'N/A'}',
                                    Icons.medical_services,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildInfoChip(
                                    'Vaccination: ${animalData['vaccination'] ?? 'N/A'}',
                                    Icons.vaccines,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _showApproveDialog(context, animalId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade800,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'Approve',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _showRejectDialog(context, animalId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade800,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'Reject',
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
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kSecondaryTextColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: kSecondaryTextColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, String animalId) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text(
          'Approve Animal',
          style: TextStyle(color: kPrimaryTextColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This animal will be visible to all users.',
              style: TextStyle(color: kSecondaryTextColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              style: const TextStyle(color: kPrimaryTextColor),
              decoration: InputDecoration(
                labelText: 'Optional Message (for user)',
                labelStyle: const TextStyle(color: kSecondaryTextColor),
                hintText: 'e.g., Great job! This animal looks healthy.',
                hintStyle: TextStyle(
                  color: kSecondaryTextColor.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: kPrimaryAccentColor),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kPrimaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Logic is unchanged
              try {
                await AnimalService.approveAnimal(
                  animalId: animalId,
                  adminMessage: messageController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Animal approved successfully!'),
                    backgroundColor: Colors.green.shade800,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error approving animal: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String animalId) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text(
          'Reject Animal',
          style: TextStyle(color: kPrimaryTextColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This animal will not be visible to users.',
              style: TextStyle(color: kSecondaryTextColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              style: const TextStyle(color: kPrimaryTextColor),
              decoration: InputDecoration(
                labelText: 'Reason for Rejection *',
                labelStyle: const TextStyle(color: kSecondaryTextColor),
                hintText: 'e.g., Incomplete information...',
                hintStyle: TextStyle(
                  color: kSecondaryTextColor.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: kPrimaryAccentColor),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kPrimaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Logic is unchanged
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
                await AnimalService.rejectAnimal(
                  animalId: animalId,
                  adminMessage: messageController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Animal rejected successfully!'),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error rejecting animal: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown date';
    } catch (e) {
      return 'Unknown date';
    }
  }
}
