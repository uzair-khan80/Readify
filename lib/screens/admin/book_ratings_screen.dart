// lib/screens/admin/book_ratings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookRatingsScreen extends StatelessWidget {
  const BookRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F1724) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Book Ratings & Reviews'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('books').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 110);
                }
                
                final books = snapshot.data!.docs;
                
                // Safe calculation with null checks
                int totalBooks = books.length;
                int booksWithRatings = books.where((book) {
                  try {
                    final data = book.data() as Map<String, dynamic>? ?? {};
                    final rating = data['rating'] ?? 0;
                    return (rating is num && rating > 0);
                  } catch (e) {
                    return false;
                  }
                }).length;
                
                double averageRating = 0;
                if (books.isNotEmpty) {
                  final totalRating = books.fold<double>(0, (sum, book) {
                    try {
                      final data = book.data() as Map<String, dynamic>? ?? {};
                      final ratingRaw = data['rating'] ?? 0;
                      final rating = ratingRaw is num ? ratingRaw.toDouble() : 0;
                      return sum + rating;
                    } catch (e) {
                      return sum;
                    }
                  });
                  averageRating = totalBooks > 0 ? totalRating / totalBooks : 0;
                }

                double ratingPercentage = totalBooks > 0 
                    ? (booksWithRatings / totalBooks) * 100 
                    : 0;

                return SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildStatCard(
                        context,
                        "Total Books",
                        totalBooks.toString(),
                        Icons.book,
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        context,
                        "Rated Books",
                        booksWithRatings.toString(),
                        Icons.star,
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        context,
                        "Avg Rating",
                        averageRating.toStringAsFixed(1),
                        Icons.star_rate,
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        context,
                        "Rating %",
                        "${ratingPercentage.toStringAsFixed(0)}%",
                        Icons.analytics,
                        Colors.purple,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Books List Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Book Ratings Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('books').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "No books found",
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final books = snapshot.data!.docs;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 768) {
                      // Desktop/Tablet View - Grid with fixed constraints
                      return _buildDesktopGrid(context, books);
                    } else {
                      // Mobile View - List
                      return _buildMobileList(context, books);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      elevation: 2,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopGrid(BuildContext context, List<QueryDocumentSnapshot> books) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          try {
            final book = books[index].data() as Map<String, dynamic>? ?? {};
            final bookId = books[index].id;
            final title = book['title']?.toString() ?? 'Unknown Title';
            final coverUrl = book['coverUrl']?.toString();

            // Safe conversion to double
            final avgRatingRaw = book['rating'] ?? 0;
            final avgRating = avgRatingRaw is num
                ? avgRatingRaw.toDouble()
                : double.tryParse(avgRatingRaw.toString()) ?? 0.0;

            return Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showRatingsDialog(context, bookId, title, avgRating),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Book Cover
                      if (coverUrl != null && coverUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            coverUrl,
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 60,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.book, size: 30, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.book, size: 30, color: Colors.grey),
                        ),
                      
                      const SizedBox(width: 16),
                      
                      // Book Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            
                            // Rating Stars
                            Row(
                              children: [
                                _buildRatingStars(avgRating),
                                const SizedBox(width: 8),
                                Text(
                                  avgRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // Ratings Count
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('books')
                                  .doc(bookId)
                                  .collection('ratings')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                return Text(
                                  '$count ${count == 1 ? 'rating' : 'ratings'}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // View Button
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            );
          } catch (e) {
            // Fallback card if there's an error
            return Card(
              color: cardColor,
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('Error loading book'),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<QueryDocumentSnapshot> books) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        try {
          final book = books[index].data() as Map<String, dynamic>? ?? {};
          final bookId = books[index].id;
          final title = book['title']?.toString() ?? 'Unknown Title';
          final coverUrl = book['coverUrl']?.toString();

          // Safe conversion to double
          final avgRatingRaw = book['rating'] ?? 0;
          final avgRating = avgRatingRaw is num
              ? avgRatingRaw.toDouble()
              : double.tryParse(avgRatingRaw.toString()) ?? 0.0;

          return Card(
            color: cardColor,
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: coverUrl != null && coverUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        coverUrl,
                        width: 40,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 40,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.book, size: 20, color: Colors.grey),
                        ),
                      ),
                    )
                  : Container(
                      width: 40,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.book, size: 20, color: Colors.grey),
                    ),
              title: Text(
                title,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Row(
                children: [
                  _buildRatingStars(avgRating, size: 16),
                  const SizedBox(width: 4),
                  Text(avgRating.toStringAsFixed(1), style: TextStyle(color: textColor)),
                ],
              ),
              trailing: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('books')
                    .doc(bookId)
                    .collection('ratings')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Chip(
                    label: Text(count.toString()),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    labelStyle: const TextStyle(fontSize: 12),
                  );
                },
              ),
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('books')
                      .doc(bookId)
                      .collection('ratings')
                      .snapshots(),
                  builder: (context, ratingSnapshot) {
                    if (ratingSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (!ratingSnapshot.hasData || ratingSnapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No ratings yet',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final ratings = ratingSnapshot.data!.docs;

                    return Column(
                      children: ratings.map((r) {
                        try {
                          final rData = r.data() as Map<String, dynamic>? ?? {};

                          // Safe conversion to double
                          final ratingRaw = rData['rating'] ?? 0;
                          final rating = ratingRaw is num
                              ? ratingRaw.toDouble()
                              : double.tryParse(ratingRaw.toString()) ?? 0.0;

                          final email = rData['email']?.toString() ?? 'Unknown';
                          final comment = rData['comment']?.toString() ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: const Icon(Icons.person, size: 20),
                            ),
                            title: Text(email, style: TextStyle(color: textColor)),
                            subtitle: comment.isNotEmpty ? Text(comment) : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildRatingStars(rating, size: 16),
                                const SizedBox(width: 4),
                                Text(rating.toStringAsFixed(1)),
                              ],
                            ),
                          );
                        } catch (e) {
                          return const ListTile(
                            leading: Icon(Icons.error),
                            title: Text('Error loading rating'),
                          );
                        }
                      }).toList(),
                    );
                  },
                )
              ],
            ),
          );
        } catch (e) {
          return Card(
            color: cardColor,
            margin: const EdgeInsets.only(bottom: 16),
            child: const ListTile(
              leading: Icon(Icons.error),
              title: Text('Error loading book'),
            ),
          );
        }
      },
    );
  }

  Widget _buildRatingStars(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.orange,
          size: size,
        );
      }),
    );
  }

  void _showRatingsDialog(BuildContext context, String bookId, String title, double avgRating) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRatingStars(avgRating),
                    const SizedBox(width: 8),
                    Text(avgRating.toStringAsFixed(1), style: TextStyle(color: textColor)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Individual Ratings:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('books')
                        .doc(bookId)
                        .collection('ratings')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text('No ratings yet', style: TextStyle(color: textColor)),
                        );
                      }

                      final ratings = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: ratings.length,
                        itemBuilder: (context, index) {
                          try {
                            final rData = ratings[index].data() as Map<String, dynamic>? ?? {};
                            final rating = rData['rating'] ?? 0;
                            final email = rData['email']?.toString() ?? 'Unknown';
                            final comment = rData['comment']?.toString() ?? '';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                child: const Icon(Icons.person, size: 20),
                              ),
                              title: Text(email, style: TextStyle(color: textColor)),
                              subtitle: comment.isNotEmpty ? Text(comment) : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildRatingStars(rating is num ? rating.toDouble() : 0.0, size: 16),
                                  const SizedBox(width: 4),
                                  Text(rating.toString()),
                                ],
                              ),
                            );
                          } catch (e) {
                            return const ListTile(
                              leading: Icon(Icons.error),
                              title: Text('Error loading rating'),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}