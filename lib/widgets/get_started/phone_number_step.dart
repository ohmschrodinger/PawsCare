import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/verification_constants.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

/// Country code data
class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

/// Popular country codes
class CountryCodes {
  static const List<CountryCode> countries = [
    CountryCode(
      name: 'United States',
      code: 'US',
      dialCode: '+1',
      flag: '🇺🇸',
    ),
    CountryCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    CountryCode(
      name: 'United Kingdom',
      code: 'GB',
      dialCode: '+44',
      flag: '🇬🇧',
    ),
    CountryCode(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    CountryCode(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭'),
    CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    CountryCode(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    CountryCode(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    CountryCode(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
    CountryCode(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
    CountryCode(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
    CountryCode(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
    CountryCode(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    CountryCode(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
    CountryCode(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
    CountryCode(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    CountryCode(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
    CountryCode(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭'),
    CountryCode(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
    CountryCode(name: 'Vietnam', code: 'VN', dialCode: '+84', flag: '🇻🇳'),
    CountryCode(
      name: 'Saudi Arabia',
      code: 'SA',
      dialCode: '+966',
      flag: '🇸🇦',
    ),
    CountryCode(name: 'UAE', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
    CountryCode(
      name: 'South Africa',
      code: 'ZA',
      dialCode: '+27',
      flag: '🇿🇦',
    ),
    CountryCode(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
    CountryCode(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
  ];

  static CountryCode get defaultCountry => countries[0]; // US
}

/// Step 2: Phone Number Input
class PhoneNumberStep extends StatefulWidget {
  final String phoneNumber;
  final Function(String phoneNumber, String verificationId) onNext;

  const PhoneNumberStep({
    super.key,
    required this.phoneNumber,
    required this.onNext,
  });

  @override
  State<PhoneNumberStep> createState() => _PhoneNumberStepState();
}

class _PhoneNumberStepState extends State<PhoneNumberStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  bool _isLoading = false;
  String? _errorMessage;
  CountryCode _selectedCountry = CountryCodes.defaultCountry;

  @override
  void initState() {
    super.initState();
    // Parse existing phone number if available
    String phoneWithoutCode = widget.phoneNumber;
    if (widget.phoneNumber.isNotEmpty) {
      // Try to extract country code from existing phone
      for (var country in CountryCodes.countries) {
        if (widget.phoneNumber.startsWith(country.dialCode)) {
          _selectedCountry = country;
          phoneWithoutCode = widget.phoneNumber.substring(
            country.dialCode.length,
          );
          break;
        }
      }
    }
    _phoneController = TextEditingController(text: phoneWithoutCode);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Basic validation - at least 6 digits
    if (digitsOnly.length < 6) {
      return 'Phone number is too short';
    }

    // Maximum 15 digits (international standard)
    if (digitsOnly.length > 15) {
      return 'Phone number is too long';
    }

    return null;
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Country Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const Divider(height: 1),
            // Country list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: CountryCodes.countries.length,
                itemBuilder: (context, index) {
                  final country = CountryCodes.countries[index];
                  final isSelected = country.code == _selectedCountry.code;
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      country.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: Text(
                      country.dialCode,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF2196F3)
                            : Colors.grey.shade600,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF2196F3).withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Format phone number with selected country code
      final digitsOnly = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      final formattedPhone = '${_selectedCountry.dialCode}$digitsOnly';

      // Check if phone number already exists
      final phoneExists = await UserService.phoneNumberExists(formattedPhone);

      if (phoneExists) {
        setState(() {
          _errorMessage = VerificationConstants.phoneAlreadyExistsError;
          _isLoading = false;
        });
        return;
      }

      // Send verification code via Firebase Phone Auth
      await AuthService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        onCodeSent: (verificationId) {
          if (mounted) {
            // Code sent successfully, move to next step
            widget.onNext(formattedPhone, verificationId);
          }
        },
        onError: (error) {
          if (mounted) {
            String userFriendlyError = error;

            // Handle specific Firebase Phone Auth errors
            if (error.contains('app-not-authorized')) {
              userFriendlyError =
                  'Phone verification is not properly configured.\n\n'
                  'For testing, please use a test phone number:\n'
                  '• Go to Firebase Console → Authentication → Settings\n'
                  '• Add a test phone number (e.g., +1 5551234567)\n'
                  '• Set a test code (e.g., 123456)\n'
                  '• Use that number to test the app';
            } else if (error.contains('invalid-phone-number')) {
              userFriendlyError =
                  'Invalid phone number format. Please check and try again.';
            } else if (error.contains('too-many-requests')) {
              userFriendlyError =
                  'Too many attempts. Please wait a few minutes and try again.';
            } else if (error.contains('quota-exceeded')) {
              userFriendlyError =
                  'SMS quota exceeded. Please use a test phone number or try again later.';
            }

            setState(() {
              _errorMessage = userFriendlyError;
              _isLoading = false;
            });
          }
        },
        onAutoVerified: (credential) {
          // Auto-verification happened (Android)
          // For registration flow, we'll handle this in the verification step
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to send verification code. Please try again.\n\nError: ${e.toString()}';
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  size: 40,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Enter your phone number',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'We\'ll send you a verification code to confirm your number.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // Phone Number field with country code selector
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country code selector
                InkWell(
                  onTap: _showCountryPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCountry.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCountry.dialCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Phone number input
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                    validator: _validatePhone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleNext(),
                  ),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
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

            const SizedBox(height: 32),

            // Next button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Send Verification Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Privacy note
            Center(
              child: Text(
                'Your phone number will be kept private',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
