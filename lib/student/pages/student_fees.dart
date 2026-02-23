import 'package:flutter/material.dart';

// ---------- WONDERFUL COLOR PALETTE (Matching Student Dashboard) ----------
const Color kPrimaryColor = Color(0xFF023471); // Deep blue (from your palette)
const Color kSecondaryColor = Color(0xFF5AB04B); // Green (from your palette)
const Color kAccentColor = Color(0xFF5AB04B); // Green as accent
const Color kSoftPurple = Color(0xFF4A6FA5); // Soft blue-purple (adjusted)
const Color kSoftPink = Color(0xFF7CB86E); // Soft green-pink (adjusted)
const Color kSoftOrange = Color(0xFFF59E0B); // Keep amber for warning
const Color kSoftBlue = Color(0xFF4D7EC1); // Lighter blue (adjusted)
const Color kSoftGreen = Color(0xFFE4F1E2); // Light green tint (from dashboard)
const Color kSuccessColor = Color(0xFF3D8C30); // Darker green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kBackgroundColor = Color(0xFFF5F8FC); // Light background
const Color kSurfaceColor = Colors.white;
const Color kTextPrimaryColor = Color(0xFF1A1E1F); // Dark slate
const Color kTextSecondaryColor = Color(0xFF4F5A5E); // Medium slate

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [Color(0xFF023471), Color(0xFF5AB04B)];
const List<Color> kSuccessGradient = [Color(0xFF3D8C30), Color(0xFF5AB04B)];
const List<Color> kWarningGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];

// FIXED: Dummy Fee Data
final Map<String, dynamic> dummyFeeSummary = {
  'total': 2200.00,
  'paid': 1200.00,
  'remaining': 1000.00,
  'status': 'Partial',
};

// FIXED: Dummy terms and fee table data
final List<Map<String, dynamic>> dummyTerms = [
  {
    'title': 'Term 1 Fees',
    'fees': [
      {
        'type': 'Tuition',
        'amount': 800.0,
        'paid': 800.0,
        'balance': 0.0,
        'status': 'Paid',
      },
      {
        'type': 'Transport',
        'amount': 200.0,
        'paid': 100.0,
        'balance': 100.0,
        'status': 'Partial',
      },
    ],
  },
  {
    'title': 'Term 2 Fees',
    'fees': [
      {
        'type': 'Tuition',
        'amount': 800.0,
        'paid': 400.0,
        'balance': 400.0,
        'status': 'Partial',
      },
      {
        'type': 'Uniform',
        'amount': 200.0,
        'paid': 0.0,
        'balance': 200.0,
        'status': 'Due',
      },
    ],
  },
  {
    'title': 'Annual Fees',
    'fees': [
      {
        'type': 'Activities',
        'amount': 200.0,
        'paid': 0.0,
        'balance': 200.0,
        'status': 'Due',
      },
    ],
  },
];

// Dummy Payment History
final List<Map<String, dynamic>> dummyPayments = [
  {
    'date': '2024-01-15',
    'amount': 400.0,
    'method': 'Credit Card',
    'receipt': '#1234ABC',
  },
  {
    'date': '2024-03-10',
    'amount': 400.0,
    'method': 'Bank Transfer',
    'receipt': '#1235DEF',
  },
  {
    'date': '2024-05-01',
    'amount': 400.0,
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

  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kSoftBlue, kSoftGreen],
          stops: [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ---------------- REDESIGNED APP BAR (Matching Dashboard) ----------------
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryColor, kPrimaryColor, kSecondaryColor],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Fees Management",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Fee Details",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Download Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- MAIN CONTENT ----------------
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // ---------------- FEE SUMMARY CARD (Redesigned) ----------------
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
      ),
    );
  }

  // ---------------- REDESIGNED FEE SUMMARY CARD (Matching Dashboard Style) ----------------
  Widget _buildFeeSummaryCard(Map<String, dynamic> summary) {
    String status = summary['status'] ?? 'Unknown';
    Color statusColor = status == 'Paid'
        ? kSuccessColor
        : (status == 'Partial' ? kWarningColor : kErrorColor);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, kSoftGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSoftPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: kSoftPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fee Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
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
                            color: statusColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Status: $status',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Fee breakdown with enhanced design
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildEnhancedFeeRow(
                  'Total Fees',
                  _safeToDouble(summary['total']),
                  kTextPrimaryColor,
                  Icons.receipt_rounded,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildEnhancedFeeRow(
                  'Paid Amount',
                  _safeToDouble(summary['paid']),
                  kSuccessColor,
                  Icons.check_circle_rounded,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildEnhancedFeeRow(
                  'Balance',
                  _safeToDouble(summary['remaining']),
                  kWarningColor,
                  Icons.warning_amber_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced fee row with icons
  Widget _buildEnhancedFeeRow(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: kTextSecondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          "\$${amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeSummaryRow(String label, double amount, Color color) {
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
          "\$${amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ---------------- REDESIGNED TERM FEES SECTION (Matching Dashboard Cards) ----------------
  Widget _buildTermFeesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kSecondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Term/Period Fees',
                style: TextStyle(
                  color: kTextPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        ...List<Widget>.generate(dummyTerms.length, (int i) {
          final Map<String, dynamic> t = dummyTerms[i];
          final dynamic fees = t['fees'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                key: PageStorageKey<int>(i),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                childrenPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: i == 0
                          ? [kSoftPurple, kPrimaryColor]
                          : i == 1
                          ? [kSoftPink, kSecondaryColor]
                          : [kSoftBlue, kPrimaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      i == 0
                          ? Icons.looks_one_rounded
                          : i == 1
                          ? Icons.looks_two_rounded
                          : Icons.looks_3_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                title: Text(
                  t['title'] ?? 'Term ${i + 1}',
                  style: TextStyle(
                    color: kTextPrimaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                subtitle: _buildTermSubtitle(fees),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _openTerm == i
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: kSecondaryColor,
                    size: 20,
                  ),
                ),
                initiallyExpanded: _openTerm == i,
                onExpansionChanged: (bool expanded) {
                  setState(() {
                    _openTerm = expanded ? i : null;
                  });
                },
                children: [
                  Builder(
                    builder: (BuildContext context) {
                      if (fees is List && fees.isNotEmpty) {
                        if (fees.first is Map) {
                          return _buildEnhancedFeesTable(
                            List<Map<String, dynamic>>.from(fees),
                          );
                        }
                      }
                      return Container(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'No fee data available.',
                          style: TextStyle(
                            color: kTextSecondaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
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

  // Subtitle showing quick fee summary
  Widget _buildTermSubtitle(dynamic fees) {
    if (fees is List && fees.isNotEmpty) {
      double total = 0;
      double paid = 0;
      for (var fee in fees) {
        total += _safeToDouble(fee['amount']);
        paid += _safeToDouble(fee['paid']);
      }
      return Row(
        children: [
          Text(
            'Total: \$${total.toStringAsFixed(0)}',
            style: TextStyle(color: kTextSecondaryColor, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: kTextSecondaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Paid: \$${paid.toStringAsFixed(0)}',
            style: TextStyle(
              color: kSuccessColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // ---------------- REDESIGNED FEES TABLE (More Visual) ----------------
  Widget _buildEnhancedFeesTable(List<Map<String, dynamic>> feeRows) {
    return Column(
      children: feeRows.map((row) {
        String typeStr = row['type']?.toString() ?? "Unknown";
        double amount = _safeToDouble(row['amount']);
        double paid = _safeToDouble(row['paid']);
        double balance = _safeToDouble(row['balance']);
        String status = row['status']?.toString() ?? "Unknown";

        Color statusColor = status == 'Paid'
            ? kSuccessColor
            : status == 'Partial'
            ? kWarningColor
            : kErrorColor;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      typeStr,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kTextPrimaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFeeProgressIndicator(
                    label: 'Amount',
                    value: amount,
                    color: kTextPrimaryColor,
                  ),
                  const SizedBox(width: 12),
                  _buildFeeProgressIndicator(
                    label: 'Paid',
                    value: paid,
                    color: kSuccessColor,
                  ),
                  const SizedBox(width: 12),
                  _buildFeeProgressIndicator(
                    label: 'Balance',
                    value: balance,
                    color: kWarningColor,
                  ),
                ],
              ),
              if (balance > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: paid / amount,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(kSuccessColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeeProgressIndicator({
    required String label,
    required double value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: kTextSecondaryColor),
          ),
          const SizedBox(height: 2),
          Text(
            '\$${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
        rows: List<DataRow>.generate(feeRows.length, (int i) {
          final Map<String, dynamic> row = feeRows[i];
          String typeStr = row['type']?.toString() ?? "Unknown";
          double amount = _safeToDouble(row['amount']);
          double paid = _safeToDouble(row['paid']);
          double balance = _safeToDouble(row['balance']);
          String status = row['status']?.toString() ?? "Unknown";

          Color statusColor = status == 'Paid'
              ? kSuccessColor
              : status == 'Partial'
              ? kWarningColor
              : kErrorColor;

          return DataRow(
            cells: [
              DataCell(Text(typeStr)),
              DataCell(Text('\$${amount.toStringAsFixed(2)}')),
              DataCell(Text('\$${paid.toStringAsFixed(2)}')),
              DataCell(Text('\$${balance.toStringAsFixed(2)}')),
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
                    status,
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

  // ---------------- REDESIGNED PAYMENT HISTORY (Matching Dashboard) ----------------
  Widget _buildPaymentHistorySection() {
    return Container(
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
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kSoftBlue, kPrimaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: const Text(
            'Payment History',
            style: TextStyle(
              color: kTextPrimaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            '${dummyPayments.length} transactions',
            style: TextStyle(color: kTextSecondaryColor, fontSize: 12),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kSecondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _paymentHistoryOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: kSecondaryColor,
              size: 20,
            ),
          ),
          initiallyExpanded: _paymentHistoryOpen,
          onExpansionChanged: (bool expanded) {
            setState(() {
              _paymentHistoryOpen = expanded;
            });
          },
          children: dummyPayments.map((Map<String, dynamic> p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, kSoftGreen.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kSuccessColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.receipt_rounded,
                      color: kSuccessColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt: ${p['receipt'] ?? "N/A"}',
                          style: TextStyle(
                            color: kTextPrimaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kSoftPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                p['date']?.toString() ?? "Unknown",
                                style: TextStyle(
                                  color: kSoftPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              p['method']?.toString() ?? "Unknown",
                              style: TextStyle(
                                color: kTextSecondaryColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${_safeToDouble(p['amount']).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: kSuccessColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kSuccessColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Paid',
                          style: TextStyle(
                            color: kSuccessColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
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

  // ---------------- REDESIGNED NOTES CARD (Matching Dashboard) ----------------
  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, kSoftGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kSoftOrange, kWarningColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Important Notes',
                style: TextStyle(
                  color: kTextPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnhancedNoteLine(
            Icons.calendar_today_rounded,
            'Fee payments due by 25th of each month.',
            kPrimaryColor,
          ),
          const SizedBox(height: 16),
          _buildEnhancedNoteLine(
            Icons.warning_amber_rounded,
            'Late payments will incur additional charges.',
            kWarningColor,
          ),
          const SizedBox(height: 16),
          _buildEnhancedNoteLine(
            Icons.payment_rounded,
            'Pay via student portal or contact office for payment instructions.',
            kSuccessColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedNoteLine(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: kTextSecondaryColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
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
