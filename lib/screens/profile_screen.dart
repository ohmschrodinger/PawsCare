import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'settings_screen.dart'; // Add this import

// --- Assuming these services and screens exist in your project ---
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'pet_detail_screen.dart'; // Needed for navigation

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) {
      // Navigate to login screen after logout
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();

    // Handle user not logged in
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: const Center(
          child: Text('Please log in to view your account.'),
        ),
      );
    }

    // Main UI for logged-in user
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: _buildAppBar(context, user),
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
            final photoUrl = data?['photoUrl']?.toString();

            return Column(
              children: [
                const SizedBox(height: 20),
                _ProfileHeader(
                  displayName: fullName.isNotEmpty ? fullName : email,
                  email: email,
                  photoUrl: photoUrl,
                  isUploading: _isUploading,
                  onChangePhoto: () => _pickAndUploadAvatar(user.uid),
                  onEditProfile: () => _showEditProfileSheet(
                    context: context,
                    uid: user.uid,
                    initialFullName: fullName,
                    initialPhone: phone,
                    initialAddress: address,
                  ),
                ),
                const SizedBox(height: 20),
                TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: 'My Posts'),
                    Tab(text: 'Liked'),
                    Tab(text: 'Saved'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // My Posts Tab
                      _AnimalGridView(
                        stream: _getMyPostsStream(user.uid),
                        emptyMessage: "You haven't posted any animals yet.",
                      ),
                      // Liked Tab (Placeholder)
                      _AnimalGridView(
                        stream: _getLikedAnimalsStream(user.uid),
                        emptyMessage: "You haven't liked any animals yet.",
                      ),
                      // Saved Tab (Placeholder)
                      _AnimalGridView(
                        stream: _getSavedAnimalsStream(user.uid),
                        emptyMessage: "You haven't saved any animals yet.",
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Build a consistent AppBar
  AppBar _buildAppBar(BuildContext context, User user) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appBarTextColor = theme.textTheme.titleLarge?.color;

    return AppBar(
      backgroundColor: isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
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
          // ... inside _buildAppBar method
          IconButton(
            icon: Icon(Icons.settings_outlined, color: appBarTextColor),
            onPressed: () {
              // Navigate to the new SettingsScreen
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: appBarTextColor),
          onSelected: (value) {
            if (value == 'logout') _logout();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Data Streams for Tabs ---
  Stream<QuerySnapshot> _getMyPostsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('animals')
        .where('postedBy', isEqualTo: uid)
        .snapshots();
  }

  // Placeholder: Shows all approved animals. Update logic when feature is built.
  Stream<QuerySnapshot> _getLikedAnimalsStream(String uid) {
    // TODO: Replace with actual logic for liked animals
    return FirebaseFirestore.instance
        .collection('animals')
        .where('approvalStatus', isEqualTo: 'approved')
        .limit(10) // Limit for placeholder
        .snapshots();
  }

  // Placeholder: Shows all approved animals. Update logic when feature is built.
  Stream<QuerySnapshot> _getSavedAnimalsStream(String uid) {
    // TODO: Replace with actual logic for saved animals
    return FirebaseFirestore.instance
        .collection('animals')
        .where('approvalStatus', isEqualTo: 'approved')
        .limit(10) // Limit for placeholder
        .snapshots();
  }

  // --- Methods for profile actions (unchanged logic) ---
  Future<void> _pickAndUploadAvatar(String uid) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _isUploading = true);

      final file = File(picked.path);
      final storageRef =
          FirebaseStorage.instance.ref().child('user_avatars/$uid.jpg');
      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();

      await UserService.updateUserProfile(uid: uid, data: {'photoUrl': url});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
}

// --- New and Refactored Widgets ---

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isUploading;
  final VoidCallback onChangePhoto;
  final VoidCallback onEditProfile;

  const _ProfileHeader({
    Key? key,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isUploading = false,
    required this.onChangePhoto,
    required this.onEditProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? NetworkImage(photoUrl!)
                  : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? Text(
                      _computeInitials(displayName),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                ),
                onPressed: isUploading ? null : onChangePhoto,
                icon: isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _computeInitials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.first.substring(0, 1).toUpperCase();
  }
}

class _AnimalGridView extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String emptyMessage;

  const _AnimalGridView({
    Key? key,
    required this.stream,
    required this.emptyMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load animals.'));
        }
        final animals = snapshot.data?.docs ?? [];
        if (animals.isEmpty) {
          return Center(
            child: Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: animals.length,
          itemBuilder: (context, index) {
            final doc = animals[index];
            final data = doc.data() as Map<String, dynamic>;
            final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];
            final petData = {
              'id': doc.id,
              ...data,
              'image': imageUrls.isNotEmpty ? imageUrls.first : null,
            };

            return _AnimalGridCard(pet: petData);
          },
        );
      },
    );
  }
}

class _AnimalGridCard extends StatelessWidget {
  final Map<String, dynamic> pet;

  const _AnimalGridCard({Key? key, required this.pet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailScreen(petData: pet),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: pet['image'] != null
                  ? Image.network(
                      pet['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.pets, color: Colors.grey, size: 40),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.pets, color: Colors.grey, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pet['species'] ?? 'N/A'} • ${pet['age'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

