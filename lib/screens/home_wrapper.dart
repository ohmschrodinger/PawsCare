import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawscare/screens/home_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appBarColor = isDarkMode
        ? theme.scaffoldBackgroundColor
        : Colors.grey.shade50;
    final appBarTextColor = theme.textTheme.titleLarge?.color;

    return WillPopScope(
      onWillPop: () async {
        if (_navigatorKey.currentState?.canPop() ?? false) {
          _navigatorKey.currentState?.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: isDarkMode
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          backgroundColor: appBarColor,
          elevation: 0,
          title: Text(
            'PawsCare',
            style: TextStyle(
              color: appBarTextColor,
              fontWeight: FontWeight.bold,
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
            PopupMenuButton<String>(
              icon: Icon(Icons.account_circle, color: appBarTextColor),
              onSelected: (value) {
                if (value == 'logout') {
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Navigator(
          key: _navigatorKey,
          initialRoute: '/',
          onGenerateRoute: (RouteSettings settings) {
            WidgetBuilder builder;
            switch (settings.name) {
              case '/':
                builder = (BuildContext context) =>
                    const HomeScreen(showAppBar: false);
                break;
              default:
                throw Exception('Invalid route: ${settings.name}');
            }
            return MaterialPageRoute(builder: builder, settings: settings);
          },
        ),
      ),
    );
  }
}
