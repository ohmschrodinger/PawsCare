import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuccessStoriesScreen extends StatelessWidget {
  const SuccessStoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Success Stories'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5AC8F2),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('success_stories')
            .orderBy('postedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final stories = snapshot.data?.docs ?? [];
          if (stories.isEmpty) {
            return const Center(child: Text('No success stories yet!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final data = stories[index].data() as Map<String, dynamic>;

              final timestamp = data['postedAt'] is Timestamp
                  ? (data['postedAt'] as Timestamp).toDate()
                  : null;
              final formattedTime = timestamp != null
                  ? '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                  : 'Unknown date';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1.5,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with avatar, author and post time
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                                ? NetworkImage(data['imageUrl'])
                                : null,
                            child: (data['imageUrl'] == null || data['imageUrl'].toString().isEmpty)
                                ? const Icon(Icons.pets, color: Colors.white)
                                : null,
                            backgroundColor: Colors.blueAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['author'] ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
                            onPressed: () {
                              // TODO: Add options menu
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Story content with tweet style font and spacing
                      Text(
                        data['story'] ?? '',
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddStoryDialog(context);
        },
        backgroundColor: const Color(0xFF5AC8F2),
        child: const Icon(Icons.add_comment),
        tooltip: 'Add Success Story',
      ),
    );
  }

  void _showAddStoryDialog(BuildContext context) {
    final authorController = TextEditingController();
    final storyController = TextEditingController();
    final imageUrlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Success Story'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              TextField(
                controller: storyController,
                decoration: const InputDecoration(labelText: 'Story'),
                maxLines: 3,
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (storyController.text.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('success_stories').add({
                'author': authorController.text.trim(),
                'story': storyController.text.trim(),
                'imageUrl': imageUrlController.text.trim(),
                'postedAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}
