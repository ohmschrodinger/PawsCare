import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // Import for ImageFilter
import '../services/animal_service.dart';
import '../services/logging_service.dart';

// --- THEME CONSTANTS FOR THE DARK UI ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
// --- CHANGE 1: Primary accent color is now white ---
const Color kPrimaryAccentColor = Colors.white;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);
// -------------------------------------------------

class ApplicationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> applicationData;
  final String applicationId;
  final bool isAdmin;

  const ApplicationDetailScreen({
    super.key,
    required this.applicationData,
    required this.applicationId,
    this.isAdmin = false,
  });

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  bool _isLoading = false;
  final _reasonController = TextEditingController();

  // --- All backend logic is unchanged ---
  void _showReasonDialog({required bool isApprove}) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: AlertDialog(
          backgroundColor: kCardColor.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            isApprove ? 'Approve Application' : 'Reject Application',
            style: const TextStyle(
              color: kPrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
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
                      : 'Rejection Reason *',
                  labelStyle: const TextStyle(color: kSecondaryTextColor),
                  hintText: isApprove
                      ? 'Add a message for the applicant...'
                      : 'Please provide a reason...',
                  hintStyle: TextStyle(
                    color: kSecondaryTextColor.withOpacity(0.7),
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: kPrimaryAccentColor,
                      width: 1.5,
                    ),
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: kPrimaryTextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (!isApprove && _reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a reason for rejection'),
                    ),
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
                backgroundColor: isApprove ? Colors.green : Colors.red,
                foregroundColor: kPrimaryTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text(isApprove ? 'Approve' : 'Reject'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .update({
            'status': 'Accepted',
            'adminMessage': _reasonController.text.trim(),
            'reviewedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await LoggingService.logEvent(
        'application_approved',
        data: {
          'applicationId': widget.applicationId,
          'petId':
              widget.applicationData['petId'] ??
              widget.applicationData['animalId'],
          'adminMessage': _reasonController.text.trim(),
        },
      );

      final String? petId =
          (widget.applicationData['petId'] as String?) ??
          (widget.applicationData['animalId'] as String?);
      if (petId != null) {
        await FirebaseFirestore.instance
            .collection('animals')
            .doc(petId)
            .update({
              'status': 'Adopted',
              'adoptedAt': FieldValue.serverTimestamp(),
            });

        final QuerySnapshot others = await FirebaseFirestore.instance
            .collection('applications')
            .where('petId', isEqualTo: petId)
            .where('status', isEqualTo: 'Under Review')
            .get();

        final WriteBatch batch = FirebaseFirestore.instance.batch();
        for (final doc in others.docs) {
          if (doc.id == widget.applicationId) continue;
          batch.update(doc.reference, {
            'status': 'Rejected',
            'adminMessage':
                'We\'re sorry, this pet has been adopted by another applicant.',
            'reviewedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();

        await AnimalService.updateAnimalStatus(
          animalId: petId,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReject() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .update({
            'status': 'Rejected',
            'adminMessage': _reasonController.text.trim(),
            'reviewedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await LoggingService.logEvent(
        'application_rejected',
        data: {
          'applicationId': widget.applicationId,
          'petId':
              widget.applicationData['petId'] ??
              widget.applicationData['animalId'],
          'adminMessage': _reasonController.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Application rejected')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  @override
  Widget build(BuildContext context) {
    final data = widget.applicationData;
    final status = data['status']?.toString().toLowerCase() ?? 'under review';
    Color statusColor;
    String statusText;

    switch (status) {
      case 'accepted':
      case 'approved':
        statusColor = Colors.green.shade400;
        statusText = 'Accepted';
        break;
      case 'rejected':
        statusColor = Colors.red.shade400;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.blue.shade400; // Changed from yellow
        statusText = 'Under Review';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Application Details',
          style: TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.2),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusBadge(
                    statusText,
                    statusColor,
                    data['adminMessage'],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    'Applicant & Pet Information',
                    Icons.person_pin_circle_outlined,
                    [
                      _buildInfoRowWithIcon(
                        'Full Name',
                        data['applicantName'],
                        Icons.person_outline,
                      ),
                      _buildInfoRowWithIcon(
                        'Email',
                        data['applicantEmail'],
                        Icons.email_outlined,
                      ),
                      _buildInfoRowWithIcon(
                        'Phone',
                        data['applicantPhone'],
                        Icons.phone_outlined,
                      ),
                      _buildInfoRowWithIcon(
                        'Address',
                        data['applicantAddress'],
                        Icons.location_on_outlined,
                      ),
                      const Divider(height: 24, color: Colors.white12),
                      _buildInfoRowWithIcon(
                        'Pet Name',
                        data['petName'],
                        Icons.pets_outlined,
                      ),
                      _buildInfoRowWithIcon(
                        'Why Adopt',
                        data['whyAdoptPet'],
                        Icons.volunteer_activism_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    'Household & Pet History',
                    Icons.family_restroom_outlined,
                    [
                      _buildInfoRowWithIcon(
                        'Home Ownership',
                        data['homeOwnership'],
                        Icons.house_outlined,
                      ),
                      _buildInfoRowWithIcon(
                        'Household Members',
                        (data['householdMembers'] ?? '').toString(),
                        Icons.groups_outlined,
                      ),
                      _buildInfoRowWithIcon(
                        'Allergies',
                        (data['hasAllergies'] ?? false),
                        Icons.sick_outlined,
                      ),
                      _buildInfoRowWithIcon(
                        'Members Agree',
                        (data['allMembersAgree'] ?? false),
                        Icons.task_alt_outlined,
                      ),
                      const Divider(height: 24, color: Colors.white12),
                      _buildInfoRowWithIcon(
                        'Has Current Pets',
                        (data['hasCurrentPets'] ?? false),
                        Icons.pets,
                      ),
                      if (data['hasCurrentPets'] == true)
                        _buildInfoRowWithIcon(
                          'Details',
                          data['currentPetsDetails'],
                          Icons.arrow_right_alt,
                        ),
                      _buildInfoRowWithIcon(
                        'Has Past Pets',
                        (data['hasPastPets'] ?? false),
                        Icons.history_edu_outlined,
                      ),
                      if (data['hasPastPets'] == true)
                        _buildInfoRowWithIcon(
                          'Details',
                          data['pastPetsDetails'],
                          Icons.arrow_right_alt,
                        ),
                      _buildInfoRowWithIcon(
                        'Surrendered Pet?',
                        (data['hasSurrenderedPets'] ?? false),
                        Icons.night_shelter,
                      ),
                      if (data['hasSurrenderedPets'] == true)
                        _buildInfoRowWithIcon(
                          'Circumstance',
                          data['surrenderedPetsCircumstance'],
                          Icons.arrow_right_alt,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    'Care, Vet & Commitment',
                    Icons.favorite_outline,
                    [
                      _buildInfoRowWithIcon(
                        'Hours Left Alone',
                        data['hoursLeftAlone'],
                        Icons.timer_off_outlined,
                      ),
                      _buildInfoRowWithIcon(
                        'Kept When Alone',
                        data['whereKeptWhenAlone'],
                        Icons.home_outlined,
                      ),
                      _buildInfoRowWithIcon(
                        'Financially Prepared',
                        (data['financiallyPrepared'] ?? false),
                        Icons.attach_money_outlined,
                      ),
                      const Divider(height: 24, color: Colors.white12),
                      _buildInfoRowWithIcon(
                        'Has Veterinarian',
                        (data['hasVeterinarian'] ?? false),
                        Icons.local_hospital_outlined,
                      ),
                      if (data['hasVeterinarian'] == true)
                        _buildInfoRowWithIcon(
                          'Vet Contact',
                          data['vetContactInfo'],
                          Icons.contact_phone_outlined,
                        ),
                      _buildInfoRowWithIcon(
                        'Will Provide Vet Care',
                        (data['willingToProvideVetCare'] ?? false),
                        Icons.medical_services_outlined,
                      ),
                      const Divider(height: 24, color: Colors.white12),
                      _buildInfoRowWithIcon(
                        'Prepared for Lifetime',
                        (data['preparedForLifetimeCommitment'] ?? false),
                        Icons.handshake_outlined,
                      ),
                      _buildInfoRowWithIcon(
                        'Plan if cannot keep',
                        data['ifCannotKeepCare'],
                        Icons.crisis_alert_outlined,
                      ),
                    ],
                  ),
                  if (widget.isAdmin && status == 'under review')
                    _buildAdminActionButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: kPrimaryAccentColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildGlassmorphicActionButton(
              label: 'Reject',
              icon: Icons.close,
              color: Colors.red,
              onTap: _isLoading
                  ? null
                  : () => _showReasonDialog(isApprove: false),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildGlassmorphicActionButton(
              label: 'Approve',
              icon: Icons.check,
              color: Colors.green,
              onTap: _isLoading
                  ? null
                  : () => _showReasonDialog(isApprove: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(50.0),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(50.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: kPrimaryTextColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: kPrimaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    String statusText,
    Color color,
    String? adminMessage,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16.0),
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
                  letterSpacing: 0.5,
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
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: kCardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: kPrimaryAccentColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    // --- CHANGE 2: Consistent Font Sizing ---
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryTextColor,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5, color: Colors.white12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRowWithIcon(String label, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
      return 'Not provided';
    }
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    return value.toString();
  }
}
