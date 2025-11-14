// screens/terms_and_service_screen.dart

import 'package:flutter/material.dart';
import 'package:pawscare/constants/app_colors.dart';

class TermsAndServiceScreen extends StatelessWidget {
  const TermsAndServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Terms of Service',
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

          _buildSectionHeader('Welcome to PawsCare!'),
          _buildContent(
            'These Terms of Service ("Terms") govern your use of the PawsCare mobile application (the "App", "Service"), operated by PawsCare Team. By downloading, accessing, or using the PawsCare mobile application, you agree to be bound by these Terms of Service.\n\nIf you do not agree with these Terms, please do not use the App.',
          ),

          _buildSectionHeader('1. Eligibility'),
          _buildContent(
            'You must:\n'
            '• Be at least 13 years old\n'
            '• Agree to these Terms\n'
            '• Use the app in compliance with applicable laws\n\n'
            'If you are under 18, you confirm that you have parental or guardian consent to use the app.',
          ),

          _buildSectionHeader('2. Your Account'),
          _buildContent(
            'To use certain features, you must create an account using:\n'
            '• Email/password\n'
            '• Google login\n'
            '• Phone number (OTP login)\n\n'
            'You agree to:\n'
            '• Provide accurate and truthful information\n'
            '• Keep your login credentials secure\n'
            '• Be responsible for all activity under your account\n\n'
            'We are not liable for unauthorized access resulting from your failure to secure your device or credentials.',
          ),

          _buildSectionHeader('3. User Content'),
          _buildContent(
            'You may upload various forms of content, including:\n'
            '• Animal photos\n'
            '• Adoption listings\n'
            '• Posts, comments, likes\n'
            '• Profile information\n\n'
            'By uploading content, you grant PawsCare:\n'
            '• A non-exclusive, worldwide license to store, display, and process your content only within the platform for adoption and community-related purposes.\n\n'
            'You retain ownership of your content.\n\n'
            'We reserve the right to remove any content that:\n'
            '• Violates these Terms\n'
            '• Is harmful, abusive, misleading, or inappropriate\n'
            '• Poses risks to the community or animals\n'
            '• Violates laws or copyright rules',
          ),

          _buildSectionHeader('4. Posting Adoption Listings'),
          _buildContent(
            'When creating animal adoption listings, you agree that:\n'
            '• You have the legal right to post the animal for adoption\n'
            '• The information you provide is accurate and truthful\n'
            '• You are responsible for any communication or arrangements made between you and adopters\n\n'
            'PawsCare is NOT responsible for:\n'
            '• Verifying accuracy of listings\n'
            '• Communication between users\n'
            '• Any disputes or issues arising from adoption outside the app\n\n'
            'All adoption decisions and communication are your responsibility.',
          ),

          _buildSectionHeader('5. Prohibited Activities'),
          _buildContent(
            'You agree NOT to:\n'
            '• Upload harmful, abusive, illegal, or misleading content\n'
            '• Post animals that you do not own or have rights to list\n'
            '• Impersonate others\n'
            '• Harass or abuse users\n'
            '• Attempt to hack, disrupt, or reverse engineer the App\n'
            '• Use the App for commercial advertising or spam\n'
            '• Upload copyrighted content without permission\n\n'
            'Violation may result in account suspension or permanent ban.',
          ),

          _buildSectionHeader('6. Third-Party Services'),
          _buildContent(
            'PawsCare uses third-party services to operate:\n'
            '• Firebase Authentication\n'
            '• Firestore Database\n'
            '• Firebase Storage\n'
            '• Google Analytics\n'
            '• Google Sheets API\n\n'
            'By using the app, you also agree to their respective terms and policies.\n\n'
            'PawsCare is not responsible for issues arising from third-party services.',
          ),

          _buildSectionHeader('7. Account Deletion'),
          _buildContent(
            'You may delete your account at any time using the Delete Account feature in the app.\n\n'
            'When your account is deleted:\n'
            '• Your personal information is permanently removed from Firebase systems\n'
            '• Your posts, comments, and listings may be removed or anonymized\n'
            '• Certain data may be retained for security, fraud prevention, or operational obligations\n'
            '• You lose access to all app features permanently\n\n'
            'We are not responsible for data loss resulting from account deletion.',
          ),

          _buildSectionHeader('8. Intellectual Property'),
          _buildContent(
            'All app content, design, features, logos, and code are the property of PawsCare Team.\n\n'
            'You may not:\n'
            '• Copy, distribute, or modify the app\n'
            '• Reverse-engineer or attempt to extract source code\n'
            '• Use the app\'s branding without permission',
          ),

          _buildSectionHeader('9. Limitation of Liability'),
          _buildContent(
            'To the fullest extent permitted by law, PawsCare Team is NOT liable for:\n'
            '• Any damages from the use or inability to use the app\n'
            '• User interactions, conflicts, or adoption arrangements\n'
            '• Loss of data or unauthorized access\n'
            '• Errors, bugs, outages, or service interruptions\n'
            '• Inaccurate or misleading content posted by users\n\n'
            'You use the app at your own risk.',
          ),

          _buildSectionHeader('10. Disclaimer'),
          _buildContent(
            'PawsCare is a platform that facilitates animal adoption.\n'
            'We do not:\n'
            '• Guarantee successful adoptions\n'
            '• Verify user identities or animal ownership\n'
            '• Provide warranties of any kind\n\n'
            'All user-generated content is the responsibility of the user who created it.',
          ),

          _buildSectionHeader('11. Termination'),
          _buildContent(
            'We may suspend or terminate your account if you:\n'
            '• Violate these Terms\n'
            '• Post harmful or inappropriate content\n'
            '• Abuse or disrupt the Service\n'
            '• Engage in fraudulent or unsafe behavior\n\n'
            'We may also modify or discontinue the Service at any time.',
          ),

          _buildSectionHeader('12. Changes to These Terms'),
          _buildContent(
            'We may update these Terms periodically. Updated Terms will be posted inside the app and take effect upon posting.\n\n'
            'Continued use of the app means you accept the updated Terms.',
          ),

          _buildSectionHeader('13. Contact Us'),
          _buildContent(
            'For any questions, issues, or requests related to these Terms:\n\n'
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
