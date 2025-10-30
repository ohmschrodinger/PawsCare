import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/navigation_guard.dart';
import '../constants/verification_constants.dart';
import '../utils/auth_error_messages.dart';

/// New Sign-In Screen supporting Email and Phone authentication
class NewSignInScreen extends StatefulWidget {
  const NewSignInScreen({super.key});

  @override
  State<NewSignInScreen> createState() => _NewSignInScreenState();
}

class _NewSignInScreenState extends State<NewSignInScreen> {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Form state
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validation
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }

    if (!VerificationConstants.emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Sign-in methods
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Check if account exists
      final accountExists = await UserService.emailExists(email);
      if (!accountExists) {
        setState(() {
          _errorMessage =
              'No account found with this email. Please sign up first.';
          _isLoading = false;
        });
        return;
      }

      // Sign in
      final userCredential = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Sign-in failed');
      }

      // Check verification status
      await _handlePostSignIn(user);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = AuthErrorMessages.fromFirebaseAuthException(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign-in failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePostSignIn(User user) async {
    // Use NavigationGuard to determine where to navigate
    final route = await NavigationGuard.handlePostAuthentication(user);

    if (route == null) {
      // Should not happen, but handle gracefully
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
      return;
    }

    if (mounted) {
      if (route == '/entry-point') {
        // User was signed out (inactive account)
        setState(() {
          _errorMessage =
              'Your account has been deactivated. Please contact support.';
        });
      } else {
        // Navigate to appropriate route
        Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background from image
      // Added an AppBar back, but styled transparently to hold the back button
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        // Use .only(bottom: true) to avoid double padding with AppBar
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // == Header added back ==
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue to PawsCare',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 32),

                // Email field
                _buildLabel('Email'),
                const SizedBox(height: 8),
                _buildEmailField(),
                const SizedBox(height: 24), // Increased spacing

                // Password field
                _buildLabel('Password'),
                const SizedBox(height: 8),
                _buildPasswordField(),
                const SizedBox(height: 8),

                // == Forgot password added back ==
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/password-reset');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade300, // Styled for dark theme
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Spacing before error

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // Dark theme error color
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
                  const SizedBox(height: 24),
                ] else ...[
                  // Added space to keep button in same place
                  const SizedBox(height: 24),
                ],

                // Sign-in button
                _buildSignInButton(),

                const SizedBox(height: 32), // Spacing before sign up

                // == "Sign Up" link added back ==
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/get-started');
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade300, // Styled for dark theme
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue.shade300,
                        ),
                      ),
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

  /// Helper widget for the text labels above input fields
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        // Removed labelText
        hintText: 'youremail@example.com',
        hintStyle: TextStyle(color: Colors.grey.shade700),
        // Removed prefixIcon
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none, // No border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none, // No border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none, // No border on focus
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2E), // Darker field color
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        // Error styling for dark theme
        errorStyle: TextStyle(color: Colors.red.shade300),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: _validateEmail,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        letterSpacing: 2, // Added letter spacing for '***'
      ),
      decoration: InputDecoration(
        // Removed labelText
        hintText: '************',
        hintStyle: TextStyle(color: Colors.grey.shade700, letterSpacing: 2),
        // Removed prefixIcon
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade500,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        // Error styling for dark theme
        errorStyle: TextStyle(color: Colors.red.shade300),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
      ),
      validator: _validatePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _signInWithEmail(),
    );
  }

  /// New Gradient Sign In Button
  Widget _buildSignInButton() {
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
          onTap: _isLoading ? null : _signInWithEmail,
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 12),
                        const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

