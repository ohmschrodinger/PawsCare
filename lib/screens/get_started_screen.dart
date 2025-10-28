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
    // Navigate to the main app screen
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
        backgroundColor: Colors.black, // Changed to solid black
        body: SafeArea(
          child: Column(
            children: [
              // Custom navigation (Back/Close)
              _buildNavigation(),

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

  /// Custom navigation bar (replaces AppBar)
  Widget _buildNavigation() {
    return Container(
      height: 56, // Standard AppBar height
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back/Close Button
          IconButton(
            icon: Icon(
              _currentStep > 0 ? Icons.arrow_back_ios_new : Icons.close,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () {
              if (_currentStep > 0) {
                _goToPreviousStep();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          // Title
          Text(
            'Get Started',
            style: TextStyle(
              color: Colors.grey.shade200,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Spacer to center title
          const SizedBox(width: 48), // Width of an IconButton
        ],
      ),
    );
  }

  /// Styled Gradient Progress Indicator
  Widget _buildProgressIndicator() {
    const gradient = LinearGradient(
      colors: [
        Color(0xFFD500F9), // Purple-ish
        Color(0xFFED00AA), // Pink
        Color(0xFFF77062), // Orange-ish
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: List.generate(5, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                // Apply gradient if completed or current, otherwise dark grey
                gradient: isCompleted || isCurrent ? gradient : null,
                color: isCompleted || isCurrent
                    ? null
                    : const Color(0xFF3A3A3A),
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
