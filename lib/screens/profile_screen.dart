import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'settings_screen.dart';
import '../services/user_favorites_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'pet_detail_screen.dart';
import 'package:pawscare/constants/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();

    if (user == null) {
      // --- MODIFICATION: Applying glassmorphic background to logged-out view ---
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Account',
            style: TextStyle(color: kPrimaryTextColor),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/app_wallpaper_blurred.png',
                fit: BoxFit.cover,
              ),
            ),
            const Center(
              child: Text(
                'Please log in to view your account.',
                style: TextStyle(color: kSecondaryTextColor),
              ),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // --- CHANGE 1: Set background to transparent and extend body ---
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context, user),
        // --- CHANGE 2: Use a Stack for the layered background ---
        body: Stack(
          children: [
            // --- LAYER 1: The background image ---
            Positioned.fill(
              child: Image.asset(
                'assets/images/app_wallpaper_blurred.png',
                fit: BoxFit.cover,
              ),
            ),
            // --- LAYER 3: Your original screen content inside a SafeArea ---
            SafeArea(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: kPrimaryAccentColor,
                      ),
                    );
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
                      const TabBar(
                        labelColor: Colors.amber,
                        unselectedLabelColor: kSecondaryTextColor,
                        indicatorColor: Colors.amber,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'My Posts'),
                          Tab(text: 'Liked'),
                          Tab(text: 'Saved'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _AnimalGridView(
                              stream: _getMyPostsStream(user.uid),
                              emptyMessage:
                                  "You haven't posted any animals yet.",
                            ),
                            _AnimalGridView(
                              stream: _getLikedAnimalsStream(user.uid),
                              emptyMessage:
                                  "You haven't liked any animals yet.",
                            ),
                            _AnimalGridView(
                              stream: _getSavedAnimalsStream(user.uid),
                              emptyMessage:
                                  "You haven't saved any animals yet.",
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CHANGE 3: Make AppBar transparent ---
  AppBar _buildAppBar(BuildContext context, User user) {
    return AppBar(
      backgroundColor: Colors.transparent, // Set to transparent
      elevation: 0,
      title: const Text(
        'Account',
        style: TextStyle(color: kPrimaryTextColor, fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: kPrimaryTextColor),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getMyPostsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('animals')
        .where('postedBy', isEqualTo: uid)
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots();
  }

  Stream<QuerySnapshot> _getLikedAnimalsStream(String uid) {
    return UserFavoritesService.getLikedAnimalDetails();
  }

  Stream<QuerySnapshot> _getSavedAnimalsStream(String uid) {
    return UserFavoritesService.getSavedAnimalDetails();
  }

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
      final storageRef = FirebaseStorage.instance.ref().child(
        'user_avatars/$uid.jpg',
      );
      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();
      await UserService.updateUserProfile(uid: uid, data: {'photoUrl': url});
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
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

    darkInputDecoration(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kSecondaryTextColor),
      filled: true,
      fillColor: Colors.black.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: kPrimaryAccentColor, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E).withOpacity(0.75),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: fullNameController,
                      style: const TextStyle(color: kPrimaryTextColor),
                      decoration: darkInputDecoration('Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      style: const TextStyle(color: kPrimaryTextColor),
                      decoration: darkInputDecoration('Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      style: const TextStyle(color: kPrimaryTextColor),
                      decoration: darkInputDecoration('Address'),
                      keyboardType: TextInputType.streetAddress,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                        child: InkWell(
                          onTap: () async {
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
                                const SnackBar(
                                  content: Text('Profile updated'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update: $e')),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: kPrimaryAccentColor.withOpacity(
                                0.65,
                              ), // Translucent yellow
                              borderRadius: BorderRadius.circular(60.0),
                            ),
                            child: const Center(
                              child: Text(
                                'Save Changes',
                                style: TextStyle(
                                  color:
                                      kPrimaryTextColor, // White text for better contrast
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isUploading;
  final VoidCallback onChangePhoto;
  final VoidCallback onEditProfile;

  const _ProfileHeader({
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isUploading = false,
    required this.onChangePhoto,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: kPrimaryAccentColor.withOpacity(0.2),
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? Text(
                        _computeInitials(displayName),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryAccentColor,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: kCardColor,
                    shape: const CircleBorder(
                      side: BorderSide(color: kBackgroundColor, width: 2),
                    ),
                    elevation: 2,
                  ),
                  onPressed: isUploading ? null : onChangePhoto,
                  icon: isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kPrimaryAccentColor,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.grey,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kPrimaryTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(fontSize: 16, color: kSecondaryTextColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onEditProfile,
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimaryTextColor,
              side: const BorderSide(color: kSecondaryTextColor),
            ),
            child: const Text('Edit Profile'),
          ),
        ],
      ),
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

  const _AnimalGridView({required this.stream, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryAccentColor),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Could not load animals.',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }
        final animals = snapshot.data?.docs ?? [];
        if (animals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  color: kSecondaryTextColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
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

  const _AnimalGridCard({required this.pet});

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
        elevation: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            pet['image'] != null
                ? Image.network(
                    pet['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Icon(
                        Icons.pets,
                        color: kSecondaryTextColor,
                        size: 40,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Icon(
                      Icons.pets,
                      color: kSecondaryTextColor,
                      size: 40,
                    ),
                  ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pet['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kPrimaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pet['species'] ?? 'N/A'} • ${pet['age'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kPrimaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
