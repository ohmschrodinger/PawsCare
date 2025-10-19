import 'package:flutter/material.dart';
import 'package:pawscare/screens/adoption_form_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -----------------------------------------

class PetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> petData;

  const PetDetailScreen({super.key, required this.petData});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  Widget _getStatusChip(String status) {
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade900.withOpacity(0.5);
        foregroundColor = Colors.orange.shade300;
        borderColor = Colors.orange.shade700;
        break;
      case 'adopted':
        backgroundColor = Colors.red.shade900.withOpacity(0.5);
        foregroundColor = Colors.red.shade300;
        borderColor = Colors.red.shade700;
        break;
      case 'available':
      default:
        backgroundColor = Colors.green.shade900.withOpacity(0.5);
        foregroundColor = Colors.green.shade300;
        borderColor = Colors.green.shade700;
    }

    return Chip(
      label: Text(status),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(
        color: foregroundColor,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: borderColor),
      ),
    );
  }

  // --- 👇 UI CHANGES ARE HERE ---
  @override
  Widget build(BuildContext context) {
    List<String> imageUrls = [];
    final raw = widget.petData['imageUrls'];
    if (raw is List) {
      imageUrls = raw.whereType<String>().toList();
    } else if (raw is String && raw.isNotEmpty) {
      imageUrls = [raw];
    } else if (widget.petData['image'] is String &&
        widget.petData['image'] != null) {
      imageUrls = [widget.petData['image']];
    }

    final String status = widget.petData['status']?.toString() ?? 'available';
    final bool isAdopted = status.toLowerCase() == 'adopted';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildImageGallery(imageUrls),
          _buildContentBody(status),
          if (!isAdopted) _buildAdoptMeButton(),
        ],
      ),
    );
  }

  Widget _buildContentBody(String status) {
    String getField(String key) => widget.petData[key]?.toString() ?? '';
    final bool isAdopted = status.toLowerCase() == 'adopted';

    return SingleChildScrollView(
      child: Column(
        children: [
          // This SizedBox creates the space for the image behind the card
          const SizedBox(height: 360),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          getField('name'),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Favorite button styled like the reference image
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFFBE6C2),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.brown.shade800,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${getField('species')} • ${getField('age')} • ${getField('gender')}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: kSecondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const SizedBox(height: 24),
                  _buildSectionHeader('About ${getField('name')}'),
                  const SizedBox(height: 8),
                  Text(
                    getField('rescueStory').isNotEmpty
                        ? getField('rescueStory')
                        : 'No story available.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: kPrimaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Details'),
                  const SizedBox(height: 8),
                  _getStatusChip(getField('status')),
                  const SizedBox(height: 8),
                  // Basic meta
                  _buildInfoRow(
                    Icons.email,
                    'Posted By:',
                    getField('postedByEmail'),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    'Posted On:',
                    _formatDate(widget.petData['postedAt']),
                  ),
                  const SizedBox(height: 12),

                  // Pet specifics from the submission form
                  _buildInfoRow(
                    Icons.pets,
                    'Breed Type:',
                    getField('breedType'),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.label, 'Breed:', getField('breed')),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.transgender,
                    'Gender:',
                    getField('gender'),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today, 'Age:', getField('age')),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.health_and_safety,
                    'Sterilized:',
                    getField('sterilization'),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.vaccines,
                    'Vaccination:',
                    getField('vaccination'),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.waves,
                    'Dewormed:',
                    getField('deworming'),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.family_restroom,
                    'Mother Status:',
                    getField('motherStatus'),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.medical_information,
                    'Known Medical Issues:',
                    getField('medicalIssues'),
                  ),
                  const SizedBox(height: 12),
                  // Location & contact
                  _buildInfoRow(
                    Icons.location_on,
                    'Location:',
                    getField('location'),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.phone,
                    'Contact:',
                    getField('contactPhone'),
                  ),
                  if (isAdopted)
                    _buildInfoRow(
                      Icons.event_available,
                      'Adopted On:',
                      _formatDate(widget.petData['adoptedAt']),
                    ),

                  // This SizedBox ensures there's space for the floating "Adopt Me" button
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // --- END OF UI CHANGES ---

  Widget _buildImageGallery(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 400,
        width: double.infinity,
        color: Colors.grey.shade900,
        child: const Icon(Icons.pets, size: 80, color: kSecondaryTextColor),
      );
    }

    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Image.network(
                imageUrls[index],
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 400,
                  width: double.infinity,
                  color: Colors.grey.shade900,
                  child: const Icon(
                    Icons.pets,
                    size: 80,
                    color: kSecondaryTextColor,
                  ),
                ),
              );
            },
          ),
          // Gradient overlay for better text visibility on the AppBar
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
          if (imageUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: imageUrls.length,
                  effect: const WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    activeDotColor: kPrimaryAccentColor,
                    dotColor: Colors.white54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdoptMeButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [kBackgroundColor, kBackgroundColor.withOpacity(0.8)],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AdoptionFormScreen(petData: widget.petData),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryAccentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Adopt Me',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kSecondaryTextColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kPrimaryTextColor,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: kSecondaryTextColor,
                    ),
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
        color: kPrimaryAccentColor,
      ),
    );
  }
}
