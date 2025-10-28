// screens/view_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> animalData;

  const ViewDetailsScreen({super.key, required this.animalData});

  @override
  State<ViewDetailsScreen> createState() => _ViewDetailsScreenState();
}

class _ViewDetailsScreenState extends State<ViewDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animalData = widget.animalData;
    final postedAt = animalData['postedAt'] as Timestamp?;
    final postedDate = postedAt != null
        ? DateFormat('MMM d, yyyy').format(postedAt.toDate())
        : 'N/A';

    final imageUrls = (animalData['imageUrls'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Text(
          animalData['name'] ?? 'Animal Details',
          style: const TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos carousel
            if (imageUrls.isNotEmpty) ...[
              SizedBox(
                height: 300,
                width: double.infinity,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: imageUrls.length,
                      onPageChanged: (idx) =>
                          setState(() => _currentPage = idx),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade900,
                            child: const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: kSecondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imageUrls.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            width: _currentPage == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? kPrimaryTextColor
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
              const SizedBox(height: 12),
            ] else ...[
              // fallback when no images
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Center(
                  child: Icon(Icons.pets, size: 64, color: kSecondaryTextColor),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Name prominently in body as well
            Text(
              animalData['name'] ?? 'Unknown',
              style: const TextStyle(
                color: kPrimaryTextColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            _buildDetailItem('Posted by', animalData['postedByEmail']),
            _buildDetailItem('Date', postedDate),
            const SizedBox(height: 12),
            _buildSectionHeader('Basic Info'),
            _buildDetailItem('Species', animalData['species']),
            _buildDetailItem('Breed', animalData['breed']),
            _buildDetailItem('Age', animalData['age']),
            _buildDetailItem('Gender', animalData['gender']),
            _buildDetailItem('Mother Status', animalData['motherStatus']),
            const SizedBox(height: 12),
            _buildSectionHeader('Health & Wellness'),
            _buildDetailItem('Sterilization', animalData['sterilization']),
            _buildDetailItem('Vaccination', animalData['vaccination']),
            _buildDetailItem('Deworming', animalData['deworming']),
            if (animalData['medicalIssues']?.isNotEmpty ?? false)
              _buildDetailItem('Medical Issues', animalData['medicalIssues']),
            const SizedBox(height: 12),
            _buildSectionHeader('Location & Contact'),
            _buildDetailItem('Location', animalData['location']),
            _buildDetailItem('Contact', animalData['contactPhone']),
            if (animalData['rescueStory']?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              _buildSectionHeader('Rescue Story'),
              _buildContent(animalData['rescueStory'] ?? ''),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: kPrimaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    final isPhoneNumber = label == 'Contact';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kSecondaryTextColor,
                ),
              ),
            ),
            Expanded(
              child: isPhoneNumber
                  ? InkWell(
                      onTap: () => _launchWhatsApp(value),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    )
                  : Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: kPrimaryTextColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Remove any non-digit characters except the leading +
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Create WhatsApp URL
    final whatsappUrl = Uri.parse('https://wa.me/$cleanNumber');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening WhatsApp: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildContent(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: kSecondaryTextColor,
          height: 1.5,
        ),
      ),
    );
  }
}
