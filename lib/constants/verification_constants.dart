/// Constants related to user verification and authentication

class VerificationConstants {
  // Verification timeout durations
  static const int phoneVerificationTimeoutSeconds = 60;
  static const int emailVerificationCheckIntervalSeconds = 3;
  static const int maxEmailVerificationCheckAttempts = 20;

  // Error messages
  static const String phoneAlreadyExistsError =
      'This phone number is already registered. Please sign in instead.';
  static const String emailAlreadyExistsError =
      'This email is already registered. Please sign in instead.';
  static const String phoneVerificationRequiredError =
      'Phone verification is required to access the app.';
  static const String emailVerificationRequiredError =
      'Email verification is required to access the app.';
  static const String invalidPhoneNumberError =
      'Please enter a valid phone number.';
  static const String invalidVerificationCodeError =
      'Invalid verification code. Please try again.';
  static const String verificationCodeExpiredError =
      'Verification code has expired. Please request a new one.';
  static const String googleEmailConflictError =
      'An account with this email already exists. Please use a different sign-in method.';

  // Success messages
  static const String phoneVerifiedSuccess =
      'Phone number verified successfully!';
  static const String emailVerifiedSuccess = 'Email verified successfully!';
  static const String verificationCodeSentSuccess =
      'Verification code sent successfully!';

  // Info messages
  static const String checkEmailMessage =
      'Please check your email for the verification link.';
  static const String enterVerificationCodeMessage =
      'Enter the verification code sent to your phone.';

  // Sign-in method types
  static const String signInMethodEmail = 'email';
  static const String signInMethodPhone = 'phone';
  static const String signInMethodGoogle = 'google';

  // Phone number formatting
  static const String phoneNumberPrefix = '+1'; // Default US prefix
  static const int phoneNumberLength = 10; // Without country code

  // Regex patterns
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$', // E.164 format
  );
  static final RegExp phoneNumberOnlyDigits = RegExp(r'^\d{10}$');

  // Navigation routes (to be used in Phase 2-4)
  static const String entryPointRoute = '/entry-point';
  static const String getStartedRoute = '/get-started';
  static const String phoneVerificationRoute = '/phone-verification';
  static const String emailVerificationRoute = '/email-verification';
  static const String signInRoute = '/sign-in';
}
