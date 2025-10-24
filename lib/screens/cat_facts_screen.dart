import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pawscare/services/cat_facts_service.dart';

// Theme constants matching home screen
const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryAccentColor = Colors.amber;
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFFB0B0B0);

class CatFactsScreen extends StatefulWidget {
  const CatFactsScreen({super.key});

  @override
  State<CatFactsScreen> createState() => _CatFactsScreenState();
}

class _CatFactsScreenState extends State<CatFactsScreen> {
  String _currentFact = '';
  String _currentImageUrl = '';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchNewCatFact();
  }

  Future<void> _fetchNewCatFact() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await CatFactsService.getCatFactAndImage();

      if (mounted) {
        setState(() {
          _currentFact = data['fact'] ?? 'No fact available';
          _currentImageUrl =
              data['imageUrl'] ?? 'https://via.placeholder.com/400';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load cat facts. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Cat Facts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background image layer
          Positioned.fill(
            child: Image.asset(
              'assets/images/catfacts.jpeg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.2),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),

          // Main content
          SafeArea(
            // --- MODIFICATION START ---
            // Show full-screen loader ONLY on the initial load.
            child: (_isLoading && _currentFact.isEmpty)
                ? const Center(
                    child: CircularProgressIndicator(
                      color: kPrimaryAccentColor,
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            _buildNewFactButton(),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Top content grouped together
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 12),
                                        _buildHeaderSection(),
                                        const SizedBox(height: 24),
                                        _buildCatImageCard(),
                                        const SizedBox(height: 24),
                                        _buildCatFactCard(),
                                      ],
                                    ),
                                    // Button pushed to the bottom
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 32, bottom: 24),
                                      child: _buildNewFactButton(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            // --- MODIFICATION END ---
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Did You Know?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kPrimaryTextColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Learn fascinating facts about our feline friends',
          style: TextStyle(fontSize: 15, color: kSecondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildCatImageCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: kCardColor,
        ),
        // --- MODIFICATION START ---
        // Show loader inside the card when fetching a new image.
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryAccentColor),
              )
            : Image.network(
                _currentImageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: kPrimaryAccentColor,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: kCardColor,
                    child: const Center(
                      child: Icon(
                        Icons.pets,
                        size: 80,
                        color: kSecondaryTextColor,
                      ),
                    ),
                  );
                },
              ),
        // --- MODIFICATION END ---
      ),
    );
  }

  Widget _buildCatFactCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCardColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.lightbulb_outline,
                    color: kPrimaryAccentColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Cat Fact',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // --- MODIFICATION START ---
              // Show an inline loader or the fact text.
              _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: kPrimaryAccentColor,
                        ),
                      ),
                    )
                  : Text(
                      _currentFact,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: kPrimaryTextColor,
                      ),
                    ),
              // --- MODIFICATION END ---
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewFactButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.blue.withOpacity(0.4), width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _fetchNewCatFact,
              borderRadius: BorderRadius.circular(50),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading &&
                        _errorMessage.isEmpty) // Show only on button press
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.refresh, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      _isLoading && _errorMessage.isEmpty
                          ? 'Loading...'
                          : 'New Fact',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}