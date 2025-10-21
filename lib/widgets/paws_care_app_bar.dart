import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawscare/widgets/glassmorphic_popup_menu.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

// Assuming these are in other files, keep their imports
import '../utils/user_role.dart';
import '../main_navigation_screen.dart';
import '../screens/my_applications_screen.dart';
import '../screens/all_applications_screen.dart';
import '../screens/admin_logs_screen.dart';
import '../screens/contact_us_screen.dart';

// --- THEME CONSTANTS ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);

// --- ⭐️ MODIFICATION START ---

PreferredSizeWidget buildPawsCareAppBar({
  required BuildContext context,
  Widget? title, // Accepts an optional custom title widget
  bool isTransparent = false, // Accepts an optional transparency flag
  void Function(String)? onMenuSelected,
}) {
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle.light,
    // Use the transparency flag to set the background color
    backgroundColor: isTransparent ? Colors.transparent : kBackgroundColor,
    elevation: 0,
    // If a custom title is provided, use it. Otherwise, use the default PawsCare logo.
    title: title ?? _buildDefaultTitle(context),
    centerTitle: false,
    // The actions remain the same
    actions: _buildAppBarActions(context, onMenuSelected),
  );
}

/// Helper widget for the default title (Logo + Name)
Widget _buildDefaultTitle(BuildContext context) {
  return GestureDetector(
    onTap: () => mainNavKey.currentState?.selectTab(0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('lib/assets/pawscare_logo.png', width: 38, height: 35),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            'PawsCare',
            style: GoogleFonts.borel(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Helper function to build the action icons to keep the main function clean
List<Widget> _buildAppBarActions(
    BuildContext context, void Function(String)? onMenuSelected) {
  const popupTextStyle = TextStyle(color: kPrimaryTextColor);
  const popupIconColor = kSecondaryTextColor;

  return [
    IconButton(
      icon: const Icon(Icons.chat_bubble_outline, color: kPrimaryTextColor),
      onPressed: () async {
        const rawPhone = '917057517218';
        const defaultMessage = '';
        final whatsappAppUri = Uri.parse(
          'whatsapp://send?phone=$rawPhone&text=${Uri.encodeComponent(defaultMessage)}',
        );
        final webUri = Uri.parse(
          'https://wa.me/$rawPhone?text=${Uri.encodeComponent(defaultMessage)}',
        );

        try {
          if (await canLaunchUrl(whatsappAppUri)) {
            await launchUrl(whatsappAppUri,
                mode: LaunchMode.externalApplication);
          } else if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open WhatsApp or web fallback.'),
              ),
            );
          }
        } catch (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening WhatsApp: $err')),
          );
        }
      },
    ),
    IconButton(
      icon: const Icon(Icons.notifications_none, color: kPrimaryTextColor),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications coming soon!')),
        );
      },
    ),
    FutureBuilder<String>(
      future: getCurrentUserRole(),
      builder: (context, snapshot) {
        final role = snapshot.data ?? 'user';
        final isAdmin = role == 'admin';

        return GlassmorphicPopupMenu(
          icon: const Icon(Icons.more_vert, color: kPrimaryTextColor),
          onItemSelected: (value) {
            if (value == 'my_applications') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MyApplicationsScreen(),
                ),
              );
            } else if (value == 'all_applications') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AllApplicationsScreen(),
                ),
              );
            } else if (value == 'profile') {
              mainNavKey.currentState?.selectTab(4);
            } else if (value == 'activity_logs') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminLogsScreen()),
              );
            } else if (value == 'contact_us') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
              );
            }
            if (onMenuSelected != null) onMenuSelected(value);
          },
          items: [
            const GlassmorphicPopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, color: popupIconColor),
                  SizedBox(width: 12),
                  Text('Profile', style: popupTextStyle),
                ],
              ),
            ),
            if (isAdmin) ...[
              const GlassmorphicPopupMenuItem(
                value: 'all_applications',
                child: Row(
                  children: [
                    Icon(Icons.list_alt, color: popupIconColor),
                    SizedBox(width: 12),
                    Text('All Applications', style: popupTextStyle),
                  ],
                ),
              ),
              const GlassmorphicPopupMenuItem(
                value: 'activity_logs',
                child: Row(
                  children: [
                    Icon(Icons.history, color: popupIconColor),
                    SizedBox(width: 12),
                    Text('Activity Logs', style: popupTextStyle),
                  ],
                ),
              ),
            ],
            const GlassmorphicPopupMenuItem(
              value: 'my_applications',
              child: Row(
                children: [
                  Icon(Icons.assignment, color: popupIconColor),
                  SizedBox(width: 12),
                  Text('My Applications', style: popupTextStyle),
                ],
              ),
            ),
            const GlassmorphicPopupMenuItem(
              value: 'contact_us',
              child: Row(
                children: [
                  Icon(Icons.contact_support, color: popupIconColor),
                  SizedBox(width: 12),
                  Text('Contact Us', style: popupTextStyle),
                ],
              ),
            ),
          ],
        );
      },
    ),
  ];
}

// --- ⭐️ MODIFICATION END ---