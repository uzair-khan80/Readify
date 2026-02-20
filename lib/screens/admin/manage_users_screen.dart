 // lib/screens/admin/manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F1724) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: secondaryTextColor),
                  const SizedBox(height: 16),
                  Text('No users found', 
                    style: TextStyle(color: textColor, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Users will appear here once they register',
                    style: TextStyle(color: secondaryTextColor)),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: cardColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, users.length, 'Total Users', Icons.people),
                        _buildStatItem(context, 
                          _countUsersWithRatings(users), 'Active Raters', Icons.star),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Users List Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Text('User List', 
                      style: TextStyle(
                        color: textColor, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      )),
                    const Spacer(),
                    Text('${users.length} users', 
                      style: TextStyle(color: secondaryTextColor)),
                  ],
                ),
              ),
              
              // Users List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index].data() as Map<String, dynamic>;
                      final email = user['email'] ?? 'Unknown';
                      final name = user['name'] ?? 'Unknown';
                      final joinDate = user['createdAt'] != null 
                          ? (user['createdAt'] as Timestamp).toDate() 
                          : null;

                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person, color: Colors.blue[700]),
                          ),
                          title: Text(name, 
                            style: TextStyle(
                              color: textColor, 
                              fontWeight: FontWeight.w600,
                              fontSize: 16
                            )),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(email, 
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 14
                                )),
                              if (joinDate != null)
                                Text(
                                  'Joined: ${_formatDate(joinDate)}',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12
                                  ),
                                ),
                            ],
                          ),
                          trailing: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collectionGroup('ratings')
                                .where('userId', isEqualTo: users[index].id)
                                .snapshots(),
                            builder: (context, ratingsSnapshot) {
                              final ratingCount = ratingsSnapshot.data?.docs.length ?? 0;
                              return Chip(
                                backgroundColor: ratingCount > 0 
                                    ? Colors.green.withOpacity(0.1) 
                                    : Colors.grey.withOpacity(0.1),
                                label: Text(
                                  '$ratingCount rating${ratingCount != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: ratingCount > 0 ? Colors.green : secondaryTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500
                                  ),
                                ),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            },
                          ),
                          children: [
                            Divider(
                              color: (secondaryTextColor ?? Colors.grey).withOpacity(0.2), 
                              height: 1
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ratings Given:', 
                                    style: TextStyle(
                                      color: textColor, 
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14
                                    )),
                                  const SizedBox(height: 12),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collectionGroup('ratings')
                                        .where('userId', isEqualTo: users[index].id)
                                        .snapshots(),
                                    builder: (context, ratingsSnapshot) {
                                      if (ratingsSnapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator.adaptive());
                                      }
                                      
                                      if (!ratingsSnapshot.hasData || ratingsSnapshot.data!.docs.isEmpty) {
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: backgroundColor,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline, 
                                                color: secondaryTextColor, size: 20),
                                              const SizedBox(width: 8),
                                              Text('No ratings given yet', 
                                                style: TextStyle(color: secondaryTextColor)),
                                            ],
                                          ),
                                        );
                                      }

                                      final ratings = ratingsSnapshot.data!.docs;

                                      return Column(
                                        children: ratings.map((r) {
                                          final rData = r.data() as Map<String, dynamic>;
                                          final bookTitle = rData['bookTitle'] ?? 'Unknown Book';
                                          final rating = (rData['rating'] ?? 0).toDouble();
                                          final review = rData['review']?.toString();

                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            color: backgroundColor,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(
                                                color: (secondaryTextColor ?? Colors.grey).withOpacity(0.1)
                                              ),
                                            ),
                                            child: ListTile(
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8
                                              ),
                                              leading: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.star, 
                                                  color: Colors.orange, size: 18),
                                              ),
                                              title: Text(bookTitle, 
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500
                                                )),
                                              subtitle: review != null && review.isNotEmpty
                                                  ? Text(review,
                                                      style: TextStyle(
                                                        color: secondaryTextColor,
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis)
                                                  : null,
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(rating.toStringAsFixed(1), 
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14
                                                    )),
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.star, 
                                                    color: Colors.orange, size: 16),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, int count, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];
    
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue[700], size: 24),
        ),
        const SizedBox(height: 8),
        Text(count.toString(),
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold
          )),
        Text(label,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 12,
          )),
      ],
    );
  }

  int _countUsersWithRatings(List<QueryDocumentSnapshot> users) {
    // This is a simplified implementation - you might want to enhance this
    // with actual rating counts from Firestore in a real scenario
    return users.length; // Placeholder
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}