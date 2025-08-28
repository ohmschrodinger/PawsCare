import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/auth_error_messages.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({Key? key}) : super(key: key);

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      await AuthService.sendPasswordResetEmail(email);
      
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(AuthErrorMessages.fromFirebaseAuthException(e));
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(AuthErrorMessages.general(e));
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: const Color(0xFF5AC8F2),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_emailSent) ...[
                  const Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Color(0xFF5AC8F2),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Forgot your password?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _sendPasswordResetEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5AC8F2),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Send Reset Link'),
                        ),
                ] else ...[
                  const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Email Sent!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'ve sent a password reset link to:\n${_emailController.text}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Please check your email and follow the instructions to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5AC8F2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Back to Login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
