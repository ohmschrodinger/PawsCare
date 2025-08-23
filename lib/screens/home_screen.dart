// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/screens/my_applications_screen.dart';
import 'package:pawscare/screens/post_animal_screen.dart';
import 'package:pawscare/screens/my_posted_animals_screen.dart';
import 'package:pawscare/screens/profile_screen.dart';
import '../services/animal_service.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;
  bool _indexError = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // TODO: Add logic here to set _isAdmin based on user role if needed.
  }

  // Provide Stream for animal documents
  Stream<QuerySnapshot> _getAnimalsStream() {
    // Always use unsorted collection stream
    return FirebaseFirestore.instance.collection('animals').snapshots();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
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
    // index 0 is Home, do nothing
  }

  // Like action, can be passed to PetCard
  void _likeAnimal(BuildContext context, String animalId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('favorites').add({
      'userId': user.uid,
      'animalId': animalId,
      'likedAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to favorites!'),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'PAWS CARE - Admin' : 'PAWS CARE'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5AC8F2),
        foregroundColor: Colors.white,
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
                    Text('Toggle Index Error'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _getAnimalsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('DEBUG: Firestore error: ${snapshot.error}');
                    if (!_indexError &&
                        snapshot.error.toString().contains(
                          'requires an index',
                        )) {
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
                          const Text('Error loading animals'),
                          const SizedBox(height: 8),
                          Text(
                            'Please create the required Firestore index',
                            style: TextStyle(color: Colors.grey),
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
                  // Only approved for normal users
                  final filteredAnimals = _isAdmin
                      ? animals
                      : animals.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['approvalStatus'] == 'approved';
                        }).toList();

                  print(
                    'DEBUG: Found ${animals.length} total animals, ${filteredAnimals.length} filtered',
                  );

                  if (filteredAnimals.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _isAdmin
                                ? 'No animals posted yet'
                                : 'No animals available for adoption yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to post an animal!',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PostAnimalScreen(),
                                ),
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
                      final animalData =
                          filteredAnimals[index].data() as Map<String, dynamic>;
                      final imageUrls =
                          animalData['imageUrls'] as List<dynamic>? ?? [];
                      final imageUrl =
                          (imageUrls.isNotEmpty ? imageUrls.first : null) ??
                          (animalData['image'] ??
                              'https://via.placeholder.com/150/FF5733/FFFFFF?text=Animal');
                      final pet = {
                        'id': filteredAnimals[index].id,
                        'name': animalData['name'],
                        'species': animalData['species'],
                        'age': animalData['age'],
                        'status': animalData['status'],
                        'image': imageUrl,
                        'imageUrls': imageUrls,
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
            MaterialPageRoute(
              builder: (context) => const PostAnimalScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF5AC8F2),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Post Animal',
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF5AC8F2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'My Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Fixed PetCard - Changed to StatefulWidget to support PageController and state management
class PetCard extends StatefulWidget {
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
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.pet['imageUrls'] as List<dynamic>? ?? 
                     [widget.pet['image'] ?? 'https://via.placeholder.com/300x200/CCCCCC/666666?text=No+Image'];
    
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Image Gallery
            _buildEnhancedImageGallery(imageUrls),
            
            const SizedBox(height: 16),
            
            // Pet name and info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pet['name']?.toString() ?? 'Unknown Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 24,
                          color: Color(0xFF5AC8F2),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.pet['species']?.toString() ?? ''} • ${widget.pet['age']?.toString() ?? ''}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                // Share button
                IconButton(
                  icon: const Icon(Icons.share, color: Color(0xFF5AC8F2)),
                  onPressed: () => _sharePet(widget.pet),
                  tooltip: 'Share this pet',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Rescue Story
            Text(
              widget.pet['rescueStory']?.toString() ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onLike,
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Like'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PetDetailScreen(petData: widget.pet),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5AC8F2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
            
            // Admin Info (if needed)
            if (widget.showAdminInfo) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  'Status: ${widget.pet['approvalStatus'] ?? 'pending'}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedImageGallery(List<dynamic> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
      );
    }

    return Column(
      children: [
        // Image Gallery with PageView
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenGallery(context, imageUrls, index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrls[index].toString(),
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
                ),
              );
            },
          ),
        ),
        
        // Slider Dots Indicator
        if (imageUrls.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageUrls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? const Color(0xFF5AC8F2)
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showFullScreenGallery(BuildContext context, List<dynamic> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('${widget.pet['name']} - Image ${initialIndex + 1} of ${imageUrls.length}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _sharePet(widget.pet),
                tooltip: 'Share this pet',
              ),
            ],
          ),
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrls[index].toString()),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                heroAttributes: PhotoViewHeroAttributes(tag: imageUrls[index].toString()),
              );
            },
            itemCount: imageUrls.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            pageController: PageController(initialPage: initialIndex),
          ),
        ),
      ),
    );
  }

  void _sharePet(Map<String, dynamic> petData) {
    final String petName = petData['name']?.toString() ?? 'Pet';
    final String species = petData['species']?.toString() ?? '';
    final String age = petData['age']?.toString() ?? '';
    final String rescueStory = petData['rescueStory']?.toString() ?? '';
    
    String shareText = '🐾 Check out this adorable $species named $petName!';
    if (age.isNotEmpty) {
      shareText += '\nAge: $age';
    }
    if (rescueStory.isNotEmpty) {
      shareText += '\n\n$rescueStory';
    }
    shareText += '\n\nFind your perfect companion at PawsCare! 🏠❤️';
    
    Share.share(
      shareText,
      subject: 'Adopt $petName - A Lovely $species Looking for a Home',
    );
  }
}

class MyFavoritesScreen extends StatelessWidget {
  const MyFavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'), 
        centerTitle: true,
        backgroundColor: const Color(0xFF5AC8F2),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final favoriteDocs = snapshot.data!.docs;
          if (favoriteDocs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No favorites yet!', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: favoriteDocs.length,
            itemBuilder: (context, index) {
              final doc = favoriteDocs[index];
              final animalId = doc['animalId'];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Animal ID: $animalId'),
                  trailing: const Icon(Icons.favorite, color: Colors.pinkAccent),
                  onTap: () {
                    // TODO: Navigate to animal details
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}