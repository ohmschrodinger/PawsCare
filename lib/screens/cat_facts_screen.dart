import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pawscare/services/cat_facts_service.dart';
import '../constants/app_colors.dart'; // Ensure this path is correct

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

  // Cache for facts and images
  final List<Map<String, String>> _cache = [];
  int _currentIndex = 0;
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Preload 3 facts and images
      final futures = List.generate(
        3,
        (_) => CatFactsService.getCatFactAndImage(),
      );
      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _cache.addAll(results);
          _currentIndex = 0;
          _currentFact = _cache[0]['fact'] ?? 'No fact available';
          _currentImageUrl =
              _cache[0]['imageUrl'] ?? 'https://via.placeholder.com/400';
          _isLoading = false;
        });

        // Precache the images
        for (var item in _cache) {
          if (item['imageUrl'] != null) {
            precacheImage(NetworkImage(item['imageUrl']!), context);
          }
        }
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

  Future<void> _fetchNewCatFact() async {
    if (_cache.isEmpty) {
      _initializeCache();
      return;
    }

    // Move to next cached item
    _currentIndex++;

    // If we've used all cached items, wrap around but ensure we have fresh content
    if (_currentIndex >= _cache.length) {
      _currentIndex = 0;
      // Clear old cache and reload fresh facts
      _cache.clear();
      _initializeCache();
      return;
    }

    setState(() {
      _currentFact = _cache[_currentIndex]['fact'] ?? 'No fact available';
      _currentImageUrl =
          _cache[_currentIndex]['imageUrl'] ??
          'https://via.placeholder.com/400';
    });

    // Preload new fact to maintain buffer
    if (!_isPreloading) {
      _preloadNextFact();
    }
  }

  Future<void> _preloadNextFact() async {
    _isPreloading = true;
    try {
      final data = await CatFactsService.getCatFactAndImage();
      if (mounted) {
        setState(() {
          _cache.add(data);
        });

        // Precache the new image
        if (data['imageUrl'] != null) {
          precacheImage(NetworkImage(data['imageUrl']!), context);
        }
      }
    } catch (e) {
      print('Failed to preload: $e');
    } finally {
      _isPreloading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Cat Facts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. DYNAMIC BACKGROUND LAYER
          // We use the current cat image as the background, blurred heavily.
          // This ensures the background color always matches the content.
          Positioned.fill(
            child: _currentImageUrl.isNotEmpty
                ? Image.network(
                    _currentImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.black),
                  )
                : Container(color: Colors.black),
          ),
          // Dark Overlay to ensure text readability
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),

          // 2. MAIN CONTENT
          SafeArea(
            child: _isLoading && _currentFact.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _errorMessage.isNotEmpty
                ? _buildErrorView()
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              // Subtitle
                              Text(
                                'Daily dose of feline wisdom',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // The "Card Stack"
                              _buildOverlappingCards(),

                              const SizedBox(height: 100), // Space for FAB
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      // 3. FLOATING ACTION BUTTON (More modern placement)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildModernFab(),
    );
  }

  Widget _buildOverlappingCards() {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // --- LAYER 1: THE IMAGE ---
        Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Image.network(
                    _currentImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.white.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // --- LAYER 2: THE FACT CARD (Overlapping) ---
        // We use margin to push it down, so it sits on top of the bottom of the image
        Container(
          margin: const EdgeInsets.only(top: 320), // This creates the overlap
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decorative Quote Icon Background
                    Stack(
                      children: [
                        // Fact Text
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _currentFact,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),

                    // Social Row (Share, Copy icons)
                    Divider(color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialButton(Icons.share_outlined, "Share"),
                        // The Divider
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.white.withOpacity(0.1),
                        ),

                        // The New Smart Copy Button
                        CopyButton(contentToCopy: _currentFact),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return InkWell(
      onTap: () => _handleSocialAction(label),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSocialAction(String action) {
    if (action == "Copy") {
      Clipboard.setData(ClipboardData(text: _currentFact));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fact copied to clipboard!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (action == "Share") {
      Share.share(_currentFact, subject: 'Cat Fact');
    }
  }

  Widget _buildModernFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _fetchNewCatFact,
                borderRadius: BorderRadius.circular(60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'New Fact',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.32,
                            color: kPrimaryTextColor,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializeCache,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class CopyButton extends StatefulWidget {
  final String contentToCopy;

  const CopyButton({super.key, required this.contentToCopy});

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _isCopied = false;

  void _handleCopy() {
    // 1. Copy to clipboard
    Clipboard.setData(ClipboardData(text: widget.contentToCopy));

    // 2. Change state to "Copied"
    setState(() => _isCopied = true);

    // 3. Revert back after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleCopy,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        // AnimatedSwitcher makes the icon/text change buttery smooth
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _isCopied
              ? Row(
                  key: const ValueKey('copied'),
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: Colors.greenAccent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Copied",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('copy'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Copy",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
