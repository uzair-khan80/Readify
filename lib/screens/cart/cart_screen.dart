import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readify/screens/checkout/checkout_screen.dart';
import '../../providers/cart_provider.dart';
import '../../providers/theme_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 4; // Cart index

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    Future.microtask(() {
      Provider.of<CartProvider>(context, listen: false).loadCart();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Premium color palette
    final primaryColor = isDark ? Color(0xFF7C4DFF) : Color(0xFF6A4CFF);
    final secondaryColor = isDark ? Color(0xFF00E5FF) : Color(0xFF00B8D4);
    final surfaceColor = isDark ? Color(0xFF1E1B2E) : Color(0xFFF8F7FF);
   final backgroundColor = isDark ? Color(0xFF0F1724) : Color(0xFFF8F9FA);

    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "My Cart",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        actions: [
          if (cartProvider.items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: Color(0xFFFF6B6B)),
              onPressed: _showClearCartDialog,
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: cartProvider.isLoading
            ? _buildLoadingState(primaryColor, isDark, backgroundColor)
            : cartProvider.items.isEmpty
                ? _buildEmptyState(primaryColor, secondaryColor, isDark, backgroundColor)
                : _buildCartContent(cartProvider, primaryColor, secondaryColor, surfaceColor, isDark, context, backgroundColor),
      ),
      bottomNavigationBar: _buildModernBottomNavBar(isDark),
    );
  }

  Widget _buildLoadingState(Color primaryColor, bool isDark, Color backgroundColor) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              "Loading your cart...",
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, Color secondaryColor, bool isDark, Color backgroundColor) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    secondaryColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Your cart is empty",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Explore our collection and add some books!",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(CartProvider cartProvider, Color primaryColor, Color secondaryColor, Color surfaceColor, bool isDark, BuildContext context, Color backgroundColor) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // Header with item count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text(
                  "Items (${cartProvider.items.length})",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Color(0xFF666666),
                  ),
                ),
                const Spacer(),
                Text(
                  "Total: Rs${cartProvider.totalPrice.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Cart items list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: cartProvider.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = cartProvider.items[index];
                return _buildCartItem(item, cartProvider, primaryColor, secondaryColor, surfaceColor, isDark, index);
              },
            ),
          ),

          // Checkout section
          _buildCheckoutSection(cartProvider, primaryColor, secondaryColor, isDark, context),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, CartProvider cartProvider, Color primaryColor, Color secondaryColor, Color surfaceColor, bool isDark, int index) {
    final price = (item["price"] * item["quantity"]).toStringAsFixed(0);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: primaryColor.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                surfaceColor,
                isDark ? Color(0xFF25233A) : Color(0xFFF0EFFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover with shadow
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item["coverUrl"] != null
                        ? Image.network(
                            item["coverUrl"],
                            width: 70,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                _buildPlaceholderCover(primaryColor, secondaryColor),
                          )
                        : _buildPlaceholderCover(primaryColor, secondaryColor),
                  ),
                ),
                const SizedBox(width: 16),

                // Book details and controls
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Color(0xFF2D2D2D),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Rs${item["price"]} each",
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quantity controls
                      Row(
                        children: [
                          _buildQuantityButton(
                            icon: Icons.remove,
                            onPressed: item["quantity"] > 1
                                ? () => cartProvider.updateQuantity(
                                      item["id"],
                                      item["quantity"] - 1,
                                    )
                                : null,
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${item["quantity"]}",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          _buildQuantityButton(
                            icon: Icons.add,
                            onPressed: () => cartProvider.updateQuantity(
                              item["id"],
                              item["quantity"] + 1,
                            ),
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price and remove button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Rs$price",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 22),
                      color: Color(0xFFFF6B6B),
                      onPressed: () => _showRemoveDialog(item["id"], cartProvider, item["title"]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(Color primaryColor, Color secondaryColor) {
    return Container(
      width: 70,
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.2),
            secondaryColor.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.book_rounded,
        size: 32,
        color: primaryColor.withOpacity(0.6),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color primaryColor,
    required bool isDark,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: onPressed != null 
            ? primaryColor.withOpacity(0.1)
            : (isDark ? Colors.white30 : Colors.black26),
        borderRadius: BorderRadius.circular(8),
        border: onPressed != null 
            ? Border.all(color: primaryColor.withOpacity(0.3))
            : null,
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        color: onPressed != null 
            ? primaryColor
            : (isDark ? Colors.white30 : Colors.black26),
      ),
    );
  }

  Widget _buildCheckoutSection(CartProvider cartProvider, Color primaryColor, Color secondaryColor, bool isDark, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1B2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Color(0xFF2D2D2D),
                ),
              ),
              Text(
                "Rs${cartProvider.totalPrice.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Checkout button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shadowColor: primaryColor.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Proceed to Checkout",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
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
              Navigator.pushNamed(context, '/wishlist');
            } else if (index == 3) {
              Navigator.pushNamed(context, '/profile');
            } else if (index == 4) {
              // Already on cart page, do nothing
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

  void _showRemoveDialog(String itemId, CartProvider cartProvider, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Color(0xFF1E1B2E) 
            : Colors.white,
        title: Text(
          "Remove Item", 
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Color(0xFF2D2D2D)
          )
        ),
        content: Text(
          "Remove \"$title\" from your cart?",
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Color(0xFF666666)
          )
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel", 
              style: TextStyle(color: Color(0xFF6A4CFF))
            ),
          ),
          TextButton(
            onPressed: () {
              cartProvider.removeFromCart(itemId);
              Navigator.pop(context);
            },
            child: Text(
              "Remove", 
              style: TextStyle(color: Color(0xFFFF6B6B))
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Color(0xFF1E1B2E) 
            : Colors.white,
        title: Text(
          "Clear Cart", 
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Color(0xFF2D2D2D)
          )
        ),
        content: Text(
          "Remove all items from your cart?",
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Color(0xFF666666)
          )
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Color(0xFF6A4CFF))),
          ),
          TextButton(
            onPressed: () {
              final cartProvider = Provider.of<CartProvider>(context, listen: false);
              for (final item in cartProvider.items) {
                cartProvider.removeFromCart(item["id"]);
              }
              Navigator.pop(context);
            },
            child: Text("Clear All", style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }
}