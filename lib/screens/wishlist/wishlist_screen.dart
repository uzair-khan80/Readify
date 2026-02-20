import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  int _currentIndex = 2; // Wishlist index

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[700];
    final scaffoldColor = isDark ? const Color(0xFF0F1724) : const Color(0xFFF8F9FA);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: scaffoldColor,
        appBar: AppBar(
          title: Text(
            "Wishlist",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: textColor,
        ),
        body: const Center(
          child: Text("Please login to view your wishlist"),
        ),
      );
    }

    final wishlistRef = FirebaseFirestore.instance
        .collection("wishlists")
        .doc(user.email)
        .collection("books");

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text(
          "Wishlist",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: wishlistRef.orderBy("addedAt", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.deepPurpleAccent,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading wishlist",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No books in your wishlist",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Start adding books to your wishlist!",
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final bookId = doc.id;

                return _buildWishlistItem(
                  data, 
                  bookId, 
                  wishlistRef, 
                  isDark, 
                  textColor, 
                  secondaryTextColor
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _buildModernBottomNavBar(isDark),
    );
  }

  Widget _buildWishlistItem(
    Map<String, dynamic> book, 
    String bookId, 
    CollectionReference wishlistRef,
    bool isDark, 
    Color textColor, 
    Color? secondaryTextColor
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: book["coverUrl"] != null
              ? Image.network(
                  book["coverUrl"],
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 70,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(Icons.book, color: isDark ? Colors.white54 : Colors.grey[500]),
                  ),
                )
              : Container(
                  width: 50,
                  height: 70,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(Icons.book, color: isDark ? Colors.white54 : Colors.grey[500]),
                ),
        ),
        title: Text(
          book["title"] ?? "Untitled",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book["author"] ?? "Unknown Author",
              style: TextStyle(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rs${book["price"]?.toStringAsFixed(0) ?? "0"}',
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
          ),
          onPressed: () async {
            await wishlistRef.doc(bookId).delete();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${book["title"]}" removed from wishlist'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
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
              Navigator.pushNamed(context, '/search');
            } else if (index == 2) {
              // Already on wishlist page, do nothing
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