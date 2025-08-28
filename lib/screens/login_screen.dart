import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../utils/auth_error_messages.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _confirmPasswordController.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final userCredential = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Check if email is verified
        if (!user.emailVerified) {
          setState(() => _isLoading = false);
          Navigator.pushNamed(context, '/email-verification');
          return;
        }

        // Ensure user document exists in Firestore (for users who signed up before collection was deleted)
        try {
          await UserService.ensureUserDocumentExists(
            uid: user.uid,
            email: email,
            fullName: null,
          );
        } catch (e) {
          print('Warning: Failed to ensure user document exists: $e');
          // Don't block the login process if Firestore fails
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/main');
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(AuthErrorMessages.fromFirebaseAuthException(e));
    } catch (e) {
      _showErrorDialog(AuthErrorMessages.general(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final fullName = _fullNameController.text.trim();

      final userCredential = await AuthService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Create user document in Firestore
        try {
          await UserService.createUserDocument(
            uid: user.uid,
            email: email,
            fullName: fullName.isNotEmpty ? fullName : null,
          );
        } catch (e) {
          print('Warning: Failed to create user document in Firestore: $e');
          // Don't block the signup process if Firestore fails
        }

        setState(() => _isLoading = false);
        if (!mounted) return;
        
        // Navigate to email verification screen instead of main screen
        Navigator.pushReplacementNamed(context, '/email-verification');
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(AuthErrorMessages.fromFirebaseAuthException(e));
    } catch (e) {
      _showErrorDialog(AuthErrorMessages.general(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      appBar: AppBar(title: const Text('PawsCare')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'PawsCare',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5AC8F2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Login to continue' : 'Create an account',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                const SizedBox(height: 48),

                if (!_isLogin) ...[
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),

                if (!_isLogin) ...[
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 24),
                ],

                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _isLogin ? _login : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5AC8F2),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_isLogin ? 'Login' : 'Sign Up'),
                      ),
                const SizedBox(height: 16),

                if (_isLogin)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/password-reset');
                    },
                    child: const Text('Forgot Password?'),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account?"
                          : "Already have an account?",
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _formKey.currentState?.reset();
                          _emailController.clear();
                          _passwordController.clear();
                          _fullNameController.clear();
                          _confirmPasswordController.clear();
                        });
                      },
                      child: Text(_isLogin ? 'Sign Up' : 'Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
