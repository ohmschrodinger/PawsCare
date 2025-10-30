// screens/about_developers_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pawscare/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pawscare/services/contact_info_service.dart';
import 'package:pawscare/models/contact_info_model.dart';

class AboutDevelopersScreen extends StatefulWidget {
  const AboutDevelopersScreen({super.key});

  @override
  State<AboutDevelopersScreen> createState() => _AboutDevelopersScreenState();
}

class _AboutDevelopersScreenState extends State<AboutDevelopersScreen> {
  ContactInfo? _contactInfo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  Future<void> _loadContactInfo() async {
    try {
      final contactInfo = await ContactInfoService.getContactInfo();
      if (mounted) {
        setState(() {
          _contactInfo = contactInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'About Developers',
          style: TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryAccentColor),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load developer information',
                      style: TextStyle(
                        color: kPrimaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check your internet connection and try again.',
                      style: TextStyle(
                        color: kSecondaryTextColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _loadContactInfo();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryAccentColor,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _contactInfo == null
          ? const Center(
              child: Text(
                'No developer information available',
                style: TextStyle(color: kPrimaryTextColor),
              ),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Meet the team'),
          _buildContent(
            'Hello! We\'re a small, passionate team that designed and built this app from the ground up for PawsCare NGO. We truly hope you enjoy using it as much as we enjoyed creating it!',
          ),
          const SizedBox(height: 8),
          _buildContent('This app was designed and developed by:'),
          const SizedBox(height: 16),
          _buildDeveloperCard(
            name: _contactInfo!.developer1Name,
            role: _contactInfo!.developer1Role,
            linkedInUrl: _contactInfo!.developer1Linkedin,
            githubUrl: _contactInfo!.developer1Github,
          ),
          const SizedBox(height: 16),
          _buildDeveloperCard(
            name: _contactInfo!.developer2Name,
            role: _contactInfo!.developer2Role,
            linkedInUrl: _contactInfo!.developer2Linkedin,
            githubUrl: _contactInfo!.developer2Github,
          ),
          const SizedBox(height: 16),
          _buildDeveloperCard(
            name: _contactInfo!.developer3Name,
            role: _contactInfo!.developer3Role,
            linkedInUrl: _contactInfo!.developer3Linkedin,
            githubUrl: _contactInfo!.developer3Github,
          ),
          const SizedBox(height: 24),
          _buildContent(
            'We\'d love to hear from you! Whether you have feedback, ideas, or simply want to say hello, feel free to connect with us through our LinkedIn profiles.',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          color: kPrimaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  Widget _buildContent(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            color: kSecondaryTextColor,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperCard({
    required String name,
    required String role,
    required String linkedInUrl,
    required String githubUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: kPrimaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: const TextStyle(fontSize: 14, color: kSecondaryTextColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLinkButton(
                icon: FontAwesomeIcons.linkedin,
                label: 'LinkedIn',
                url: linkedInUrl,
              ),
              const SizedBox(width: 12),
              _buildLinkButton(
                icon: FontAwesomeIcons.github,
                label: 'GitHub',
                url: githubUrl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String label,
    required String url,
  }) {
    // Authentic brand colors
    final bool isLinkedIn = label.toLowerCase().contains('linkedin');
    final Color iconColor = isLinkedIn
        ? const Color(0xFF0077B5)
        : Colors.white; // LinkedIn Blue / White

    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: kPrimaryAccentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color:
                    Colors.white, // ✅ White text for both LinkedIn and GitHub
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }
}
