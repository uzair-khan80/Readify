class Book {
  final String id;
  final String title;
  final String author;
  final String category;
  final double price;
  final String coverUrl;
  final String description;
  final double rating; // ✅ sirf user ratings se update hoga

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.price,
    required this.coverUrl,
    required this.description,
    this.rating = 0.0, // ✅ default value
  });

  // fromMap
  factory Book.fromMap(Map<String, dynamic> map, String docId) {
    return Book(
      id: docId,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      coverUrl: map['coverUrl'] ?? '',
      description: map['description'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(), // ✅ safe
    );
  }

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'category': category,
      'price': price,
      'coverUrl': coverUrl,
      'description': description,
      // 👇 yahan rating mat bhejna jab admin add/update kare
      // rating sirf FirestoreService.addBook me default set hoga
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? category,
    double? price,
    String? coverUrl,
    String? description,
    double? rating,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      price: price ?? this.price,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      rating: rating ?? this.rating,
    );
  }
}
