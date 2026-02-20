import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistProvider with ChangeNotifier {
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  Future<void> loadWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("wishlist")
        .get();

   _items = snapshot.docs.map((doc) {
  return {
    "id": doc.id,
    "title": doc["title"],
    "author": doc["author"],
    "coverUrl": doc["coverUrl"],
    "price": doc["price"], // ✅ add this
  };
}).toList();


    notifyListeners();
  }

  Future<void> addToWishlist(Map<String, dynamic> book) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wishlistRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("wishlist")
        .doc(book["id"]);

    final doc = await wishlistRef.get();

    if (!doc.exists) {
      await wishlistRef.set({
        "title": book["title"],
        "author": book["author"],
        "coverUrl": book["coverUrl"],
      });
    }

    await loadWishlist();
  }

  Future<void> removeFromWishlist(String bookId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("wishlist")
        .doc(bookId)
        .delete();

    await loadWishlist();
  }

  bool isInWishlist(String bookId) {
    return _items.any((item) => item["id"] == bookId);
  }
}
