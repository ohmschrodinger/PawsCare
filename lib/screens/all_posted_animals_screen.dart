import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'pet_detail_screen.dart';
import 'package:pawscare/constants/app_colors.dart';
import 'package:pawscare/services/animal_service.dart';

class AllPostedAnimalsScreen extends StatefulWidget {
  const AllPostedAnimalsScreen({super.key});

  @override
  State<AllPostedAnimalsScreen> createState() => _AllPostedAnimalsScreenState();
}

class _AllPostedAnimalsScreenState extends State<AllPostedAnimalsScreen> {
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDoc.data()?['role'] as String?;
      final isAdmin = role == 'admin' || role == 'superadmin';

      if (!isAdmin && mounted) {
        // User is not admin, navigate back
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Admin privileges required.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Stream<QuerySnapshot> _getAnimalsStream() {
    return FirebaseFirestore.instance
        .collection('animals')
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: kPrimaryAccentColor),
        ),
      );
    }

    if (!_isAdmin) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'All Posted Animals',
          style: TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getAnimalsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Something went wrong.',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryAccentColor),
            );
          }

          final animals = snapshot.data?.docs ?? [];

          if (animals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: 64,
                    color: kSecondaryTextColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No animals posted yet.",
                    style: TextStyle(fontSize: 18, color: kSecondaryTextColor),
                  ),
                ],
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
              final animalId = doc.id;
              final petData = {
                'id': animalId,
                ...data,
                'image': imageUrls.isNotEmpty ? imageUrls.first : null,
              };

              return _AnimalGridCard(
                pet: petData,
                onDelete: () => _refreshAfterDelete(),
              );
            },
          );
        },
      ),
    );
  }

  void _refreshAfterDelete() {
    // The stream will automatically update, but we can force a rebuild if needed
    setState(() {});
  }
}

class _AnimalGridCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final VoidCallback onDelete;

  const _AnimalGridCard({required this.pet, required this.onDelete});

  Future<void> _handleDelete(BuildContext context) async {
    final animalId = pet['id'] as String;

    // Check if animal can be deleted
    final checkResult = await AnimalService.canDeleteAnimal(animalId);
    final canDelete = checkResult['canDelete'] as bool;
    final reason = checkResult['reason'] as String;

    if (!context.mounted) return;

    if (!canDelete) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kCardColor,
          title: const Text(
            'Cannot Delete',
            style: TextStyle(color: kPrimaryTextColor),
          ),
          content: Text(
            reason,
            style: const TextStyle(color: kSecondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: kPrimaryAccentColor),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text(
          'Delete Animal Post',
          style: TextStyle(color: kPrimaryTextColor),
        ),
        content: const Text(
          'Are you sure you want to delete this animal post? This action cannot be undone.',
          style: TextStyle(color: kSecondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kSecondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: kPrimaryAccentColor),
      ),
    );

    try {
      await AnimalService.deleteAnimalPost(animalId);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Animal post deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Trigger refresh
      onDelete();
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kSecondaryTextColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Post',
                style: TextStyle(color: kPrimaryTextColor),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _handleDelete(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = pet['status'] as String? ?? '';
    final isAdopted = status == 'Adopted';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PetDetailScreen(petData: pet)),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: kCardColor,
        elevation: 2,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: pet['image'] != null
                      ? Image.network(
                          pet['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade900,
                                child: const Icon(
                                  Icons.pets,
                                  color: kSecondaryTextColor,
                                  size: 40,
                                ),
                              ),
                        )
                      : Container(
                          color: Colors.grey.shade900,
                          child: const Icon(
                            Icons.pets,
                            color: kSecondaryTextColor,
                            size: 40,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pet['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: kPrimaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdopted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Adopted',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pet['species'] ?? 'N/A'} • ${pet['age'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kSecondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Three-dot menu button at bottom right
            Positioned(
              right: 4,
              bottom: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showOptionsMenu(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
