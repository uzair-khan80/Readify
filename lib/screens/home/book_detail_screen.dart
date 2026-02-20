// lib/screens/home/book_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/book_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  double? userRating;
  bool isRatingLoading = false;
  bool isRated = false;
  bool isInWishlist = false; // 👈 wishlist flag
  final TextEditingController _reviewController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    String? bookId;
    Book? bookObj;

    if (args is String) bookId = args;
    if (args is Book) bookObj = args;

    final cart = Provider.of<CartProvider>(context, listen: false);
    final firestore = FirestoreService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<Book?>(
      future: bookObj != null
          ? Future.value(bookObj)
          : firestore.getBookById(bookId ?? ''),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF0F1724) : const Color(0xFFF8F9FA),
            body: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.deepPurpleAccent,
              ),
            ),
          );
        }

        final book = snapshot.data!;

        // fetch rating + wishlist status
        if (user != null && userRating == null) {
          firestore.getUserRating(book.id, user.email!).then((value) {
            if (mounted) {
              setState(() {
                userRating = value ?? 0;
                isRated = (value != null);
              });
            }
          });
          FirebaseFirestore.instance
              .collection("wishlists")
              .doc(user.email)
              .collection("books")
              .doc(book.id)
              .get()
              .then((doc) {
            if (mounted) {
              setState(() => isInWishlist = doc.exists);
            }
          });
        }

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0F1724) : const Color(0xFFF8F9FA),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                // Hero AppBar
                SliverAppBar(
                  expandedHeight: 320,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  actions: [
                    if (user != null)
                      IconButton(
                        icon: Icon(
                          isInWishlist
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                        onPressed: () async {
                          final ref = FirebaseFirestore.instance
                              .collection("wishlists")
                              .doc(user.email)
                              .collection("books")
                              .doc(book.id);
                          if (isInWishlist) {
                            await ref.delete();
                          } else {
                            await ref.set({
                              "id": book.id,
                              "title": book.title,
                              "coverUrl": book.coverUrl,
                              "price": book.price,
                              "author": book.author,
                              "addedAt": FieldValue.serverTimestamp(),
                            });
                          }
                          setState(() => isInWishlist = !isInWishlist);
                        },
                      )
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'book_${book.id}',
                          child: Image.network(book.coverUrl, fit: BoxFit.cover),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  )),
                              Text("by ${book.author}",
                                  style:
                                      const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Body
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price + Buttons
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Rs. ${book.price.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.deepPurpleAccent,
                                )),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await cart.addToCart({
                                        "id": book.id,
                                        "title": book.title,
                                        "price": book.price,
                                        "quantity": 1,
                                        "coverUrl": book.coverUrl,
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '"${book.title}" added to cart'),
                                          backgroundColor:
                                              Colors.deepPurpleAccent,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurpleAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text("Add to Cart"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Expanded(
                                //   child: OutlinedButton(
                                //     onPressed: () {
                                //       ScaffoldMessenger.of(context)
                                //           .showSnackBar(
                                //         SnackBar(
                                //           content: Text(
                                //               'Buying "${book.title}"...'),
                                //         ),
                                //       );
                                //     },
                                //     style: OutlinedButton.styleFrom(
                                //       side: const BorderSide(
                                //         color: Colors.deepPurpleAccent,
                                //         width: 2,
                                //       ),
                                //       shape: RoundedRectangleBorder(
                                //         borderRadius: BorderRadius.circular(14),
                                //       ),
                                //     ),
                                //     child: const Text(
                                //       "Buy Now",
                                //       style: TextStyle(
                                //           color: Colors.deepPurpleAccent),
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Rating
                      if (user != null)
                        _buildRatingSection(isDark, firestore, book, user),

                      const SizedBox(height: 16),

                      // Description
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(book.description,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                            )),
                      ),

                      // Reviews
                      if (user != null) _buildReviewSection(book, isDark),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingSection(
      bool isDark, FirestoreService firestore, Book book, User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Your Rating",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        isRatingLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.deepPurpleAccent,
                ),
              )
            : RatingBar.builder(
                initialRating: userRating ?? 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                ignoreGestures: isRated,
                itemBuilder: (context, _) => const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) async {
                  if (!isRated) {
                    setState(() => isRatingLoading = true);
                    await firestore.rateBook(book.id, user.email!, rating);
                    setState(() {
                      userRating = rating;
                      isRatingLoading = false;
                      isRated = true;
                    });
                  }
                },
              ),
      ]),
    );
  }

  Widget _buildReviewSection(Book book, bool isDark) {
    final user = FirebaseAuth.instance.currentUser!;
    final reviewsRef = FirebaseFirestore.instance
        .collection("books")
        .doc(book.id)
        .collection("reviews");

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Reviews",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        // Input field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  hintText: "Write a review...",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                if (_reviewController.text.trim().isNotEmpty) {
                  await reviewsRef.add({
                    "user": user.email,
                    "review": _reviewController.text.trim(),
                    "createdAt": FieldValue.serverTimestamp(),
                  });
                  _reviewController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
              ),
              child: const Text("Post"),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Reviews list
        StreamBuilder<QuerySnapshot>(
          stream: reviewsRef.orderBy("createdAt", descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Text("No reviews yet.");
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  leading: const Icon(Icons.person, color: Colors.deepPurple),
                  title: Text(data["review"] ?? ""),
                  subtitle: Text(data["user"] ?? ""),
                );
              }).toList(),
            );
          },
        ),
      ]),
    );
  }
}
