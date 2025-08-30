import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/user_role.dart';
import '../main_navigation_screen.dart';

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
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;
  final appBarColor = isDarkMode
      ? theme.scaffoldBackgroundColor
      : Colors.grey.shade50;
  final appBarTextColor = theme.textTheme.titleLarge?.color;

  return AppBar(
    systemOverlayStyle: isDarkMode
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
    backgroundColor: appBarColor,
    elevation: 0,
    title: GestureDetector(
      onTap: () {
        // Navigate to home (index 0) using the mainNavKey
        mainNavKey.currentState?.selectTab(0);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets, color: appBarTextColor, size: 24),
          const SizedBox(width: 8),
          Text(
            'PawsCare',
            style: TextStyle(
              color: appBarTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
    centerTitle: false,
    actions: [
      IconButton(
        icon: Icon(Icons.chat_bubble_outline, color: appBarTextColor),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat feature coming soon!')),
          );
        },
      ),
      IconButton(
        icon: Icon(Icons.notifications_none, color: appBarTextColor),
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
          return PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: appBarTextColor),
            onSelected: (value) {
              if (onMenuSelected != null) onMenuSelected(value);
              if (value == 'logout' && onLogout != null) onLogout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: const [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              if (isAdmin)
                PopupMenuItem(
                  value: 'all_applications',
                  child: Row(
                    children: const [
                      Icon(Icons.list_alt),
                      SizedBox(width: 8),
                      Text('All Applications'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'my_applications',
                child: Row(
                  children: const [
                    Icon(Icons.assignment),
                    SizedBox(width: 8),
                    Text('My Applications'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}
