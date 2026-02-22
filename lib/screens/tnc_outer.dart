// screens/tnc_outer.dart

import 'package:flutter/material.dart';
import 'package:pawscare/constants/app_colors.dart';

class TncOuterScreen extends StatelessWidget {
  const TncOuterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Terms & Privacy Policy',
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
          // Header
          _buildSectionHeader('Last Updated'),
          _buildContent('November 14, 2025'),

          _buildSectionHeader('Developer/Company'),
          _buildContent(
            'PawsCare Team\nContact Email: pawscareanimalresq@gmail.com',
          ),

          // Introduction
          _buildSectionHeader('Welcome to PawsCare!'),
          _buildContent(
            'These Terms of Service and Privacy Policy ("Terms") govern your use of the PawsCare mobile application (the "App", "Service"), operated by PawsCare Team. By downloading, accessing, or using the PawsCare mobile application, you agree to be bound by these Terms and Privacy Policy.\n\nIf you do not agree with these Terms, please do not use the App.',
          ),

          // Terms of Service Section
          _buildSectionHeader('TERMS OF SERVICE'),

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

          _buildSectionHeader('5. Adoption Application Agreement'),
          _buildContent(
            'By submitting an adoption application through PawsCare, you acknowledge and agree that:\n\n'
            '• All information provided in the application is true, accurate, and complete to the best of your knowledge\n'
            '• You have not knowingly omitted any information that may be relevant to your application\n'
            '• You understand that providing false or misleading information may result in rejection of your application and/or suspension of your account\n'
            '• You consent to the animal owner or PawsCare Team contacting you regarding your application\n'
            '• You understand that submitting an application does not guarantee approval or adoption\n'
            '• You are genuinely interested in adopting and capable of providing proper care for the animal\n'
            '• You accept full responsibility for any consequences arising from inaccurate information provided\n\n'
            'PawsCare reserves the right to verify the information provided and reject applications that contain false or misleading details.',
          ),

          _buildSectionHeader('6. Prohibited Activities'),
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

          _buildSectionHeader('7. Third-Party Services'),
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

          _buildSectionHeader('10. Termination'),
          _buildContent(
            'We may suspend or terminate your account if you:\n'
            '• Violate these Terms\n'
            '• Post harmful or inappropriate content\n'
            '• Abuse or disrupt the Service\n'
            '• Engage in fraudulent or unsafe behavior\n\n'
            'We may also modify or discontinue the Service at any time.',
          ),

          // Privacy Policy Section
          _buildSectionHeader('PRIVACY POLICY'),

          _buildSectionHeader('Information We Collect'),

          _buildSubheader('Personal Information'),
          _buildContent(
            'When creating or updating an account, we may collect:\n'
            '• Full name\n'
            '• Email address\n'
            '• Phone number\n'
            '• Address (optional)\n'
            '• Profile photo',
          ),

          _buildSubheader('User-Generated Content'),
          _buildContent(
            'We collect content you upload or create in the app, including:\n'
            '• Pet photos\n'
            '• Adoption listings\n'
            '• Posts, comments, likes\n'
            '• Community interactions',
          ),

          _buildSubheader('Authentication Information'),
          _buildContent(
            'Authentication is handled securely through Firebase Authentication, which may collect:\n'
            '• Email/password\n'
            '• Google login credentials\n'
            '• Phone number for OTP verification',
          ),

          _buildSubheader('Device & Diagnostic Data'),
          _buildContent(
            'We automatically collect:\n'
            '• Device ID\n'
            '• Crash logs\n'
            '• App performance data\n'
            '• Analytics and usage statistics',
          ),

          _buildSubheader('Location Information'),
          _buildContent(
            'With your permission, we may collect:\n'
            '• Approximate location\n'
            '• Precise GPS location\n\n'
            'Used for improving adoption relevance and app experience.',
          ),

          _buildSectionHeader('How We Use Your Information'),
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

          _buildSectionHeader('Data Sharing'),
          _buildContent(
            'We do NOT sell or share your data with third parties for advertising.\n\n'
            'We only share data with trusted service providers necessary for app functionality:\n\n'
            'Firebase Services:\n'
            '• Firebase Authentication\n'
            '• Firestore Database\n'
            '• Firebase Storage\n\n'
            'Google APIs:\n'
            '• Google Analytics\n'
            '• Google Sheets API (for logging internal app activity)\n\n'
            'These services process data on our behalf and follow strict security measures.\n\n'
            'We do NOT share data with NGOs, external partners, or advertisers.',
          ),

          _buildSectionHeader('Data Storage & Security'),
          _buildContent(
            'Your data is securely stored using:\n'
            '• Firebase Firestore\n'
            '• Firebase Storage\n'
            '• Firebase Authentication\n\n'
            'We apply industry-standard security measures to protect your data, including encryption and secure access protocols.\n\n'
            'However, no method of electronic transmission is 100% secure, and we cannot guarantee absolute protection.',
          ),

          _buildSectionHeader('Your Rights'),
          _buildContent(
            'You have the right to:\n'
            '• Access your personal data\n'
            '• Update or correct your information\n'
            '• Withdraw permissions (location, camera, etc.)\n'
            '• Request deletion of your data\n'
            '• Delete your account\n\n'
            'To exercise any rights, contact us at pawscareanimalresq@gmail.com.',
          ),

          _buildSectionHeader('Account Deletion'),
          _buildContent(
            'PawsCare provides an in-app Delete Account feature.\n\n'
            'When you delete your account:\n'
            '• Your personal information (name, email, phone, profile photo, address) is permanently deleted from Firebase Authentication and Firestore.\n'
            '• Your listings, posts, and comments may be deleted or anonymized depending on moderation needs.\n'
            '• Internal logs stored via Google Sheets API may be retained for security, fraud prevention, or operational purposes unless removal is required by law.\n'
            '• Your app access is permanently removed.\n\n'
            'You may delete your account anytime from within the app or by contacting us at pawscareanimalresq@gmail.com.',
          ),

          _buildSectionHeader('Changes to These Terms'),
          _buildContent(
            'We may update these Terms and Privacy Policy periodically. Updated Terms will be posted inside the app and take effect upon posting.\n\n'
            'Continued use of the app means you accept the updated Terms.',
          ),

          _buildSectionHeader('Contact Us'),
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
