import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawscare/screens/home_screen.dart';
import 'package:pawscare/widgets/paws_care_app_bar.dart';
import '../../main_navigation_screen.dart';

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
        appBar: buildPawsCareAppBar(
          context: context,
          onLogout: () {
            FirebaseAuth.instance.signOut();
            Navigator.of(context).pushReplacementNamed('/login');
          },
          onMenuSelected: (value) {
            if (value == 'profile') {
              if (mainNavKey.currentState != null) {
                mainNavKey.currentState!.selectTab(4);
              } else {
                Navigator.of(context).pushNamed('/main');
              }
            } else if (value == 'all_applications') {
              Navigator.of(context).pushNamed('/all-applications');
            } else if (value == 'my_applications') {
              Navigator.of(context).pushNamed('/my-applications');
            }
          },
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
