import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/animal_service.dart';

class PostAnimalScreen extends StatefulWidget {
  const PostAnimalScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pending Requests',
            ),
            Tab(
              icon: Icon(Icons.add_circle),
              text: 'Add New Animal',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingRequestsTab(),
          _buildAddNewAnimalTab(),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view pending requests'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: AnimalService.getPendingAnimals(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final animals = snapshot.data?.docs ?? [];

        if (animals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending requests!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All animals have been reviewed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: animals.length,
          itemBuilder: (context, index) {
            final animalData = animals[index].data() as Map<String, dynamic>;
            final animalId = animals[index].id;
            final postedByEmail = animalData['postedByEmail'] ?? 'Unknown';

            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animal Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(
                      animalData['image'] ?? 'https://via.placeholder.com/150/FF5733/FFFFFF?text=Animal',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Animal Name and Posted By
                        Text(
                          animalData['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5AC8F2),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Basic Info
                        Text(
                          '${animalData['species'] ?? ''} • ${animalData['age'] ?? ''} • ${animalData['gender'] ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Posted By Info
                        Text(
                          'Posted by: $postedByEmail',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Posted Date
                        Text(
                          'Posted on: ${_formatDate(animalData['postedAt'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Rescue Story
                        if (animalData['rescueStory']?.isNotEmpty == true) ...[
                          Text(
                            'Rescue Story:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            animalData['rescueStory'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Medical Info
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
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showApproveDialog(context, animalId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'Approve',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showRejectDialog(context, animalId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'Reject',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                  Icon(
                    Icons.pets,
                    size: 48,
                    color: const Color(0xFF5AC8F2),
                  ),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
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
              items: ['With Mother', 'Without Mother', 'Unknown'].map((String value) {
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
                prefixIcon: Icon(Icons.menu_book),   // book icon
                hintText: 'Tell us about how this animal was found or their background...',
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the rescue story';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AnimalService.postAnimal(
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        age: _ageController.text.trim(),
        gender: _selectedGender,
        sterilization: _selectedSterilization,
        vaccination: _selectedVaccination,
        rescueStory: _rescueStoryController.text.trim(),
        motherStatus: _selectedMotherStatus,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Animal posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
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
        });
        
        // Switch to pending requests tab to see the new post
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
                hintText: 'e.g., Incomplete information, inappropriate content...',
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
