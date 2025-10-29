// lib/screens/animal_adoption_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawscare/services/animal_service.dart';
import 'package:pawscare/widgets/animal_card.dart';
import 'package:pawscare/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pawscare/screens/animal_map_screen.dart';
import 'package:pawscare/constants/app_colors.dart';

class AnimalAdoptionScreen extends StatefulWidget {
  const AnimalAdoptionScreen({super.key});

  @override
  State<AnimalAdoptionScreen> createState() => _AnimalAdoptionScreenState();
}

class _AnimalAdoptionScreenState extends State<AnimalAdoptionScreen> {
  String _sortBy = 'postedAt';
  String _speciesFilter = 'All';
  String _genderFilter = 'All';
  String _ageFilter = 'All';
  Position? _currentPosition;
  bool _hasActiveFilters = false;

  void _openFilterSheet() async {
    print(
      'Opening filter sheet with current values - Sort: $_sortBy, Species: $_speciesFilter, Gender: $_genderFilter, Age: $_ageFilter',
    );
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _FilterSheet(
          currentSort: _sortBy,
          currentSpecies: _speciesFilter,
          currentGender: _genderFilter,
          currentAge: _ageFilter,
        );
      },
    );

    if (result != null) {
      print('Filter result received: $result');
      setState(() {
        _sortBy = result['sortBy'] ?? _sortBy;
        _speciesFilter = result['species'] ?? _speciesFilter;
        _genderFilter = result['gender'] ?? _genderFilter;
        _ageFilter = result['age'] ?? _ageFilter;

        print(
          'Updated filters - Sort: $_sortBy, Species: $_speciesFilter, Gender: $_genderFilter, Age: $_ageFilter',
        );

        // Check if any filters are active
        _hasActiveFilters =
            _speciesFilter != 'All' ||
            _genderFilter != 'All' ||
            _ageFilter != 'All';
      });

      // If "Near Me" is selected, get current location
      if (_sortBy == 'nearMe' && _currentPosition == null) {
        _getCurrentLocation();
      }
    } else {
      print('Filter sheet was dismissed without applying changes');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final hasPermission = await LocationService.hasLocationPermission();

      if (!hasPermission) {
        final permission = await LocationService.requestPermission();

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Location permission is required for "Near Me" sorting',
                ),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => LocationService.openAppSettings(),
                ),
              ),
            );
          }
          setState(() => _sortBy = 'postedAt'); // Fallback to default
          return;
        }
      }

      final position = await LocationService.getCurrentLocation();

      if (position != null) {
        setState(() => _currentPosition = position);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get your location. Please try again.'),
            ),
          );
        }
        setState(() => _sortBy = 'postedAt'); // Fallback to default
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _sortBy = 'postedAt'); // Fallback to default
    }
  }

  // --- NEW CODE: START ---
  // New helper method to parse age strings like "2 Years, 5 Months" into a total number of months.
  int? _parseAgeToMonths(String ageString) {
    final ageText = ageString.toLowerCase();
    int totalMonths = 0;

    // RegExp to find the 'years' part and capture the number
    final RegExp yearRegExp = RegExp(r'(\d+)\s*year(s)?');
    final Match? yearMatch = yearRegExp.firstMatch(ageText);

    if (yearMatch != null) {
      // Found a 'year' value, parse it and convert to months
      final int years = int.parse(yearMatch.group(1)!);
      totalMonths += years * 12;
    }

    // RegExp to find the 'months' part and capture the number
    final RegExp monthRegExp = RegExp(r'(\d+)\s*month(s)?');
    final Match? monthMatch = monthRegExp.firstMatch(ageText);

    if (monthMatch != null) {
      // Found a 'month' value, parse it and add to the total
      final int months = int.parse(monthMatch.group(1)!);
      totalMonths += months;
    }

    // If no numbers were parsed at all, return null. Otherwise, return the calculated total.
    return totalMonths > 0 ? totalMonths : null;
  }

  // Helper method to check if an animal matches the selected age filter.
  // This now uses the robust _parseAgeToMonths helper for numerical comparison.
  bool _matchesAgeFilter(Map<String, dynamic> animal) {
    final ageString = animal['age'] as String?;
    if (ageString == null) return false;

    // Use our new helper to get a numerical age in months
    final int? ageInMonths = _parseAgeToMonths(ageString);
    if (ageInMonths == null) {
      // If parsing fails, don't include it in the filtered list
      return false;
    }

    switch (_ageFilter) {
      case 'Puppy/Kitten': // 0-1 year
        return ageInMonths <= 12;
      case 'Young': // 1-3 years
        return ageInMonths > 12 && ageInMonths <= 36;
      case 'Adult': // 3-7 years
        return ageInMonths > 36 && ageInMonths <= 84;
      case 'Senior': // 7+ years
        return ageInMonths > 84;
      default: // 'All'
        return true;
    }
  }
  // --- NEW CODE: END ---

  // Helper method to build filter chips
  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
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

  // Helper method to clear individual filters
  void _clearFilter(String filterType) {
    setState(() {
      switch (filterType) {
        case 'species':
          _speciesFilter = 'All';
          break;
        case 'gender':
          _genderFilter = 'All';
          break;
        case 'age':
          _ageFilter = 'All';
          break;
      }

      // Update active filters status
      _hasActiveFilters =
          _speciesFilter != 'All' ||
          _genderFilter != 'All' ||
          _ageFilter != 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- CHANGE 1: Allow the body to extend behind the AppBar ---
      extendBodyBehindAppBar: true,

      // --- CHANGE 2: Make the AppBar transparent ---
      appBar: AppBar(
        title: const Text(
          'Adopt Love',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent, // Set to transparent
        elevation: 0, // Remove shadow
        actions: [
          // Map view button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnimalMapScreen(),
                ),
              );
            },
            icon: const Icon(Icons.map, color: Colors.white),
            tooltip: 'Map View',
          ),
          // Filter button with indicator
          Stack(
            children: [
              IconButton(
                onPressed: _openFilterSheet,
                icon: const Icon(Icons.tune, color: Colors.white),
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      // --- CHANGE 3: Use a Stack for the layered background effect ---
      body: Stack(
        children: [
          // --- LAYER 1: The background image ---
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.2),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // --- LAYER 2: The blur overlay ---
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),

          // --- LAYER 3: Your original screen content, now inside a SafeArea ---
          SafeArea(
            child: Column(
              children: [
                // Filter chips display
                if (_hasActiveFilters) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_speciesFilter != 'All')
                            _buildFilterChip(
                              'Species: $_speciesFilter',
                              () => _clearFilter('species'),
                            ),
                          if (_genderFilter != 'All')
                            _buildFilterChip(
                              'Gender: $_genderFilter',
                              () => _clearFilter('gender'),
                            ),
                          if (_ageFilter != 'All')
                            _buildFilterChip(
                              'Age: $_ageFilter',
                              () => _clearFilter('age'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                // Main content
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: AnimalService.getAvailableAnimals(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Something went wrong',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: kPrimaryAccentColor,
                          ),
                        );
                      }

                      List<QueryDocumentSnapshot> animals =
                          snapshot.data?.docs ?? [];
                      final List<Map<String, dynamic>> animalList = animals.map(
                        (doc) {
                          return {
                            'id': doc.id,
                            ...(doc.data() as Map<String, dynamic>),
                          };
                        },
                      ).toList();

                      // Apply filters
                      List<Map<String, dynamic>> filtered = animalList.where((
                        a,
                      ) {
                        // Species filter
                        final speciesMatch =
                            _speciesFilter == 'All' ||
                            (a['species'] ?? '').toString().toLowerCase() ==
                                _speciesFilter.toLowerCase();

                        // Gender filter
                        final genderMatch =
                            _genderFilter == 'All' ||
                            (a['gender'] ?? '').toString().toLowerCase() ==
                                _genderFilter.toLowerCase();

                        // Age filter
                        final ageMatch =
                            _ageFilter == 'All' || _matchesAgeFilter(a);

                        // Debug print to help troubleshoot (only for first animal to avoid spam)
                        if (animalList.indexOf(a) == 0) {
                          print(
                            'Sample Animal: ${a['name']}, Species: ${a['species']}, Gender: ${a['gender']}, Status: ${a['status']}, Approval: ${a['approvalStatus']}, Active: ${a['isActive']}',
                          );
                          print(
                            'Current Filters - Species: $_speciesFilter, Gender: $_genderFilter, Age: $_ageFilter',
                          );
                        }

                        return speciesMatch && genderMatch && ageMatch;
                      }).toList();

                      // Apply sorting
                      if (_sortBy == 'name') {
                        filtered.sort(
                          (a, b) => (a['name'] ?? '')
                              .toString()
                              .toLowerCase()
                              .compareTo(
                                (b['name'] ?? '').toString().toLowerCase(),
                              ),
                        );
                      } else if (_sortBy == 'nearMe') {
                        // Sort by distance from current location
                        if (_currentPosition != null) {
                          filtered.sort((a, b) {
                            final aLat = a['latitude'] as double?;
                            final aLng = a['longitude'] as double?;
                            final bLat = b['latitude'] as double?;
                            final bLng = b['longitude'] as double?;

                            if (aLat == null || aLng == null) return 1;
                            if (bLat == null || bLng == null) return -1;

                            final distanceA = LocationService.calculateDistance(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                              aLat,
                              aLng,
                            );

                            final distanceB = LocationService.calculateDistance(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                              bLat,
                              bLng,
                            );

                            return distanceA.compareTo(distanceB);
                          });
                        } else {
                          // If location not available, fall back to recent
                          filtered.sort((a, b) {
                            final aTime = a['postedAt'] as Timestamp?;
                            final bTime = b['postedAt'] as Timestamp?;
                            if (aTime == null && bTime == null) return 0;
                            if (aTime == null) return 1;
                            if (bTime == null) return -1;
                            return bTime.compareTo(aTime);
                          });
                        }
                      } else {
                        filtered.sort((a, b) {
                          final aTime = a['postedAt'] as Timestamp?;
                          final bTime = b['postedAt'] as Timestamp?;
                          if (aTime == null && bTime == null) return 0;
                          if (aTime == null) return 1;
                          if (bTime == null) return -1;
                          return bTime.compareTo(aTime); // Descending
                        });
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16.0,
                                        12.0,
                                        16.0,
                                        12.0,
                                      ),
                                      child: const Text(
                                        'Pets available for adoption',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (filtered.isEmpty)
                                      Expanded(
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 48.0,
                                              bottom: 90.0,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.pets_outlined,
                                                  size: 64,
                                                  color: kSecondaryTextColor
                                                      .withOpacity(0.5),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  _hasActiveFilters
                                                      ? 'No animals match your filters.'
                                                      : 'No animals available for adoption.',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: kSecondaryTextColor,
                                                  ),
                                                ),
                                                if (_hasActiveFilters) ...[
                                                  const SizedBox(height: 8),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _speciesFilter = 'All';
                                                        _genderFilter = 'All';
                                                        _ageFilter = 'All';
                                                        _hasActiveFilters =
                                                            false;
                                                      });
                                                    },
                                                    child: const Text(
                                                      'Clear all filters',
                                                      style: TextStyle(
                                                        color:
                                                            kPrimaryAccentColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      ...filtered.map((animalData) {
                                        return AnimalCard(
                                          animal: animalData,
                                          isLiked:
                                              false, // You'll likely connect this to a state management solution
                                          isSaved:
                                              false, // You'll likely connect this to a state management solution
                                          likeCount:
                                              (animalData['likeCount']
                                                  as int?) ??
                                              0,
                                          onLike: () {},
                                          onSave: () {},
                                        );
                                      }).toList(),
                                    if (filtered.isNotEmpty)
                                      const SizedBox(
                                        height: 90,
                                      ), // Padding for floating navigation bar if any
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String currentSort;
  final String currentSpecies;
  final String currentGender;
  final String currentAge;

  const _FilterSheet({
    required this.currentSort,
    required this.currentSpecies,
    required this.currentGender,
    required this.currentAge,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String localSort;
  late String localSpecies;
  late String localGender;
  late String localAge;

  @override
  void initState() {
    super.initState();
    localSort = widget.currentSort;
    localSpecies = widget.currentSpecies;
    localGender = widget.currentGender;
    localAge = widget.currentAge;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardColor.withOpacity(0.25),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: ListView(
                controller: controller,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sort by',
                    style: TextStyle(color: kSecondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: DropdownButtonFormField<String>(
                        value: localSort,
                        items: const [
                          DropdownMenuItem(
                            value: 'postedAt',
                            child: Text('Recently Added'),
                          ),
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('Name (A-Z)'),
                          ),
                          DropdownMenuItem(
                            value: 'nearMe',
                            child: Text('Near Me'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => localSort = v ?? 'postedAt'),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue.withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownColor: Colors.black.withOpacity(0.8),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Species',
                    style: TextStyle(color: kSecondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: DropdownButtonFormField<String>(
                        value: localSpecies,
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All Species'),
                          ),
                          DropdownMenuItem(value: 'Dog', child: Text('Dogs')),
                          DropdownMenuItem(value: 'Cat', child: Text('Cats')),
                        ],
                        onChanged: (v) =>
                            setState(() => localSpecies = v ?? 'All'),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue.withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownColor: Colors.black.withOpacity(0.8),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gender',
                    style: TextStyle(color: kSecondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: DropdownButtonFormField<String>(
                        value: localGender,
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('Any Gender'),
                          ),
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => localGender = v ?? 'All'),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue.withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownColor: Colors.black.withOpacity(0.8),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Age Range',
                    style: TextStyle(color: kSecondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: DropdownButtonFormField<String>(
                        value: localAge,
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('Any Age'),
                          ),
                          DropdownMenuItem(
                            value: 'Puppy/Kitten',
                            child: Text('Puppy/Kitten (0-1 year)'),
                          ),
                          DropdownMenuItem(
                            value: 'Young',
                            child: Text('Young (1-3 years)'),
                          ),
                          DropdownMenuItem(
                            value: 'Adult',
                            child: Text('Adult (3-7 years)'),
                          ),
                          DropdownMenuItem(
                            value: 'Senior',
                            child: Text('Senior (7+ years)'),
                          ),
                        ],
                        onChanged: (v) => setState(() => localAge = v ?? 'All'),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue.withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownColor: Colors.black.withOpacity(0.8),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop({
                                      'sortBy': 'postedAt',
                                      'species': 'All',
                                      'gender': 'All',
                                      'age': 'All',
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(50),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text(
                                        'Clear All',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50.0),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    print(
                                      'Applying filters - Sort: $localSort, Species: $localSpecies, Gender: $localGender, Age: $localAge',
                                    );
                                    Navigator.of(context).pop({
                                      'sortBy': localSort,
                                      'species': localSpecies,
                                      'gender': localGender,
                                      'age': localAge,
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(50.0),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Apply Filters',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
