import 'package:flutter/material.dart';

// ==================== COLOR CONSTANTS (DEFINED HERE) ====================
const Color kPrimaryColor = Color(0xFF2A2E45); // Deep charcoal
const Color kSecondaryColor = Color(0xFF6C5CE7); // Rich purple
const Color kAccentColor = Color(0xFF00B894); // Mint green
const Color kSoftPurple = Color(0xFFA29BFE); // Light purple
const Color kSoftPink = Color(0xFFFF7675); // Soft pink
const Color kSoftOrange = Color(0xFFFDCB6E); // Warm orange
const Color kSoftBlue = Color(0xFF74B9FF); // Sky blue
const Color kBackgroundStart = Color(0xFFE8EEF9); // Light blue-gray
const Color kBackgroundEnd = Color(0xFFF5F0FF); // Light purple
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF2D3436); // Dark gray
const Color kTextSecondary = Color(0xFF636E72); // Medium gray
const Color kSuccessColor = Color(0xFF059669); // Dark green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red

class FeeHistoryScreen extends StatelessWidget {
   FeeHistoryScreen({Key? key}) : super(key: key);

  // FIXED: Changed from 'const' to regular list because of dynamic data
  final List<Map<String, dynamic>> transactions = [
    {
      'childName': 'Ava Carter',
      'date': '2024-05-15',
      'amount': 1000.00,
      'method': 'Credit Card',
      'receipt': 'RCP001',
    },
    {
      'childName': 'Ava Carter',
      'date': '2024-05-01',
      'amount': 800.00,
      'method': 'Bank Transfer',
      'receipt': 'RCP002',
    },
    {
      'childName': 'Liam Carter',
      'date': '2024-05-10',
      'amount': 2800.00,
      'method': 'Cash',
      'receipt': 'RCP003',
    },
  ];

  // Helper method to calculate total safely
  double _calculateTotal() {
    return transactions.fold(0.0, (sum, t) {
      final amount = t['amount'];
      if (amount is num) {
        return sum + amount.toDouble();
      }
      return sum;
    });
  }

  // Helper method to get appropriate icon for payment method
  IconData _getPaymentIcon(String method) {
    if (method.contains('Credit Card') || method.contains('card')) {
      return Icons.credit_card_rounded;
    } else if (method.contains('Bank Transfer') || method.contains('bank')) {
      return Icons.account_balance_rounded;
    } else if (method.contains('Cash')) {
      return Icons.payments_rounded;
    } else {
      return Icons.receipt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalPaid = _calculateTotal();

    return Scaffold(
      backgroundColor: kBackgroundEnd,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text('Payment History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Total Paid Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kSuccessColor, kSuccessColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: kSuccessColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Paid',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${totalPaid.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'All time',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Transactions List Header
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // Transactions List
                ...List.generate(
                  transactions.length,
                  (index) {
                    final transaction = transactions[index];
                    
                    // Safe extraction with default values
                    final String childName = transaction['childName'] ?? 'Unknown';
                    final String date = transaction['date'] ?? 'Unknown';
                    final String method = transaction['method'] ?? 'Unknown';
                    final String receipt = transaction['receipt'] ?? 'Unknown';
                    
                    // Safe amount conversion
                    double amount = 0.0;
                    if (transaction['amount'] is num) {
                      amount = (transaction['amount'] as num).toDouble();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Icon based on payment method
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kSoftPurple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getPaymentIcon(method),
                              color: kSoftPurple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Transaction details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  childName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: kTextPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$date • $method',
                                  style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Receipt: $receipt',
                                  style: TextStyle(
                                    color: kSoftPurple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Amount and status
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: kSuccessColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kSuccessColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Paid',
                                  style: TextStyle(
                                    color: kSuccessColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}