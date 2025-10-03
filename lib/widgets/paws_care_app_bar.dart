import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/user_role.dart';
import '../main_navigation_screen.dart';
import '../screens/my_applications_screen.dart';
import '../screens/all_applications_screen.dart';
import '../screens/admin_logs_screen.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);

PreferredSizeWidget buildPawsCareAppBar({
  required BuildContext context,
  void Function(String)? onMenuSelected,
}) {
  const popupTextStyle = TextStyle(color: kPrimaryTextColor);
  const popupIconColor = kSecondaryTextColor;

  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle.light,
    backgroundColor: kBackgroundColor,
    elevation: 0,
    title: GestureDetector(
      onTap: () => mainNavKey.currentState?.selectTab(0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('lib/assets/pawscare_logo.png', width: 38, height: 38),
          const SizedBox(width: 8),
          const Text(
            'PawsCare',
            style: TextStyle(
              color: kPrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
    centerTitle: false,
    actions: [
      IconButton(
        icon: const Icon(Icons.chat_bubble_outline, color: kPrimaryTextColor),
        onPressed: () async {
          const rawPhone =
              '917057517218'; // country code + number, no '+' sign for these URIs
          const defaultMessage = 'Hello, I\'m interested in PawsCare!';

          // 1) Try WhatsApp app (preferred)
          final whatsappAppUri = Uri.parse(
            'whatsapp://send?phone=$rawPhone&text=${Uri.encodeComponent(defaultMessage)}',
          );

          // 2) Fallback to web wa.me
          final webUri = Uri.parse(
            'https://wa.me/$rawPhone?text=${Uri.encodeComponent(defaultMessage)}',
          );

          try {
            if (await canLaunchUrl(whatsappAppUri)) {
              await launchUrl(
                whatsappAppUri,
                mode: LaunchMode.externalApplication,
              );
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

          return Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: const PopupMenuThemeData(color: kCardColor),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: kPrimaryTextColor),
              onSelected: (value) {
                // Full-screen navigation
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
                }

                if (onMenuSelected != null) onMenuSelected(value);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: popupIconColor),
                      SizedBox(width: 8),
                      Text('Profile', style: popupTextStyle),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  const PopupMenuItem(
                    value: 'all_applications',
                    child: Row(
                      children: [
                        Icon(Icons.list_alt, color: popupIconColor),
                        SizedBox(width: 8),
                        Text('All Applications', style: popupTextStyle),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'activity_logs',
                    child: Row(
                      children: [
                        Icon(Icons.history, color: popupIconColor),
                        SizedBox(width: 8),
                        Text('Activity Logs', style: popupTextStyle),
                      ],
                    ),
                  ),
                ],
                const PopupMenuItem(
                  value: 'my_applications',
                  child: Row(
                    children: [
                      Icon(Icons.assignment, color: popupIconColor),
                      SizedBox(width: 8),
                      Text('My Applications', style: popupTextStyle),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}
