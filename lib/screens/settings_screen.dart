import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/screens/my_applications_screen.dart';
import 'package:pawscare/screens/saved_posts_screen.dart';
import 'package:pawscare/services/auth_service.dart';
import 'package:pawscare/services/user_service.dart';
import 'package:pawscare/screens/terms_and_service.dart';
import 'package:pawscare/screens/private_policy.dart'; // <-- Import added
import 'package:pawscare/screens/my_posted_animals_screen.dart';

// --- Re-using the color palette for consistency ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -------------------------------------------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isEditing = false;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _pushNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = AuthService.getCurrentUser();
    if (user == null) {
      if (mounted) {
        setState(() {
          _errorMessage = "User not found.";
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _fullNameController.text = data['fullName'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _addressController.text = data['address'] ?? '';
        if (mounted) {
          setState(() {
            _pushNotificationsEnabled =
                data['pushNotificationsEnabled'] ?? true;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Failed to load data.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final user = AuthService.getCurrentUser()!;
    final data = {
      'fullName': _fullNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'pushNotificationsEnabled': _pushNotificationsEnabled,
    };

    try {
      await UserService.updateUserProfile(uid: user.uid, data: data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: Colors.green.shade800,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _toggleEditState(bool save) {
    if (save) {
      _saveProfile();
    } else {
      setState(() {
        _isEditing = !_isEditing;
        if (!_isEditing) {
          _loadUserData(); // Revert changes if canceling
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: kPrimaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: () => _toggleEditState(_isEditing),
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: const TextStyle(
                  color: kPrimaryAccentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _fullNameController.text.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryAccentColor),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    final user = AuthService.getCurrentUser();
    final email = user?.email ?? 'No email available';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        children: [
          _buildSectionHeader('Account'),
          _buildInfoTile('Email', email),
          _buildEditableTile(_fullNameController, 'Full Name'),
          _buildEditableTile(
            _phoneController,
            'Phone Number',
            keyboardType: TextInputType.phone,
          ),
          _buildEditableTile(
            _addressController,
            'Address',
            keyboardType: TextInputType.streetAddress,
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: TextButton(
                onPressed: () => _toggleEditState(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          const SizedBox(height: 20),
          _buildSectionHeader('My Activity'),
          _buildNavigationTile('My Posted Animals', Icons.article_outlined, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyPostedAnimalsScreen()),
            );
          }),
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: kCardColor,
          ),
          _buildNavigationTile(
            'My Applications',
            Icons.playlist_add_check_outlined,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
              );
            },
          ),
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: kCardColor,
          ),
          _buildNavigationTile(
            'Saved Posts',
            Icons.bookmark_border,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
              );
            },
          ),
          
          const SizedBox(height: 20),
          _buildSectionHeader('Preferences'),
          _buildSwitchTile(
            'Push Notifications',
            Icons.notifications_outlined,
            _pushNotificationsEnabled,
            (value) {
              setState(() => _pushNotificationsEnabled = value);
              _saveProfile();
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Legal'),
          _buildNavigationTile('Terms of Service', null, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsAndServiceScreen()),
            );
          }),
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: kCardColor,
          ),
          _buildNavigationTile('Privacy Policy', null, () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const PrivatePolicyScreen(), // <-- Navigation fixed
              ),
            );
          }),
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: _logout,
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: kSecondaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEditableTile(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kSecondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: controller,
            enabled: _isEditing,
            style: TextStyle(
              fontSize: 16,
              color: _isEditing ? kPrimaryTextColor : kSecondaryTextColor,
            ),
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: kCardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade800),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                  color: kPrimaryAccentColor,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              errorStyle: const TextStyle(color: Colors.redAccent),
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? 'This field cannot be empty'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kSecondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: kSecondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    IconData? icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: kSecondaryTextColor) : null,
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: kPrimaryTextColor),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: kSecondaryTextColor)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon, color: kSecondaryTextColor),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: kPrimaryTextColor),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: kPrimaryAccentColor,
      inactiveTrackColor: Colors.grey.shade800,
    );
  }
}
