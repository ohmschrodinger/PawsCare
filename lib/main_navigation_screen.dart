import 'package:flutter/material.dart';
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
      });
    }
  }

  void selectTab(int index) {
    if (_selectedIndex != index) {
      _onItemTapped(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If not on Home tab, navigate to Home instead of exiting
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }

        // On Home tab: allow the system to handle back (exit app)
        return true;
      },
      child: Scaffold(
        // Use PageStorage to fully preserve scroll positions for each tab
        body: PageStorage(
          bucket: _bucket,
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
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
          backgroundColor: kCardColor,
          selectedItemColor: kPrimaryAccentColor,
          unselectedItemColor: kSecondaryTextColor,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
