import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/animal_service.dart';

// --- Re-using the color palette for consistency ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -------------------------------------------------

class ApplicationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> applicationData;
  final String applicationId;
  final bool isAdmin;

  const ApplicationDetailScreen({
    Key? key,
    required this.applicationData,
    required this.applicationId,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  bool _isLoading = false;
  final _reasonController = TextEditingController();

  void _showReasonDialog({required bool isApprove}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: Text(
          isApprove ? 'Approve Application' : 'Reject Application',
          style: const TextStyle(color: kPrimaryTextColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reasonController,
              style: const TextStyle(color: kPrimaryTextColor),
              decoration: InputDecoration(
                labelText: isApprove
                    ? 'Approval Message (Optional)'
                    : 'Rejection Reason',
                labelStyle: const TextStyle(color: kSecondaryTextColor),
                hintText: isApprove
                    ? 'Add a message for the applicant...'
                    : 'Please provide a reason for rejection...',
                hintStyle: const TextStyle(color: kSecondaryTextColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: kPrimaryAccentColor),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _reasonController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: kPrimaryTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              if (!isApprove && _reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please provide a reason for rejection')),
                );
                return;
              }
              Navigator.pop(context);
              if (isApprove) {
                _handleApprove();
              } else {
                _handleReject();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green.shade600 : Colors.red.shade600,
              foregroundColor: kPrimaryTextColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove() async {
    setState(() => _isLoading = true);
    try {
      // Approve selected application
      await FirebaseFirestore.instance
          .collection('adoptionApplications')
          .doc(widget.applicationId)
          .update({
        'status': 'approved',
        'adminMessage': _reasonController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If linked to an animal, mark it adopted and auto-reject others
      final String? animalId = widget.applicationData['animalId'] as String?;
      if (animalId != null) {
        await FirebaseFirestore.instance
            .collection('animals')
            .doc(animalId)
            .update({
          'status': 'Adopted',
          'adoptedAt': FieldValue.serverTimestamp(),
        });

        // Auto-reject other pending applications for this animal in this collection
        final QuerySnapshot others = await FirebaseFirestore.instance
            .collection('adoptionApplications')
            .where('animalId', isEqualTo: animalId)
            .where('status', isEqualTo: 'under review')
            .get();

        final WriteBatch batch = FirebaseFirestore.instance.batch();
        for (final doc in others.docs) {
          if (doc.id == widget.applicationId) continue;
          batch.update(doc.reference, {
            'status': 'rejected',
            'adminMessage': _reasonController.text.trim().isNotEmpty
                ? _reasonController.text.trim()
                : 'Auto-rejected: another application was approved for this pet.',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();

        // Update local animal status through service for consistency (optional)
        await AnimalService.updateAnimalStatus(
          animalId: animalId,
          status: 'Adopted',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application approved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReject() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('adoptionApplications')
          .doc(widget.applicationId)
          .update({
        'status': 'rejected',
        'adminMessage': _reasonController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Application rejected')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date not available';
    DateTime? date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is Timestamp) {
      date = timestamp.toDate();
    }

    if (date == null) return 'Date not available';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.applicationData;
    final status = data['status']?.toString().toLowerCase() ?? 'under review';
    Color statusColor;
    String statusText;

    switch (status) {
      case 'approved':
        statusColor = Colors.green.shade400;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red.shade400;
        statusText = 'Rejected';
        break;
      default:
        statusColor = kPrimaryAccentColor;
        statusText = 'Under Review';
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Application Details',
          style: TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold, // <-- Font weight added
          ),
        ),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusBadge(statusText, statusColor, data['adminMessage']),
                const SizedBox(height: 24),
                _buildSectionCard(
                    'Applicant & Pet Information', Icons.person_pin_circle_outlined, [
                  _buildSectionHeader('Applicant Information'),
                  _buildInfoRowWithIcon(
                      'Full Name', data['applicantName'], Icons.person_outline),
                  _buildInfoRowWithIcon(
                      'Email', data['applicantEmail'], Icons.email_outlined),
                  _buildInfoRowWithIcon(
                      'Phone', data['applicantPhone'], Icons.phone_outlined),
                  _buildInfoRowWithIcon('Address', data['applicantAddress'],
                      Icons.location_on_outlined),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Pet Information'),
                  _buildInfoRowWithIcon(
                      'Pet Name', data['petName'], Icons.pets_outlined),
                  _buildInfoRowWithIcon('Type Looking For',
                      data['petTypeLookingFor'], Icons.search_outlined),
                  _buildInfoRowWithIcon('Why Adopt', data['whyAdoptPet'],
                      Icons.volunteer_activism_outlined),
                ]),
                const SizedBox(height: 24),
                _buildSectionCard(
                    'Household & Pet History', Icons.family_restroom_outlined, [
                  _buildSectionHeader('Household Information'),
                  _buildInfoRowWithIcon(
                      'Home Ownership', data['homeOwnership'], Icons.house_outlined),
                  _buildInfoRowWithIcon(
                      'Household Members',
                      (data['householdMembers'] ?? '').toString(),
                      Icons.groups_outlined),
                  _buildInfoRowWithIcon('Allergies',
                      (data['hasAllergies'] ?? '').toString(), Icons.sick_outlined),
                  _buildInfoRowWithIcon(
                      'Members Agree',
                      (data['allMembersAgree'] ?? '').toString(),
                      Icons.task_alt_outlined),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Pet History'),
                  _buildInfoRowWithIcon('Has Current Pets',
                      (data['hasCurrentPets'] ?? '').toString(), Icons.pets),
                  if (data['hasCurrentPets'] == true)
                    _buildInfoRowWithIcon(
                        'Details', data['currentPetsDetails'], Icons.arrow_right_alt),
                  _buildInfoRowWithIcon(
                      'Has Past Pets',
                      (data['hasPastPets'] ?? '').toString(),
                      Icons.history_edu_outlined),
                  if (data['hasPastPets'] == true)
                    _buildInfoRowWithIcon(
                        'Details', data['pastPetsDetails'], Icons.arrow_right_alt),
                  _buildInfoRowWithIcon(
                      'Surrendered Pet?',
                      (data['hasSurrenderedPets'] ?? '').toString(),
                      Icons.night_shelter),
                  if (data['hasSurrenderedPets'] == true)
                    _buildInfoRowWithIcon('Circumstance',
                        data['surrenderedPetsCircumstance'], Icons.arrow_right_alt),
                ]),
                const SizedBox(height: 24),
                _buildSectionCard('Care, Vet & Commitment', Icons.favorite_outline, [
                  _buildSectionHeader('Care & Responsibility'),
                  _buildInfoRowWithIcon('Hours Left Alone',
                      data['hoursLeftAlone'], Icons.timer_off_outlined),
                  _buildInfoRowWithIcon('Kept When Alone',
                      data['whereKeptWhenAlone'], Icons.home_outlined),
                  _buildInfoRowWithIcon(
                      'Financially Prepared',
                      (data['financiallyPrepared'] ?? '').toString(),
                      Icons.attach_money_outlined),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Veterinary Care'),
                  _buildInfoRowWithIcon(
                      'Has Veterinarian',
                      (data['hasVeterinarian'] ?? '').toString(),
                      Icons.local_hospital_outlined),
                  if (data['hasVeterinarian'] == true)
                    _buildInfoRowWithIcon('Vet Contact', data['vetContactInfo'],
                        Icons.contact_phone_outlined),
                  _buildInfoRowWithIcon(
                      'Will Provide Vet Care',
                      (data['willingToProvideVetCare'] ?? '').toString(),
                      Icons.medical_services_outlined),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Commitment'),
                  _buildInfoRowWithIcon(
                      'Prepared for Lifetime',
                      (data['preparedForLifetimeCommitment'] ?? '').toString(),
                      Icons.family_restroom_outlined),
                  _buildInfoRowWithIcon('Plan if cannot keep',
                      data['ifCannotKeepCare'], Icons.crisis_alert_outlined),
                ]),
                
                // --- ADMIN ACTION BUTTONS MOVED HERE ---
                if (widget.isAdmin && status == 'under review')
                  _buildAdminActionButtons(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                  child: CircularProgressIndicator(color: kPrimaryAccentColor)),
            ),
        ],
      ),
    );
  }
  
  // --- NEW WIDGET FOR ADMIN BUTTONS ---
  Widget _buildAdminActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              onPressed: _isLoading
                  ? null
                  : () => _showReasonDialog(isApprove: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: kPrimaryTextColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
              onPressed: _isLoading
                  ? null
                  : () => _showReasonDialog(isApprove: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: kPrimaryTextColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String statusText, Color color, String? adminMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            'STATUS: $statusText',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (adminMessage?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              adminMessage!,
              style: const TextStyle(
                color: kSecondaryTextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kPrimaryTextColor, size: 28), // <-- Color changed
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryTextColor, // <-- Color changed
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.5, color: kSecondaryTextColor),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: kPrimaryTextColor,
        ),
      ),
    );
  }

  Widget _buildInfoRowWithIcon(String label, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kSecondaryTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kPrimaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatValue(value),
                  style: const TextStyle(
                    color: kSecondaryTextColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null || value == '') {
      return 'N/A';
    }
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    return value.toString();
  }
}