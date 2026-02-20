import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethod();
  }

  Future<void> _loadPaymentMethod() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

      if (doc.exists && doc.data()!.containsKey("payment")) {
        final pay = doc["payment"];
        _cardNumberController.text = pay["cardNumber"] ?? "";
        _expiryController.text = pay["expiry"] ?? "";
        _cvvController.text = pay["cvv"] ?? "";
      }
    }
  }

  Future<void> _savePaymentMethod() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "payment": {
          "cardNumber": _cardNumberController.text.trim(),
          "expiry": _expiryController.text.trim(),
          "cvv": _cvvController.text.trim(),
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment method saved!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Methods")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: "Card Number",
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expiryController,
              decoration: const InputDecoration(
                labelText: "Expiry Date (MM/YY)",
                prefixIcon: Icon(Icons.date_range),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cvvController,
              decoration: const InputDecoration(
                labelText: "CVV",
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _savePaymentMethod,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    child: const Text("Save Payment Method"),
                  ),
          ],
        ),
      ),
    );
  }
}
