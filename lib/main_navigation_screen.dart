import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:pawscare/screens/home_screen.dart';
import 'package:pawscare/screens/post_animal_screen.dart';
import 'package:pawscare/screens/profile_screen.dart';
import 'package:pawscare/screens/community_feed_screen.dart';
import 'package:pawscare/screens/animal_adoption_screen.dart';

const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);

final mainNavKey = GlobalKey<_MainNavigationScreenState>();

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  // Keep a stack of visited tab indices (most-recent-last). Home (0) is the base.
  final List<int> _navStack = [0];

  // Keep a persistent list of screens
  final List<Widget> _screens = [
    const HomeScreen(),
    const AnimalAdoptionScreen(),
    const PostAnimalScreen(),
    const CommunityFeedScreen(),
    const ProfileScreen(),
  ];

  // Optional: use a PageStorageBucket to preserve scroll positions
  final PageStorageBucket _bucket = PageStorageBucket();

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        // Maintain MRU order: remove if present and push to end
        _navStack.remove(index);
        _navStack.add(index);
      });
    }
  }

  void selectTab(int index) {
    // Public API: select a tab programmatically and update the stack similarly
    if (_selectedIndex != index) {
      _onItemTapped(index);
    } else {
      // If selecting the same tab, ensure it's the most recent in the stack
      _navStack.remove(index);
      _navStack.add(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If we have a history of tabs, pop back to the previous one.
        if (_navStack.length > 1) {
          setState(() {
            _navStack.removeLast();
            _selectedIndex = _navStack.last;
          });
          return false; // handled
        }

        // If stack is only one entry but it's not Home, navigate to Home instead of exiting
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
            _navStack.removeWhere((i) => i == 0);
            _navStack.add(0);
          });
          return false;
        }

        // Default: allow the system to handle the back button (exit app)
        return true;
      },
      child: Scaffold(
        // Use PageStorage to fully preserve scroll positions for each tab
        body: PageStorage(
          bucket: _bucket,
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
        // Remove default bottomNavigationBar
        bottomNavigationBar: null,
        // Use extendBody to allow content to go behind the floating nav bar
        extendBody: true,
        // Add custom floating navigation bar
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _buildFloatingNavBar(),
      ),
    );
  }

 Widget _buildFloatingNavBar() {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 8),
                blurRadius: 32,
              ),
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E).withOpacity(0.7),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(icon: Icons.home_rounded, index: 0, label: 'Home'),
                  _buildNavItem(icon: Icons.pets_rounded, index: 1, label: 'Adopt'),
                  _buildNavItem(
                    icon: Icons.add_circle_rounded,
                    index: 2,
                    label: 'Post',
                    isCenter: true,
                  ),
                  _buildNavItem(icon: Icons.groups_rounded, index: 3, label: 'Community'),
                  _buildNavItem(icon: Icons.person_rounded, index: 4, label: 'Account'),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}





  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String label,
    bool isCenter = false,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isCenter
                      ? kPrimaryAccentColor.withOpacity(0.15)
                      : Colors.white.withOpacity(0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isCenter ? 28 : 24,
                color: isSelected ? kPrimaryAccentColor : Colors.grey[400],
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kPrimaryAccentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
