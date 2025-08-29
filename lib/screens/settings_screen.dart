import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/services/auth_service.dart';
import 'package:pawscare/services/user_service.dart'; // Corrected this line

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _fullNameController.text = data['fullName'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _addressController.text = data['address'] ?? '';
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
    };

    try {
      await UserService.updateUserProfile(uid: user.uid, data: data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
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
    setState(() {
      if (save) {
        _saveProfile();
      } else {
        _isEditing = !_isEditing;
        // If canceling, reload original data
        if (!_isEditing) {
          _loadUserData();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textTheme.titleLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: () => _toggleEditState(_isEditing),
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _fullNameController.text.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    final user = AuthService.getCurrentUser();
    final email = user?.email ?? 'No email available';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        children: [
          _buildSectionHeader('Account'),
          _buildInfoTile('Email', email, theme),
          _buildEditableTile(_fullNameController, 'Full Name', theme),
          _buildEditableTile(_phoneController, 'Phone Number', theme, keyboardType: TextInputType.phone),
          _buildEditableTile(_addressController, 'Address', theme, keyboardType: TextInputType.streetAddress),
          
          if (_isEditing)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
               child: TextButton(
                 onPressed: () => _toggleEditState(false),
                 child: const Text('Cancel', style: TextStyle(color: Colors.red)),
               ),
             ),
          
          const SizedBox(height: 20),
          _buildSectionHeader('Legal'),
          _buildNavigationTile('Terms of Service', () { /* TODO */ }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildNavigationTile('Privacy Policy', () { /* TODO */ }),
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: _logout,
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
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
        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildEditableTile(TextEditingController controller, String label, ThemeData theme, {TextInputType? keyboardType}) {
    return ListTile(
      title: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      subtitle: TextFormField(
        controller: controller,
        enabled: _isEditing,
        style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
        keyboardType: keyboardType,
        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
        validator: (value) => (value == null || value.isEmpty) ? 'This field cannot be empty' : null,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, ThemeData theme) {
    return ListTile(
      title: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      subtitle: Text(value, style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
    );
  }

  Widget _buildNavigationTile(String title, VoidCallback? onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: onTap != null ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
      onTap: onTap,
    );
  }
}
