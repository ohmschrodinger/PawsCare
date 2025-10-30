// screens/about_developers_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pawscare/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDevelopersScreen extends StatelessWidget {
  const AboutDevelopersScreen({super.key});

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
      body: _buildBody(),
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
            name: 'Om Dhamame',
            role: 'Lead Developer',
            linkedInUrl: 'https://www.linkedin.com/in/ohmschrodinger/',
            githubUrl: 'https://github.com/ohmschrodinger',
          ),
          const SizedBox(height: 16),
          _buildDeveloperCard(
            name: 'Mahi Sharma',
            role: 'Developer',
            linkedInUrl: 'https://www.linkedin.com/in/mahisharma',
            githubUrl: 'https://github.com/mahisharma',
          ),
          const SizedBox(height: 16),
          _buildDeveloperCard(
            name: 'Kushagra Goyal',
            role: 'Developer',
            linkedInUrl: 'https://www.linkedin.com/in/kushagra',
            githubUrl: 'https://github.com/kushagragoyal',
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
    final Color iconColor =
        isLinkedIn ? const Color(0xFF0077B5) : Colors.white; // LinkedIn Blue / White

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
                color: Colors.white, // ✅ White text for both LinkedIn and GitHub
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
