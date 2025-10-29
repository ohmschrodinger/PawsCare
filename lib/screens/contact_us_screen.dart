import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawscare/theme/typography.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:pawscare/constants/app_colors.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open $url')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'pawscareanimalresq@gmail.com',
      query: 'subject=Contact from PawsCare App',
    );
    await _launchUrl(uri.toString(), context);
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    const rawPhone = '917057517218';
    final whatsappAppUri = Uri.parse('whatsapp://send?phone=$rawPhone');
    final webUri = Uri.parse('https://wa.me/$rawPhone');

    try {
      if (await canLaunchUrl(whatsappAppUri)) {
        await launchUrl(whatsappAppUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open WhatsApp')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Contact Us',
          style: AppTypography.title3.copyWith(color: kPrimaryTextColor),
        ),
      ),
      body: Stack(
        children: [
          // --- LAYER 1: The background image ---
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.2),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // --- LAYER 2: The blur overlay ---
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),

          // --- LAYER 3: Your original screen content, now inside a SafeArea ---
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Get in Touch',
                      style: AppTypography.title1.copyWith(
                        color: kPrimaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'d love to hear from you!',
                      style: AppTypography.body.copyWith(
                        color: kSecondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Contact Us Section
                    Text(
                      'Contact us on',
                      style: AppTypography.title3.copyWith(
                        color: kPrimaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email Card
                    _buildGlassmorphicContactCard(
                      context: context,
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: 'pawscareanimalresq@gmail.com',
                      onTap: () => _launchEmail(context),
                      onCopy: () => _copyToClipboard(
                        'pawscareanimalresq@gmail.com',
                        context,
                      ),
                    ),

                    // WhatsApp Card
                    _buildGlassmorphicContactCard(
                      context: context,
                      icon: Icons.chat,
                      title: 'WhatsApp',
                      subtitle: '+91 7057517218',
                      onTap: () => _launchWhatsApp(context),
                      onCopy: () => _copyToClipboard('+91 7057517218', context),
                    ),

                    // LinkedIn Card
                    _buildGlassmorphicContactCard(
                      context: context,
                      icon: Icons.business,
                      title: 'LinkedIn',
                      subtitle: 'PawsCare',
                      onTap: () => _launchUrl(
                        'https://www.linkedin.com/company/pawscare/',
                        context,
                      ),
                      onCopy: () => _copyToClipboard(
                        'https://www.linkedin.com/company/pawscare/',
                        context,
                      ),
                    ),

                    // Instagram Card
                    _buildGlassmorphicContactCard(
                      context: context,
                      icon: Icons.photo_camera,
                      title: 'Instagram',
                      subtitle: '@pawscareanimalresq',
                      onTap: () => _launchUrl(
                        'https://www.instagram.com/pawscareanimalresq/',
                        context,
                      ),
                      onCopy: () =>
                          _copyToClipboard('pawscareanimalresq', context),
                    ),

                    const SizedBox(height: 40),

                    // Volunteer Section
                    _buildVolunteerSection(context),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required VoidCallback onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kPrimaryAccentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: kPrimaryAccentColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTypography.headline.copyWith(
                                color: kPrimaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: AppTypography.subhead.copyWith(
                                color: kSecondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          color: kSecondaryTextColor,
                          size: 20,
                        ),
                        onPressed: onCopy,
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolunteerSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kPrimaryAccentColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kPrimaryAccentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism,
                          color: kPrimaryAccentColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Want to Volunteer?',
                          style: AppTypography.title2.copyWith(
                            color: kPrimaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join our community of passionate volunteers who make a difference in the lives of animals every day. Your time and dedication can help save lives!',
                    style: AppTypography.subhead.copyWith(
                      color: kSecondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kPrimaryAccentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50.0),
                            border: Border.all(
                              color: kPrimaryAccentColor.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _launchUrl(
                                'https://docs.google.com/forms/d/e/1FAIpQLSduQq2bKmfyvKAkZPOeWR0ZqboNr0hMW2xyUW4geYIidSvxJg/viewform',
                                context,
                              ),
                              borderRadius: BorderRadius.circular(50.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Fill Volunteer Form',
                                      style: AppTypography.callout.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward,
                                      size: 20,
                                      color: kPrimaryTextColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
