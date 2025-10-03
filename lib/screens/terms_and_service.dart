// screens/terms_and_service_screen.dart

import 'package:flutter/material.dart';

const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);

class TermsAndServiceScreen extends StatelessWidget {
  const TermsAndServiceScreen({Key? key}) : super(key: key);

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
          _buildSectionHeader('Effective Date'),
          _buildContent('October 3, 2025'),
          _buildSectionHeader('Welcome to PawsCare!'),
          _buildContent(
              'These Terms of Service ("Terms") govern your use of the PawsCare mobile application (the "Service"), operated by PawsCare. By creating an account or using our Service, you agree to be bound by these Terms.'),
          _buildSectionHeader('1. The PawsCare Service'),
          _buildContent(
              'PawsCare is a platform designed to connect potential adopters with animals in need of a home. The Service allows users to browse animals, apply for adoption, and submit animals for adoption, subject to approval by our administrators ("Admins").'),
          _buildSectionHeader('2. User Accounts & Roles'),
          _buildContent(
              'Account Creation: You must register for an account using Firebase Authentication to use most features of the Service. You agree to provide accurate and complete information and to keep this information up to date.\n\n'
              'Roles: The service has two roles: "Users" (general public, potential adopters) and "Admins" (NGO staff, moderators). Your permissions are determined by your assigned role.\n\n'
              'Account Security: You are responsible for safeguarding your account password and for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.'),
          _buildSectionHeader('3. User-Generated Content (UGC)'),
          _buildContent(
              'This refers to any content you submit to the Service, such as animal profiles, images, and rescue stories.\n\n'
              'Animal Submissions: Users may submit animal profiles for listing on the platform. All submissions are subject to review and approval by our Admins.\n\n'
              'Responsibility: You are solely responsible for the UGC you submit. You warrant that you have all necessary rights to post the content and that it is accurate, truthful, and not misleading.\n\n'
              'Our Rights: We reserve the right, in our sole discretion, to review, approve, reject, edit, or remove any UGC at any time and for any reason. A rejection may be accompanied by a reason to allow for resubmission.\n\n'
              'License: By posting UGC, you grant PawsCare a worldwide, non-exclusive, royalty-free license to use, reproduce, display, and distribute your content in connection with the Service.'),
          _buildSectionHeader('4. Adoption Application Process'),
          _buildContent(
              'Submitting an Application: When you apply to adopt an animal, you agree to provide truthful and complete information in the adoption form.\n\n'
              'No Guarantee: Submitting an application does not guarantee adoption. Our Admins review all applications and make decisions based on the best interest of the animal.\n\n'
              'Decision: The Admin\'s decision to accept or reject an application is final. You will be notified of the decision via in-app or push notifications.'),
          _buildSectionHeader('5. Prohibited Conduct'),
          _buildContent(
              'You agree not to:\n'
              '- Use the Service for any illegal purpose or in violation of any local, state, national, or international law.\n'
              '- Provide false or fraudulent information in your account, animal submissions, or adoption applications.\n'
              '- Harass, threaten, or defraud other users or Admins.\n'
              '- Reverse engineer, decompile, or otherwise attempt to discover the source code of the Service.\n'
              '- Interfere with the proper working of the Service.'),
          _buildSectionHeader('6. Termination'),
          _buildContent(
              'We may terminate or suspend your account, without prior notice, for conduct that we believe violates these Terms or is otherwise harmful to other users of the Service, us, or third parties. You may terminate your account at any time by contacting us at pawscareanimalresq@gmail.com.'),
          _buildSectionHeader('7. Disclaimers'),
          _buildContent(
              'The Service is provided "AS IS" without warranties of any kind. We do not guarantee that the Service will be uninterrupted, secure, or error-free. We are not responsible for the conduct of any user or the health and temperament of any animal listed.'),
          _buildSectionHeader('8. Limitation of Liability'),
          _buildContent(
              'To the fullest extent permitted by law, PawsCare shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, resulting from your use of the Service.'),
          _buildSectionHeader('9. Governing Law'),
          _buildContent(
              'These Terms shall be governed by the laws of India. Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts located in Mumbai, Maharashtra.'),
          _buildSectionHeader('10. Contact Us'),
          _buildContent(
              'If you have any questions about these Terms, please contact us at: pawscareanimalresq@gmail.com'),
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
