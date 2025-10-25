// lib/screens/animal_map_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pawscare/services/location_service.dart';
import 'package:pawscare/screens/pet_detail_screen.dart';
import 'package:pawscare/constants/animal_status.dart';

// --- THEME CONSTANTS ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kPrimaryAccentColor = Colors.amber;
const Color kCardColor = Color(0xFF1E1E1E);

class AnimalMapScreen extends StatefulWidget {
  const AnimalMapScreen({super.key});

  @override
  State<AnimalMapScreen> createState() => _AnimalMapScreenState();
}

class _AnimalMapScreenState extends State<AnimalMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;
  List<Map<String, dynamic>> _animals = [];

  // Default camera position (centered on India)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629), // Center of India
    zoom: 5,
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);

    try {
      // Get current location
      final hasPermission = await LocationService.hasLocationPermission();
      if (hasPermission) {
        _currentPosition = await LocationService.getCurrentLocation();
      }

      // Fetch animals from Firestore
      await _fetchAnimals();

      // Create markers
      await _createMarkers();
    } catch (e) {
      print('Error initializing map: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading map: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAnimals() async {
    try {
      print('DEBUG: Fetching animals for map...');
      final snapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('status', isEqualTo: AnimalStatus.available)
          .where('approvalStatus', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true)
          .get();

      _animals = snapshot.docs.map((doc) {
        final data = doc.data();
        print(
          'DEBUG: Animal ${doc.id}: ${data['name']}, lat: ${data['latitude']}, lng: ${data['longitude']}',
        );
        return {'id': doc.id, ...data};
      }).toList();

      print('DEBUG: Fetched ${_animals.length} animals for map');
    } catch (e) {
      print('Error fetching animals: $e');
      _animals = [];
    }
  }

  Future<void> _createMarkers() async {
    final Set<Marker> markers = {};

    print('DEBUG: Creating markers for ${_animals.length} animals');

    // Add marker for current location if available
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
        ),
      );
      print('DEBUG: Added current location marker');
    }

    // Add markers for each animal with valid coordinates
    int validAnimals = 0;
    int invalidAnimals = 0;

    for (var animal in _animals) {
      final lat = animal['latitude'] as double?;
      final lng = animal['longitude'] as double?;

      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        validAnimals++;
        final animalId = animal['id'] as String;
        final name = animal['name'] as String? ?? 'Unknown';
        final species = animal['species'] as String? ?? 'Animal';
        final gender = animal['gender'] as String? ?? '';
        final age = animal['age'] as String? ?? '';

        print('DEBUG: Adding marker for $name at ($lat, $lng)');

        // Choose marker color based on species
        double hue = BitmapDescriptor.hueRed;
        if (species.toLowerCase() == 'dog') {
          hue = BitmapDescriptor.hueOrange;
        } else if (species.toLowerCase() == 'cat') {
          hue = BitmapDescriptor.hueViolet;
        }

        markers.add(
          Marker(
            markerId: MarkerId(animalId),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title: name,
              snippet: '$species • $gender • $age',
              onTap: () => _showAnimalDetails(animal),
            ),
            onTap: () => _showAnimalBottomSheet(animal),
          ),
        );
      } else {
        invalidAnimals++;
        final name = animal['name'] as String? ?? 'Unknown';
        print(
          'DEBUG: Skipping $name - invalid coordinates (lat: $lat, lng: $lng)',
        );
      }
    }

    print(
      'DEBUG: Created ${markers.length} markers ($validAnimals valid animals, $invalidAnimals invalid)',
    );

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });

    // Move camera to show all markers or user location
    if (_mapController != null && _markers.isNotEmpty) {
      _fitMapToMarkers();
    }
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    // Calculate bounds to fit all markers
    double? minLat, maxLat, minLng, maxLng;

    for (var marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = minLat == null ? lat : (lat < minLat ? lat : minLat);
      maxLat = maxLat == null ? lat : (lat > maxLat ? lat : maxLat);
      minLng = minLng == null ? lng : (lng < minLng ? lng : minLng);
      maxLng = maxLng == null ? lng : (lng > maxLng ? lng : maxLng);
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } else if (_currentPosition != null) {
      // Fallback to user location
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 12,
          ),
        ),
      );
    }
  }

  void _showAnimalDetails(Map<String, dynamic> animal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PetDetailScreen(petData: animal)),
    );
  }

  void _showAnimalBottomSheet(Map<String, dynamic> animal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnimalInfoSheet(
        animal: animal,
        onViewDetails: () {
          Navigator.pop(context);
          _showAnimalDetails(animal);
        },
        currentPosition: _currentPosition,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Apply dark theme to map if needed
    // controller.setMapStyle('''[{"elementType":"geometry","stylers":[{"color":"#212121"}]}]''');

    if (_markers.isNotEmpty) {
      _fitMapToMarkers();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              title: const Text(
                'Animals Near You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.black.withOpacity(0.25),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                if (_currentPosition != null)
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: () {
                      if (_mapController != null && _currentPosition != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              zoom: 12,
                            ),
                          ),
                        );
                      }
                    },
                    tooltip: 'My Location',
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    _initializeMap();
                  },
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Container(
              color: kBackgroundColor,
              child: const Center(
                child: CircularProgressIndicator(color: kPrimaryAccentColor),
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: _initialPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                ),

                // Legend
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Legend',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildLegendItem(Colors.orange, 'Dogs'),
                              _buildLegendItem(Colors.purple, 'Cats'),
                              _buildLegendItem(Colors.red, 'Others'),
                              _buildLegendItem(Colors.blue, 'Your Location'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Animal count
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.pets,
                                color: kPrimaryAccentColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_markers.length - (_currentPosition != null ? 1 : 0)} animals available for adoption',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AnimalInfoSheet extends StatelessWidget {
  final Map<String, dynamic> animal;
  final VoidCallback onViewDetails;
  final Position? currentPosition;

  const _AnimalInfoSheet({
    required this.animal,
    required this.onViewDetails,
    this.currentPosition,
  });

  String _getDistance() {
    if (currentPosition == null) return '';

    final lat = animal['latitude'] as double?;
    final lng = animal['longitude'] as double?;

    if (lat == null || lng == null) return '';

    final distance = LocationService.calculateDistance(
      currentPosition!.latitude,
      currentPosition!.longitude,
      lat,
      lng,
    );

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m away';
    } else {
      return '${distance.toStringAsFixed(1)} km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = animal['name'] as String? ?? 'Unknown';
    final species = animal['species'] as String? ?? 'Animal';
    final gender = animal['gender'] as String? ?? '';
    final age = animal['age'] as String? ?? '';
    final breed = animal['breed'] as String? ?? '';

    // Get first image from imageUrls array
    String? imageUrl;
    final imageUrls = animal['imageUrls'];
    if (imageUrls != null && imageUrls is List && imageUrls.isNotEmpty) {
      imageUrl = imageUrls[0] as String?;
    }

    final distance = _getDistance();

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Animal image
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.pets,
                            size: 60,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                // Animal info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$species${breed.isNotEmpty ? ' • $breed' : ''}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (gender.isNotEmpty) _buildChip(gender),
                              if (age.isNotEmpty) _buildChip(age),
                              if (distance.isNotEmpty)
                                _buildChip(
                                  distance,
                                  color: kPrimaryAccentColor,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // View details button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryAccentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Full Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey[700])?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (color ?? Colors.grey[600])!.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
