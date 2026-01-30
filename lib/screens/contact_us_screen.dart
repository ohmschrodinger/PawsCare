import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawscare/theme/typography.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pawscare/constants/app_colors.dart';
import 'package:pawscare/services/contact_info_service.dart';
import 'package:pawscare/models/contact_info_model.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
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
    if (_contactInfo == null) return;

    final uri = Uri(
      scheme: 'mailto',
      path: _contactInfo!.pawscareEmail,
      query: 'subject=Contact from PawsCare App',
    );
    await _launchUrl(uri.toString(), context);
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    if (_contactInfo == null) return;

    final rawPhone = _contactInfo!.pawscareWhatsapp.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
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
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Contact Us',
          style: AppTypography.title3.copyWith(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryAccentColor),
            )
          : _errorMessage != null
          ? _buildErrorView()
          : _contactInfo == null
          ? const Center(
              child: Text(
                'No contact information available',
                style: TextStyle(color: kPrimaryTextColor),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 32),
                  _buildContactSection(context),
                  const SizedBox(height: 32),
                  _buildVolunteerSection(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load contact information',
              style: AppTypography.title3.copyWith(color: kPrimaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              style: AppTypography.body.copyWith(color: kSecondaryTextColor),
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
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get in Touch',
          style: AppTypography.title1.copyWith(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'re here to help and answer any questions regarding adoption and volunteering.',
          style: AppTypography.body.copyWith(
            color: kSecondaryTextColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTACT CHANNELS',
          style: AppTypography.caption1.copyWith(
            color: kSecondaryTextColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildContactListTile(
                context: context,
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: _contactInfo!.pawscareEmail,
                onTap: () => _launchEmail(context),
                onLongPress: () =>
                    _copyToClipboard(_contactInfo!.pawscareEmail, context),
                showDivider: true,
              ),
              _buildContactListTile(
                context: context,
                icon: Icons.chat_bubble_outline,
                title: 'WhatsApp',
                subtitle: _contactInfo!.pawscareWhatsapp,
                onTap: () => _launchWhatsApp(context),
                onLongPress: () =>
                    _copyToClipboard(_contactInfo!.pawscareWhatsapp, context),
                showDivider: true,
              ),
              _buildContactListTile(
                context: context,
                icon: Icons.business,
                title: 'LinkedIn',
                subtitle: 'Connect with PawsCare',
                onTap: () =>
                    _launchUrl(_contactInfo!.pawscareLinkedin, context),
                onLongPress: () =>
                    _copyToClipboard(_contactInfo!.pawscareLinkedin, context),
                showDivider: true,
              ),
              _buildContactListTile(
                context: context,
                icon: Icons.camera_alt_outlined,
                title: 'Instagram',
                subtitle: '@pawscareanimalresq',
                onTap: () => _launchUrl(_contactInfo!.pawscareInsta, context),
                onLongPress: () =>
                    _copyToClipboard(_contactInfo!.pawscareInsta, context),
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool showDivider = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryAccentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: kPrimaryAccentColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.body.copyWith(
                            color: kPrimaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.caption1.copyWith(
                            color: kSecondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: kSecondaryTextColor.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
            if (showDivider)
              const Divider(height: 1, color: Color(0xFF2C2C2E), indent: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JOIN OUR MISSION',
          style: AppTypography.caption1.copyWith(
            color: kSecondaryTextColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: kPrimaryAccentColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  _launchUrl(_contactInfo!.pawscareVolunteerform, context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Become a Volunteer',
                            style: AppTypography.title3.copyWith(
                              color: kPrimaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Help us make a difference in the lives of animals.',
                            style: AppTypography.caption1.copyWith(
                              color: kSecondaryTextColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimaryAccentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.black, // High contrast on accent color
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
