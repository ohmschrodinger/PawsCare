/// Model for contact information stored in Firestore
/// Collection: contact_info
/// Document: info
class ContactInfo {
  final String pawscareEmail;
  final String pawscareInsta;
  final String pawscareLinkedin;
  final String pawscareWhatsapp;
  final String pawscareVolunteerform;

  final String developer1Linkedin;
  final String developer1Github;
  final String developer1Name;
  final String developer1Role;

  final String developer2Linkedin;
  final String developer2Github;
  final String developer2Name;
  final String developer2Role;

  final String developer3Linkedin;
  final String developer3Github;
  final String developer3Name;
  final String developer3Role;

  ContactInfo({
    required this.pawscareEmail,
    required this.pawscareInsta,
    required this.pawscareLinkedin,
    required this.pawscareWhatsapp,
    required this.pawscareVolunteerform,
    required this.developer1Linkedin,
    required this.developer1Github,
    required this.developer1Name,
    required this.developer1Role,
    required this.developer2Linkedin,
    required this.developer2Github,
    required this.developer2Name,
    required this.developer2Role,
    required this.developer3Linkedin,
    required this.developer3Github,
    required this.developer3Name,
    required this.developer3Role,
  });

  /// Create ContactInfo from Firestore document
  factory ContactInfo.fromMap(Map<String, dynamic> data) {
    return ContactInfo(
      pawscareEmail: data['pawscare_email'] ?? '',
      pawscareInsta: data['pawscare_insta'] ?? '',
      pawscareLinkedin: data['pawscare_linkedin'] ?? '',
      pawscareWhatsapp: data['pawscare_whatsapp'] ?? '',
      pawscareVolunteerform: data['pawscare_volunteerform'] ?? '',
      developer1Linkedin: data['developer1_linkedin'] ?? '',
      developer1Github: data['developer1_github'] ?? '',
      developer1Name: data['developer1_name'] ?? 'Developer',
      developer1Role: data['developer1_role'] ?? 'Developer',
      developer2Linkedin: data['developer2_linkedin'] ?? '',
      developer2Github: data['developer2_github'] ?? '',
      developer2Name: data['developer2_name'] ?? 'Developer',
      developer2Role: data['developer2_role'] ?? 'Developer',
      developer3Linkedin: data['developer3_linkedin'] ?? '',
      developer3Github: data['developer3_github'] ?? '',
      developer3Name: data['developer3_name'] ?? 'Developer',
      developer3Role: data['developer3_role'] ?? 'Developer',
    );
  }

  /// Convert ContactInfo to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'pawscare_email': pawscareEmail,
      'pawscare_insta': pawscareInsta,
      'pawscare_linkedin': pawscareLinkedin,
      'pawscare_whatsapp': pawscareWhatsapp,
      'pawscare_volunteerform': pawscareVolunteerform,
      'developer1_linkedin': developer1Linkedin,
      'developer1_github': developer1Github,
      'developer1_name': developer1Name,
      'developer1_role': developer1Role,
      'developer2_linkedin': developer2Linkedin,
      'developer2_github': developer2Github,
      'developer2_name': developer2Name,
      'developer2_role': developer2Role,
      'developer3_linkedin': developer3Linkedin,
      'developer3_github': developer3Github,
      'developer3_name': developer3Name,
      'developer3_role': developer3Role,
    };
  }
}
