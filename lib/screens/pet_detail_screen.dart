// screens/pet_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:pawscare/screens/adoption_form_screen.dart'; // Import the new screen

class PetDetailScreen extends StatelessWidget {
  // Add helper methods at the top of the class
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date not available';

    DateTime? date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp.toDate != null) {
      date = timestamp.toDate();
    }

    if (date == null) return 'Date not available';
    return '${date.day}/${date.month}/${date.year}';
  }

  // New helper method to build a trait chip
  Widget _buildTraitChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, color: Colors.blueGrey, size: 20),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.blueGrey[800],
        ),
      ),
      backgroundColor: Colors.blueGrey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.blueGrey[200]!),
      ),
    );
  }

  // New helper method to build a row of trait chips
  Widget _buildTraitsRow(List<Widget> chips) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: chips,
    );
  }

  final Map<String, dynamic> petData;

  const PetDetailScreen({super.key, required this.petData});

  @override
  Widget build(BuildContext context) {
    // Robust handling for imageUrls
    List<String> imageUrls = [];
    final raw = petData['imageUrls'];
    if (raw is List) {
      imageUrls = raw.whereType<String>().toList();
    } else if (raw is String && raw.isNotEmpty) {
      imageUrls = [raw];
    } else if (petData['image'] is String && petData['image'] != null) {
      imageUrls = [petData['image']];
    }
    // Defensive null checks for all fields
    String getField(String key) => petData[key]?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              // TODO: Implement favorite functionality
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true, // This allows the body to go behind the app bar
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animal Image Gallery
            _buildImageGallery(imageUrls),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet Name & Status Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getField('name'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${getField('gender')} • ${getField('age')} • ${getField('size')}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Chip(
                        label: Text(getField('status')),
                        backgroundColor: Colors.green.withOpacity(0.1),
                        labelStyle: const TextStyle(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Traits & Compatibility Section
                  _buildSectionHeader('Traits & Compatibility'),
                  const SizedBox(height: 8),
                  _buildTraitsRow([
                    _buildTraitChip('House Trained', Icons.check),
                    _buildTraitChip('Cat Compatible', Icons.pets),
                    _buildTraitChip('Shots Up to Date', Icons.vaccines),
                    _buildTraitChip('Kid Compatible', Icons.child_friendly),
                    _buildTraitChip('Slightly Active', Icons.directions_run),
                  ]),
                  const SizedBox(height: 24),

                  // Description Section
                  _buildSectionHeader('About ${getField('name')}'),
                  const SizedBox(height: 8),
                  Text(
                    getField('rescueStory').isNotEmpty
                        ? getField('rescueStory')
                        : 'No rescue story available.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Location and Contact
                  _buildSectionHeader('Location'),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      Icons.location_on, 'Location:', getField('location')),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.email, 'Posted By:', getField('postedByEmail')),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      Icons.access_time, 'Posted On:', _formatDate(petData['postedAt'])),
                  const SizedBox(height: 32),

                  // "Adopt Me" Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AdoptionFormScreen(petData: petData),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5AC8F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Adopt Me',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildImageGallery(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 400,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Icon(
          Icons.image_not_supported,
          size: 80,
          color: Colors.grey,
        ),
      );
    }
    return SizedBox(
      height: 400,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: Image.network(
              imageUrls[index],
              height: 400,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 400,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: ' $value',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF5AC8F2),
      ),
    );
  }
}