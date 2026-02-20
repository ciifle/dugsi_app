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

class FeePaymentScreen extends StatelessWidget {
  final Map<String, dynamic> fee;

  const FeePaymentScreen({Key? key, required this.fee}) : super(key: key);

  // Helper method to get initials safely
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  // Safe extraction methods
  String _getChildName() {
    return fee['childName'] ?? 'Unknown';
  }

  String _getClassName() {
    return fee['className'] ?? 'Not Assigned';
  }

  double _getTotalFee() {
    final value = fee['totalFee'];
    if (value is num) return value.toDouble();
    return 0.0;
  }

  double _getPaidAmount() {
    final value = fee['paidAmount'];
    if (value is num) return value.toDouble();
    return 0.0;
  }

  double _getDueAmount() {
    final value = fee['dueAmount'];
    if (value is num) return value.toDouble();
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // Safe extraction
    final String childName = _getChildName();
    final String className = _getClassName();
    final double totalFee = _getTotalFee();
    final double paidAmount = _getPaidAmount();
    final double dueAmount = _getDueAmount();

    return Scaffold(
      backgroundColor: kBackgroundEnd,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text('Make Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Child Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Child Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kSoftPurple, kSoftBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(childName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              childName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                              ),
                            ),
                            Text(
                              className,
                              style: TextStyle(
                                color: kTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    'Total Fee',
                    '\$${totalFee.toStringAsFixed(2)}',
                    kTextPrimary,
                  ),
                  _buildInfoRow(
                    'Paid Amount',
                    '\$${paidAmount.toStringAsFixed(2)}',
                    kSuccessColor,
                  ),
                  _buildInfoRow(
                    'Due Amount',
                    '\$${dueAmount.toStringAsFixed(2)}',
                    kWarningColor,
                  ),
                  const Divider(height: 30),
                  _buildInfoRow(
                    'Payable Now',
                    '\$${dueAmount.toStringAsFixed(2)}',
                    kAccentColor,
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Method
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PaymentMethodCard(
                    icon: Icons.credit_card_rounded,
                    title: 'Credit / Debit Card',
                    subtitle: 'Pay with Visa, Mastercard',
                    selected: true,
                  ),
                  const SizedBox(height: 8),
                  _PaymentMethodCard(
                    icon: Icons.account_balance_rounded,
                    title: 'Bank Transfer',
                    subtitle: 'Direct bank transfer',
                    selected: false,
                  ),
                  const SizedBox(height: 8),
                  _PaymentMethodCard(
                    icon: Icons.payments_rounded,
                    title: 'Cash',
                    subtitle: 'Pay at school office',
                    selected: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Pay Button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kAccentColor, kAccentColor.withOpacity(0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kAccentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Payment Successful'),
                        content: const Text(
                          'Your payment has been processed successfully.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Text(
                      "Pay Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

  Widget _buildInfoRow(
    String label,
    String value,
    Color color, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: kTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? kAccentColor : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? kAccentColor : kTextSecondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? kAccentColor : kTextPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (selected)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kAccentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}
