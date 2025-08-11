import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    // Show confirmation dialog
    bool shouldSignOut = await _showSignOutDialog();
    if (!shouldSignOut) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
      // The AuthWrapper will automatically redirect to login page
    } catch (e) {
      _showSnackBar('Error signing out. Please try again.');
      setState(() {
        _isSigningOut = false;
      });
    }
  }

  Future<bool> _showSignOutDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        user?.email ?? 'User',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              
              // Welcome Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Welcome to the App!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You have successfully signed in and verified your email address.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              
              // Account Information Section
              Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              
              // User Details Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user?.email ?? 'Not available',
                      ),
                      Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.verified_user,
                        label: 'Email Verified',
                        value: user?.emailVerified == true ? 'Yes' : 'No',
                        valueColor: user?.emailVerified == true ? Colors.green : Colors.red,
                      ),
                      Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.access_time,
                        label: 'Account Created',
                        value: user?.metadata.creationTime != null
                            ? _formatDate(user!.metadata.creationTime!)
                            : 'Not available',
                      ),
                      Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.login,
                        label: 'Last Sign In',
                        value: user?.metadata.lastSignInTime != null
                            ? _formatDate(user!.metadata.lastSignInTime!)
                            : 'Not available',
                      ),
                    ],
                  ),
                ),
              ),
              
              Spacer(),
              
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSigningOut ? null : _signOut,
                  icon: _isSigningOut
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.logout),
                  label: Text(
                    _isSigningOut ? 'Signing Out...' : 'Sign Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}