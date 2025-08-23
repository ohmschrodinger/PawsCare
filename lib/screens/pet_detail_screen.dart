// screens/pet_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:pawscare/screens/adoption_form_screen.dart'; // Import the new screen

class PetDetailScreen extends StatelessWidget {
  final Map<String, dynamic> petData;

  const PetDetailScreen({super.key, required this.petData});

  @override
  Widget build(BuildContext context) {
    // Fix: Ensure imageUrls is always a List<String>
    final dynamic imageUrlsRaw = petData['imageUrls'];
    final List<String> imageUrls = (imageUrlsRaw is List)
        ? List<String>.from(imageUrlsRaw)
        : (imageUrlsRaw is String && imageUrlsRaw.isNotEmpty)
            ? [imageUrlsRaw]
            : (petData['image'] != null ? [petData['image']] : []);
    return Scaffold(
      appBar: AppBar(
        title: Text(petData['name']!),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animal Image Gallery
            _buildImageGallery(imageUrls),
            const SizedBox(height: 24),

            // Key Info Section
            Text(
              petData['name']!,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5AC8F2),
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.cake, 'Age:', petData['age']!),
            _buildInfoRow(Icons.pets, 'Species:', petData['species']!),
            _buildInfoRow(petData['gender'] == 'Male' ? Icons.male : Icons.female, 'Gender:', petData['gender']!),
            _buildInfoRow(Icons.medical_services, 'Sterilization:', petData['sterilization']!),
            _buildInfoRow(Icons.local_hospital, 'Vaccination:', petData['vaccination']!),
            const SizedBox(height: 24),

            // About Me / My Story Section
            _buildSectionHeader('About Me / My Story'),
            const SizedBox(height: 8),
            Text(
              petData['rescueStory']!,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.family_restroom, 'Mother Status:', petData['motherStatus']!),
            const SizedBox(height: 24),

            // Availability & Contact
            _buildSectionHeader('Availability & Contact'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCEDC8), // Light green for availability
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                petData['status']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF33691E), // Darker green text
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Contact Info: Please contact us at adoption@pawscare.org for more details.',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 32),

            // "Adopt Me" Button (Now functional)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to AdoptionFormScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdoptionFormScreen(petData: petData),
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
                  'Adopt Me', // No longer "Coming Soon!"
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
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
        height: 250,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
      );
    }
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              imageUrls[index],
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
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