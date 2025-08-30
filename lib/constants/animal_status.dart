/// Constants for animal status values in Firestore
class AnimalStatus {
  /// Status for animals that can be adopted
  static const String available = 'Available for Adoption';

  /// Status for animals that have been adopted
  static const String adopted = 'Adopted';

  /// Status for animals with pending adoption requests
  static const String pending = 'Pending Adoption';

  /// List of all valid statuses
  static const List<String> validStatuses = [available, adopted, pending];
}
