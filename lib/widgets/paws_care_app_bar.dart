import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/user_role.dart';
import '../main_navigation_screen.dart';

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
        children:  [
        Image.asset(
        'lib/assets/pawscare_logo.png', // path relative to project root
        width: 38,  // adjust as needed
        height: 38, // adjust as needed
        ),
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

          return Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: const PopupMenuThemeData(color: kCardColor),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: kPrimaryTextColor),
              onSelected: (value) {
                if (onMenuSelected != null) onMenuSelected(value);
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
              ],
            ),
          );
        },
      ),
    ],
  );
}
