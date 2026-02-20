// lib/screens/admin/admin_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  Future<void> _updateStatus(String orderId, String status, String userId) async {
    final db = FirebaseFirestore.instance;
    await db.collection("orders").doc(orderId).update({"status": status});
    await db.collection("users").doc(userId).collection("orders").doc(orderId).update({"status": status});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).colorScheme.background;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Order Management"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("orders").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData) {
            return const SizedBox();
          }

          final orders = snapshot.data!.docs;
          final pendingOrders = orders.where((order) {
            final data = order.data() as Map<String, dynamic>;
            return data["status"] == "pending";
          }).length;
          
          final approvedOrders = orders.where((order) {
            final data = order.data() as Map<String, dynamic>;
            return data["status"] == "approved";
          }).length;
          
          final totalRevenue = orders.fold<double>(0, (sum, order) {
            final data = order.data() as Map<String, dynamic>;
            return sum + (data["total"] ?? 0);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards Section - FIXED: Revenue card value display issue
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                    final childAspectRatio = constraints.maxWidth > 600 ? 1.8 : 1.5;
                    
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildStatCard(
                          context,
                          "Total Orders",
                          orders.length.toString(),
                          Icons.shopping_cart_outlined,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          context,
                          "Pending",
                          pendingOrders.toString(),
                          Icons.pending_actions_outlined,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          context,
                          "Approved",
                          approvedOrders.toString(),
                          Icons.verified_outlined,
                          Colors.green,
                        ),
                        _buildStatCard(
                          context,
                          "Total Revenue",
                          "Rs ${_formatRevenue(totalRevenue)}", // FIXED: Proper revenue formatting
                          Icons.attach_money,
                          Colors.purple,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Orders List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Recent Orders",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      constraints: const BoxConstraints(maxWidth: 100),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: secondaryTextColor!.withOpacity(0.2)),
                      ),
                      child: Text(
                        "${orders.length} orders",
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Orders List Section
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("orders")
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: secondaryTextColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No orders yet",
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Orders will appear here once placed",
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final orders = snapshot.data!.docs;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 768) {
                          return _buildDataTable(context, orders);
                        } else {
                          return _buildMobileList(context, orders);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.05),
              color.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: _getValueFontSize(value), // FIXED: Dynamic font size based on value length
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Helper function to format revenue properly
  String _formatRevenue(double revenue) {
    if (revenue >= 1000000) {
      return '${(revenue / 1000000).toStringAsFixed(1)}M';
    } else if (revenue >= 1000) {
      return '${(revenue / 1000).toStringAsFixed(1)}K';
    } else {
      return revenue.toStringAsFixed(0);
    }
  }

  // FIXED: Dynamic font size based on value length
  double _getValueFontSize(String value) {
    if (value.length <= 5) return 18;
    if (value.length <= 8) return 16;
    if (value.length <= 12) return 14;
    return 12;
  }

  Widget _buildDataTable(BuildContext context, List<QueryDocumentSnapshot> orders) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 16,
                headingRowHeight: 50,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 60,
                headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) => secondaryTextColor!.withOpacity(0.1),
                ),
                columns: [
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 80),
                      child: Text("Order ID", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    ),
                  ),
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 120),
                      child: Text("User", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    ),
                  ),
                  DataColumn(
                    label: Text("Items", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ),
                  DataColumn(
                    label: Text("Total", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ),
                  DataColumn(
                    label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ),
                ],
                rows: orders.map((orderDoc) {
                  final order = orderDoc.data() as Map<String, dynamic>;
                  final orderId = orderDoc.id;
                  final userEmail = order["userEmail"] ?? order["email"] ?? "N/A";
                  final items = order["items"] as List<dynamic>;
                  final status = order["status"] ?? "pending";
                  final total = order["total"] ?? 0;

                  Color statusColor;
                  switch (status) {
                    case "approved":
                      statusColor = Colors.green;
                      break;
                    case "rejected":
                      statusColor = Colors.red;
                      break;
                    default:
                      statusColor = Colors.orange;
                  }

                  return DataRow(
                    cells: [
                      DataCell(
                        Tooltip(
                          message: orderId,
                          child: Text(
                            "#${orderId.substring(0, 6)}",
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Tooltip(
                          message: userEmail,
                          child: Text(
                            userEmail,
                            style: TextStyle(color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Text("${items.length} items", style: TextStyle(color: textColor)),
                      ),
                      DataCell(
                        Text(
                          "Rs ${total.toStringAsFixed(0)}", // FIXED: Added space for better readability
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 80),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        status == "pending"
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.check, color: Colors.green, size: 16),
                                    ),
                                    onPressed: () => _updateStatus(orderId, "approved", order["userId"]),
                                    tooltip: "Approve",
                                  ),
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.close, color: Colors.red, size: 16),
                                    ),
                                    onPressed: () => _updateStatus(orderId, "rejected", order["userId"]),
                                    tooltip: "Reject",
                                  ),
                                ],
                              )
                            : Text(
                                "Completed",
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<QueryDocumentSnapshot> orders) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final orderDoc = orders[index];
        final order = orderDoc.data() as Map<String, dynamic>;
        final orderId = orderDoc.id;
        final userId = order["userId"];
        final userEmail = order["userEmail"] ?? order["email"] ?? "N/A";
        final items = order["items"] as List<dynamic>;
        final status = order["status"] ?? "pending";
        final total = order["total"] ?? 0;
        final createdAt = order["createdAt"] != null 
            ? (order["createdAt"] as Timestamp).toDate() 
            : null;

        Color statusColor;
        switch (status) {
          case "approved":
            statusColor = Colors.green;
            break;
          case "rejected":
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.orange;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Order #${orderId.substring(0, 6)}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Order Details
                _buildDetailRow(Icons.person_outline, "User", userEmail, secondaryTextColor!),
                _buildDetailRow(Icons.shopping_basket_outlined, "Items", "${items.length} products", secondaryTextColor),
                _buildDetailRow(Icons.calendar_today_outlined, "Date", 
                    createdAt != null ? _formatDate(createdAt) : "N/A", secondaryTextColor),
                
                const SizedBox(height: 8),
                
                // Total Amount
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Amount",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Rs ${total.toStringAsFixed(0)}", // FIXED: Added space
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),

                // Items Preview
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    "Order Items (${items.length})",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),

                ...items.take(2).map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: secondaryTextColor.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        item["coverUrl"] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item["coverUrl"],
                                  width: 35,
                                  height: 45,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 35,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: secondaryTextColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(Icons.book, size: 20, color: secondaryTextColor),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 35,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: secondaryTextColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(Icons.book, size: 20, color: secondaryTextColor),
                              ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["title"] ?? "Unknown Book",
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Qty: ${item["quantity"]} × Rs ${(item["price"] ?? 0).toStringAsFixed(0)}", // FIXED: Added space
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "Rs ${((item["price"] ?? 0) * (item["quantity"] ?? 1)).toStringAsFixed(0)}", // FIXED: Added space
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                if (items.length > 2) 
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "+ ${items.length - 2} more items",
                      style: TextStyle(color: secondaryTextColor, fontSize: 11),
                    ),
                  ),

                // Actions
                if (status == "pending") ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _updateStatus(orderId, "approved", userId),
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text("Approve", style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _updateStatus(orderId, "rejected", userId),
                        icon: const Icon(Icons.close, size: 14),
                        label: const Text("Reject", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: secondaryColor),
          const SizedBox(width: 6),
          Text("$label: ", style: TextStyle(color: secondaryColor, fontSize: 11)),
          Expanded(
            child: Text(value, 
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}