import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Reuse color constants from other files for consistency
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);

class AdminLogsScreen extends StatelessWidget {
  const AdminLogsScreen({super.key});

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Activity Logs',
          style: TextStyle(color: kPrimaryTextColor),
        ),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryTextColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logs')
            .orderBy('createdAt', descending: true)
            .limit(200)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading logs: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryAccentColor),
            );
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No logs yet',
                style: TextStyle(color: kSecondaryTextColor),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;
              final eventType = data['eventType'] ?? 'unknown';
              final userEmail =
                  data['userEmail'] ?? data['userId'] ?? 'anonymous';
              final createdAt = _formatTimestamp(
                data['createdAt'] as Timestamp?,
              );
              final payload = data['data'] ?? {};

              return Card(
                color: kCardColor,
                child: ListTile(
                  title: Text(
                    eventType,
                    style: const TextStyle(
                      color: kPrimaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        'By: $userEmail',
                        style: const TextStyle(color: kSecondaryTextColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payload.toString(),
                        style: const TextStyle(
                          color: kSecondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    createdAt,
                    style: const TextStyle(
                      color: kSecondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
