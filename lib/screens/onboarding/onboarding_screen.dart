import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> onboardingData = [
    {
      'image': 'assets/onboard1.png',
      'title': 'Discover New Books',
      'subtitle': 'Explore thousands of titles across all genres with our intelligent recommendation system.',
    },
    {
      'image': 'assets/onboard2.png',
      'title': 'Read Anywhere',
      'subtitle': 'Your entire library fits in your pocket. Read offline anytime, anywhere.',
    },
    {
      'image': 'assets/onboard3.png',
      'title': 'Shop Easily',
      'subtitle': 'Secure, one-tap purchases with instant delivery to your device.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0A0E21), const Color(0xFF1D1A31)]
                : [const Color(0xFFF8F4FF), const Color(0xFFE8EFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Theme Toggle
                    IconButton(
                      onPressed: () => themeProvider.toggleTheme(),
                      icon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: isDark ? Colors.amber : Colors.deepPurple,
                        size: 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? Colors.white12 : Colors.deepPurple.withOpacity(0.1),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    
                    // Skip Button
                    if (_currentPage < onboardingData.length - 1)
                      TextButton(
                        onPressed: _navigateToLogin,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.deepPurple.withOpacity(0.8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: List.generate(
                    onboardingData.length,
                    (index) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: _currentPage == index
                              ? Colors.deepPurpleAccent
                              : (isDark ? Colors.white24 : Colors.grey.withOpacity(0.3)),
                          boxShadow: _currentPage == index
                              ? [
                                  BoxShadow(
                                    color: Colors.deepPurpleAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Page Content
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardingData.length,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final data = onboardingData[index];
                    return AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - _fadeAnimation.value) * 20),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated Illustration Container
                            Hero(
                              tag: 'onboard_$index',
                              child: Container(
                                width: screenWidth * 0.7,
                                height: screenWidth * 0.7,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? [Colors.deepPurple.withOpacity(0.3), Colors.deepPurpleAccent.withOpacity(0.1)]
                                        : [Colors.deepPurple.withOpacity(0.1), Colors.deepPurpleAccent.withOpacity(0.05)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.deepPurple.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Image.asset(
                                        data['image']!,
                                        height: screenWidth * 0.5,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 48),

                            // Title with fade animation
                            AnimatedOpacity(
                              opacity: _currentPage == index ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                data['title']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Subtitle with staggered animation
                            AnimatedOpacity(
                              opacity: _currentPage == index ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 700),
                              child: Text(
                                data['subtitle']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Navigation Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    onPressed: _currentPage == onboardingData.length - 1 
                        ? _navigateToLogin
                        : () {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.deepPurpleAccent.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == onboardingData.length - 1 
                                ? 'Get Started' 
                                : 'Continue',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_currentPage < onboardingData.length - 1) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}