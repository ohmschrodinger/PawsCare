import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/user_role.dart';
import '../main_navigation_screen.dart';

// --- Re-using the color palette for consistency ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -------------------------------------------------

class AppBarMenuItem {
  final String value;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  AppBarMenuItem({
    required this.value,
    required this.label,
    required this.icon,
    this.onTap,
  });
}

PreferredSizeWidget buildPawsCareAppBar({
  required BuildContext context,
  VoidCallback? onLogout,
  void Function(String)? onMenuSelected,
}) {
  // Style for text within the popup menu
  const popupTextStyle = TextStyle(color: kPrimaryTextColor);
  // Style for icons within the popup menu
  const popupIconColor = kSecondaryTextColor;

  return AppBar(
    // Ensure status bar icons are light to contrast with the dark background
    systemOverlayStyle: SystemUiOverlayStyle.light,
    backgroundColor: kBackgroundColor,
    elevation: 0,
    title: GestureDetector(
      onTap: () {
        // Navigate to home (index 0) using the mainNavKey
        mainNavKey.currentState?.selectTab(0);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          // Use the yellow accent for the main brand icon
          Icon(Icons.pets, color: kPrimaryAccentColor, size: 24),
          SizedBox(width: 8),
          Text(
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
        // Use primary text color for action icons
        icon: const Icon(Icons.chat_bubble_outline, color: kPrimaryTextColor),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat feature coming soon!')),
          );
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
          // Theme the popup menu to have a dark background
          return Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: const PopupMenuThemeData(
                color: kCardColor, // Dark background for the menu
              ),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: kPrimaryTextColor),
              onSelected: (value) {
                if (onMenuSelected != null) onMenuSelected(value);
                if (value == 'logout' && onLogout != null) onLogout();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: const [
                      Icon(Icons.person, color: popupIconColor),
                      SizedBox(width: 8),
                      Text('Profile', style: popupTextStyle),
                    ],
                  ),
                ),
                if (isAdmin)
                  PopupMenuItem(
                    value: 'all_applications',
                    child: Row(
                      children: const [
                        Icon(Icons.list_alt, color: popupIconColor),
                        SizedBox(width: 8),
                        Text('All Applications', style: popupTextStyle),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'my_applications',
                  child: Row(
                    children: const [
                      Icon(Icons.assignment, color: popupIconColor),
                      SizedBox(width: 8),
                      Text('My Applications', style: popupTextStyle),
                    ],
                  ),
                ),
                // --- It's good practice to also include the Logout option in this list ---
                // --- The original code was missing this part in the itemBuilder. ---
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: popupIconColor),
                      SizedBox(width: 8),
                      Text('Logout', style: popupTextStyle),
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