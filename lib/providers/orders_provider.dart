import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersProvider with ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];

  List<Map<String, dynamic>> get orders => _orders;

  Future<void> loadOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("orders")
        .where("userId", isEqualTo: user.uid)
        .orderBy("createdAt", descending: true)
        .get();

    _orders = snapshot.docs.map((doc) {
      return {
        "id": doc.id,
        "bookIds": List<String>.from(doc["bookIds"]),
        "totalAmount": doc["totalAmount"],
        "status": doc["status"],
        "createdAt": (doc["createdAt"] as Timestamp).toDate(),
      };
    }).toList();

    notifyListeners();
  }

  Future<void> placeOrder(List<Map<String, dynamic>> cartItems, double totalAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orderRef = FirebaseFirestore.instance.collection("orders").doc();

    await orderRef.set({
      "userId": user.uid,
      "bookIds": cartItems.map((e) => e["id"]).toList(),
      "totalAmount": totalAmount,
      "status": "pending", // pending | shipped | delivered
      "createdAt": FieldValue.serverTimestamp(),
    });

    await loadOrders();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await FirebaseFirestore.instance
        .collection("orders")
        .doc(orderId)
        .update({"status": status});

    await loadOrders();
  }
}
