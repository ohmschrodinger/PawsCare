import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/animal_service.dart';
import '../services/storage_service.dart';

class PostAnimalScreen extends StatefulWidget {
  final int initialTab;
  const PostAnimalScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<PostAnimalScreen> createState() => _PostAnimalScreenState();
}

class _PostAnimalScreenState extends State<PostAnimalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _sterilizationController = TextEditingController();
  final _vaccinationController = TextEditingController();
  final _rescueStoryController = TextEditingController();
  final _motherStatusController = TextEditingController();

  // Form state
  String _selectedGender = 'Male';
  String _selectedSterilization = 'Yes';
  String _selectedVaccination = 'Yes';
  String _selectedMotherStatus = 'Unknown';
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _speciesController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _sterilizationController.dispose();
    _vaccinationController.dispose();
    _rescueStoryController.dispose();
    _motherStatusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 4) return;
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _images.add(pickedFile);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Management'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5AC8F2),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending Requests'),
            Tab(icon: Icon(Icons.add_circle), text: 'Add New Animal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPendingRequestsTab(), _buildAddNewAnimalTab()],
      ),
    );
  }

Widget _buildPendingRequestsTab() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Center(
      child: Text('Please log in to view pending requests'),
    );
  }
  return StreamBuilder<QuerySnapshot>(
    stream: AnimalService.getPendingAnimals(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, roleSnapshot) {
          String role = 'user';
          if (roleSnapshot.connectionState == ConnectionState.done &&
              roleSnapshot.hasData) {
            role = roleSnapshot.data?.data() != null
                ? (roleSnapshot.data!.get('role') ?? 'user')
                : 'user';
          }

          final allAnimals = snapshot.data?.docs ?? [];
          List<DocumentSnapshot> animals;
          if (role == 'admin') {
            animals = allAnimals;
          } else {
            animals = allAnimals.where((doc) =>
              (doc.data() as Map<String, dynamic>)['postedByEmail'] == user.email
            ).toList();
          }

          return animals.isEmpty
    ? Center(
        child: Text(
          'No pending requests for now',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
    : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: animals.length,
        itemBuilder: (context, index) {
          final animalData =
              animals[index].data() as Map<String, dynamic>;
          final animalId = animals[index].id;
          final postedByEmail = animalData['postedByEmail'] ?? 'Unknown';
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animalData['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5AC8F2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${animalData['species'] ?? ''} • ${animalData['age'] ?? ''} • ${animalData['gender'] ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posted by: $postedByEmail',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posted on: ${_formatDate(animalData['postedAt'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          'Sterilization: ${animalData['sterilization'] ?? 'N/A'}',
                          Icons.medical_services,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          'Vaccination: ${animalData['vaccination'] ?? 'N/A'}',
                          Icons.vaccines,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (role == 'admin')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _showApproveDialog(context, animalId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Approve',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _showRejectDialog(context, animalId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      );
      },
      );
    },
  );
}


  Widget _buildAddNewAnimalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5AC8F2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5AC8F2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.pets, size: 48, color: const Color(0xFF5AC8F2)),
                  const SizedBox(height: 8),
                  Text(
                    'Add New Animal for Adoption',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5AC8F2),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill out the form below to post a new animal. Admin posts are approved immediately.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Animal Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Animal Name *',
                prefixIcon: Icon(Icons.pets),
                hintText: 'Enter the animal\'s name...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the animal\'s name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Species
            TextFormField(
              controller: _speciesController,
              decoration: const InputDecoration(
                labelText: 'Species *',
                prefixIcon: Icon(Icons.category),
                hintText: 'e.g., Dog, Cat, Bird, Rabbit...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the species';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Age
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age *',
                prefixIcon: Icon(Icons.calendar_today),
                hintText: 'e.g., 2 years, 6 months, Puppy...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the age';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender *',
                prefixIcon: Icon(Icons.wc),
                border: OutlineInputBorder(),
              ),
              items: ['Male', 'Female'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select gender';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Sterilization Status
            DropdownButtonFormField<String>(
              value: _selectedSterilization,
              decoration: const InputDecoration(
                labelText: 'Sterilization Status *',
                prefixIcon: Icon(Icons.medical_services),
                border: OutlineInputBorder(),
              ),
              items: ['Yes', 'No', 'Unknown'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSterilization = newValue!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select sterilization status';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Vaccination Status
            DropdownButtonFormField<String>(
              value: _selectedVaccination,
              decoration: const InputDecoration(
                labelText: 'Vaccination Status *',
                prefixIcon: Icon(Icons.vaccines),
                border: OutlineInputBorder(),
              ),
              items: ['Yes', 'No', 'Unknown'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedVaccination = newValue!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select vaccination status';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Mother Status
            DropdownButtonFormField<String>(
              value: _selectedMotherStatus,
              decoration: const InputDecoration(
                labelText: 'Mother Status *',
                prefixIcon: Icon(Icons.family_restroom),
                border: OutlineInputBorder(),
              ),
              items: ['With Mother', 'Without Mother', 'Unknown'].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMotherStatus = newValue!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select mother status';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Rescue Story
            TextFormField(
              controller: _rescueStoryController,
              decoration: const InputDecoration(
                labelText: 'Rescue Story *',
                prefixIcon: Icon(Icons.menu_book), // book icon
                hintText:
                    'Tell us about how this animal was found or their background...',
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the rescue story';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Photo Upload Section
            Text(
              'Upload Animal Photos (1-4, mandatory)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _images.length < 4
                      ? () => _pickImage(ImageSource.gallery)
                      : null,
                  icon: Icon(Icons.photo_library),
                  label: Text('Gallery'),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _images.length < 4
                      ? () => _pickImage(ImageSource.camera)
                      : null,
                  icon: Icon(Icons.camera_alt),
                  label: Text('Camera'),
                ),
              ],
            ),
            SizedBox(height: 8),
            _images.isEmpty
                ? Text(
                    'No images selected.',
                    style: TextStyle(color: Colors.red),
                  )
                : SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8),
                      itemBuilder: (context, index) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_images[index].path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            SizedBox(height: 16),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5AC8F2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Posting Animal...'),
                      ],
                    )
                  : const Text(
                      'Post Animal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one photo of the animal.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Create a new animal document to get its ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null)
        throw Exception('User must be logged in to post an animal');
      final animalDoc = await FirebaseFirestore.instance
          .collection('animals')
          .add({
            'name': _nameController.text.trim(),
            'species': _speciesController.text.trim(),
            'age': _ageController.text.trim(),
            'status': 'Available for Adoption',
            'gender': _selectedGender,
            'sterilization': _selectedSterilization,
            'vaccination': _selectedVaccination,
            'rescueStory': _rescueStoryController.text.trim(),
            'motherStatus': _selectedMotherStatus,
            'postedBy': user.uid,
            'postedByEmail': user.email,
            'postedAt': FieldValue.serverTimestamp(),
            'isActive': false, // will be updated after approval
            'approvalStatus': 'pending',
            'adminMessage': '',
            'imageUrls': [], // placeholder
          });
      final animalId = animalDoc.id;

      // 2. Upload images and get URLs
      List<String> imageUrls = [];
      for (int i = 0; i < _images.length; i++) {
        final url = await StorageService.uploadAnimalImage(
          File(_images[i].path),
          animalId,
          i,
        );
        imageUrls.add(url);
      }

      // 3. Update animal document with image URLs
      await animalDoc.update({
        'imageUrls': imageUrls,
        'image': imageUrls.isNotEmpty ? imageUrls[0] : null,
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Animal posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _nameController.clear();
        _speciesController.clear();
        _ageController.clear();
        _rescueStoryController.clear();
        setState(() {
          _selectedGender = 'Male';
          _selectedSterilization = 'Yes';
          _selectedVaccination = 'Yes';
          _selectedMotherStatus = 'Unknown';
          _images.clear();
        });
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting animal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showApproveDialog(BuildContext context, String animalId) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Animal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This animal will be visible to all users.'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Optional Message (for user)',
                hintText: 'e.g., Great job! This animal looks healthy.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await AnimalService.approveAnimal(
                  animalId: animalId,
                  adminMessage: messageController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Animal approved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error approving animal: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String animalId) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Animal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This animal will not be visible to users.'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection *',
                hintText:
                    'e.g., Incomplete information, inappropriate content...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await AnimalService.rejectAnimal(
                  animalId: animalId,
                  adminMessage: messageController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Animal rejected successfully!'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error rejecting animal: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown date';
    } catch (e) {
      return 'Unknown date';
    }
  }
}
