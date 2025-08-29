// lib/widgets/animal_card.dart

import 'package:flutter/material.dart';

class AnimalCard extends StatelessWidget {
  final Map<String, dynamic> animal;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final bool isLiked;
  final bool isSaved;

  const AnimalCard({
    Key? key,
    required this.animal,
    this.onTap,
    this.onLike,
    this.onSave,
    this.isLiked = false,
    this.isSaved = false,
  }) : super(key: key);

  Color _getStatusColor() {
    final status = animal['status']?.toString().toLowerCase() ?? 'available';
    switch (status) {
      case 'available':
        return Colors.green;
      case 'adopted':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    final status = animal['status']?.toString() ?? 'Available';
    return status;
  }

  IconData _getGenderIcon(String? gender) {
    return gender?.toLowerCase() == 'male' ? Icons.male : Icons.female;
  }

  Color _getGenderColor(String? gender) {
    return gender?.toLowerCase() == 'male' ? Colors.blue : Colors.pink;
  }

  String _getTimeAgo() {
    final postedAt = animal['postedAt'];
    if (postedAt == null) return 'Posted recently';
    
    try {
      DateTime postedDate;
      if (postedAt is DateTime) {
        postedDate = postedAt;
      } else if (postedAt.runtimeType.toString().contains('Timestamp')) {
        // Firebase Timestamp
        postedDate = postedAt.toDate();
      } else {
        return 'Posted recently';
      }
      
      final now = DateTime.now();
      final difference = now.difference(postedDate);
      
      if (difference.inDays > 0) {
        return 'Posted ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return 'Posted ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else {
        return 'Posted recently';
      }
    } catch (e) {
      return 'Posted recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final imageUrls = animal['imageUrls'] as List<dynamic>? ?? [];
    final imageUrl = (imageUrls.isNotEmpty ? imageUrls.first : null) ??
        (animal['image'] ?? 'https://via.placeholder.com/300x200');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(4), // Minimal rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with status badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 220,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.pets,
                        color: Colors.grey[400],
                        size: 60,
                      ),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Action buttons overlay
                if (onLike != null || onSave != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        if (onLike != null)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: onLike,
                              icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.grey[600],
                                size: 20,
                              ),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ),
                        if (onLike != null && onSave != null)
                          const SizedBox(width: 8),
                        if (onSave != null)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: onSave,
                              icon: Icon(
                                isSaved ? Icons.bookmark : Icons.bookmark_border,
                                color: isSaved ? Colors.blue : Colors.grey[600],
                                size: 20,
                              ),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            // Animal details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and gender
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          animal['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _getGenderIcon(animal['gender']),
                        color: _getGenderColor(animal['gender']),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Breed
                  Text(
                    animal['breed'] ?? animal['species'] ?? 'Mixed Breed',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Age and location
                  Row(
                    children: [
                      Text(
                        animal['age'] ?? 'Unknown age',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (animal['location'] != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            animal['location'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Posted time
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  // Description (if available)
                  if (animal['description'] != null && 
                      animal['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      animal['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Additional info chips
                  if (animal['vaccination'] != null || 
                      animal['sterilization'] != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (animal['vaccination'] != null)
                          _buildInfoChip(
                            Icons.vaccines,
                            'Vaccinated: ${animal['vaccination']}',
                            Colors.green,
                          ),
                        if (animal['sterilization'] != null)
                          _buildInfoChip(
                            Icons.healing,
                            'Sterilized: ${animal['sterilization']}',
                            Colors.blue,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}