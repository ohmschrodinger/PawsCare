// screens/pet_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:pawscare/screens/adoption_form_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> petData;

  const PetDetailScreen({super.key, required this.petData});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Robust handling for imageUrls
    List<String> imageUrls = [];
    final raw = widget.petData['imageUrls'];
    if (raw is List) {
      imageUrls = raw.whereType<String>().toList();
    } else if (raw is String && raw.isNotEmpty) {
      imageUrls = [raw];
    } else if (widget.petData['image'] is String && widget.petData['image'] != null) {
      imageUrls = [widget.petData['image']];
    }
    // Defensive null checks for all fields
    String getField(String key) => widget.petData[key]?.toString() ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(getField('name')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePet(widget.petData),
            tooltip: 'Share this pet',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Animal Image Gallery
            _buildEnhancedImageGallery(imageUrls),
            const SizedBox(height: 24),

            // Key Info Section
            Text(
              getField('name'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5AC8F2),
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.cake, 'Age:', getField('age')),
            _buildInfoRow(Icons.pets, 'Species:', getField('species')),
            _buildInfoRow(getField('gender') == 'Male' ? Icons.male : Icons.female, 'Gender:', getField('gender')),
            _buildInfoRow(Icons.medical_services, 'Sterilization:', getField('sterilization')),
            _buildInfoRow(Icons.local_hospital, 'Vaccination:', getField('vaccination')),
            const SizedBox(height: 24),

            // About Me / My Story Section
            _buildSectionHeader('About Me / My Story'),
            const SizedBox(height: 8),
            Text(
              getField('rescueStory'),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.family_restroom, 'Mother Status:', getField('motherStatus')),
            const SizedBox(height: 24),

            // Availability & Contact
            _buildSectionHeader('Availability & Contact'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCEDC8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                getField('status'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF33691E),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Contact Info: Please contact us at adoption@pawscare.org for more details.',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 32),

            // "Adopt Me" Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdoptionFormScreen(petData: widget.petData),
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
    );
  }

  Widget _buildEnhancedImageGallery(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
      );
    }

    return Column(
      children: [
        // Image Gallery with PageView
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenGallery(context, imageUrls, index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
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
                  ),
                ),
              );
            },
          ),
        ),
        
        // Slider Dots Indicator
        if (imageUrls.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageUrls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? const Color(0xFF5AC8F2)
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showFullScreenGallery(BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('${widget.petData['name']} - Image ${initialIndex + 1} of ${imageUrls.length}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _sharePet(widget.petData),
                tooltip: 'Share this pet',
              ),
            ],
          ),
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrls[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                heroAttributes: PhotoViewHeroAttributes(tag: imageUrls[index]),
              );
            },
            itemCount: imageUrls.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            pageController: PageController(initialPage: initialIndex),
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  void _sharePet(Map<String, dynamic> petData) {
    final String petName = petData['name']?.toString() ?? 'Pet';
    final String species = petData['species']?.toString() ?? '';
    final String age = petData['age']?.toString() ?? '';
    final String rescueStory = petData['rescueStory']?.toString() ?? '';
    
    String shareText = '🐾 Check out this adorable $species named $petName!';
    if (age.isNotEmpty) {
      shareText += '\nAge: $age';
    }
    if (rescueStory.isNotEmpty) {
      shareText += '\n\n$rescueStory';
    }
    shareText += '\n\nFind your perfect companion at PawsCare! 🏠❤️';
    
    Share.share(
      shareText,
      subject: 'Adopt $petName - A Lovely $species Looking for a Home',
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