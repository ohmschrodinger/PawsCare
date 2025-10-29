import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../constants/verification_constants.dart';

/// Step 3: Phone Verification - Enter code sent to phone
class PhoneVerificationStep extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final VoidCallback onVerified;
  final Function(String newVerificationId) onResend;

  const PhoneVerificationStep({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.onVerified,
    required this.onResend,
  });

  @override
  State<PhoneVerificationStep> createState() => _PhoneVerificationStepState();
}

class _PhoneVerificationStepState extends State<PhoneVerificationStep> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verify the code with Firebase
      await AuthService.verifyPhoneCode(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      // Verification successful
      if (mounted) {
        widget.onVerified();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = VerificationConstants.invalidVerificationCodeError;
          _isLoading = false;
        });

        // Clear all fields on error
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Resend verification code via Firebase
      await AuthService.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        onCodeSent: (verificationId) {
          if (mounted) {
            widget.onResend(verificationId);
            _startResendTimer();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Verification code resent successfully',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green.shade800, // Darker green
              ),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = error;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to resend code. Please try again.';
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

  String _formatPhoneNumber(String phone) {
    // Format +15551234567 to (555) 123-4567
    if (phone.startsWith('+1')) {
      final digits = phone.substring(2);
      if (digits.length == 10) {
        return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
      }
    }
    // Simple formatting for other numbers
    // e.g., +447123456789 -> +44 7123 456789
    if (phone.startsWith('+')) {
      int splitIndex;
      if (phone.length > 8) {
        splitIndex = phone.length - 6;
      } else if (phone.length > 4) {
        splitIndex = phone.length - 3;
      } else {
        return phone; // Return as is if too short
      }
      return '${phone.substring(0, splitIndex)} ${phone.substring(splitIndex)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          const Text(
            'Enter verification code',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle with phone number
          Text(
            'We sent a 6-digit code to',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _formatPhoneNumber(widget.phoneNumber),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade200, // Changed to lighter grey
            ),
          ),
          const SizedBox(height: 32),

          // 6-digit code input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 50, // Adjusted width for spacing
                height: 58,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E), // Styled fill
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none, // No border
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      // Use gradient color for focus? Or just white.
                      borderSide:
                          BorderSide(color: Colors.grey.shade400, width: 1.5),
                    ),
                    // Error styling for dark theme
                    errorStyle: const TextStyle(height: 0), // Hide default
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.red.shade300, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.red.shade300, width: 2),
                    ),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }

                    // Auto-verify when all 6 digits are entered
                    if (index == 5 &&
                        value.isNotEmpty &&
                        _controllers.every((c) => c.text.isNotEmpty)) {
                      _verifyCode();
                    }
                  },
                ),
              );
            }),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Using the same dark error as sign in
                color: const Color(0xFF5A1D1D),
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
          ],

          const SizedBox(height: 32),

          // Verify button
          _buildVerifyButton(),

          const SizedBox(height: 24),

          // Resend code option
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the code? ",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              if (_canResend)
                GestureDetector(
                  onTap: _resendCode,
                  child: Text(
                    'Resend',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade300, // Styled for dark theme
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue.shade300,
                    ),
                  ),
                )
              else
                Text(
                  'Resend in $_resendCountdown s',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// New Gradient Verify Button
  Widget _buildVerifyButton() {
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
          onTap: _isLoading ? null : _verifyCode,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              // Dark button color, matching fields
              color:
                  _isLoading ? const Color(0xFF1A1A1A) : const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Verify',
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
}
