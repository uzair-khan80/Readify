// lib/screens/home/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/book_model.dart';
import '../search/search_screen.dart';

// Move ChatMessage and MessageType to top level
enum MessageType { user, ai, error }

class ChatMessage {
  final MessageType type;
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.type, required this.content, DateTime? timestamp}) 
    : timestamp = timestamp ?? DateTime.now();

  Map<String, String> toMap() => {
    'type': type.name,
    'content': content,
  };
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String selectedCategory = 'All';
  final firestore = FirestoreService();
  List<String> categories = ['All']; // start with 'All'

  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Enhanced Chatbot state variables
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  static const String _apiKey = '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';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'deepseek/deepseek-chat';
  bool _isChatLoading = false;
  List<ChatMessage> _chatHistory = [];
  bool _isChatOpen = false;
  bool _ttsEnabled = false; // TTS only activates after user interaction

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    final fetchedCategories = snapshot.docs.map((doc) => doc['name'] as String).toList();
    setState(() {
      categories = ['All', ...fetchedCategories];
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadCategories();
    
    // Initialize TTS with error handling
    _initializeTTS();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // Enhanced Chatbot methods
  Future<void> _initializeTTS() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.45);
      // Don't auto-start TTS - wait for user interaction
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> _fetchAIResponse(String prompt) async {
    if (_isChatLoading) return;

    setState(() {
      _isChatLoading = true;
      _chatHistory.add(ChatMessage(type: MessageType.user, content: prompt));
    });

    try {
      final response = await _makeApiRequest(prompt);
      await _handleApiResponse(response);
    } catch (e) {
      _handleError('Network Error: $e');
    } finally {
      _completeChatInteraction();
    }
  }

  Future<http.Response> _makeApiRequest(String prompt) async {
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'HTTP-Referer': 'https://readify.com',
      'X-Title': 'Readify App',
      'Content-Type': 'application/json',
    };

    final messages = _chatHistory
        .map((msg) => {
              "role": msg.type == MessageType.user ? "user" : "assistant",
              "content": msg.content
            })
        .toList();

    final body = jsonEncode({
      "model": _model,
      "messages": messages,
    });

    return await http.post(Uri.parse(_apiUrl), headers: headers, body: body);
  }

  Future<void> _handleApiResponse(http.Response response) async {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final reply = data['choices'][0]['message']['content'].trim();
      
      setState(() {
        _chatHistory.add(ChatMessage(type: MessageType.ai, content: reply));
      });

      // Only speak if TTS is enabled by user
      if (_ttsEnabled) {
        await _speakText(reply);
      }
    } else {
      _handleError('Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _speakText(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  void _handleError(String errorMessage) {
    setState(() {
      _chatHistory.add(ChatMessage(type: MessageType.error, content: errorMessage));
    });
    debugPrint('Chatbot Error: $errorMessage');
  }

  void _completeChatInteraction() {
    setState(() => _isChatLoading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleChatSend() async {
    final input = _chatController.text.trim();
    if (input.isEmpty) return;

    await _flutterTts.stop();
    _chatController.clear();
    FocusScope.of(context).unfocus();
    _fetchAIResponse(input);
  }

  void _startNewChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Chat'),
        content: const Text('Clear current conversation?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _chatHistory.clear());
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String? text) {
    if (text == null) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard")),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final isUser = message.type == MessageType.user;
    final isError = message.type == MessageType.error;
    
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isError ? Colors.red.withOpacity(0.8) : 
                   isUser ? const Color(0xFF10A37F) : const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            message.content,
            style: TextStyle(
              fontSize: 16,
              color: isUser || isError ? Colors.white : Colors.white70,
            ),
          ),
        ),
        if (!isUser && !isError)
          TextButton(
            onPressed: () => _copyToClipboard(message.content),
            child: const Text('Copy', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10A37F).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Text("Typing", style: TextStyle(fontSize: 16)),
          SizedBox(width: 4),
          _AnimatedDots(),
        ],
      ),
    );
  }

  void _openChatDialog() {
    setState(() {
      _isChatOpen = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                // TTS Toggle Button
                IconButton(
                  icon: Icon(
                    _ttsEnabled ? Icons.volume_up : Icons.volume_off,
                    color: _ttsEnabled ? const Color(0xFF10A37F) : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _ttsEnabled = !_ttsEnabled;
                    });
                    if (!_ttsEnabled) {
                      _flutterTts.stop();
                    }
                  },
                  tooltip: _ttsEnabled ? 'Disable voice' : 'Enable voice',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isChatOpen = false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatHistory.length + (_isChatLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isChatLoading && index == _chatHistory.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildChatMessage(_chatHistory[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        decoration: InputDecoration(
                          hintText: "Ask about books...",
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onSubmitted: (_) => _handleChatSend(),
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isChatLoading ? null : _handleChatSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10A37F),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _startNewChat,
            child: const Text('New Chat'),
          ),
        ],
      ),
    ).then((_) {
      setState(() {
        _isChatOpen = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[700];
    final scaffoldColor = isDark ? const Color(0xFF0F1724) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: scaffoldColor,

      drawer: _buildGlassmorphismDrawer(isDark, context),

      appBar: AppBar(
        title: const Text('Readify', style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.5,
        )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              ),
              child: Icon(Icons.menu, color: textColor, size: 22),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          _buildAppBarAction(
            icon: Icons.search,
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const SearchScreen(),
                transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
              ),
            ),
            textColor: textColor,
            isDark: isDark,
          ),
          _buildAppBarAction(
            icon: isDark ? Icons.wb_sunny : Icons.nights_stay,
            onPressed: () => themeProvider.toggleTheme(),
            textColor: textColor,
            isDark: isDark,
          ),
          Stack(
            children: [
              _buildAppBarAction(
                icon: Icons.shopping_cart_outlined,
                onPressed: () => Navigator.pushNamed(context, '/cart'),
                textColor: textColor,
                isDark: isDark,
              ),
              if (cart.items.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.redAccent, blurRadius: 8, spreadRadius: 1),
                      ],
                    ),
                    child: Text(
                      cart.items.length.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),

      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () async => cart.loadCart(),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            color: Colors.deepPurpleAccent,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreetingSection(secondaryTextColor, textColor),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Featured', textColor),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: _buildFeaturedBooks(isDark),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Categories', textColor),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: _buildCategoriesSection(isDark, textColor),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Recommended', textColor),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                
                _buildRecommendedBooks(isDark, textColor),
                
                // Add extra padding at the bottom to prevent overflow
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100), // Extra space for FAB and bottom nav
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: _buildModernBottomNavBar(isDark),
      
      // Add Floating Action Button for chatbot
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 70), // Position above bottom nav
        child: FloatingActionButton(
          onPressed: _openChatDialog,
          backgroundColor: const Color(0xFF10A37F),
          child: Icon(
            _isChatOpen ? Icons.chat : Icons.auto_awesome,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildGlassmorphismDrawer(bool isDark, BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E293B).withOpacity(0.95), const Color(0xFF0F1724).withOpacity(0.95)]
                : [Colors.white.withOpacity(0.95), const Color(0xFFF8F9FA).withOpacity(0.95)],
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.deepPurple.shade700, Colors.purple.shade800]
                        : [Colors.deepPurpleAccent, Colors.purpleAccent],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("users")
                      .doc(user?.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final name = data?['name'] ?? "Guest User";
                    final email = user?.email ?? "guest@example.com";

                    return UserAccountsDrawerHeader(
                      decoration: const BoxDecoration(color: Colors.transparent),
                      accountName: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      accountEmail: Text(
                        email,
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                      ),
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(
                          name.isNotEmpty ? name[0] : "G",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildDrawerItem(Icons.person_outline, 'Profile', () => Navigator.pushNamed(context, '/profile'), isDark),
                      _buildDrawerItem(Icons.favorite_border, 'Wishlist', () => Navigator.pushNamed(context, '/wishlist'), isDark),
                      _buildDrawerItem(Icons.shopping_bag_outlined, 'Orders', () => Navigator.pushNamed(context, '/my-orders'), isDark),
                      const Divider(indent: 20, endIndent: 20, height: 40),
                      _buildDrawerItem(Icons.logout, 'Logout', () {
                        FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      }, isDark),
                      // Add extra padding at the bottom
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarAction({required IconData icon, required VoidCallback onPressed, required Color textColor, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
          child: Icon(icon, color: textColor, size: 20),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildGreetingSection(Color? secondaryTextColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Good Morning,', style: TextStyle(
          color: secondaryTextColor ?? Colors.grey[700], // Provide fallback
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        )),
        const SizedBox(height: 8),
        Text('Find your next read', style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.2,
          letterSpacing: -0.5,
        )),
        const SizedBox(height: 16),
        Container(
          height: 4,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(title, style: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: textColor,
      letterSpacing: -0.3,
    ));
  }

  Widget _buildFeaturedBooks(bool isDark) {
    return SizedBox(
      height: 260,
      child: StreamBuilder<List<Book>>(
        stream: firestore.streamFeaturedBooks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final books = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(right: 20),
              child: FeaturedCard(book: books[i], isDark: isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection(bool isDark, Color textColor) {
    return SizedBox(
      height: 56,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: categories.map((c) {
          final selected = c == selectedCategory;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(c, style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : textColor,
              )),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  selectedCategory = c;
                });
              },
              selectedColor: Colors.deepPurpleAccent,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
              labelStyle: TextStyle(color: selected ? Colors.white : textColor),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? Colors.deepPurpleAccent : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  width: selected ? 0 : 1,
                ),
              ),
              elevation: selected ? 4 : 0,
              shadowColor: Colors.deepPurple.withOpacity(0.3),
            ),
          );
        }).toList(),
      ),
    );
  }

  SliverToBoxAdapter _buildRecommendedBooks(bool isDark, Color textColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: StreamBuilder<List<Book>>(
          stream: firestore.streamAllBooks(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: textColor)),
              );
            }

            // Exclude featured books
           List<Book> allBooks = snapshot.data ?? [];
          List<Book> featuredBooks = [];
          firestore.streamFeaturedBooks(limit: 3).first.then((value) {
            featuredBooks = value;
          });

            List<Book> books = snapshot.data ?? [];
            if (selectedCategory != 'All') {
              books = books.where((b) => b.category == selectedCategory).toList();
            }
            if (books.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text('No books in this category.', style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 16,
                  )),
                ),
              );
            }

            return GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: books.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (ctx, idx) => BookGridCard(book: books[idx]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
          child: Icon(icon, color: isDark ? Colors.white70 : Colors.black87, size: 20),
        ),
        title: Text(title, style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        )),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildModernBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.deepPurpleAccent,
          unselectedItemColor: isDark ? Colors.white54 : Colors.grey[600],
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          onTap: (index) {
            if (index < 0 || index >= 5) return;
            setState(() => _currentIndex = index);
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
            } else if (index == 2) {
              Navigator.pushNamed(context, '/wishlist');
            } else if (index == 3) {
              Navigator.pushNamed(context, '/profile');
            } else if (index == 4) {
              Navigator.pushNamed(context, '/cart');
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 0 ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.home_outlined, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                ),
                child: const Icon(Icons.home_filled, size: 22),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 1 ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.search, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                ),
                child: const Icon(Icons.search, size: 22),
              ),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 2 ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.favorite_border, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                ),
                child: const Icon(Icons.favorite, size: 22),
              ),
              label: 'Wishlist',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 3 ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.person_outline, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                ),
                child: const Icon(Icons.person, size: 22),
              ),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 4 ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.shopping_cart_outlined, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                ),
                child: const Icon(Icons.shopping_cart, size: 22),
              ),
              label: 'Cart',
            ),
          ],
        ),
      ),
    );
  }
}

class FeaturedCard extends StatelessWidget {
  final Book book;
  final bool isDark;
  const FeaturedCard({super.key, required this.book, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/book', arguments: book),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F1724)]
                : [const Color(0xFF7C3AED), const Color(0xFF9333EA)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Hero(
                    tag: 'book_${book.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: book.coverUrl.isNotEmpty
                          ? Image.network(
                              book.coverUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: Icon(Icons.book, size: 50, color: Colors.white.withOpacity(0.7)),
                            ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Rs. ${book.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookGridCard extends StatelessWidget {
  final Book book;
  const BookGridCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white60 : Colors.grey[700];

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/book', arguments: book),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: Hero(
                tag: 'book_${book.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: book.coverUrl.isNotEmpty
                      ? Image.network(
                          book.coverUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(Icons.book, size: 40, color: textColor.withOpacity(0.5)),
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${book.author} • ${book.category}',
                      style: TextStyle(
                        fontSize: 11,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs. ${book.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_shopping_cart,
                            size: 14,
                            color: Colors.deepPurpleAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated dots widget for typing indicator
class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => __AnimatedDotsState();
}

class __AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
    _dotCount = IntTween(begin: 0, end: 3).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (context, child) {
        final dots = '.' * (_dotCount.value + 1);
        return Text(dots, style: const TextStyle(fontSize: 16));
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}