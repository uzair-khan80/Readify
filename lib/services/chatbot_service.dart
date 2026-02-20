// lib/services/chatbot_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ChatbotService {
  // ✅ DeepSeek API Key (replace if needed)
  static const String _apiKey = 'sk-4d982a073f9341d9a7b3204f063cf536';
  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Detect language of user input
  String _detectLanguage(String text) {
    final urduRegex = RegExp(r'[\u0600-\u06FF]');
    final englishRegex = RegExp(r'[a-zA-Z]');
    
    bool hasUrdu = urduRegex.hasMatch(text);
    bool hasEnglish = englishRegex.hasMatch(text);
    
    if (hasUrdu && !hasEnglish) return 'urdu';
    if (hasEnglish && !hasUrdu) return 'english';
    return 'mixed';
  }

  // Search books in Firestore
  Future<List<Map<String, dynamic>>> _searchBooks(String query, String language) async {
    try {
      final booksRef = _firestore.collection('books');
      QuerySnapshot snapshot;
      
      snapshot = await booksRef
          .where('keywords', arrayContains: query.toLowerCase())
          .limit(10)
          .get();
      
      if (snapshot.docs.isEmpty) {
        snapshot = await booksRef
            .where('title', isGreaterThanOrEqualTo: query)
            .where('title', isLessThan: query + 'z')
            .limit(10)
            .get();
      }
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'author': data['author'] ?? '',
          'price': data['price'] ?? 0,
          'category': data['category'] ?? '',
          'description': data['description'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Book search error: $e');
      return [];
    }
  }

  // Get recommendations
  Future<List<Map<String, dynamic>>> _getRecommendations(String category, double? maxPrice) async {
    try {
      Query query = _firestore.collection('books');
      
      if (category.toLowerCase() != 'all') {
        query = query.where('category', isEqualTo: category);
      }
      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }
      
      final snapshot = await query.limit(10).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'author': data['author'] ?? '',
          'price': data['price'] ?? 0,
          'category': data['category'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Recommendation error: $e');
      return [];
    }
  }

  // ✅ Generate AI response via DeepSeek API
  Future<String> _generateAIResponse(String userMessage, String language, List<Map<String, dynamic>> books) async {
    try {
      String systemPrompt = '''
You are a helpful bookstore assistant. Respond in the same language as the user's query (Urdu, English, or mixed).
Only answer book-related queries.
Available books: ${books.map((b) => '${b['title']} by ${b['author']} - Rs. ${b['price']}').join(', ')}.
If no relevant books found, politely say so in the user's language.
''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('DeepSeek error: ${response.body}');
        return _getFallbackResponse(userMessage, language);
      }
    } catch (e) {
      debugPrint('AI API error: $e');
      return _getFallbackResponse(userMessage, language);
    }
  }

  // Fallback
  String _getFallbackResponse(String userMessage, String language) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (language == 'urdu') {
      if (lowerMessage.contains('کتاب') || lowerMessage.contains('بُک')) {
        return 'میں آپ کی کتابوں کے بارے میں مدد کر سکتا ہوں۔ براہ کرم اپنی درخواست مزید وضاحت سے بتائیں۔';
      }
      return 'معذرت، میں اس وقت آپ کی درخواست پر کارروائی نہیں کر سکتا۔ براہ کرم بعد میں کوشش کریں۔';
    } else {
      if (lowerMessage.contains('book')) {
        return 'I can help you with books. Please specify your request in more detail.';
      }
      return 'Sorry, I cannot process your request right now. Please try again later.';
    }
  }

  // Main entry
  Future<String> processMessage(String userMessage) async {
    final language = _detectLanguage(userMessage);
    List<Map<String, dynamic>> relevantBooks = [];

    final lowerMessage = userMessage.toLowerCase();
    
    final priceMatch = RegExp(r'(\d+)\s*(روپے|روپیہ|rs|rp|pkr)').firstMatch(userMessage);
    double? maxPrice = priceMatch != null ? double.parse(priceMatch.group(1)!) : null;

    String category = 'All';
    final categoryKeywords = {
      'fiction': ['فکشن', 'fiction', 'ناول', 'novel'],
      'non-fiction': ['غیر فکشن', 'non-fiction', 'تاریخ', 'history'],
      'science': ['سائنس', 'science', 'سائنسی', 'scientific'],
      'technology': ['ٹیکنالوجی', 'technology', 'ٹیک', 'tech'],
      'biography': ['سوانح', 'biography', 'آتما کتھا', 'autobiography'],
    };

    for (final entry in categoryKeywords.entries) {
      if (entry.value.any((keyword) => lowerMessage.contains(keyword))) {
        category = entry.key;
        break;
      }
    }

    if (maxPrice != null || category != 'All') {
      relevantBooks = await _getRecommendations(category, maxPrice);
    } else {
      relevantBooks = await _searchBooks(userMessage, language);
    }

    return await _generateAIResponse(userMessage, language, relevantBooks);
  }
}
