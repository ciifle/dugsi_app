import 'package:flutter/material.dart';
import 'package:kobac/school_admin/pages/payment_details_page.dart';

// --- Premium 3D Design Constants ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class Payment {
  final String studentName;
  final String studentId;
  final String feeType;
  final double amount;
  final String status;
  final DateTime date;

  const Payment({
    required this.studentName,
    required this.studentId,
    required this.feeType,
    required this.amount,
    required this.status,
    required this.date,
  });
}

final List<Payment> dummyPayments = [
  Payment(studentName: 'Ayaan Mohamed', studentId: 'STU10234', feeType: 'Tuition', amount: 1200.0, status: 'Paid', date: DateTime(2024, 6, 1)),
  Payment(studentName: 'Zahra Ali', studentId: 'STU10567', feeType: 'Transport', amount: 200.0, status: 'Partial', date: DateTime(2024, 6, 2)),
  Payment(studentName: 'Yusuf Barre', studentId: 'STU10987', feeType: 'Exam', amount: 150.0, status: 'Unpaid', date: DateTime(2024, 5, 28)),
  Payment(studentName: 'Nasra Hassan', studentId: 'STU11022', feeType: 'Tuition', amount: 1200.0, status: 'Paid', date: DateTime(2024, 6, 1)),
];

class PaymentsScreen extends StatelessWidget {
  final bool embedInParent;
  const PaymentsScreen({Key? key, this.embedInParent = false}) : super(key: key);

  double get totalPayments => dummyPayments.fold(0, (a, b) => a + b.amount);
  double get paidAmount => dummyPayments.where((p) => p.status == 'Paid').fold(0, (a, b) => a + b.amount);
  double get outstandingAmount => dummyPayments.where((p) => p.status != 'Paid').fold(0, (a, b) => a + b.amount);

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBgColor, kPrimaryBlue.withOpacity(0.02)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!embedInParent)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    _BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Payments",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                    _FilterButton(onPressed: () {}),
                  ],
                ),
              ),
            if (embedInParent) const SizedBox(height: 12),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: "Total",
                        value: "\$${totalPayments.toInt()}",
                        color: kPrimaryBlue,
                        icon: Icons.attach_money_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SummaryCard(
                        label: "Outstanding",
                        value: "\$${outstandingAmount.toInt()}",
                        color: kPrimaryBlue.withOpacity(0.85),
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: dummyPayments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final payment = dummyPayments[index];
                  return _PaymentCard(payment: payment);
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (embedInParent) return body;
    return Scaffold(backgroundColor: kBgColor, body: body);
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _FilterButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.filter_list_rounded, color: kPrimaryBlue, size: 24),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: color.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;

  const _PaymentCard({required this.payment});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid': return kPrimaryGreen;
      case 'Partial': return Colors.orange;
      default: return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentDetailsPage())),
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kCardRadius),
            boxShadow: [
              BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
              BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: kPrimaryBlue, size: 24),
              ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${payment.feeType} • ${payment.date.day}/${payment.date.month}",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${payment.amount.toInt()}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: kPrimaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                payment.status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: _getStatusColor(payment.status),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    ),
    );
  }
}
