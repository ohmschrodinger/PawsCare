import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawscare/screens/my_applications_screen.dart';
import 'package:pawscare/screens/saved_posts_screen.dart';
import 'package:pawscare/services/auth_service.dart';
import 'package:pawscare/services/user_service.dart';
import 'package:pawscare/screens/terms_and_service.dart';
import 'package:pawscare/screens/private_policy.dart';
import 'package:pawscare/screens/my_posted_animals_screen.dart';
import 'package:pawscare/screens/all_posted_animals_screen.dart';
import 'package:pawscare/screens/contact_us_screen.dart';
import 'package:pawscare/screens/about_developers_screen.dart';
import 'package:pawscare/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isAdmin = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
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
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _addressController.text = data['address'] ?? '';

        // Check if user is admin
        final role = data['role'] as String?;
        _isAdmin = role == 'admin' || role == 'superadmin';
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
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
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
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/entry-point', (route) => false);
    }
  }

 Future<void> _showDeleteAccountDialog() async {
    final TextEditingController confirmController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: kCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // More modern rounded corners
            side: BorderSide(color: Colors.grey.shade800, width: 1), // Subtle border definition
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Delete Account',
                style: TextStyle(
                  color: kPrimaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. IMPROVED WARNING SECTION
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This action cannot be undone.',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You will permanently lose:',
                        style: TextStyle(color: kSecondaryTextColor, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint('Profile & personal info'),
                      _buildBulletPoint('Posted animals & applications'),
                      _buildBulletPoint('Saved posts & favorites'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // 2. INPUT INSTRUCTION
                const Center(
                  child: Text(
                    'Type "delete" to confirm:',
                    style: TextStyle(
                      color: kPrimaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // 3. IMPROVED INPUT FIELD
                TextField(
                  controller: confirmController,
                  style: const TextStyle(
                    color: kPrimaryTextColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center, // Focuses attention
                  decoration: InputDecoration(
                    hintText: 'delete',
                    hintStyle: TextStyle(color: kSecondaryTextColor.withOpacity(0.4)),
                    filled: true,
                    fillColor: kBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: kSecondaryTextColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: kSecondaryTextColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            // 4. BALANCED BUTTONS
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      confirmController.dispose();
                      Navigator.of(dialogContext).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: kSecondaryTextColor, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (confirmController.text.toLowerCase() == 'delete') {
                        Navigator.of(dialogContext).pop();
                        confirmController.dispose();
                        await _deleteAccount();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please type "delete" to confirm'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Delete', 
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Add this helper widget method inside your class
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: kSecondaryTextColor, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: kSecondaryTextColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteAccount() async {
    try {
      setState(() => _isLoading = true);

      final user = AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryAccentColor),
            );
          },
        );
      }

      // Store the UID before deletion
      final String uid = user.uid;

      // Delete the Firebase Auth account FIRST
      // This is critical: if auth deletion fails, we don't delete Firestore data
      await AuthService.deleteAccount();

      // Only delete Firestore data if auth deletion succeeded
      await UserService.deleteUserData(uid);

      // Close loading dialog and navigate to entry point
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/entry-point', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        String errorMessage = 'Failed to delete account';

        if (e.code == 'requires-recent-login') {
          errorMessage =
              'Please log out and log back in before deleting your account for security reasons.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  color: Color.fromARGB(255, 255, 255, 255),
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
    if (_isLoading && _firstNameController.text.isEmpty) {
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
          _buildEditableTile(_firstNameController, 'First Name'),
          _buildEditableTile(_lastNameController, 'Last Name'),
          _buildInfoTile('Phone Number', _phoneController.text),
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
          _buildNavigationTile('Saved Posts', Icons.bookmark_border, () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SavedPostsScreen()));
          }),

          // Admin Section - Only visible to admins
          if (_isAdmin) ...[
            const SizedBox(height: 20),
            _buildSectionHeader('Admin'),
            _buildNavigationTile('All Posted Animals', Icons.pets_outlined, () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AllPostedAnimalsScreen(),
                ),
              );
            }),
          ],

          const SizedBox(height: 20),
          _buildSectionHeader('Support'),
          _buildNavigationTile('Contact Us', Icons.contact_support, () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ContactUsScreen()));
          }),
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
          const SizedBox(height: 20),
          _buildSectionHeader('Developers'),
          _buildNavigationTile('About Developers', Icons.code, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutDevelopersScreen()),
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
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _showDeleteAccountDialog,
              child: const Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
}
