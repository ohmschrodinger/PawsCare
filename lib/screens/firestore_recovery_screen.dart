import 'package:flutter/material.dart';
import '../utils/firestore_recovery.dart';

class FirestoreRecoveryScreen extends StatefulWidget {
  const FirestoreRecoveryScreen({Key? key}) : super(key: key);

  @override
  State<FirestoreRecoveryScreen> createState() => _FirestoreRecoveryScreenState();
}

class _FirestoreRecoveryScreenState extends State<FirestoreRecoveryScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _statusData;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final status = await FirestoreRecovery.checkUsersCollectionStatus();
      setState(() {
        _statusData = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking status: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerRecovery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await FirestoreRecovery.recreateUsersCollection();
      setState(() {
        _successMessage = 'Recovery completed successfully!';
        _isLoading = false;
      });
      // Refresh status after recovery
      await _checkStatus();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during recovery: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Recovery'),
        backgroundColor: const Color(0xFF5AC8F2),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Users Collection Recovery',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5AC8F2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This screen helps you recover the users collection that was accidentally deleted from Firestore.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_statusData != null)
                      _buildStatusInfo(_statusData!)
                    else
                      const Text('Status not available'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recovery Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recovery Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Click the button below to attempt recovery of the users collection.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _triggerRecovery,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5AC8F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Trigger Recovery'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Messages
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (_successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),

            const SizedBox(height: 24),

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What This Does',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• Creates user documents in Firestore for existing Firebase Auth users\n'
                      '• Ensures new signups create both Auth and Firestore records\n'
                      '• Updates user profiles when adoption applications are submitted\n'
                      '• Provides a foundation for user data management',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(Map<String, dynamic> status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusRow('Status', status['status'] ?? 'Unknown'),
        if (status['currentUserUid'] != null)
          _buildStatusRow('Current User UID', status['currentUserUid']),
        if (status['currentUserEmail'] != null)
          _buildStatusRow('Current User Email', status['currentUserEmail']),
        if (status['userDocumentExists'] != null)
          _buildStatusRow('User Document Exists', status['userDocumentExists'].toString()),
        if (status['message'] != null)
          _buildStatusRow('Message', status['message']),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
