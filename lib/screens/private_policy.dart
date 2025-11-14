// screens/private_policy.dart

import 'package:flutter/material.dart';
import 'package:pawscare/constants/app_colors.dart';

class PrivatePolicyScreen extends StatelessWidget {
  const PrivatePolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
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
          _buildSectionHeader('Last Updated'),
          _buildContent('November 14, 2025'),

          _buildSectionHeader('Developer/Company'),
          _buildContent(
            'PawsCare Team\nContact Email: pawscareanimalresq@gmail.com',
          ),

          _buildContent(
            'PawsCare ("we", "our", "us") operates the PawsCare mobile application ("App"). This Privacy Policy explains how we collect, use, store, and protect your information when you use our services.\n\nBy using PawsCare, you agree to the practices described in this Privacy Policy.',
          ),

          _buildSectionHeader('1. Information We Collect'),

          _buildSubheader('1.1 Personal Information'),
          _buildContent(
            'When creating or updating an account, we may collect:\n'
            '• Full name\n'
            '• Email address\n'
            '• Phone number\n'
            '• Address (optional)\n'
            '• Profile photo',
          ),

          _buildSubheader('1.2 User-Generated Content'),
          _buildContent(
            'We collect content you upload or create in the app, including:\n'
            '• Pet photos\n'
            '• Adoption listings\n'
            '• Posts, comments, likes\n'
            '• Community interactions',
          ),

          _buildSubheader('1.3 Authentication Information'),
          _buildContent(
            'Authentication is handled securely through Firebase Authentication, which may collect:\n'
            '• Email/password\n'
            '• Google login credentials\n'
            '• Phone number for OTP verification',
          ),

          _buildSubheader('1.4 Device & Diagnostic Data'),
          _buildContent(
            'We automatically collect:\n'
            '• Device ID\n'
            '• Crash logs\n'
            '• App performance data\n'
            '• Analytics and usage statistics',
          ),

          _buildSubheader('1.5 Location Information'),
          _buildContent(
            'With your permission, we may collect:\n'
            '• Approximate location\n'
            '• Precise GPS location\n\n'
            'Used for improving adoption relevance and app experience.',
          ),

          _buildSectionHeader('2. How We Use Your Information'),
          _buildContent(
            'Your information is used to:\n'
            '• Create and manage user accounts\n'
            '• Display and manage adoption listings\n'
            '• Provide community features (posts, comments, likes)\n'
            '• Maintain platform safety through moderation\n'
            '• Improve and develop new features\n'
            '• Analyze app performance and usage\n'
            '• Maintain internal logs (via Google Sheets API) for record-keeping\n'
            '• Ensure authentication and security\n\n'
            'We do NOT use your information for advertising or marketing.',
          ),

          _buildSectionHeader('3. Data Sharing'),
          _buildContent(
            'We do NOT sell or share your data with third parties for advertising.\n\n'
            'We only share data with trusted service providers necessary for app functionality:',
          ),

          _buildSubheader('3.1 Firebase Services'),
          _buildContent(
            '• Firebase Authentication\n'
            '• Firestore Database\n'
            '• Firebase Storage',
          ),

          _buildSubheader('3.2 Google APIs'),
          _buildContent(
            '• Google Analytics\n'
            '• Google Sheets API (for logging internal app activity)\n\n'
            'These services process data on our behalf and follow strict security measures.\n\n'
            'We do NOT share data with NGOs, external partners, or advertisers.',
          ),

          _buildSectionHeader('4. Data Storage & Security'),
          _buildContent(
            'Your data is securely stored using:\n'
            '• Firebase Firestore\n'
            '• Firebase Storage\n'
            '• Firebase Authentication\n\n'
            'We apply industry-standard security measures to protect your data, including encryption and secure access protocols.\n\n'
            'However, no method of electronic transmission is 100% secure, and we cannot guarantee absolute protection.',
          ),

          _buildSectionHeader('5. Children\'s Privacy'),
          _buildContent(
            'PawsCare is intended for users aged 13 and above.\n\n'
            'We do not knowingly collect personal information from children under 13. If we discover such information, we will delete it immediately.',
          ),

          _buildSectionHeader('6. Your Rights'),
          _buildContent(
            'You have the right to:\n'
            '• Access your personal data\n'
            '• Update or correct your information\n'
            '• Withdraw permissions (location, camera, etc.)\n'
            '• Request deletion of your data\n'
            '• Delete your account\n\n'
            'To exercise any rights, contact us at pawscareanimalresq@gmail.com.',
          ),

          _buildSectionHeader('7. Permissions Used by the App'),
          _buildContent(
            'PawsCare may request the following permissions:\n'
            '• Camera – for capturing pet images\n'
            '• Storage/Photos – for uploading images\n'
            '• Location (approximate & precise) – for improving adoption relevance\n'
            '• Internet access – for app functionality\n\n'
            'Permissions are used only for their intended purpose.',
          ),

          _buildSectionHeader('8. Account Deletion'),
          _buildContent(
            'PawsCare provides an in-app Delete Account feature.\n\n'
            'When you delete your account:\n'
            '• Your personal information (name, email, phone, profile photo, address) is permanently deleted from Firebase Authentication and Firestore.\n'
            '• Your listings, posts, and comments may be deleted or anonymized depending on moderation needs.\n'
            '• Internal logs stored via Google Sheets API may be retained for security, fraud prevention, or operational purposes unless removal is required by law.\n'
            '• Your app access is permanently removed.\n\n'
            'You may delete your account anytime from within the app or by contacting us at pawscareanimalresq@gmail.com.',
          ),

          _buildSectionHeader('9. Changes to This Privacy Policy'),
          _buildContent(
            'We may update this Privacy Policy from time to time. Any changes will be posted inside the app, and the "Last Updated" date will be revised.\n\n'
            'Continued use of the app after changes indicates acceptance of the updated policy.',
          ),

          _buildSectionHeader('10. Contact Us'),
          _buildContent(
            'For questions, concerns, or privacy requests, contact us:\n\n'
            '📧 pawscareanimalresq@gmail.com\n'
            '👥 PawsCare Team',
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
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSubheader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0, left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: kPrimaryTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
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
            fontSize: 14,
            color: kSecondaryTextColor,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
