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
  static const double _navBarHeight = 72; // keep in sync with padding you like

  int _selectedIndex = 0;
  final List<int> _navStack = [0];

  final List<Widget> _screens = const [
    HomeScreen(),
    AnimalAdoptionScreen(),
    PostAnimalScreen(),
    CommunityFeedScreen(),
    ProfileScreen(),
  ];

  final PageStorageBucket _bucket = PageStorageBucket();

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        // Keep navStack unique-ish: remove any existing occurrence and push to end.
        _navStack.remove(index);
        _navStack.add(index);
      });
    } else {
      // If the user taps the already-selected tab, normalize the stack so this
      // tab is the most recent entry (prevents weird back toggles).
      _navStack.remove(index);
      _navStack.add(index);
    }
  }

  // public method if you need to switch from elsewhere
  void selectTab(int index) {
    if (_selectedIndex != index) {
      _onItemTapped(index);
    } else {
      _navStack.remove(index);
      _navStack.add(index);
    }
  }

  /// Call this instead of ScaffoldMessenger.of(context).showSnackBar
  /// to ensure the SnackBar sits *above* the fixed nav bar.
  // void showAboveNavSnackBar(SnackBar snackBar) {
  //   final bottomMargin =
  //       _navBarHeight + 20; // nav height + same bottom padding you use
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     snackBar.copyWith(
  //       behavior: SnackBarBehavior.floating,
  //       margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
onWillPop: () async {
  // If there's cross-tab history and the last entry is NOT Home (0),
  // pop it and navigate to the previous tab.
  if (_navStack.length > 1 && _navStack.last != 0) {
    setState(() {
      _navStack.removeLast();
      _selectedIndex = _navStack.last;
    });
    return false;
  }

  // If we're not on Home, go to Home (normalize navStack) — don’t exit yet.
  if (_selectedIndex != 0) {
    setState(() {
      _selectedIndex = 0;
      _navStack
        ..removeWhere((i) => i == 0)
        ..add(0);
    });
    return false;
  }

  // If already on Home → confirm before exiting.
  final shouldExit = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Exit App?",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        "Do you really want to exit?",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel", style: TextStyle(color: Colors.amber)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Exit", style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );

  return shouldExit ?? false;
},

      
      child: Scaffold(
        // IMPORTANT: prevent body from being pushed up by keyboard
        resizeToAvoidBottomInset: false,
        extendBody: true, // lets content draw under our floating glass bar
        // no floatingActionButton or bottomNavigationBar anymore
        body: Stack(
          children: [
            // Content
            PageStorage(
              bucket: _bucket,
              child: IndexedStack(index: _selectedIndex, children: _screens),
            ),

            // Fixed nav overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildFloatingNavBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    // Remove any SafeArea here so it doesn't jump with insets.
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 34),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: _navBarHeight,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E).withOpacity(0.6),
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
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isCenter ? 28 : 25,
                color: isSelected ? kPrimaryAccentColor : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
