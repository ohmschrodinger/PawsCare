// screens/pet_detail_screen.dart
import 'package:flutter/material.dart';
// Note: You would need to create this adoption form screen or remove this import if not used.
// import 'package:pawscare/screens/adoption_form_screen.dart'; 

// --- THEME CONSTANTS FOR A CLEAN UI ---
const Color kPrimaryColor = Colors.black;
const Color kSecondaryColor = Color(0xFF616161); // Dark grey
const Color kBackgroundColor = Color(0xFFF5F5F5); // Light grey background
const Color kCardColor = Colors.white;

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
      backgroundColor: kBackgroundColor,
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
                  // Basic Info Card
                  _buildFormSection(
                    title: 'Basic Information',
                    children: [
                      Text(
                        getField('name'),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kPrimaryColor),
                      ),
                      const SizedBox(height: 16),
                      _buildBasicAttributes(),
                      const SizedBox(height: 16),
                      _buildIconInfoRow(Icons.pets, getField('breed')),
                      _buildIconInfoRow(Icons.location_on_outlined, getField('location')),
                      _buildIconInfoRow(Icons.access_time, 'Posted ${getField('postedDate')}'),
                    ],
                  ),

                  // Health & Wellness Card
                  _buildFormSection(
                    title: 'Health & Wellness',
                    children: [
                      _buildHealthStatusRow('Sterilized', getField('sterilization')),
                      _buildHealthStatusRow('Vaccinated', getField('vaccination')),
                      _buildHealthStatusRow('Dewormed', getField('deworming')),
                      if (getField('medicalIssues').isNotEmpty)
                        _buildIconInfoRow(Icons.medical_services, getField('medicalIssues')),
                    ],
                  ),

                  // Behavior & Temperament Card
                  _buildFormSection(
                    title: 'Behavior & Temperament',
                    children: [
                      _buildCompatibilityRow('Children', getField('kidCompatibility')),
                      _buildCompatibilityRow('Other Dogs', getField('dogCompatibility')),
                      _buildCompatibilityRow('Cats', getField('catCompatibility')),
                      _buildCompatibilityRow('Activity Level', getField('activityLevel')),
                    ],
                  ),

                  // Description Card
                  if (getField('description').isNotEmpty)
                    _buildFormSection(
                      title: 'About',
                      children: [
                        Text(
                          getField('description'),
                          style: const TextStyle(fontSize: 16, height: 1.5, color: kSecondaryColor),
                        ),
                      ],
                    ),

                  // Action Buttons Card
                  _buildFormSection(
                    title: 'Contact Options',
                    children: [
                      _buildActionButtons(),
                    ],
                  ),

                  // Rescue Center Info Card
                  if (getField('rescueName').isNotEmpty)
                    _buildFormSection(
                      title: 'Rescue Center',
                      children: [
                        _buildRescueInfo(),
                      ],
                    ),

                  // Comment Section Card
                  _buildFormSection(
                    title: 'Comments',
                    children: [
                      _buildCommentsSection(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a form section with consistent styling
  Widget _buildFormSection({required String title, required List<Widget> children}) {
    return Card(
      color: kCardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
            const Divider(height: 24),
            ...children,
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
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
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
            backgroundColor: Colors.black.withOpacity(0.7),
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
            backgroundColor: Colors.black.withOpacity(0.7),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.redAccent),
              onPressed: () { /* Handle favorite action */ },
            ),
          ),
        ),
        // Page indicator dots
        if (imageUrls.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imageUrls.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  height: 8.0,
                  width: _currentPage == index ? 24.0 : 8.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_currentPage == index ? 0.9 : 0.6),
                    borderRadius: BorderRadius.circular(12),
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
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: const Icon(Icons.pets, size: 80, color: Colors.grey),
    );
  }

  /// Builds the "Male • Senior • Medium" row.
  Widget _buildBasicAttributes() {
    return Row(
      children: [
        _buildAttributeChip(getField('gender')),
        const SizedBox(width: 8),
        _buildAttributeChip(getField('age')),
        const SizedBox(width: 8),
        _buildAttributeChip(getField('size')),
      ],
    );
  }

  /// Builds an individual attribute chip
  Widget _buildAttributeChip(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Builds a row with an icon and text, like for location or breed.
  Widget _buildIconInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: kSecondaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: kSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds health status rows
  Widget _buildHealthStatusRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            value.toLowerCase() == 'true' || value.toLowerCase() == 'yes' 
              ? Icons.check_circle 
              : Icons.cancel,
            color: value.toLowerCase() == 'true' || value.toLowerCase() == 'yes' 
              ? Colors.green 
              : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ${value.toLowerCase() == 'true' || value.toLowerCase() == 'yes' ? 'Yes' : 'No'}',
            style: const TextStyle(fontSize: 16, color: kSecondaryColor),
          ),
        ],
      ),
    );
  }

  /// Builds compatibility rows
  Widget _buildCompatibilityRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            _getCompatibilityIcon(value),
            color: _getCompatibilityColor(value),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 16, color: kSecondaryColor),
          ),
        ],
      ),
    );
  }

  /// Gets the appropriate icon for compatibility
  IconData _getCompatibilityIcon(String value) {
    switch (value.toLowerCase()) {
      case 'good':
        return Icons.sentiment_satisfied;
      case 'cautious':
        return Icons.sentiment_neutral;
      case 'not recommended':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  /// Gets the appropriate color for compatibility
  Color _getCompatibilityColor(String value) {
    switch (value.toLowerCase()) {
      case 'good':
        return Colors.green;
      case 'cautious':
        return Colors.orange;
      case 'not recommended':
        return Colors.red;
      default:
        return kSecondaryColor;
    }
  }

  /// Builds the row of action buttons (Call, Email, Text).
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(Icons.call, 'Call', () { /* Handle call */ }),
        const SizedBox(width: 12),
        _buildActionButton(Icons.email, 'Email', () { /* Handle email */ }),
        const SizedBox(width: 12),
        _buildActionButton(Icons.message, 'Text', () { /* Handle text */ }),
      ],
    );
  }
  
  /// Helper for creating a single action button.
  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
          getField('rescueName'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Rescue Center",
            style: TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  /// Builds the entire comment section.
  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // List of comments
        if (_comments.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: kPrimaryColor,
                      child: Text(
                        comment['user']![0],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment['user']!,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment['comment']!,
                            style: const TextStyle(color: kSecondaryColor),
                          ),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _addComment,
              style: IconButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}