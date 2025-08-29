import 'package:flutter/material.dart';
import 'package:pawscare/screens/home_wrapper.dart';
import 'package:pawscare/screens/my_applications_screen.dart';
import 'package:pawscare/screens/post_animal_screen.dart';
import 'package:pawscare/screens/my_posted_animals_screen.dart';
import 'package:pawscare/screens/profile_screen.dart';
import 'package:pawscare/screens/community_feed_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeWrapper(),
    MyApplicationsScreen(),
    PostAnimalScreen(),
    MyPostedAnimalsScreen(),
    CommunityFeedScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Post Animal'),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'My Posts'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF5AC8F2),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
