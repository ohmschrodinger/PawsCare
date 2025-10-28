import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../constants/verification_constants.dart';

/// Step 5: Email Verification - Verify email before accessing app
class EmailVerificationStep extends StatefulWidget {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final VoidCallback onVerified;

  const EmailVerificationStep({
    super.key,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.onVerified,
  });

  @override
  State<EmailVerificationStep> createState() => _EmailVerificationStepState();
}

class _EmailVerificationStepState extends State<EmailVerificationStep> {
  bool _isLoading = false;
  bool _isCheckingVerification = false;
  bool _accountCreated = false;
  String? _errorMessage;
  Timer? _checkTimer;
  int _checkCount = 0;

  @override
  void initState() {
    super.initState();
    _createAccount();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _createAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create Firebase Auth account
      final userCredential = await AuthService.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create account');
      }

      // Create Firestore user document
      await UserService.createUserDocument(
        uid: user.uid,
        email: widget.email,
        firstName: widget.firstName,
        lastName: widget.lastName,
        phoneNumber: widget.phoneNumber,
        signInMethod: VerificationConstants.signInMethodEmail,
        isEmailVerified: false,
        isPhoneVerified: true, // Already verified in previous step
      );

      // Email verification is automatically sent in AuthService.createUserWithEmailAndPassword

      setState(() {
        _accountCreated = true;
        _isLoading = false;
      });

      // Start checking for email verification
      _startVerificationCheck();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create account: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startVerificationCheck() {
    _checkTimer = Timer.periodic(
      Duration(
        seconds: VerificationConstants.emailVerificationCheckIntervalSeconds,
      ),
      (timer) async {
        if (_checkCount >=
            VerificationConstants.maxEmailVerificationCheckAttempts) {
          timer.cancel();
          return;
        }

        _checkCount++;
        await _checkEmailVerification();
      },
    );
  }

  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;

    setState(() {
      _isCheckingVerification = true;
    });

    try {
      await AuthService.reloadUser();
      final isVerified = AuthService.isEmailVerified();

      if (isVerified) {
        _checkTimer?.cancel();

        // Update verification status in Firestore
        final user = AuthService.getCurrentUser();
        if (user != null) {
          await UserService.updateEmailVerificationStatus(
            uid: user.uid,
            isVerified: true,
          );
        }

        if (mounted) {
          widget.onVerified();
        }
      }
    } catch (e) {
      print('Error checking email verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to resend verification email. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_accountCreated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Creating your account...',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              size: 50,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Verify your email',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'We sent a verification link to',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            widget.email,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2196F3),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionStep('1', 'Check your email inbox'),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '2',
                  'Click the verification link in the email',
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '3',
                  'Come back here - we\'ll detect it automatically',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Checking status
          if (_isCheckingVerification)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Checking verification status...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Manual check button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _checkEmailVerification,
              icon: const Icon(Icons.refresh),
              label: const Text('I\'ve verified, check now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2196F3),
                side: const BorderSide(color: Color(0xFF2196F3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Resend email option
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the email? ",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              GestureDetector(
                onTap: _isLoading ? null : _resendVerificationEmail,
                child: Text(
                  'Resend',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isLoading ? Colors.grey : const Color(0xFF2196F3),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Help text
          Text(
            'Check your spam folder if you can\'t find the email',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
