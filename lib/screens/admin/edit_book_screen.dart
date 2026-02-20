// lib/screens/admin/edit_book_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/firestore_service.dart';

class EditBookScreen extends StatefulWidget {
  final Book book;
  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();

  late String _title;
  late String _author;
  late String _category;
  late double _price;
  late String _description;


  @override
  void initState() {
    super.initState();
    _title = widget.book.title;
    _author = widget.book.author;
    _category = widget.book.category;
    _price = widget.book.price;
    _description = widget.book.description;

  }

  void _updateBook() async {
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  final updatedBook = widget.book.copyWith(
    title: _title,
    author: _author,
    category: _category,
    price: _price,
    description: _description,
  );

  await _firestore.updateBook(updatedBook); // ✅ fixed
  Navigator.pop(context);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Book")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: "Title"),
                onSaved: (v) => _title = v!,
              ),
              TextFormField(
                initialValue: _author,
                decoration: const InputDecoration(labelText: "Author"),
                onSaved: (v) => _author = v!,
              ),
              FutureBuilder(
  future: FirebaseFirestore.instance.collection("categories").get(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final docs = snapshot.data!.docs;

    // unique categories
    final categories = docs.map((doc) => doc["name"] as String).toSet().toList();

    // agar _category list me nahi hai to null pass karo
    final dropdownValue = categories.contains(_category) ? _category : null;

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: "Category"),
      value: dropdownValue,
      items: categories
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (value) {
        setState(() => _category = value!);
      },
      onSaved: (value) => _category = value!,
      validator: (value) =>
          value == null || value.isEmpty ? "Please select a category" : null,
    );
  },
),

              TextFormField(
                initialValue: _price.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
                onSaved: (v) => _price = double.parse(v!),
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: "Description"),
                onSaved: (v) => _description = v!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateBook,
                child: const Text("Update Book"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
