// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/screens/my_applications_screen.dart';
import 'package:pawscare/screens/post_animal_screen.dart';
import 'package:pawscare/screens/my_posted_animals_screen.dart';
import 'package:pawscare/screens/profile_screen.dart';
import '../services/animal_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;
  bool _indexError = false; // Track if we hit index errors

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _checkIfAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  Stream<QuerySnapshot> _getAnimalsStream() {
    print('DEBUG: Getting animals stream, isAdmin: $_isAdmin, indexError: $_indexError');
    
    if (_isAdmin) {
      // Admin sees all animals
      if (_indexError) {
        // Fallback: simple query without ordering
        return FirebaseFirestore.instance
            .collection('animals')
            .snapshots();
      } else {
        return FirebaseFirestore.instance
            .collection('animals')
            .orderBy('postedAt', descending: true)
            .snapshots()
            .handleError((error) {
              print('Admin query error: $error');
              if (mounted) {
                setState(() {
                  _indexError = true;
                });
              }
            });
      }
    } else {
      // Users see only approved animals
      if (_indexError) {
        // Fallback: simple query without ordering
        return FirebaseFirestore.instance
            .collection('animals')
            .where('approvalStatus', isEqualTo: 'approved')
            .snapshots();
      } else {
        return FirebaseFirestore.instance
            .collection('animals')
            .where('approvalStatus', isEqualTo: 'approved')
            .orderBy('postedAt', descending: true)
            .snapshots()
            .handleError((error) {
              print('User query error: $error');
              if (mounted) {
                setState(() {
                  _indexError = true;
                });
              }
            });
      }
    }
  }

  Future<bool> _checkIfAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      return userDoc.data()?['role'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    if (index == 0) {
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyApplicationsScreen()),
      ).then((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PostAnimalScreen()),
      ).then((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyPostedAnimalsScreen()),
      ).then((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      ).then((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'PAWS CARE - Admin' : 'PAWS CARE'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              await AnimalService.testAnimalsCollection();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Check console for debug info')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter coming soon!')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'toggle_index_error') {
                setState(() {
                  _indexError = !_indexError;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Index error mode: $_indexError')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'toggle_index_error',
                child: Row(
                  children: [
                    Icon(Icons.bug_report),
                    SizedBox(width: 8),
                    Text('Toggle Fallback Mode'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Show warning if using fallback mode
          if (_indexError)
            Container(
              width: double.infinity,
              color: Colors.orange[100],
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Using fallback mode - animals may not be sorted by date. Please create the required Firestore index.',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _indexError = false;
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _getAnimalsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('DEBUG: Firestore error: ${snapshot.error}');
                    
                    // If we haven't tried fallback mode yet, try it
                    if (!_indexError && snapshot.error.toString().contains('requires an index')) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _indexError = true;
                          });
                        }
                      });
                    }
                    
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error loading animals'),
                          const SizedBox(height: 8),
                          Text(
                            'Please create the required Firestore index',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _indexError = true;
                              });
                            },
                            child: const Text('Try Fallback Mode'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print('DEBUG: Waiting for Firestore connection...');
                    return const Center(child: CircularProgressIndicator());
                  }

                  final animals = snapshot.data?.docs ?? [];
                  
                  // Filter out non-approved animals for regular users
                  final filteredAnimals = _isAdmin 
                      ? animals 
                      : animals.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['approvalStatus'] == 'approved';
                        }).toList();

                  print('DEBUG: Found ${animals.length} total animals, ${filteredAnimals.length} filtered');

                  if (filteredAnimals.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _isAdmin 
                                ? 'No animals posted yet' 
                                : 'No animals available for adoption yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to post an animal!',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PostAnimalScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5AC8F2),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Post Animal'),
                          ),
                          if (_isAdmin) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                await AnimalService.testAnimalsCollection();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Test Collection'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredAnimals.length,
                    itemBuilder: (context, index) {
                      final animalData = filteredAnimals[index].data() as Map<String, dynamic>;
                      final imageUrls = animalData['imageUrls'] as List<dynamic>?;
                      final imageUrl = (imageUrls != null && imageUrls.isNotEmpty)
                          ? imageUrls.first as String
                          : (animalData['image'] ?? 'https://via.placeholder.com/150/FF5733/FFFFFF?text=Animal');
                      final pet = {
                        'id': filteredAnimals[index].id,
                        'name': animalData['name'],
                        'species': animalData['species'],
                        'age': animalData['age'],
                        'status': animalData['status'],
                        'image': imageUrl,
                        'imageUrls': imageUrls ?? [],
                        'gender': animalData['gender'],
                        'sterilization': animalData['sterilization'],
                        'vaccination': animalData['vaccination'],
                        'rescueStory': animalData['rescueStory'],
                        'motherStatus': animalData['motherStatus'],
                        'approvalStatus': animalData['approvalStatus'],
                      };
                      return PetCard(
                        pet: pet,
                        showAdminInfo: _isAdmin,
                        onLike: () => _likeAnimal(context, pet['id']),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostAnimalScreen()),
          );
        },
        backgroundColor: const Color(0xFF5AC8F2),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Post Animal',
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'My History'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Post Animal'),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'My Posts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF5AC8F2),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class PetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final bool showAdminInfo;
  final VoidCallback? onLike;

  const PetCard({
    Key? key,
    required this.pet,
    this.showAdminInfo = false,
    this.onLike,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrls = pet['imageUrls'] as List<dynamic>? ?? [pet['image'] ?? ''];
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image gallery
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.black,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Image.network(
                              imageUrls[index],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrls[index],
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              pet['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '${pet['species'] ?? ''} • ${pet['age'] ?? ''}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              pet['rescueStory'] ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onLike,
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Like'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PetDetailScreen(petData: pet),
                        ),
                      );
                    },
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MyFavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Center(child: Text('Please log in'));

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final favoriteDocs = snapshot.data!.docs;
          if (favoriteDocs.isEmpty) return Center(child: Text('No favorites yet!'));
          return ListView(
            children: favoriteDocs.map((doc) {
              final animalId = doc['animalId'];
              return ListTile(
                title: Text('Animal ID: $animalId'),
                trailing: Icon(Icons.favorite, color: Colors.pinkAccent),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

void _likeAnimal(BuildContext context, String animalId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance.collection('favorites').add({
    'userId': user.uid,
    'animalId': animalId,
    'likedAt': FieldValue.serverTimestamp(),
  });
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Added to favorites!'), backgroundColor: Colors.pinkAccent),
  );
}