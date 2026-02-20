// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/theme_provider.dart';
import '../../screens/admin/books_list_screen.dart';
import '../../screens/admin/manage_users_screen.dart';
import '../../screens/admin/admin_orders_screen.dart';
import '../../screens/admin/book_ratings_screen.dart';
import '../../screens/admin/manage_categories_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  bool _isSidebarExpanded = true;

  // Breakpoint constants for responsive design
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1200;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= tabletBreakpoint;

    // Theme colors
    final backgroundColor = isDark ? const Color(0xFF0F1724) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? Colors.grey[850]! : Colors.white;
    final primaryColor = isDark ? Colors.deepPurpleAccent : Colors.deepPurple;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            // Desktop sidebar - only show on larger screens
            if (!isMobile)
              _buildDesktopSidebar(
                isDark: isDark,
                cardColor: cardColor,
                primaryColor: primaryColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),
            
            // Main content area
            Expanded(
              child: Column(
                children: [
                  _buildAppBar(
                    isDark: isDark,
                    textColor: textColor,
                    primaryColor: primaryColor,
                    themeProvider: themeProvider,
                    isMobile: isMobile,
                  ),
                  Expanded(
                    child: _currentIndex == 0
                        ? _buildDashboardContent(
                            cardColor: cardColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            primaryColor: primaryColor,
                          )
                        : _getSelectedScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Mobile bottom navigation
      bottomNavigationBar: isMobile 
          ? _buildBottomNavigationBar(primaryColor, textColor, cardColor)
          : null,
    );
  }

  // ---------------- Desktop Sidebar ----------------
  Widget _buildDesktopSidebar({
    required bool isDark,
    required Color cardColor,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 280 : 80,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!, 
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with proper constraints
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: _isSidebarExpanded 
                  ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
                  : const EdgeInsets.all(16),
              child: _isSidebarExpanded
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings, 
                            color: primaryColor, 
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Admin Panel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings, 
                          color: primaryColor, 
                          size: 28,
                        ),
                      ),
                    ),
            ),
          ),

          // Navigation Items with proper spacing
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _buildSidebarItem(
                  icon: Icons.dashboard, 
                  title: 'Dashboard', 
                  index: 0, 
                  primaryColor: primaryColor, 
                  textColor: textColor,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  icon: Icons.book, 
                  title: 'Manage Books', 
                  index: 1, 
                  primaryColor: primaryColor, 
                  textColor: textColor,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  icon: Icons.category, 
                  title: 'Manage Categories', 
                  index: 2, 
                  primaryColor: primaryColor, 
                  textColor: textColor,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  icon: Icons.people, 
                  title: 'Manage Users', 
                  index: 3, 
                  primaryColor: primaryColor, 
                  textColor: textColor,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  icon: Icons.star, 
                  title: 'Book Ratings', 
                  index: 4, 
                  primaryColor: primaryColor, 
                  textColor: textColor,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  icon: Icons.shopping_bag, 
                  title: 'Orders', 
                  index: 5, 
                  primaryColor: primaryColor, 
                  textColor: textColor,
                ),
              ],
            ),
          ),

          // Footer with proper layout constraints
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!, 
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (_isSidebarExpanded) ...[
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Administrator',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Sidebar Item ----------------
  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required int index,
    required Color primaryColor,
    required Color textColor,
  }) {
    final isSelected = _currentIndex == index;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: primaryColor.withOpacity(0.3), width: 1) 
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : primaryColor,
                    size: 20,
                  ),
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? primaryColor : textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- App Bar ----------------
  Widget _buildAppBar({
    required bool isDark,
    required Color textColor,
    required Color primaryColor,
    required ThemeProvider themeProvider,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24, 
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900]! : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!, 
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Mobile menu button with proper spacing
          if (isMobile) ...[
            IconButton(
              icon: Icon(Icons.menu, color: textColor),
              onPressed: () {
                // TODO: Implement mobile drawer
              },
            ),
            const SizedBox(width: 8),
          ],
          
          // Title with flexible space
          Expanded(
            child: Text(
              _getAppBarTitle(),
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // Theme toggle button
          Container(
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: primaryColor,
                size: 22,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
          const SizedBox(width: 8),
          
          // Logout button
          Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Bottom Navigation Bar ----------------
  Widget _buildBottomNavigationBar(Color primaryColor, Color textColor, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: textColor.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard, size: 22), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.book, size: 22), label: "Books"),
          BottomNavigationBarItem(icon: Icon(Icons.category, size: 22), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.people, size: 22), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.star, size: 22), label: "Ratings"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag, size: 22), label: "Orders"),
        ],
      ),
    );
  }

  // ---------------- App Bar Title ----------------
  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return "Dashboard";
      case 1: return "Manage Books";
      case 2: return "Manage Categories";
      case 3: return "Manage Users";
      case 4: return "Book Ratings";
      case 5: return "Orders";
      default: return "Admin Panel";
    }
  }

  // ---------------- Screen Selection ----------------
  Widget _getSelectedScreen() {
    switch (_currentIndex) {
      case 1: return  BooksListScreen();
      case 2: return const ManageCategoriesScreen();
      case 3: return const ManageUsersScreen();
      case 4: return const BookRatingsScreen();
      case 5: return const AdminOrdersScreen();
      default: return const Center(child: Text("Not Found"));
    }
  }

  // ---------------- Dashboard Content ----------------
  Widget _buildDashboardContent({
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primaryColor,
  }) {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final booksRef = FirebaseFirestore.instance.collection('books');
    final ordersRef = FirebaseFirestore.instance.collection('orders');

    return FutureBuilder(
      future: Future.wait([usersRef.get(), booksRef.get(), ordersRef.get()]),
      builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading data',
              style: TextStyle(color: textColor),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Text(
              'No data available',
              style: TextStyle(color: textColor),
            ),
          );
        }

        final usersCount = snapshot.data![0].docs.length;
        final booksCount = snapshot.data![1].docs.length;

        double totalRevenue = 0;
        for (var doc in snapshot.data![2].docs) {
          final data = doc.data() as Map<String, dynamic>;
          final price = (data['total'] ?? 0).toDouble();
          totalRevenue += price;
        }
        final ordersCount = snapshot.data![2].docs.length;

        double avgRating = 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: textColor, 
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back! Here\'s what\'s happening with your store.',
                style: TextStyle(fontSize: 16, color: secondaryTextColor),
              ),
              const SizedBox(height: 32),

              // Responsive stats grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    children: [
                      _buildModernStatCard(
                        title: "Total Revenue", 
                        value: "Rs. ${totalRevenue.toStringAsFixed(0)}", 
                        icon: Icons.monetization_on,
                        cardColor: cardColor, 
                        textColor: textColor,
                        gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      _buildModernStatCard(
                        title: "Users", 
                        value: usersCount.toString(), 
                        icon: Icons.people,
                        cardColor: cardColor, 
                        textColor: textColor,
                        gradientColors: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                      ),
                      _buildModernStatCard(
                        title: "Orders", 
                        value: ordersCount.toString(), 
                        icon: Icons.shopping_bag,
                        cardColor: cardColor, 
                        textColor: textColor,
                        gradientColors: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                      ),
                      _buildModernStatCard(
                        title: "Books", 
                        value: booksCount.toString(), 
                        icon: Icons.book,
                        cardColor: cardColor, 
                        textColor: textColor,
                        gradientColors: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
                      ),
                      _buildModernStatCard(
                        title: "Avg Rating", 
                        value: avgRating > 0 ? "${avgRating.toStringAsFixed(1)} ★" : "-", 
                        icon: Icons.star,
                        cardColor: cardColor, 
                        textColor: textColor,
                        gradientColors: const [Color(0xFFfa709a), Color(0xFFfee140)],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- Responsive Grid Calculation ----------------
  int _getCrossAxisCount(double containerWidth) {
    if (containerWidth > desktopBreakpoint) return 4;
    if (containerWidth > tabletBreakpoint) return 3;
    if (containerWidth > 400) return 2;
    return 1; // Very small screens
  }

  // ---------------- Stat Card ----------------
  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors, 
                  begin: Alignment.topLeft, 
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: textColor, 
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor.withOpacity(0.7), 
                fontSize: 14, 
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}