// lib/screens/admin/books_list_screen.dart
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/book_model.dart';
import 'add_book_screen.dart';
import 'edit_book_screen.dart';

class BooksListScreen extends StatelessWidget {
  final _firestore = FirestoreService();

  BooksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Books Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBookScreen()),
          );
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Book added successfully")),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ✅ Stats Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<List<Book>>(
              stream: _firestore.streamAllBooks(),
              builder: (context, snapshot) {
                final totalBooks = snapshot.hasData ? snapshot.data!.length : 0;
                return Row(
                  children: [
                    _buildStatCard(
                      context: context,
                      title: "Total Books",
                      value: "$totalBooks",
                      icon: Icons.library_books,
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      context: context,
                      title: "Active",
                      value: "$totalBooks",
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _buildStatCard(
                      context: context,
                      title: "Last Updated",
                      value: "Now",
                      icon: Icons.update,
                      color: Colors.orange,
                    ),
                  ],
                );
              },
            ),
          ),

          // ✅ Books List / Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildBooksTable(context),
            ),
          ),
        ],
      ),
    );
  }

  // 📊 Stat Card
  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  // 📚 Books Table
  Widget _buildBooksTable(BuildContext context) {
    return StreamBuilder<List<Book>>(
      stream: _firestore.streamAllBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No books found."));
        }

        final books = snapshot.data!;

        return LayoutBuilder(
          builder: (context, constraints) {
            // ✅ Desktop / Tablet view
            if (constraints.maxWidth > 600) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: MaterialStateProperty.resolveWith(
                      (states) => Colors.grey.shade200),
                  columns: const [
                    DataColumn(label: Text('Cover')),
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Author')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: books.map((book) {
                    return DataRow(
                      cells: [
                        DataCell(
                          book.coverUrl.isNotEmpty
                              ? Image.network(
                                  book.coverUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image_not_supported,
                                  size: 40, color: Colors.grey),
                        ),
                        DataCell(SizedBox(
                          width: 150,
                          child: Text(
                            book.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                        DataCell(SizedBox(
                          width: 120,
                          child: Text(
                            book.author,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                        DataCell(Text("Rs. ${book.price}")),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blueAccent),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditBookScreen(book: book),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _firestore.deleteBook(book.id!);
                              },
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              );
            }

            // ✅ Mobile view
            return ListView.separated(
              itemCount: books.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  leading: book.coverUrl.isNotEmpty
                      ? Image.network(
                          book.coverUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported,
                          size: 40, color: Colors.grey),
                  title: Text(book.title),
                  subtitle: Text(book.author),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditBookScreen(book: book),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _firestore.deleteBook(book.id!);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
