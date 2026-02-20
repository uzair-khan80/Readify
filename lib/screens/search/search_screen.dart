import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _results = [];
  int _currentIndex = 1; // Search index

  Future<void> _searchBooks(String query) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      _results = snapshot.docs;
      _isSearching = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final scaffoldColor = isDark ? const Color(0xFF0F1724) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Search books...',
            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
            border: InputBorder.none,
          ),
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              _searchBooks(query);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear, color: textColor),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _isSearching = false;
                _results = [];
              });
            },
          )
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: !_isSearching
          ? Center(
              child: Text(
                'Start typing to search for books',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            )
          : _results.isEmpty
              ? Center(
                  child: Text(
                    'No books found',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // Space for bottom navigation
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final book = _results[index].data();
                    final bookId = _results[index].id;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            book['coverUrl'],
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 50,
                              height: 70,
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: Icon(Icons.book, color: isDark ? Colors.white54 : Colors.grey[500]),
                            ),
                          ),
                        ),
                        title: Text(
                          book['title'] ?? '',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          book['author'] ?? '',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                        trailing: Text(
                          'Rs${book['price']?.toStringAsFixed(0) ?? '0'}',
                          style: TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/book',
                            arguments: bookId,
                          );
                        },
                      ),
                    );
                  },
                ),
      bottomNavigationBar: _buildModernBottomNavBar(isDark),
    );
  }

  Widget _buildModernBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.deepPurpleAccent,
          unselectedItemColor: isDark ? Colors.white54 : Colors.grey[600],
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          onTap: (index) {
            if (index < 0 || index >= 5) return;
            setState(() => _currentIndex = index);
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 1) {
              // Already on search page, do nothing
            } else if (index == 2) {
              Navigator.pushNamed(context, '/wishlist');
            } else if (index == 3) {
              Navigator.pushNamed(context, '/profile');
            } else if (index == 4) {
              Navigator.pushNamed(context, '/cart');
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 0 ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.home_outlined, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                ),
                child: const Icon(Icons.home_filled, size: 22),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 1 ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.search, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                ),
                child: const Icon(Icons.search, size: 22),
              ),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 2 ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.favorite_border, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                ),
                child: const Icon(Icons.favorite, size: 22),
              ),
              label: 'Wishlist',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 3 ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.person_outline, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                ),
                child: const Icon(Icons.person, size: 22),
              ),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 4 ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.shopping_cart_outlined, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                ),
                child: const Icon(Icons.shopping_cart, size: 22),
              ),
              label: 'Cart',
            ),
          ],
        ),
      ),
    );
  }
}