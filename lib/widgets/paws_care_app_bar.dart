import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawscare/widgets/glassmorphic_popup_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

// Assuming these are in other files, keep their imports
import '../utils/user_role.dart';
import '../main_navigation_screen.dart';
import '../screens/my_applications_screen.dart';
import '../screens/all_applications_screen.dart';
import '../screens/admin_logs_screen.dart';
import '../screens/contact_us_screen.dart';
import '../services/notification_badge_service.dart';
import '../constants/app_colors.dart';

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
  BuildContext context,
  void Function(String)? onMenuSelected,
) {
  const popupTextStyle = TextStyle(color: kPrimaryTextColor);
  const popupIconColor = kSecondaryTextColor;

  return [
    // Cat Facts Icon
    IconButton(
      icon: const Icon(Icons.lightbulb_outline, color: kPrimaryTextColor),
      tooltip: 'Cat Facts',
      onPressed: () {
        Navigator.of(context).pushNamed('/cat-facts');
      },
    ),
    FutureBuilder<String>(
      future: getCurrentUserRole(),
      builder: (context, snapshot) {
        final role = snapshot.data ?? 'user';
        final isAdmin = role == 'admin';

        return StreamBuilder<bool>(
          stream: isAdmin
              ? NotificationBadgeService.hasUnderReviewApplications()
              : NotificationBadgeService.hasNewApplicationUpdates(
                  FirebaseAuth.instance.currentUser?.uid ?? '',
                ),
          builder: (context, badgeSnapshot) {
            final showBadge = badgeSnapshot.data ?? false;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                GlassmorphicPopupMenu(
                  icon: const Icon(Icons.more_vert, color: kPrimaryTextColor),
                  onItemSelected: (value) {
                    if (value == 'my_applications') {
                      // Mark applications as seen when user opens My Applications
                      if (!isAdmin) {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId != null) {
                          NotificationBadgeService.markApplicationsAsSeen(
                            userId,
                          );
                        }
                      }
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
                        MaterialPageRoute(
                          builder: (_) => const AdminLogsScreen(),
                        ),
                      );
                    } else if (value == 'contact_us') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ContactUsScreen(),
                        ),
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
                      GlassmorphicPopupMenuItem(
                        value: 'all_applications',
                        child: Row(
                          children: [
                            const Icon(Icons.list_alt, color: popupIconColor),
                            const SizedBox(width: 12),
                            const Text(
                              'All Applications',
                              style: popupTextStyle,
                            ),
                            const SizedBox(width: 8),
                            if (showBadge)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
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
                    GlassmorphicPopupMenuItem(
                      value: 'my_applications',
                      child: Row(
                        children: [
                          const Icon(Icons.assignment, color: popupIconColor),
                          const SizedBox(width: 12),
                          const Text('My Applications', style: popupTextStyle),
                          const SizedBox(width: 8),
                          if (!isAdmin && showBadge)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
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
                ),
                // Red dot notification badge
                if (showBadge)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: kBackgroundColor, width: 1.5),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    ),
  ];
}

// --- ⭐️ MODIFICATION END ---
