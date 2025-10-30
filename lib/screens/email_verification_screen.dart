import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/auth_error_messages.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isVerified = false;
  bool _canResend = true;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isLoading = true);

    try {
      await AuthService.reloadUser();
      final verified = AuthService.isEmailVerified();

      setState(() {
        _isVerified = verified;
        _isLoading = false;
      });

      if (verified) {
        // Wait a moment to show the success state
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(AuthErrorMessages.fromFirebaseAuthException(e));
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(AuthErrorMessages.general(e));
    }
  }

  Future<void> _onVerifiedButtonPressed() async {
    await _checkVerificationStatus();
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.sendEmailVerification();

      setState(() {
        _isLoading = false;
        _canResend = false;
        _resendCooldown = 60; // 60 seconds cooldown
      });

      // Start countdown
      _startResendCooldown();

      _showSuccessDialog('Verification email sent successfully!');
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(AuthErrorMessages.fromFirebaseAuthException(e));
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(AuthErrorMessages.general(e));
    }
  }

  void _startResendCooldown() {
    // Using a Timer instead of Future.doWhile for better state management
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            _canResend = true;
            timer.cancel(); // Stop the timer
          }
        });
      } else {
        timer.cancel(); // Stop if widget is disposed
      }
    });
  }

  // Handle back button behavior
  Future<bool> _onWillPop() async {
    // If user tries to go back, show a dialog asking if they want to cancel verification
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2C2C2E), // Dark theme
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Cancel Verification?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to cancel email verification? You will be signed out.',
              style: TextStyle(color: Colors.grey.shade300),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(true); // Allow pop
                  await AuthService.signOut();
                  if (mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/entry-point', (route) => false);
                  }
                },
                child: Text(
                  'Cancel & Sign Out',
                  style: TextStyle(color: Colors.red.shade300),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E), // Dark theme
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Oops!', style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: Colors.grey.shade300)),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E), // Dark theme
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Success', style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: Colors.grey.shade300)),
        actions: [
          TextButton(
            child: const Text('Okay', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    final email = user?.email ?? 'your email';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black, // Dark theme background
        body: SafeArea(
          child: Column(
            children: [
              _buildNavigation(), // Custom navigation bar
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading) ...[
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Checking verification status...',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                            ),
                          ),
                        ] else if (_isVerified) ...[
                          Icon(
                            Icons.verified_user,
                            size: 80,
                            color: Colors.green.shade400,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Email Verified!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Redirecting to the app...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.mark_email_unread_outlined,
                            size: 80,
                            color: Colors.blue.shade300,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Verify Your Email',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'We\'ve sent a verification email to:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2C2C2E,
                              ), // Dark input style
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              email,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Please check your email and click the verification link to continue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Primary gradient button
                          _buildVerifiedButton(),
                          const SizedBox(height: 16),
                          // Resend button
                          TextButton(
                            onPressed: _canResend && !_isLoading
                                ? _resendVerificationEmail
                                : null,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                            ),
                            child: Text(
                              _canResend
                                  ? 'Resend Verification Email'
                                  : 'Resend in $_resendCooldown seconds',
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '• Check your spam folder\n• Make sure the email address is correct',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
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
          // Back Button (triggers OnWillPop)
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
            onPressed: _onWillPop,
          ),
          // Title
          Text(
            'Email Verification',
            style: TextStyle(
              color: Colors.grey.shade200,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Sign Out Button
          TextButton(
            onPressed: () async {
              await AuthService.signOut();
              if (!mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/entry-point', (route) => false);
            },
            child: Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.blue.shade300,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gradient "I've Verified" Button
  Widget _buildVerifiedButton() {
    return Container(
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
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
        padding: const EdgeInsets.all(2.0), // Border thickness
        child: InkWell(
          onTap: _isLoading || _isVerified ? null : _onVerifiedButtonPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              color: _isLoading || _isVerified
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFF2C2C2E),
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
                      'I\'ve Verified My Email',
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
