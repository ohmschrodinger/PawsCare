import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum to track verification status
enum VerificationStatus { notVerified, verified }

/// User model class representing a user in the PawsCare application
class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? address;
  final String role;
  final bool isActive;
  final bool profileCompleted;

  // Verification status fields
  final bool isEmailVerified;
  final bool isPhoneVerified;

  // Sign-in method tracking
  final String signInMethod; // 'email', 'phone', 'google'

  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.address,
    this.role = 'user',
    this.isActive = true,
    this.profileCompleted = false,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.signInMethod = 'email',
    this.createdAt,
    this.updatedAt,
  });

  /// Get full name by combining first and last name
  String get fullName => '$firstName $lastName'.trim();

  /// Check if user has completed all required verifications
  bool get isFullyVerified {
    // Google users don't need phone verification
    if (signInMethod == 'google') {
      return isEmailVerified;
    }
    // Email/phone sign-up requires both verifications
    return isEmailVerified && isPhoneVerified;
  }

  /// Check if user can access the app
  bool get canAccessApp {
    return isFullyVerified && isActive;
  }

  /// Factory constructor to create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      role: data['role'] ?? 'user',
      isActive: data['isActive'] ?? true,
      profileCompleted: data['profileCompleted'] ?? false,
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      signInMethod: data['signInMethod'] ?? 'email',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Factory constructor to create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      role: data['role'] ?? 'user',
      isActive: data['isActive'] ?? true,
      profileCompleted: data['profileCompleted'] ?? false,
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      signInMethod: data['signInMethod'] ?? 'email',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'address': address,
      'role': role,
      'isActive': isActive,
      'profileCompleted': profileCompleted,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'signInMethod': signInMethod,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    String? role,
    bool? isActive,
    bool? profileCompleted,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? signInMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      signInMethod: signInMethod ?? this.signInMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, fullName: $fullName, phoneNumber: $phoneNumber, '
        'isEmailVerified: $isEmailVerified, isPhoneVerified: $isPhoneVerified, '
        'signInMethod: $signInMethod, canAccessApp: $canAccessApp)';
  }
}
