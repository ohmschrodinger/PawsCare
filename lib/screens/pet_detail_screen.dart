// screens/pet_detail_screen.dart
import 'package:flutter/material.dart';
// Note: You would need to create this adoption form screen or remove this import if not used.
// import 'package:pawscare/screens/adoption_form_screen.dart'; 

// Converted to StatefulWidget to manage state for the new comment section
class PetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> petData;

  const PetDetailScreen({super.key, required this.petData});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // State for the comment section
  final TextEditingController _commentController = TextEditingController();
  // Using a list of maps for more structured comment data
  final List<Map<String, String>> _comments = [
    {'user': 'Alex R.', 'comment': 'What a beautiful dog! Hope he finds a home soon.'},
    {'user': 'Maria G.', 'comment': 'Is he good with other large dogs?'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // Helper function to safely get data from the map
  String getField(String key) => widget.petData[key]?.toString() ?? '';
  
  // Helper to get a list of strings (for images or attributes)
  List<String> getListField(String key) {
    final raw = widget.petData[key];
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return [];
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        // Here you would typically get the current user's name
        _comments.add({'user': 'CurrentUser', 'comment': _commentController.text});
        _commentController.clear();
      });
      // Hide keyboard after submitting
      FocusScope.of(context).unfocus();
    }
  }


  @override
  Widget build(BuildContext context) {
    List<String> imageUrls = getListField('imageUrls');
    // Fallback for a single image field
    if (imageUrls.isEmpty && getField('image').isNotEmpty) {
      imageUrls = [getField('image')];
    }
    
    return Scaffold(
      // We remove the AppBar to have a full-screen image header
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Image Gallery with overlaid buttons
            _buildImageHeader(imageUrls),

            // Section 2: Main content with padding
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getField('name'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Basic attributes row (e.g., Male • Senior • Medium)
                  _buildBasicAttributes(),
                  const SizedBox(height: 16),
                  
                  // Icon-based info rows for breed, location, etc.
                  _buildIconInfoRow(Icons.pets, getField('breed')),
                  _buildIconInfoRow(Icons.location_on_outlined, getField('location')),
                  _buildIconInfoRow(Icons.access_time, 'Posted ${getField('postedDate')}'),
                  const SizedBox(height: 20),

                  // Tags/Chips for attributes
                  _buildAttributeTags(),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    getField('description'), // Changed from 'rescueStory' to be more general
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons (Call, Email, Text)
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  
                  const Divider(),
                  const SizedBox(height: 16),

                  // Rescue Center Info
                  _buildRescueInfo(),
                  const SizedBox(height: 24),
                  
                  const Divider(),
                  const SizedBox(height: 16),

                  // Comment Section
                  _buildCommentsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the top image gallery with overlaid controls.
  Widget _buildImageHeader(List<String> imageUrls) {
    return Stack(
      children: [
        SizedBox(
          height: 350,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.isNotEmpty ? imageUrls.length : 1,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              if (imageUrls.isEmpty) {
                return _buildPlaceholderImage();
              }
              return ClipRRect( // Ensuring no sharp edges
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                ),
              );
            },
          ),
        ),
        // Back Button
        Positioned(
          top: 40,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        // Favorite Button
        Positioned(
          top: 40,
          right: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.redAccent),
              onPressed: () { /* Handle favorite action */ },
            ),
          ),
        ),
        // Page indicator dots
        if (imageUrls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imageUrls.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  /// Placeholder for when an image fails to load.
  Widget _buildPlaceholderImage() {
    return Container(
      height: 350,
      color: Colors.grey[300],
      child: const Icon(Icons.pets, size: 80, color: Colors.grey),
    );
  }

  /// Builds the "Male • Senior • Medium" row.
  Widget _buildBasicAttributes() {
    return Row(
      children: [
        Text(getField('gender'), style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const Text(' • ', style: TextStyle(fontSize: 16, color: Colors.black54)),
        Text(getField('age'), style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const Text(' • ', style: TextStyle(fontSize: 16, color: Colors.black54)),
        Text(getField('size'), style: const TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }

  /// Builds a row with an icon and text, like for location or breed.
  Widget _buildIconInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds the tags for pet attributes like "House Trined", "Kid Compatible".
  Widget _buildAttributeTags() {
    // Assumes petData['attributes'] is a List<String>
    final attributes = getListField('attributes');
    if (attributes.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: attributes.map((attribute) => Chip(
        label: Text(attribute),
        backgroundColor: const Color(0xFFF0F0F0),
        labelStyle: const TextStyle(color: Colors.black54),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      )).toList(),
    );
  }

  /// Builds the row of action buttons (Call, Email, Text).
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(Icons.call, 'Call', () { /* Handle call */ }),
        _buildActionButton(Icons.email, 'Email', () { /* Handle email */ }),
        _buildActionButton(Icons.message, 'Text', () { /* Handle text */ }),
      ],
    );
  }
  
  /// Helper for creating a single action button.
  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C4DFF), // Purple color from image
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the section with rescue center information.
  Widget _buildRescueInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getField('rescueName'), // e.g., "Ha Noi City Abandoned Animal Protection Center"
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          "Type: Rescue", // This can also be made dynamic if needed
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  /// Builds the entire comment section.
  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Comments",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // List of comments
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Important inside a SingleChildScrollView
          itemCount: _comments.length,
          itemBuilder: (context, index) {
            final comment = _comments[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    child: Text(comment['user']![0]), // First initial
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment['user']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(comment['comment']!),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Input field for new comment
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _addComment,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white
              ),
            ),
          ],
        ),
      ],
    );
  }
}