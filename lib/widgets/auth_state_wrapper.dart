import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/navigation_guard.dart';

/// Authentication State Wrapper
/// Listens to authentication state changes and enforces navigation guards
class AuthStateWrapper extends StatefulWidget {
  final Widget child;

  const AuthStateWrapper({super.key, required this.child});

  @override
  State<AuthStateWrapper> createState() => _AuthStateWrapperState();
}

class _AuthStateWrapperState extends State<AuthStateWrapper> {
  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    AuthService.authStateChanges.listen((user) async {
      if (!mounted) return;

      // Get current route
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute == null) return;

      // Skip splash screen
      if (currentRoute == '/') return;

      // Check if current route is still valid
      final redirectRoute = await NavigationGuard.checkAccessAndGetRedirect(
        requestedRoute: currentRoute,
      );

      if (redirectRoute != null && mounted) {
        // Need to redirect
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Route Guard Wrapper
/// Wraps each route to check access before displaying
class RouteGuard extends StatefulWidget {
  final Widget child;
  final String routeName;

  const RouteGuard({super.key, required this.child, required this.routeName});

  @override
  State<RouteGuard> createState() => _RouteGuardState();
}

class _RouteGuardState extends State<RouteGuard> {
  bool _isChecking = true;
  String? _redirectRoute;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final redirectRoute = await NavigationGuard.checkAccessAndGetRedirect(
      requestedRoute: widget.routeName,
    );

    if (mounted) {
      setState(() {
        _redirectRoute = redirectRoute;
        _isChecking = false;
      });

      // Redirect if needed
      if (redirectRoute != null) {
        Future.microtask(() {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(redirectRoute);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Show loading while checking
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_redirectRoute != null) {
      // Will redirect, show loading
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Access granted
    return widget.child;
  }
}
