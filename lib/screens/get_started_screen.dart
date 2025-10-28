import 'package:flutter/material.dart';
import '../widgets/get_started/name_step.dart';
import '../widgets/get_started/phone_number_step.dart';
import '../widgets/get_started/phone_verification_step.dart';
import '../widgets/get_started/email_step.dart';
import '../widgets/get_started/email_verification_step.dart';

/// Get Started Screen - Multi-step registration flow
/// Steps: Name -> Phone -> Phone Verification -> Email -> Email Verification
class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  int _currentStep = 0;

  // Data collected during registration
  String _firstName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String _email = '';
  String _password = '';
  String? _verificationId; // For phone verification

  // Navigate to next step
  void _goToNextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    }
  }

  // Navigate to previous step
  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  // Update user data
  void _updateNameData(String firstName, String lastName) {
    setState(() {
      _firstName = firstName;
      _lastName = lastName;
    });
  }

  void _updatePhoneNumber(String phoneNumber) {
    setState(() {
      _phoneNumber = phoneNumber;
    });
  }

  void _updateEmail(String email, String password) {
    setState(() {
      _email = email;
      _password = password;
    });
  }

  void _updateVerificationId(String verificationId) {
    setState(() {
      _verificationId = verificationId;
    });
  }

  // Complete registration and navigate to home
  void _completeRegistration() {
    // This will be implemented in Phase 4
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _goToPreviousStep();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2196F3)),
                  onPressed: _goToPreviousStep,
                )
              : IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF2196F3)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
          title: Text(
            'Get Started',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              const SizedBox(height: 20),

              // Step content
              Expanded(child: _buildCurrentStep()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: List.generate(5, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? const Color(0xFF2196F3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return NameStep(
          firstName: _firstName,
          lastName: _lastName,
          onNext: (firstName, lastName) {
            _updateNameData(firstName, lastName);
            _goToNextStep();
          },
        );
      case 1:
        return PhoneNumberStep(
          phoneNumber: _phoneNumber,
          onNext: (phoneNumber, verificationId) {
            _updatePhoneNumber(phoneNumber);
            _updateVerificationId(verificationId);
            _goToNextStep();
          },
        );
      case 2:
        return PhoneVerificationStep(
          phoneNumber: _phoneNumber,
          verificationId: _verificationId ?? '',
          onVerified: () {
            _goToNextStep();
          },
          onResend: (newVerificationId) {
            _updateVerificationId(newVerificationId);
          },
        );
      case 3:
        return EmailStep(
          email: _email,
          onNext: (email, password) {
            _updateEmail(email, password);
            _goToNextStep();
          },
        );
      case 4:
        return EmailVerificationStep(
          email: _email,
          password: _password,
          firstName: _firstName,
          lastName: _lastName,
          phoneNumber: _phoneNumber,
          onVerified: _completeRegistration,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
