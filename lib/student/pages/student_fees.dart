import 'package:flutter/material.dart';

// ---------- WONDERFUL COLOR PALETTE (Matching Dashboard) ----------
const Color kPrimaryColor = Color(0xFF1E3A8A); // Deep indigo
const Color kSecondaryColor = Color(0xFF3B82F6); // Bright blue
const Color kAccentColor = Color(0xFF10B981); // Emerald green
const Color kSoftPurple = Color(0xFF8B5CF6); // Light purple
const Color kSoftPink = Color(0xFFEC4899); // Pink
const Color kSoftOrange = Color(0xFFF59E0B); // Amber
const Color kSoftBlue = Color(0xFF3B82F6); // Sky blue
const Color kSuccessColor = Color(0xFF059669); // Dark green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kBackgroundColor = Color(0xFFF8FAFC); // Light background
const Color kSurfaceColor = Colors.white;
const Color kTextPrimaryColor = Color(0xFF1E293B); // Dark slate
const Color kTextSecondaryColor = Color(0xFF64748B); // Medium slate

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [Color(0xFF1E3A8A), Color(0xFF3B82F6)];
const List<Color> kSuccessGradient = [Color(0xFF10B981), Color(0xFF34D399)];
const List<Color> kWarningGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];

// Dummy Fee Data
final dummyFeeSummary = {
  'total': 2200.00,
  'paid': 1200.00,
  'remaining': 1000.00,
  'status': 'Partial', // Paid, Partial, Due
};

// Dummy terms and fee table data
final List<Map<String, dynamic>> dummyTerms = [
  {
    'title': 'Term 1 Fees',
    'fees': [
      {
        'type': 'Tuition',
        'amount': 800,
        'paid': 800,
        'balance': 0,
        'status': 'Paid',
      },
      {
        'type': 'Transport',
        'amount': 200,
        'paid': 100,
        'balance': 100,
        'status': 'Partial',
      },
    ],
  },
  {
    'title': 'Term 2 Fees',
    'fees': [
      {
        'type': 'Tuition',
        'amount': 800,
        'paid': 400,
        'balance': 400,
        'status': 'Partial',
      },
      {
        'type': 'Uniform',
        'amount': 200,
        'paid': 0,
        'balance': 200,
        'status': 'Due',
      },
    ],
  },
  {
    'title': 'Annual Fees',
    'fees': [
      {
        'type': 'Activities',
        'amount': 200,
        'paid': 0,
        'balance': 200,
        'status': 'Due',
      },
    ],
  },
];

// Dummy Payment History
final List<Map<String, dynamic>> dummyPayments = [
  {
    'date': '2024-01-15',
    'amount': 400,
    'method': 'Credit Card',
    'receipt': '#1234ABC',
  },
  {
    'date': '2024-03-10',
    'amount': 400,
    'method': 'Bank Transfer',
    'receipt': '#1235DEF',
  },
  {
    'date': '2024-05-01',
    'amount': 400,
    'method': 'Cash',
    'receipt': '#1236GHI',
  },
];

class StudentFeesScreen extends StatefulWidget {
  const StudentFeesScreen({Key? key}) : super(key: key);

  @override
  State<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends State<StudentFeesScreen>
    with SingleTickerProviderStateMixin {
  int? _openTerm;
  bool _paymentHistoryOpen = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to safely convert dynamic to double
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is bool) return value ? 1.0 : 0.0;
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor, // Matching dashboard background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- ENHANCED APP BAR WITH BACK ARROW ----------------
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Fees",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryColor, kSecondaryColor],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {},
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // ---------------- FEE SUMMARY CARD ----------------
                      _buildFeeSummaryCard(dummyFeeSummary),

                      const SizedBox(height: 20),

                      // ---------------- TERM FEES SECTION ----------------
                      _buildTermFeesSection(),

                      const SizedBox(height: 20),

                      // ---------------- PAYMENT HISTORY SECTION ----------------
                      _buildPaymentHistorySection(),

                      const SizedBox(height: 20),

                      // ---------------- NOTES CARD ----------------
                      _buildNotesCard(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSummaryCard(Map<String, dynamic> summary) {
    String status = summary['status'];
    Color statusColor = status == 'Paid'
        ? kSuccessColor
        : (status == 'Partial' ? kWarningColor : kErrorColor);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSoftPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_rounded,
                  color: kSoftPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Fee Summary',
                style: TextStyle(
                  color: kTextPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeeSummaryRow(
            'Total Fees',
            summary['total'],
            kTextPrimaryColor,
          ),
          const SizedBox(height: 10),
          _buildFeeSummaryRow('Paid Amount', summary['paid'], kSuccessColor),
          const SizedBox(height: 10),
          _buildFeeSummaryRow('Balance', summary['remaining'], kWarningColor),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: status == 'Paid'
                    ? [kSuccessColor, kAccentColor]
                    : status == 'Partial'
                    ? [kWarningColor, kSoftOrange]
                    : [kErrorColor, kSoftPink],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'Paid'
                      ? Icons.check_circle_rounded
                      : status == 'Partial'
                      ? Icons.pending_rounded
                      : Icons.warning_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Status: $status',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSummaryRow(String label, dynamic amount, Color color) {
    double amt = _safeToDouble(amount);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: kTextSecondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          "\$${amt.toStringAsFixed(2)}",
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTermFeesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kSoftOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: kSoftOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Term/Period Fees',
                style: TextStyle(
                  color: kTextPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        ...List<Widget>.generate(dummyTerms.length, (i) {
          final t = dummyTerms[i];
          final dynamic fees = t['fees'];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: kAccentColor.withOpacity(0.07),
                colorScheme: Theme.of(
                  context,
                ).colorScheme.copyWith(primary: kAccentColor),
              ),
              child: ExpansionTile(
                key: PageStorageKey(i),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: i == 0
                        ? kSoftPurple.withOpacity(0.1)
                        : i == 1
                        ? kSoftPink.withOpacity(0.1)
                        : kSoftBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    i == 0
                        ? Icons.looks_one_rounded
                        : i == 1
                        ? Icons.looks_two_rounded
                        : Icons.looks_3_rounded,
                    color: i == 0
                        ? kSoftPurple
                        : i == 1
                        ? kSoftPink
                        : kSoftBlue,
                    size: 18,
                  ),
                ),
                title: Text(
                  t['title'],
                  style: const TextStyle(
                    color: kTextPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                trailing: Icon(
                  _openTerm == i
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: kSecondaryColor,
                  size: 22,
                ),
                initiallyExpanded: _openTerm == i,
                onExpansionChanged: (open) {
                  setState(() {
                    _openTerm = open ? i : null;
                  });
                },
                children: [
                  Builder(
                    builder: (context) {
                      if (fees is List &&
                          fees.isNotEmpty &&
                          fees.first is Map) {
                        return _buildFeesTable(
                          List<Map<String, dynamic>>.from(fees),
                        );
                      } else if (fees is List && fees.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                            child: Text(
                              'No fee data available.',
                              style: TextStyle(
                                color: kTextSecondaryColor,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          child: const Text(
                            "Fee data error: Fee table cannot be displayed.",
                            style: TextStyle(
                              color: kErrorColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFeesTable(List<Map<String, dynamic>> feeRows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          kSoftPurple.withOpacity(0.05),
        ),
        dataRowColor: MaterialStateProperty.all(Colors.transparent),
        columnSpacing: 20,
        headingTextStyle: const TextStyle(fontSize: 13),
        dataTextStyle: const TextStyle(fontSize: 13),
        columns: const [
          DataColumn(
            label: Text(
              'Fee Type',
              style: TextStyle(
                color: kTextPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Amount',
              style: TextStyle(
                color: kTextPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Paid',
              style: TextStyle(
                color: kTextPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Balance',
              style: TextStyle(
                color: kTextPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(
                color: kTextPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
        rows: List<DataRow>.generate(feeRows.length, (i) {
          final row = feeRows[i];

          String typeStr = row['type']?.toString() ?? "";

          // Safely convert values using helper method
          double amount = _safeToDouble(row['amount']);
          double paid = _safeToDouble(row['paid']);
          double balance = _safeToDouble(row['balance']);

          Color statusColor;
          if (row['status'] == 'Paid') {
            statusColor = kSuccessColor;
          } else if (row['status'] == 'Partial') {
            statusColor = kWarningColor;
          } else {
            statusColor = kErrorColor;
          }

          return DataRow(
            cells: [
              DataCell(
                Text(
                  typeStr,
                  style: const TextStyle(
                    color: kTextPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: kTextPrimaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '\$${paid.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: kTextPrimaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '\$${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: kTextPrimaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    row['status'].toString(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: kAccentColor.withOpacity(0.07),
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: kAccentColor),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kSoftBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: kSoftBlue,
              size: 18,
            ),
          ),
          title: const Text(
            'Payment History',
            style: TextStyle(
              color: kTextPrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          trailing: Icon(
            _paymentHistoryOpen
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: kSecondaryColor,
            size: 22,
          ),
          initiallyExpanded: _paymentHistoryOpen,
          onExpansionChanged: (open) {
            setState(() {
              _paymentHistoryOpen = open;
            });
          },
          children: dummyPayments.map((p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: kSuccessColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_rounded,
                          size: 12,
                          color: kSuccessColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Receipt: ${p['receipt']}',
                        style: const TextStyle(
                          color: kTextPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: kSoftPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p['date'],
                          style: TextStyle(
                            color: kTextSecondaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              'Amount: ',
                              style: TextStyle(
                                color: kTextSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '\$${_safeToDouble(p['amount']).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: kSuccessColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              'Method: ',
                              style: TextStyle(
                                color: kTextSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                p['method'],
                                style: TextStyle(
                                  color: kTextPrimaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kSoftOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: kSoftOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Important Notes',
                style: TextStyle(
                  color: kTextPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNoteLine(
            Icons.calendar_today_rounded,
            'Fee payments due by 25th of each month.',
          ),
          const SizedBox(height: 10),
          _buildNoteLine(
            Icons.warning_amber_rounded,
            'Late payments will incur additional charges.',
          ),
          const SizedBox(height: 10),
          _buildNoteLine(
            Icons.payment_rounded,
            'Pay via student portal or contact office for payment instructions.',
          ),
        ],
      ),
    );
  }

  Widget _buildNoteLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: kAccentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: kAccentColor, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: kTextSecondaryColor,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
