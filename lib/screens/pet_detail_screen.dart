import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pawscare/screens/adoption_form_screen.dart';

// --- THEME CONSTANTS ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);

class PetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> petData;

  const PetDetailScreen({super.key, required this.petData});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime? date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else {
      try {
        if (timestamp.toDate != null) date = timestamp.toDate();
      } catch (_) {}
    }
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  // --- MODIFICATION: Updated for glassmorphism effect ---
  Widget _getStatusChip(String status) {
    Color tintColor;
    Color foregroundColor;
    Color borderColor;

    switch (status.toLowerCase()) {
      case 'pending':
        tintColor = Colors.orange.withOpacity(0.25);
        foregroundColor = Colors.orange.shade300;
        borderColor = Colors.orange.shade700.withOpacity(0.5);
        break;
      case 'adopted':
        tintColor = Colors.red.withOpacity(0.25);
        foregroundColor = Colors.red.shade300;
        borderColor = Colors.red.shade700.withOpacity(0.5);
        break;
      case 'available':
      default:
        tintColor = Colors.green.withOpacity(0.25);
        foregroundColor = Colors.green.shade300;
        borderColor = Colors.green.shade700.withOpacity(0.5);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tintColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // --- MODIFICATION: Updated for glassmorphism effect ---
  Widget _buildPositiveChip(String label, String? rawValue) {
    final value = (rawValue ?? '').toLowerCase();
    final isYes =
        value == 'yes' ||
        value == 'true' ||
        value == 'y' ||
        value == 'done' ||
        value == 'completed';

    // If the value is not 'yes', return an empty widget.
    if (!isYes) {
      return const SizedBox.shrink();
    }

    // Return the new glassmorphic chip widget if the value is 'yes'.
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2), // Green glass tint
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.green.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade400, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.green.shade200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 360),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                width: double.infinity,
                color: kBackgroundColor.withOpacity(0.7),
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _getStatusChip(getField('status')),
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
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPositiveChip(
                            'Sterilized',
                            widget.petData['sterilization']?.toString(),
                          ),
                          _buildPositiveChip(
                            'Vaccinated',
                            widget.petData['vaccination']?.toString(),
                          ),
                          _buildPositiveChip(
                            'Dewormed',
                            widget.petData['deworming']?.toString(),
                          ),
                        ],
                      ),
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
                      _buildDetailCard(
                        title: 'Pet Information',
                        children: [
                          _buildInfoRow(
                            Icons.pets,
                            'Breed Type:',
                            getField('breedType'),
                          ),
                          _buildInfoRow(
                            Icons.label,
                            'Breed:',
                            getField('breed'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        title: 'Health Status',
                        children: [
                          _buildInfoRow(
                            Icons.health_and_safety,
                            'Sterilized:',
                            widget.petData['sterilization']?.toString() ?? 'No',
                          ),
                          _buildInfoRow(
                            Icons.vaccines,
                            'Vaccinated:',
                            widget.petData['vaccination']?.toString() ?? 'No',
                          ),
                          _buildInfoRow(
                            Icons.waves,
                            'Dewormed:',
                            widget.petData['deworming']?.toString() ?? 'No',
                          ),
                          _buildInfoRow(
                            Icons.family_restroom,
                            'Mother Status:',
                            getField('motherStatus'),
                          ),
                          _buildInfoRow(
                            Icons.medical_information,
                            'Medical Issues:',
                            getField('medicalIssues'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        title: 'Contact & Location',
                        children: [
                          _buildInfoRow(
                            Icons.location_on,
                            'Location:',
                            getField('location'),
                          ),
                          _buildInfoRow(
                            Icons.phone,
                            'Contact:',
                            getField('contactPhone'),
                          ),
                          _buildInfoRow(
                            Icons.email,
                            'Posted By:',
                            getField('postedByEmail'),
                          ),
                          _buildInfoRow(
                            Icons.access_time,
                            'Posted On:',
                            _formatDate(widget.petData['postedAt']),
                          ),
                          if (isAdopted)
                            _buildInfoRow(
                              Icons.event_available,
                              'Adopted On:',
                              _formatDate(widget.petData['adoptedAt']),
                            ),
                        ],
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFICATION ---: Updated this widget for the glassmorphism effect.
  Widget _buildDetailCard({
    required String title,
    required List<Widget> children,
  }) {
    return ClipRRect(
      // Use ClipRRect to contain the blur effect within rounded corners
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // The blur effect
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // A subtle white tint for the "glass"
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            // A faint border to define the edge of the glass
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kPrimaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 20, color: Colors.white24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

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
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: imageUrls[index],
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 400,
                  width: double.infinity,
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kPrimaryAccentColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
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

          // top gradient (unchanged)
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

          // LEFT & RIGHT ARROWS (dynamic, no outer circle)
          if (imageUrls.length > 1) ...[
            // Left arrow: only show if there is a previous page
            if (_currentPage > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0), // increases touch target
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

            // Right arrow: only show if there is a next page
            if (_currentPage < imageUrls.length - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentPage < imageUrls.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0), // increases touch target
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // --- MODIFICATION: Updated for a subtle glassmorphic button with blue shade ---
  Widget _buildAdoptMeButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        // This container provides padding from the screen edges
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: ClipRRect(
          // Use a large circular radius to create the stadium/pill shape
          borderRadius: BorderRadius.circular(50.0),
          child: BackdropFilter(
            // The blur effect for the glass
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                // Subtle blue tint for dark theme glassmorphism
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50.0),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.4),
                  width: 1.5,
                ),
                // Subtle shadow with blue tint for depth
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AdoptionFormScreen(petData: widget.petData),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(50.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: const Text(
                      'Adopt Me',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
        color: kPrimaryTextColor,
      ),
    );
  }
}
