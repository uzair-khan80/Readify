import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookishSplashScreen extends StatefulWidget {
  const BookishSplashScreen({super.key});

  @override
  State<BookishSplashScreen> createState() => _BookishSplashScreenState();
}

class _BookishSplashScreenState extends State<BookishSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pageFlipAnimation;
  late Animation<double> _textRevealAnimation;
  late Animation<Color?> _shelfGrowAnimation;

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Book page flip animation
    _pageFlipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    // Text reveal animation
    _textRevealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Bookshelf growth animation
    _shelfGrowAnimation = ColorTween(
      begin: const Color(0xFF6B21A8).withOpacity(0.3),
      end: const Color(0xFF6B21A8),
    ).animate(_controller);

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1E1E), const Color(0xFF0D0D0D)]
                : [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Book with Page Flip
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Book Cover
                      Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B21A8),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                      
                      // Page Flip Effect
                      Transform(
                        alignment: Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..rotateY(_pageFlipAnimation.value * pi),
                        child: Container(
                          width: 60,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // Text Reveal with Typewriter Effect
              AnimatedBuilder(
                animation: _textRevealAnimation,
                builder: (context, child) {
                  final text = "Readify";
                  final revealLength = (text.length * _textRevealAnimation.value).round();
                  
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [
                          const Color(0xFF6B21A8),
                          const Color(0xFF8B5CF6),
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      text.substring(0, revealLength),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Bookshelf Progress Indicator
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: BookshelfProgressPainter(
                      progress: _controller.value,
                      color: _shelfGrowAnimation.value!,
                    ),
                    size: const Size(150, 40),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookshelfProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  BookshelfProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw bookshelf with books
    final shelfHeight = size.height;
    final shelfWidth = size.width;
    
    // Shelf base
    canvas.drawLine(
      Offset(0, shelfHeight),
      Offset(shelfWidth * progress, shelfHeight),
      paint,
    );

    // Books on shelf (simplified)
    for (double i = 0; i < shelfWidth * progress; i += 25) {
      final bookHeight = 15 + (i % 20); // Varying heights
      canvas.drawRect(
        Rect.fromPoints(
          Offset(i, shelfHeight - bookHeight),
          Offset(i + 15, shelfHeight),
        ),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}