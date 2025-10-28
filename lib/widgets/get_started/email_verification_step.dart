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
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create account: ${e.toString()}';
          _isLoading = false;
          _accountCreated =
              true; // Show page with error even if account creation failed
        });
      }
    }
  }

  void _startVerificationCheck() {
    _checkTimer?.cancel(); // Cancel any existing timer
    _checkTimer = Timer.periodic(
      Duration(
        seconds: VerificationConstants.emailVerificationCheckIntervalSeconds,
      ),
      (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
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
      _errorMessage = null;
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
      } else {
        // Show error if not verified
        if (mounted) {
          setState(() {
            _errorMessage =
                'Email not verified yet. Please check your inbox and click the verification link.';
          });
        }
      }
    } catch (e) {
      print('Error checking email verification: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error checking verification status. Please try again.';
        });
      }
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
          SnackBar(
            content: const Text(
              'Verification email sent successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade800, // Darker green
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
      return Container(
        color: Colors.black, // Dark background for loading
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Creating your account...',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          const Text(
            'Verify your email',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'We sent a verification link to',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            widget.email,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade200, // Styled
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E), // Styled
              borderRadius: BorderRadius.circular(12),
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

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5A1D1D), // Styled
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade400),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade200,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade200,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Manual check button (Styled as primary action)
          _buildCheckButton(),

          const SizedBox(height: 32),

          // Resend email option
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the email? ",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              GestureDetector(
                onTap: _isLoading || _isCheckingVerification
                    ? null
                    : _resendVerificationEmail,
                child: Text(
                  'Resend',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isLoading || _isCheckingVerification
                        ? Colors.grey.shade600
                        : Colors.blue.shade300, // Styled
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue.shade300,
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

  /// New Gradient Check Button
  Widget _buildCheckButton() {
    return Container(
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        // Gradient border
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD500F9), // Purple-ish
            Color(0xFFED00AA), // Pink
            Color(0xFFF77062), // Orange-ish
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.0), // This creates the border thickness
        child: InkWell(
          onTap: _isLoading || _isCheckingVerification
              ? null
              : _checkEmailVerification,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              // Dark button color, matching fields
              color: _isLoading || _isCheckingVerification
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: _isCheckingVerification
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'I\'ve verified, check now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
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
          decoration: const BoxDecoration(
            // Use gradient for the number circle
            gradient: LinearGradient(
              colors: [
                Color(0xFFD500F9), // Purple-ish
                Color(0xFFED00AA), // Pink
                Color(0xFFF77062), // Orange-ish
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
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
            style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }
}
