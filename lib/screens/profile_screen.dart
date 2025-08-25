import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'post_animal_screen.dart';
import 'my_posted_animals_screen.dart';
import 'my_applications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 4;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile'), centerTitle: true),
        body: const Center(child: Text('Please log in to view your profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data?.data() as Map<String, dynamic>?;

          final fullName = data?['fullName']?.toString().trim() ?? '';
          final email = user.email ?? data?['email']?.toString() ?? '';
          final phone = data?['phoneNumber']?.toString() ?? '';
          final address = data?['address']?.toString() ?? '';
          final role = data?['role']?.toString() ?? 'user';
          final isActive = (data?['isActive'] as bool?) ?? true;
          final profileCompleted =
              (data?['profileCompleted'] as bool?) ?? false;
          final createdAt = data?['createdAt'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(
                  displayName: fullName.isNotEmpty
                      ? fullName
                      : (user.displayName ?? ''),
                  email: email,
                  role: role,
                  photoUrl: data?['photoUrl']?.toString() ?? '',
                  isUploading: _isUploading,
                  onChangePhoto: () => _pickAndUploadAvatar(user.uid),
                ),
                const SizedBox(height: 18),
                // User info
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Phone', value: phone),
                        _InfoRow(label: 'Address', value: address),
                        _InfoRow(
                          label: 'Account Active',
                          value: isActive ? 'Yes' : 'No',
                        ),
                        _InfoRow(
                          label: 'Profile Complete',
                          value: profileCompleted ? 'Yes' : 'No',
                        ),
                        _InfoRow(
                          label: 'Joined',
                          value: _formatTimestamp(createdAt),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                          onPressed: () => _showEditProfileSheet(
                            context: context,
                            uid: user.uid,
                            initialFullName: fullName,
                            initialPhone: phone,
                            initialAddress: address,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // User stats
                Row(
                  children: [
                    Expanded(
                      child: _UserStatTile(
                        label: 'Animals Posted',
                        icon: Icons.upload,
                        stream: FirebaseFirestore.instance
                            .collection('animals')
                            .where('postedBy', isEqualTo: user.uid)
                            .snapshots(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _UserStatTile(
                        label: 'Applications',
                        icon: Icons.history,
                        stream: FirebaseFirestore.instance
                            .collection('applications')
                            .where('userId', isEqualTo: user.uid)
                            .snapshots(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await AuthService.signOut();
                    if (!mounted) return;
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    try {
      if (ts is Timestamp) {
        final d = ts.toDate();
        return '${d.day}/${d.month}/${d.year}';
      }
      return ts?.toString() ?? '—';
    } catch (_) {
      return '—';
    }
  }

  Future<void> _showEditProfileSheet({
    required BuildContext context,
    required String uid,
    required String initialFullName,
    required String initialPhone,
    required String initialAddress,
  }) async {
    final fullNameController = TextEditingController(text: initialFullName);
    final phoneController = TextEditingController(text: initialPhone);
    final addressController = TextEditingController(text: initialAddress);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                keyboardType: TextInputType.streetAddress,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await UserService.updateUserProfile(
                      uid: uid,
                      data: {
                        'fullName': fullNameController.text.trim(),
                        'phoneNumber': phoneController.text.trim(),
                        'address': addressController.text.trim(),
                        'profileCompleted': true,
                      },
                    );
                    if (!mounted) return;
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e')),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(String uid) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() {
        _isUploading = true;
      });

      final file = File(picked.path);
      final storageRef = FirebaseStorage.instance.ref().child(
        'user_avatars/$uid.jpg',
      );
      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();

      await UserService.updateUserProfile(uid: uid, data: {'photoUrl': url});

      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String role;
  final String? photoUrl;
  final bool isUploading;
  final VoidCallback onChangePhoto;

  const _ProfileHeader({
    Key? key,
    required this.displayName,
    required this.email,
    required this.role,
    this.photoUrl,
    this.isUploading = false,
    required this.onChangePhoto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initials = _computeInitials(
      displayName.isNotEmpty ? displayName : email,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: const Color(0xFF5AC8F2),
              backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? NetworkImage(photoUrl!)
                  : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: InkWell(
                onTap: isUploading ? null : onChangePhoto,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: isUploading
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Color(0xFF5AC8F2),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName.isNotEmpty ? displayName : email,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: role == 'admin'
                      ? Colors.orange
                      : const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: role == 'admin'
                        ? Colors.orange
                        : const Color(0xFF00796B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _computeInitials(String text) {
    try {
      final parts = text.trim().split(RegExp(r"\s+"));
      if (parts.isEmpty) return '?';
      if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
      // Concatenate first letter of first and second word
      return (parts[0].isNotEmpty ? parts[0][0] : '') +
          (parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '');
    } catch (_) {
      return '?';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({Key? key, required this.label, required this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserStatTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Stream<QuerySnapshot> stream;

  const _UserStatTile({
    Key? key,
    required this.label,
    required this.icon,
    required this.stream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5AC8F2).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF5AC8F2), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
