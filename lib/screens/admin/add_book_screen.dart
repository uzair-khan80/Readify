// lib/screens/admin/add_book_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/book_model.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  final _cloudinary = CloudinaryService();

  // Controllers
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = '';
  String _coverUrl = '';
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Pick and upload image
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    final url = await _cloudinary.uploadImage(pickedFile);

    if (url != null) {
      setState(() => _coverUrl = url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed')),
      );
    }

    setState(() => _isUploading = false);
  }

  // Save book
  void _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a cover image')),
      );
      return;
    }

    final book = Book(
      id: '', // Firestore will generate ID
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      category: _category,
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      coverUrl: _coverUrl,
      description: _descriptionController.text.trim(),
    );

    setState(() => _isUploading = true);

    try {
      await _firestore.addBook(book);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book added successfully!')),
      );

      // Reset form
      _formKey.currentState!.reset();
      _titleController.clear();
      _authorController.clear();
      _priceController.clear();
      _descriptionController.clear();
      setState(() {
        _coverUrl = '';
        _category = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add book: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Book'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),

              // Author
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author'),
                validator: (value) => value!.isEmpty ? 'Enter author' : null,
              ),
              const SizedBox(height: 12),

              // Category Dropdown
              FutureBuilder<QuerySnapshot>(
                future:
                    FirebaseFirestore.instance.collection("categories").get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text(
                        "⚠ No categories found. Please add some first.");
                  }

                  final categories =
                      docs.map((doc) => doc["name"] as String).toList();

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Category"),
                    value: _category.isNotEmpty ? _category : null,
                    items: categories
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _category = value!);
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? "Please select a category"
                        : null,
                  );
                },
              ),
              const SizedBox(height: 12),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 12),

              // Cover Image
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : _coverUrl.isEmpty
                      ? ElevatedButton.icon(
                          onPressed: _pickAndUploadImage,
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload Cover Image'),
                        )
                      : Column(
                          children: [
                            Image.network(_coverUrl, height: 150),
                            const SizedBox(height: 8),
                            ElevatedButton(
                                onPressed: _pickAndUploadImage,
                                child: const Text('Change Image')),
                          ],
                        ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _saveBook,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44)),
                child: const Text('Save Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
