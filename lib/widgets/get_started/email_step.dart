import 'package:flutter/material.dart';
import '../../constants/verification_constants.dart';
import '../../services/user_service.dart';

/// Step 4: Email Input with Password
class EmailStep extends StatefulWidget {
  final String email;
  final Function(String email, String password) onNext;

  const EmailStep({super.key, required this.email, required this.onNext});

  @override
  State<EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends State<EmailStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // Notifier to update password requirements UI in real-time
  final ValueNotifier<String> _passwordNotifier = ValueNotifier('');

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Listen to password changes
    _passwordController.addListener(() {
      _passwordNotifier.value = _passwordController.text;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordNotifier.dispose();
    super.dispose();
  }

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
      return 'Please enter a password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();

      // Check if email already exists
      final emailExists = await UserService.emailExists(email);

      if (emailExists) {
        setState(() {
          _errorMessage = VerificationConstants.emailAlreadyExistsError;
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        widget.onNext(email, _passwordController.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to validate email. Please try again.';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align labels to start
          children: [
            // Title
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Align(
              alignment: Alignment.center,
              child: Text(
                'Enter your email and create a secure password.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // Email field
            _buildLabel('Email'),
            const SizedBox(height: 8),
            _buildEmailField(),
            const SizedBox(height: 24),

            // Password field
            _buildLabel('Password'),
            const SizedBox(height: 8),
            _buildPasswordField(),
            const SizedBox(height: 24),

            // Confirm Password field
            _buildLabel('Confirm Password'),
            const SizedBox(height: 8),
            _buildConfirmPasswordField(),
            const SizedBox(height: 16),

            // Password requirements
            _buildPasswordRequirements(),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
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

            // Next button
            _buildContinueButton(),
          ],
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
        hintText: 'you@example.com',
        hintStyle: TextStyle(color: Colors.grey.shade700),
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
          borderSide: BorderSide.none, // No focus border
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'At least 6 characters',
        hintStyle: TextStyle(color: Colors.grey.shade700),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade400,
            size: 22,
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
          borderSide: BorderSide.none, // No focus border
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Re-enter your password',
        hintStyle: TextStyle(color: Colors.grey.shade700),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey.shade400,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
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
          borderSide: BorderSide.none, // No focus border
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      validator: _validateConfirmPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleNext(),
    );
  }

  /// Dynamic password requirements checker
  Widget _buildPasswordRequirements() {
    return ValueListenableBuilder<String>(
      valueListenable: _passwordNotifier,
      builder: (context, password, child) {
        final hasMinLength = password.length >= 6;
        final hasUppercase = password.contains(RegExp(r'[A-Z]'));
        final hasNumber = password.contains(RegExp(r'[0-9]'));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password must contain:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 8),
              _PasswordRequirementItem(
                text: 'At least 6 characters',
                isMet: hasMinLength,
              ),
              const SizedBox(height: 4),
              _PasswordRequirementItem(
                text: 'At least one uppercase letter',
                isMet: hasUppercase,
              ),
              const SizedBox(height: 4),
              _PasswordRequirementItem(
                text: 'At least one number',
                isMet: hasNumber,
              ),
            ],
          ),
        );
      },
    );
  }

  /// New Gradient Continue Button
  Widget _buildContinueButton() {
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
          onTap: _isLoading ? null : _handleNext,
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
                      'Continue',
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

/// Helper widget for password requirement items
class _PasswordRequirementItem extends StatelessWidget {
  final String text;
  final bool isMet;

  const _PasswordRequirementItem({required this.text, required this.isMet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
          size: 16,
          color: isMet ? Colors.green.shade400 : Colors.grey.shade500,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isMet ? Colors.grey.shade300 : Colors.grey.shade500,
            decoration: isMet ? TextDecoration.lineThrough : TextDecoration.none,
            decorationColor: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
