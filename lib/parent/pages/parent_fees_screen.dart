import 'package:flutter/material.dart';
import 'package:kobac/parent/pages/fee_history_screen.dart';
// import 'package:kobac/parent/pages/fee_payment_screen.dart'; // Uncomment if this screen exists

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

class ParentFeesScreen extends StatefulWidget {
  const ParentFeesScreen({Key? key}) : super(key: key);

  @override
  State<ParentFeesScreen> createState() => _ParentFeesScreenState();
}

class _ParentFeesScreenState extends State<ParentFeesScreen> {
  final List<Map<String, dynamic>> childrenFees = [
    {
      'childName': 'Ava Carter',
      'className': 'Grade 6 - A',
      'totalFee': 2500.00,
      'paidAmount': 1800.00,
      'dueAmount': 700.00,
      'dueDate': '2024-06-15',
      'status': 'partial',
    },
    {
      'childName': 'Liam Carter',
      'className': 'Grade 8 - B',
      'totalFee': 2800.00,
      'paidAmount': 2800.00,
      'dueAmount': 0.00,
      'dueDate': '2024-06-10',
      'status': 'paid',
    },
    {
      'childName': 'Emma Carter',
      'className': 'Grade 4 - C',
      'totalFee': 2200.00,
      'paidAmount': 1100.00,
      'dueAmount': 1100.00,
      'dueDate': '2024-06-20',
      'status': 'partial',
    },
    {
      'childName': 'Noah Carter',
      'className': 'Grade 10 - D',
      'totalFee': 3200.00,
      'paidAmount': 0.00,
      'dueAmount': 3200.00,
      'dueDate': '2024-06-25',
      'status': 'unpaid',
    },
  ];

  double get totalDue =>
      childrenFees.fold(0, (sum, fee) => sum + (fee['dueAmount'] as double));
  double get totalPaid =>
      childrenFees.fold(0, (sum, fee) => sum + (fee['paidAmount'] as double));
  int get totalChildren => childrenFees.length;
  int get paidCount =>
      childrenFees.where((fee) => fee['status'] == 'paid').length;
  int get partialCount =>
      childrenFees.where((fee) => fee['status'] == 'partial').length;
  int get unpaidCount =>
      childrenFees.where((fee) => fee['status'] == 'unpaid').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoftPurple.withOpacity(0.05), // Replaced kBackgroundEnd
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          'Family Fees',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, kSecondaryColor, kSoftPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FeeHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Family Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        kSoftPurple.withOpacity(0.02),
                        kSoftBlue.withOpacity(0.02),
                      ], // Replaced kBackgroundStart/kBackgroundEnd
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kSoftPurple.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: kSoftBlue.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(-5, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  kSoftPurple,
                                  kSoftBlue,
                                  kSecondaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: kSoftPurple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Fee Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                            ),
                          ),
                          const Spacer(),
                          // Month chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kAccentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: kAccentColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: kAccentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'June 2024',
                                  style: TextStyle(
                                    color: kAccentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Main stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            label: 'Total Due',
                            value: '\$${totalDue.toStringAsFixed(0)}',
                            color: kWarningColor,
                            icon: Icons.warning_amber_rounded,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: kTextSecondary.withOpacity(0.2),
                          ),
                          _buildSummaryItem(
                            label: 'Total Paid',
                            value: '\$${totalPaid.toStringAsFixed(0)}',
                            color: kSuccessColor,
                            icon: Icons.check_circle_rounded,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: kTextSecondary.withOpacity(0.2),
                          ),
                          _buildSummaryItem(
                            label: 'Children',
                            value: '$totalChildren',
                            color: kSoftPurple,
                            icon: Icons.family_restroom_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Status chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatusChip(
                            label: 'Paid',
                            count: paidCount,
                            color: kSuccessColor,
                          ),
                          _buildStatusChip(
                            label: 'Partial',
                            count: partialCount,
                            color: kWarningColor,
                          ),
                          _buildStatusChip(
                            label: 'Unpaid',
                            count: unpaidCount,
                            color: kErrorColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Overall progress
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Overall Progress',
                                style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: kSoftPink.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${((totalPaid / (totalPaid + totalDue)) * 100).toStringAsFixed(1)}% Complete',
                                  style: TextStyle(
                                    color: kSoftPink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress bar
                          LinearProgressIndicator(
                            value: totalPaid / (totalPaid + totalDue),
                            backgroundColor: kTextSecondary.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              kSuccessColor,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Children Fees Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kWarningColor, kSoftPink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kWarningColor.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.family_restroom_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Children's Fees",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    // Count chip - FIXED: Changed from Icons.children_rounded to Icons.family_restroom
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kSoftPurple.withOpacity(0.1),
                            kSoftBlue.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: kSoftPurple.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.family_restroom,
                            size: 12,
                            color: kSoftPurple,
                          ), // FIXED: Changed from Icons.children_rounded
                          const SizedBox(width: 4),
                          Text(
                            '$totalChildren active',
                            style: TextStyle(
                              color: kSoftPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Children Fees List
                ...List.generate(
                  childrenFees.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChildFeeCard(
                      fee: childrenFees[index],
                      onTap: () {
                        // FIXED: Commented out FeePaymentScreen navigation since it doesn't exist
                        // If you want to navigate to a payment screen, you need to:
                        // 1. Create the FeePaymentScreen widget, or
                        // 2. Navigate to an existing screen like FeeHistoryScreen with the child data

                        // Option 1: Navigate to fee history (temporarily)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeeHistoryScreen(),
                          ),
                        );

                        // Option 2: Uncomment this if you create the FeePaymentScreen
                        /*
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeePaymentScreen(fee: childrenFees[index]),
                          ),
                        );
                        */
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // View History Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kSoftPurple, kSecondaryColor, kSoftBlue],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0.2, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kSoftPurple.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: kSoftBlue.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeeHistoryScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "View Payment History",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildFeeCard extends StatelessWidget {
  final Map<String, dynamic> fee;
  final VoidCallback onTap;

  const _ChildFeeCard({required this.fee, required this.onTap});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return kSuccessColor;
      case 'partial':
        return kWarningColor;
      case 'unpaid':
        return kErrorColor;
      default:
        return kErrorColor;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'paid':
        return kSuccessColor.withOpacity(0.1);
      case 'partial':
        return kWarningColor.withOpacity(0.1);
      case 'unpaid':
        return kErrorColor.withOpacity(0.1);
      default:
        return kErrorColor.withOpacity(0.1);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'PAID';
      case 'partial':
        return 'PARTIAL';
      case 'unpaid':
        return 'UNPAID';
      default:
        return 'UNPAID';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(fee['status']);
    final statusBgColor = _getStatusBgColor(fee['status']);
    final statusText = _getStatusText(fee['status']);
    final dueAmount = fee['dueAmount'] as double;
    final totalFee = fee['totalFee'] as double;
    final paidAmount = fee['paidAmount'] as double;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: kTextSecondary.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header with avatar and details
                Row(
                  children: [
                    // Child Avatar with gradient
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor,
                            statusColor.withOpacity(0.7),
                            kSoftPurple,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          fee['childName'].split(' ').map((e) => e[0]).join(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Child Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                fee['childName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimary,
                                  fontSize: 16,
                                ),
                              ),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Class info
                          Row(
                            children: [
                              Icon(
                                Icons.class_rounded,
                                size: 12,
                                color: kSoftBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                fee['className'],
                                style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fee Progress
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kSoftPurple.withOpacity(0.02),
                        Colors.white,
                        kSoftBlue.withOpacity(0.02),
                      ], // Replaced kBackgroundStart/kBackgroundEnd
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kTextSecondary.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      // Due amount
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Due Amount',
                              style: TextStyle(
                                color: kTextSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${dueAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: kWarningColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Vertical divider
                      Container(
                        height: 30,
                        width: 1,
                        color: kTextSecondary.withOpacity(0.2),
                      ),
                      // Paid amount
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Paid Amount',
                              style: TextStyle(
                                color: kTextSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${paidAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: kSuccessColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Progress',
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${((paidAmount / totalFee) * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: paidAmount / totalFee,
                      backgroundColor: kTextSecondary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Footer with due date and arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Due date chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kSoftPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kSoftPink.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: kSoftPink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${fee['dueDate']}',
                            style: TextStyle(
                              color: kSoftPink,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kSoftPurple.withOpacity(0.1),
                            kSoftBlue.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: kSoftPurple,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// OPTIONAL: Create this if you need the FeePaymentScreen
/*
class FeePaymentScreen extends StatelessWidget {
  final Map<String, dynamic> fee;
  
  const FeePaymentScreen({Key? key, required this.fee}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pay Fee for ${fee['childName']}'),
      ),
      body: Center(
        child: Text('Payment screen for ${fee['childName']}'),
      ),
    );
  }
}
*/
