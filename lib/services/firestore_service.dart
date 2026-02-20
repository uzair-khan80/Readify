// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Add a new book
  Future<void> addBook(Book book) async {
    await _db.collection('books').add({
      ...book.toMap(),
      'rating': 0.0, // default rating
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update book
  Future<void> updateBook(Book book) async {
    if (book.id.isEmpty) throw Exception('Cannot update book without id');
    await _db.collection('books').doc(book.id).update({
      ...book.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete book
  Future<void> deleteBook(String id) async {
    await _db.collection('books').doc(id).delete();
  }

  // Stream top N featured books (for Home screen)
  Stream<List<Book>> streamFeaturedBooks({int limit = 3}) {
    return _db
        .collection('books')
        .orderBy('createdAt', descending: true)
        .limit(limit) // ✅ only top 3 featured books
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Book.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Stream ALL books (for Home screen - excluding featured)
  Stream<List<Book>> streamAllBooks() {
    return _db
        .collection('books')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allBooks = snapshot.docs
          .map((doc) => Book.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      return allBooks;
    });
  }

  // Fetch books once (optional)
  Future<List<Book>> getBooks() async {
    final snapshot =
        await _db.collection('books').orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Book.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Get single book by ID
  Future<Book?> getBookById(String id) async {
    final doc = await _db.collection('books').doc(id).get();
    if (!doc.exists) return null;
    return Book.fromMap(doc.data()! as Map<String, dynamic>, doc.id);
  }

  // -------------------- USER RATINGS --------------------

  Future<void> rateBook(String bookId, String userEmail, double rating) async {
    final bookRef = _db.collection('books').doc(bookId);
    final ratingRef = bookRef.collection('ratings').doc(userEmail);

    await ratingRef.set({
      'rating': rating,
      'email': userEmail,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final ratingsSnapshot = await bookRef.collection('ratings').get();
    double total = 0;
    for (var doc in ratingsSnapshot.docs) {
      total += (doc.data()['rating'] ?? 0);
    }
    final avgRating =
        ratingsSnapshot.docs.isNotEmpty ? total / ratingsSnapshot.docs.length : 0;
    await bookRef.update({'rating': avgRating});
  }

  Future<double?> getUserRating(String bookId, String userEmail) async {
    final doc =
        await _db.collection('books').doc(bookId).collection('ratings').doc(userEmail).get();
    if (!doc.exists) return null;
    return (doc.data()?['rating'] as num?)?.toDouble();
  }
}
