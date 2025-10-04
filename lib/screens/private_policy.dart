// screens/private_policy.dart

import 'package:flutter/material.dart';

const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);

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
          _buildSectionHeader('Effective Date'),
          _buildContent('October 3, 2025'),
          _buildSectionHeader('Introduction'),
          _buildContent(
              'This Privacy Policy explains how PawsCare collects, uses, and shares information about you when you use the PawsCare mobile application (the "Service").'),
          _buildSectionHeader('1. Information We Collect'),
          _buildContent(
              'a) Information You Provide to Us:\n'
              '- Account Information: When you register, we collect your authentication information (such as an email address) via Firebase Authentication. We also assign you a "user" role.\n'
              '- Adoption Application Data: When you apply to adopt, we collect the information you provide in the form, which may include your name, contact information, pet ownership experience, home environment details, and reason for adoption.\n'
              '- Animal Submission Data: When you submit an animal for listing, we collect the information you provide, including the animal\'s name, bio, rescue story, health status, and images.\n\n'
              'b) Information We Collect Automatically:\n'
              '- Usage Information: We collect your Firebase User ID to associate you with your data.\n'
              '- Device Information: We use Firebase Cloud Messaging to send notifications. To do this, we may collect a device token or similar identifier.'),
          _buildSectionHeader('2. How We Use Your Information'),
          _buildContent(
              'We use the information we collect to:\n'
              '- Create and manage your account and role within the app.\n'
              '- Process your adoption applications and share them with Admins for review.\n'
              '- Review and manage your animal submissions.\n'
              '- Display approved animal listings publicly on the Service.\n'
              '- Communicate with you by sending notifications about the status of your applications and submissions.\n'
              '- Operate, maintain, and improve the Service.'),
          _buildSectionHeader('3. How We Share Your Information'),
          _buildContent(
              'Your information is shared in the following ways:\n'
              '- With Admins: Your account details and the full contents of your adoption applications are shared with Admins to allow them to make informed decisions.\n'
              '- With the Public: When your animal submission is approved, the animal\'s profile (including its story, bio, and images) is made public.\n'
              '- Important Note: Your workflow mentions "Contact info" on the Pet Detail Page. You must decide if this will be the NGO\'s contact info or the submitting user\'s info. We strongly recommend against making a user\'s personal contact information public. This policy assumes only non-personal information is displayed.\n'
              '- For Legal Reasons: We may disclose your information if required to do so by law or in response to a valid request from a law enforcement or governmental authority.'),
          _buildSectionHeader('4. Data Security'),
          _buildContent(
              'We use services like Firebase that provide industry-standard security measures to protect your information. However, no electronic transmission or storage is 100% secure, and we cannot guarantee absolute security.'),
          _buildSectionHeader('5. Your Rights and Choices'),
          _buildContent(
              'You can review and update your information through the "My History" section of the app, which includes "My Applications" and "My Listings." You can also edit or delete your own animal submissions as permitted by the app\'s functionality. To delete your entire account and associated data, please contact us at [Your Support Email Address].'),
          _buildSectionHeader('6. Children\'s Privacy'),
          _buildContent(
              'The Service is not intended for individuals under the age of 18. We do not knowingly collect personal information from children under 18.'),
          _buildSectionHeader('7. Changes to this Privacy Policy'),
          _buildContent(
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy within the app.'),
          _buildSectionHeader('8. Contact Us'),
          _buildContent(
              'If you have any questions about this Privacy Policy, please contact us at: pawscareanimalresq@gmail.com'),
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
