import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:readify/screens/admin/admin_dashboard.dart';
import 'package:readify/screens/admin/admin_orders_screen.dart';
import 'package:readify/screens/admin/books_list_screen.dart';
import 'package:readify/screens/checkout/checkout_screen.dart';
import 'package:readify/screens/home/book_detail_screen.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/wishlist/wishlist_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/orders/my_orders_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/admin/add_book_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/wishlist_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ReadifyApp());
}

class ReadifyApp extends StatelessWidget {
  const ReadifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Readify',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.mode,
            theme: ThemeData(
              brightness: Brightness.light,
              useMaterial3: true,
              primaryColor: const Color(0xFF1E293B),
              scaffoldBackgroundColor: const Color(0xFFF9FAFB),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.black87),
              ),
              textTheme: const TextTheme(
                headlineMedium: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                bodyMedium: TextStyle(color: Colors.black87),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: true,
              primaryColor: const Color(0xFF0F1724),
              scaffoldBackgroundColor: const Color(0xFF0B1220),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white70),
              ),
              textTheme: const TextTheme(
                headlineMedium: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                bodyMedium: TextStyle(color: Colors.white70),
              ),
            ),

            // ✅ pehle splash chalega
            initialRoute: '/splash',

            routes: {
              '/splash': (context) => const BookishSplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const HomeScreen(),
              '/cart': (context) => const CartScreen(),
              '/wishlist': (context) => const WishlistScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/my-orders': (context) => const MyOrdersScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/admin-dashboard': (context) => const AdminDashboard(),
              '/admin-books': (context) => BooksListScreen(),
              '/add-book': (context) => const AddBookScreen(),
              '/search': (context) => const SearchScreen(),
              '/admin-orders': (ctx) => const AdminOrdersScreen(),
              '/checkout': (ctx) => const CheckoutScreen(),
              '/book': (context) => const BookDetailScreen(),
            },
          );
        },
      ),
    );
  }
}
