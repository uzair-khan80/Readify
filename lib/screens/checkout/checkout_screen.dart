// lib/screens/checkout/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Address controllers
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  // Card controllers
  final _cardNumberController = TextEditingController();
  final _cardExpController = TextEditingController();
  final _cardCvvController = TextEditingController();

  bool _isLoading = false;
  String _paymentMethod = 'COD';
  Map<String, dynamic>? _savedAddress;
  bool _useSavedAddress = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null &&
          data['address'] != null &&
          data['address'] is Map<String, dynamic>) {
        setState(() {
          _savedAddress = Map<String, dynamic>.from(data['address'] as Map);
        });
      }
    } catch (e) {
      debugPrint('Error loading saved address: $e');
    }
  }

  Future<void> _placeOrder() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }

    if (_useSavedAddress && _savedAddress == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No saved address found')));
      return;
    }

    if (!_useSavedAddress) {
      if (!_formKey.currentState!.validate()) return;
    }

    if (_paymentMethod == 'Card') {
      if (_cardNumberController.text.trim().length < 12 ||
          _cardExpController.text.trim().isEmpty ||
          _cardCvvController.text.trim().length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter valid card details')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    try {
      final db = FirebaseFirestore.instance;

      final address = _useSavedAddress
          ? _savedAddress!
          : {
              'street': _streetController.text.trim(),
              'city': _cityController.text.trim(),
              'phone': _phoneController.text.trim(),
            };

      if (!_useSavedAddress) {
        await db.collection('users').doc(user.uid).set({
          'address': address,
        }, SetOptions(merge: true));
        setState(() {
          _savedAddress = address;
          _useSavedAddress = true;
        });
      }

      final orderId = db.collection('orders').doc().id;

      final orderData = {
        'userId': user.uid,
        'userEmail': user.email,
        'items': cartProvider.items,
        'total': cartProvider.totalPrice,
        'paymentMethod': _paymentMethod,
        'status': 'pending',
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save for admin (global)
      await db.collection('orders').doc(orderId).set(orderData);

      // Save for user
      await db
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .set(orderData);

      // Clear cart
      await cartProvider.clearCart();

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully')),
      );
      Navigator.pushReplacementNamed(context, '/my-orders');
    } catch (e, st) {
      debugPrint('Place order error: $e\n$st');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardExpController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  Widget _addressCard(Map<String, dynamic> addr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
          Colors.deepPurple.withOpacity(0.1),
          Colors.deepPurpleAccent.withOpacity(0.05),
        ]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_on, color: Colors.deepPurple),
        ),
        title: Text(
          '${addr['street']}, ${addr['city']}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Phone: ${addr['phone']}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _paymentMethod == value 
              ? Colors.deepPurple 
              : Colors.grey.withOpacity(0.3),
          width: _paymentMethod == value ? 2 : 1,
        ),
        color: _paymentMethod == value 
            ? Colors.deepPurple.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Radio<String>(
          value: value,
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
          activeColor: Colors.deepPurple,
        ),
        onTap: () => setState(() => _paymentMethod = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Processing Order...',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address Section
                  _buildSectionHeader('Delivery Address'),
                  
                  if (_savedAddress != null) ...[
                    _addressCard(_savedAddress!),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _useSavedAddress = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _useSavedAddress ? Colors.deepPurple : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Use Saved',
                                    style: TextStyle(
                                      color: _useSavedAddress ? Colors.white : Colors.deepPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _useSavedAddress = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: !_useSavedAddress ? Colors.deepPurple : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'New Address',
                                    style: TextStyle(
                                      color: !_useSavedAddress ? Colors.white : Colors.deepPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (!_useSavedAddress || _savedAddress == null)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: theme.cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _streetController,
                              decoration: InputDecoration(
                                labelText: 'Street Address',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.withOpacity(0.05),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter street address'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                labelText: 'City',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.withOpacity(0.05),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter city'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.withOpacity(0.05),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter phone'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  
                  // Payment Method Section
                  _buildSectionHeader('Payment Method'),
                  
                  _buildPaymentMethodCard('Cash on Delivery', 'COD', Icons.payment),
                  _buildPaymentMethodCard('Debit / Credit Card', 'Card', Icons.credit_card),

                  if (_paymentMethod == 'Card') 
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: theme.cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _cardNumberController,
                            decoration: InputDecoration(
                              labelText: 'Card Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.05),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cardExpController,
                                  decoration: InputDecoration(
                                    labelText: 'MM/YY',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.withOpacity(0.05),
                                  ),
                                  keyboardType: TextInputType.datetime,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _cardCvvController,
                                  decoration: InputDecoration(
                                    labelText: 'CVV',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.withOpacity(0.05),
                                  ),
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  
                  // Order Summary Section
                  _buildSectionHeader('Order Summary'),
                  
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ...cartProvider.items.map((item) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.withOpacity(0.1),
                            ),
                            child: item['coverUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['coverUrl'], 
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(Icons.book, color: Colors.deepPurple),
                          ),
                          title: Text(
                            item['title'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('Qty: ${item['quantity']}'),
                          trailing: Text(
                            'Rs${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.deepPurple,
                            ),
                          ),
                        )).toList(),
                        
                        const Divider(height: 1),
                        
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Rs${cartProvider.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Place Order Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}