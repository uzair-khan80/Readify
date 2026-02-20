import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _reviews = [];

  List<Map<String, dynamic>> get reviews => _reviews;

  /// Load all reviews for a specific book
  Future<void> loadReviews(String bookId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("reviews")
        .where("bookId", isEqualTo: bookId)
        .orderBy("createdAt", descending: true)
        .get();

    _reviews = snapshot.docs.map((doc) {
      return {
        "id": doc.id,
        "userId": doc["userId"],
        "userName": doc["userName"],
        "rating": doc["rating"],
        "comment": doc["comment"],
        "createdAt": (doc["createdAt"] as Timestamp).toDate(),
      };
    }).toList();

    notifyListeners();
  }

  /// Add a new review
  Future<void> addReview(String bookId, double rating, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reviewRef = FirebaseFirestore.instance.collection("reviews").doc();

    await reviewRef.set({
      "bookId": bookId,
      "userId": user.uid,
      "userName": user.displayName ?? "Anonymous",
      "rating": rating,
      "comment": comment,
      "createdAt": FieldValue.serverTimestamp(),
    });

    await loadReviews(bookId);
  }

  /// Delete a review (only by user who wrote it)
  Future<void> deleteReview(String reviewId, String bookId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reviewDoc =
        FirebaseFirestore.instance.collection("reviews").doc(reviewId);

    final snapshot = await reviewDoc.get();
    if (snapshot.exists && snapshot["userId"] == user.uid) {
      await reviewDoc.delete();
      await loadReviews(bookId);
    }
  }

  /// Calculate average rating for a book
  double getAverageRating() {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold(0.0, (sum, r) => sum + (r["rating"] as double));
    return total / _reviews.length;
  }
}
