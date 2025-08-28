import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/auth_error_messages.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
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
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            _canResend = true;
          }
        });
      }
      return _resendCooldown > 0; // Continue while cooldown > 0
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Oops!'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Okay'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: const Color(0xFF5AC8F2),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('Checking verification status...'),
              ] else if (_isVerified) ...[
                const Icon(
                  Icons.verified,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Email Verified!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your email has been successfully verified. Redirecting to the app...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ] else ...[
                const Icon(
                  Icons.mark_email_unread,
                  size: 80,
                  color: Color(0xFF5AC8F2),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'ve sent a verification email to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Please check your email and click the verification link to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkVerificationStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5AC8F2),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('I\'ve Verified My Email'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _canResend && !_isLoading ? _resendVerificationEmail : null,
                  child: Text(
                    _canResend 
                        ? 'Resend Verification Email'
                        : 'Resend in $_resendCooldown seconds',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Didn\'t receive the email?',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Check your spam folder\n• Make sure the email address is correct\n• Wait a few minutes and try again',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
