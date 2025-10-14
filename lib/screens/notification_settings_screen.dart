import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/paws_care_app_bar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _adoptionNotifications = true;
  bool _newAnimalNotifications = true;
  bool _generalNotifications = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        setState(() {
          _adoptionNotifications = userData?['adoptionNotifications'] ?? true;
          _newAnimalNotifications = userData?['newAnimalNotifications'] ?? true;
          _generalNotifications = userData?['generalNotifications'] ?? true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationSetting(String setting, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        setting: value,
        'notificationsEnabled': _adoptionNotifications || _newAnimalNotifications || _generalNotifications,
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification settings updated'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error updating notification setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PawsCareAppBar(
        title: 'Notification Settings',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage your notification preferences',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Adoption Notifications
                  _buildNotificationCard(
                    title: 'Adoption Updates',
                    subtitle: 'Get notified when your adoption applications are approved or rejected',
                    icon: Icons.pets,
                    value: _adoptionNotifications,
                    onChanged: (value) {
                      setState(() {
                        _adoptionNotifications = value;
                      });
                      _updateNotificationSetting('adoptionNotifications', value);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // New Animal Notifications
                  _buildNotificationCard(
                    title: 'New Animals',
                    subtitle: 'Get notified when new animals are added to the platform',
                    icon: Icons.add_circle_outline,
                    value: _newAnimalNotifications,
                    onChanged: (value) {
                      setState(() {
                        _newAnimalNotifications = value;
                      });
                      _updateNotificationSetting('newAnimalNotifications', value);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // General Notifications
                  _buildNotificationCard(
                    title: 'General Updates',
                    subtitle: 'Receive general updates about the platform and your account',
                    icon: Icons.notifications,
                    value: _generalNotifications,
                    onChanged: (value) {
                      setState(() {
                        _generalNotifications = value;
                      });
                      _updateNotificationSetting('generalNotifications', value);
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Information Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'About Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can change these settings at any time. Notifications help you stay updated about your adoption applications and new animals available for adoption.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5AC8F2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5AC8F2),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5AC8F2),
          ),
        ],
      ),
    );
  }
}
