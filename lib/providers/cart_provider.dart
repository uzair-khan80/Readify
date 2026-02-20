import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartProvider with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));

  int get totalItems =>
      _items.fold(0, (sum, item) => sum + (item['quantity'] as int));

  /// Load cart items from Firestore
  Future<void> loadCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .get();

      _items = snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "title": doc["title"],
          "price": doc["price"],
          "quantity": doc["quantity"],
          "coverUrl": doc["coverUrl"],
        };
      }).toList();
    } catch (e) {
      debugPrint("⚠️ Error loading cart: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add item to cart
  Future<void> addToCart(Map<String, dynamic> book) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _db
        .collection("users")
        .doc(user.uid)
        .collection("cart")
        .doc(book["id"]);

    final doc = await cartRef.get();

    if (doc.exists) {
      // update quantity
      final currentQty = doc["quantity"] ?? 1;
      await cartRef.update({"quantity": currentQty + 1});
    } else {
      // new item
      await cartRef.set({
        "title": book["title"],
        "price": book["price"],
        "quantity": book["quantity"] ?? 1,
        "coverUrl": book["coverUrl"],
      });
    }

    await loadCart(); // refresh local list
  }

  /// Update quantity
  Future<void> updateQuantity(String bookId, int newQuantity) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef =
        _db.collection("users").doc(user.uid).collection("cart").doc(bookId);

    if (newQuantity <= 0) {
      // remove item
      await cartRef.delete();
      _items.removeWhere((item) => item["id"] == bookId);
    } else {
      await cartRef.update({"quantity": newQuantity});
      // update local copy
      _items = _items.map((item) {
        if (item["id"] == bookId) {
          return {
            ...item,
            "quantity": newQuantity,
          };
        }
        return item;
      }).toList();
    }

    notifyListeners();
  }

  /// Remove single item
  Future<void> removeFromCart(String bookId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection("users")
        .doc(user.uid)
        .collection("cart")
        .doc(bookId)
        .delete();

    _items.removeWhere((item) => item["id"] == bookId);
    notifyListeners();
  }

  /// Clear all cart items
  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _db.collection("users").doc(user.uid).collection("cart");
    final snapshot = await cartRef.get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    _items.clear();
    notifyListeners();
  }
}
