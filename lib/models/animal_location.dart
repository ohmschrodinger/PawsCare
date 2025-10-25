// lib/models/animal_location.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalLocation {
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? formattedAddress;

  AnimalLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.formattedAddress,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      'formattedAddress': formattedAddress ?? address,
      'geopoint': GeoPoint(latitude, longitude),
    };
  }

  // Create from Firestore Map
  factory AnimalLocation.fromMap(Map<String, dynamic> map) {
    // Handle both old format (string location) and new format
    if (map.containsKey('latitude') && map.containsKey('longitude')) {
      return AnimalLocation(
        address: map['address'] ?? map['formattedAddress'] ?? '',
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        placeId: map['placeId'],
        formattedAddress: map['formattedAddress'],
      );
    } else if (map.containsKey('geopoint')) {
      final GeoPoint geopoint = map['geopoint'] as GeoPoint;
      return AnimalLocation(
        address: map['address'] ?? map['formattedAddress'] ?? '',
        latitude: geopoint.latitude,
        longitude: geopoint.longitude,
        placeId: map['placeId'],
        formattedAddress: map['formattedAddress'],
      );
    } else {
      // Fallback for old data - return a default location
      return AnimalLocation(
        address: map['address'] ?? 'Unknown Location',
        latitude: 0.0,
        longitude: 0.0,
      );
    }
  }

  // Create from plain string (for backward compatibility)
  factory AnimalLocation.fromString(String address) {
    return AnimalLocation(address: address, latitude: 0.0, longitude: 0.0);
  }

  bool get hasCoordinates => latitude != 0.0 && longitude != 0.0;

  @override
  String toString() => formattedAddress ?? address;
}
