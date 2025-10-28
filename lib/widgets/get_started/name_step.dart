import 'package:flutter/material.dart';

/// Step 1: Name Input - First Name and Last Name
class NameStep extends StatefulWidget {
  final String firstName;
  final String lastName;
  final Function(String firstName, String lastName) onNext;

  const NameStep({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.onNext,
  });

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    // Updated regex to allow hyphens and apostrophes in names
    if (!RegExp(r"^[a-zA-Z'-]+(\s[a-zA-Z'-]+)*$").hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, or apostrophes';
    }
    return null;
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      widget.onNext(firstName, lastName);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Assuming this widget is placed on a screen with a black background
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
                'What\'s your name?',
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
                'Let\'s start with your first and last name.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // First Name field
            _buildLabel('First Name'),
            const SizedBox(height: 8),
            _buildFirstNameField(),
            const SizedBox(height: 24),

            // Last Name field
            _buildLabel('Last Name'),
            const SizedBox(height: 8),
            _buildLastNameField(),
            const SizedBox(height: 32),

            // Continue button
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

  Widget _buildFirstNameField() {
    return TextFormField(
      controller: _firstNameController,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Enter your first name',
        hintStyle: TextStyle(color: Colors.grey.shade700),
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
      textCapitalization: TextCapitalization.words,
      validator: (value) => _validateName(value, 'First name'),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildLastNameField() {
    return TextFormField(
      controller: _lastNameController,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Enter your last name',
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
      textCapitalization: TextCapitalization.words,
      validator: (value) => _validateName(value, 'Last name'),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleNext(),
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
          onTap: _handleNext,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              // Dark button color, matching fields
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(
              child: Text(
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
