import 'package:flutter/material.dart';

/// Entry Point Screen - The landing page when user is not signed in
/// Shows "Get Started" button and "Sign In" text link
class EntryPointScreen extends StatefulWidget {
  const EntryPointScreen({super.key});

  @override
  State<EntryPointScreen> createState() => _EntryPointScreenState();
}

class _EntryPointScreenState extends State<EntryPointScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _floatController;
  late AnimationController _catController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _catAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _catController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _catAnimation = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(CurvedAnimation(parent: _catController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _floatController.dispose();
    _catController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F4F8), Color(0xFFF0F8FF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background elements
              _buildBackgroundDecorations(),

              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated cat and paw icons
                      Column(
                        children: [
                          AnimatedBuilder(
                            animation: _catAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _catAnimation.value),
                                child: _buildCatIcon(),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _bounceAnimation.value),
                                child: _buildMainPawIcon(),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // App title and tagline
                      const Text(
                        'PawsCare',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2196F3),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Connecting Pets to Forever Homes',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),

                      // Get Started button
                      _buildGetStartedButton(),
                      const SizedBox(height: 24),

                      // Sign In text link
                      _buildSignInLink(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // Large blue sphere at lower-left
        Positioned(
          left: -120,
          bottom: -140,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.25,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.2, -0.2),
                    radius: 0.9,
                    colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Animated clouds
        Positioned(
          top: 40,
          left: 20,
          child: AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value * 0.4),
                child: Opacity(opacity: 0.55, child: const _Cloud(size: 90)),
              );
            },
          ),
        ),
        Positioned(
          bottom: 60,
          right: 24,
          child: AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value * -0.3),
                child: Opacity(opacity: 0.45, child: const _Cloud(size: 110)),
              );
            },
          ),
        ),

        // Floating paw prints
        Positioned(
          top: 100,
          right: 30,
          child: AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: _buildSmallPaw(Colors.blue.shade300, 0.3),
              );
            },
          ),
        ),
        Positioned(
          top: 150,
          left: 20,
          child: AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value * 0.7),
                child: _buildSmallPaw(Colors.green.shade300, 0.25),
              );
            },
          ),
        ),

        // Small decorative dots
        Positioned(
          top: 200,
          right: 60,
          child: AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value * 0.5),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade200.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 200,
          left: 40,
          child: AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value * -0.3),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGetStartedButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            Navigator.of(context).pushNamed('/get-started');
          },
          child: const Center(
            child: Text(
              'Get Started',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('/signin');
          },
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Color(0xFF2196F3),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainPawIcon() {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(painter: _PawPainter(Colors.blue)),
    );
  }

  Widget _buildCatIcon() {
    return SizedBox(
      width: 100,
      height: 80,
      child: CustomPaint(painter: _CatPainter(const Color(0xFF2196F3))),
    );
  }

  Widget _buildSmallPaw(Color color, double opacity) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(painter: _PawPainter(color)),
      ),
    );
  }
}

// Custom Painters (same as welcome screen)
class _PawPainter extends CustomPainter {
  final Color color;
  _PawPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.65),
        width: size.width * 0.36,
        height: size.height * 0.44,
      ),
      paint,
    );

    final lightPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.35),
        width: size.width * 0.16,
        height: size.height * 0.24,
      ),
      lightPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.3),
        width: size.width * 0.18,
        height: size.height * 0.26,
      ),
      lightPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.65, size.height * 0.35),
        width: size.width * 0.16,
        height: size.height * 0.24,
      ),
      lightPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.75, size.height * 0.5),
        width: size.width * 0.14,
        height: size.height * 0.2,
      ),
      lightPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _Cloud extends StatelessWidget {
  final double size;
  const _Cloud({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.6,
      child: CustomPaint(painter: _CloudPainter()),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = const Color(0xFF90CAF9).withOpacity(0.7);
    final lightColor = const Color(0xFFBBDEFB).withOpacity(0.8);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = baseColor;
    canvas.drawCircle(
      Offset(size.width * 0.30, size.height * 0.55),
      size.height * 0.25,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.45),
      size.height * 0.30,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.52),
      size.height * 0.22,
      paint,
    );

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.45,
        size.width * 0.64,
        size.height * 0.22,
      ),
      Radius.circular(size.height * 0.12),
    );
    canvas.drawRRect(rrect, paint);

    paint.color = lightColor;
    canvas.drawCircle(
      Offset(size.width * 0.48, size.height * 0.42),
      size.height * 0.20,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CatPainter extends CustomPainter {
  final Color color;
  _CatPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.55),
        width: size.width * 0.6,
        height: size.height * 0.6,
      ),
      paint,
    );

    // Ears
    Path leftEar = Path();
    leftEar.moveTo(size.width * 0.3, size.height * 0.35);
    leftEar.lineTo(size.width * 0.25, size.height * 0.1);
    leftEar.lineTo(size.width * 0.45, size.height * 0.25);
    leftEar.close();
    canvas.drawPath(leftEar, paint);

    Path rightEar = Path();
    rightEar.moveTo(size.width * 0.7, size.height * 0.35);
    rightEar.lineTo(size.width * 0.75, size.height * 0.1);
    rightEar.lineTo(size.width * 0.55, size.height * 0.25);
    rightEar.close();
    canvas.drawPath(rightEar, paint);

    // Eyes
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.4, size.height * 0.5),
        width: size.width * 0.08,
        height: size.height * 0.12,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.6, size.height * 0.5),
        width: size.width * 0.08,
        height: size.height * 0.12,
      ),
      eyePaint,
    );

    // Pupils
    final pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.4, size.height * 0.5),
        width: size.width * 0.04,
        height: size.height * 0.08,
      ),
      pupilPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.6, size.height * 0.5),
        width: size.width * 0.04,
        height: size.height * 0.08,
      ),
      pupilPaint,
    );

    // Nose
    final nosePaint = Paint()
      ..color = Colors.pink.shade300
      ..style = PaintingStyle.fill;

    Path nose = Path();
    nose.moveTo(size.width * 0.5, size.height * 0.6);
    nose.lineTo(size.width * 0.48, size.height * 0.65);
    nose.lineTo(size.width * 0.52, size.height * 0.65);
    nose.close();
    canvas.drawPath(nose, nosePaint);

    // Mouth
    final mouthPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    Path mouth = Path();
    mouth.moveTo(size.width * 0.5, size.height * 0.65);
    mouth.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.7,
      size.width * 0.42,
      size.height * 0.68,
    );
    canvas.drawPath(mouth, mouthPaint);

    mouth = Path();
    mouth.moveTo(size.width * 0.5, size.height * 0.65);
    mouth.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.7,
      size.width * 0.58,
      size.height * 0.68,
    );
    canvas.drawPath(mouth, mouthPaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.52),
      Offset(size.width * 0.35, size.height * 0.55),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.58),
      Offset(size.width * 0.35, size.height * 0.6),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.85, size.height * 0.52),
      Offset(size.width * 0.65, size.height * 0.55),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.58),
      Offset(size.width * 0.65, size.height * 0.6),
      whiskerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
