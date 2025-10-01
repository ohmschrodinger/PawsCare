// main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:pawscare/screens/home_wrapper.dart';
import 'package:pawscare/screens/post_animal_screen.dart';
import 'package:pawscare/screens/profile_screen.dart';
import 'package:pawscare/screens/community_feed_screen.dart';
import 'package:pawscare/screens/animal_adoption_screen.dart';

// --- Re-using the color palette for consistency ---
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -------------------------------------------------

final mainNavKey = GlobalKey<_MainNavigationScreenState>();

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeWrapper(),
    const AnimalAdoptionScreen(),
    const PostAnimalScreen(),
    const CommunityFeedScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void selectTab(int index) {
    // Check if the widget is still in the tree to prevent errors
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Adopt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        // --- UI Updates ---
        backgroundColor: kCardColor, // Dark background for the nav bar
        selectedItemColor: kPrimaryAccentColor, // Yellow for the active item
        unselectedItemColor: kSecondaryTextColor, // Grey for inactive items
        type: BottomNavigationBarType.fixed,
        // --- 👇 THESE ARE THE CHANGES ---
        showSelectedLabels: false,   // Hides label for the selected item
        showUnselectedLabels: false, // Hides labels for unselected items
        // -----------------------------
        elevation: 0, // Flat design to match the AppBar
        onTap: _onItemTapped,
      ),
    );
  }
}