int _id(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

String? _strOpt(dynamic v) => v == null ? null : v.toString().trim();

/// A generated fee row — a permanent financial snapshot. Every value here is
/// read from the stored row, never recalculated client-side from current
/// class fee settings/discounts.
class FeeRecord {
  final int id;
  final int studentId;
  final String studentName;
  final String? emisNumber;
  final int classId;
  final String className;
  final int academicYearId;
  final String billingCycle; // MONTHLY | TERM | YEARLY
  final int billingYear;
  final int billingMonth; // 1-12, 0 for YEARLY
  final String dueDate;
  final num originalAmount;
  final num discountPercentage;
  final num discountAmount;
  final num amount;
  final num paidAmount;
  final num remainingAmount;
  final String status; // UNPAID | PARTIAL | PAID

  const FeeRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.emisNumber,
    required this.classId,
    required this.className,
    required this.academicYearId,
    required this.billingCycle,
    required this.billingYear,
    required this.billingMonth,
    required this.dueDate,
    required this.originalAmount,
    required this.discountPercentage,
    required this.discountAmount,
    required this.amount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
  });

  bool get canCollectPayment => remainingAmount > 0;

  String get billingPeriodLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (billingCycle == 'MONTHLY' && billingMonth >= 1 && billingMonth <= 12) {
      return '${months[billingMonth - 1]} $billingYear';
    }
    if (billingCycle == 'YEARLY') return 'Yearly $billingYear';
    return '$billingCycle $billingYear';
  }

  factory FeeRecord.fromJson(Map<String, dynamic> json) => FeeRecord(
    id: _id(json['id']),
    studentId: _id(json['student_id']),
    studentName: (json['student_name'] ?? '').toString(),
    emisNumber: _strOpt(json['emis_number']),
    classId: _id(json['class_id']),
    className: (json['class_name'] ?? '').toString(),
    academicYearId: _id(json['academic_year_id']),
    billingCycle: (json['billing_cycle'] ?? '').toString(),
    billingYear: _id(json['billing_year']),
    billingMonth: _id(json['billing_month']),
    dueDate: (json['due_date'] ?? '').toString(),
    originalAmount: _num(json['original_amount']),
    discountPercentage: _num(json['discount_percentage']),
    discountAmount: _num(json['discount_amount']),
    amount: _num(json['amount']),
    paidAmount: _num(json['paid_amount']),
    remainingAmount: _num(json['remaining_amount']),
    status: (json['status'] ?? 'UNPAID').toString(),
  );
}

class FinanceFeeLedgerPage {
  final int academicYearId;
  final String academicYearName;
  final List<FeeRecord> fees;
  final int page;
  final int limit;
  final int total;

  const FinanceFeeLedgerPage({
    required this.academicYearId,
    required this.academicYearName,
    required this.fees,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory FinanceFeeLedgerPage.fromJson(Map<String, dynamic> json) {
    final rawYear = json['academicYear'] ?? json['academic_year'];
    final year = rawYear is Map ? Map<String, dynamic>.from(rawYear) : <String, dynamic>{};
    final pagination = json['pagination'] is Map
        ? Map<String, dynamic>.from(json['pagination'] as Map)
        : <String, dynamic>{};
    return FinanceFeeLedgerPage(
      academicYearId: _id(year['id']),
      academicYearName: (year['name'] ?? '').toString(),
      fees: (json['fees'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => FeeRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      page: _id(pagination['page']) == 0 ? 1 : _id(pagination['page']),
      limit: _id(pagination['limit']) == 0 ? 50 : _id(pagination['limit']),
      total: _id(pagination['total']),
    );
  }
}

class StudentFeeLedgerSummary {
  final num totalOriginal;
  final num totalDiscount;
  final num totalCharged;
  final num totalPaid;
  final num totalRemaining;
  final int unpaidCount;
  final int partialCount;
  final int paidCount;

  const StudentFeeLedgerSummary({
    required this.totalOriginal,
    required this.totalDiscount,
    required this.totalCharged,
    required this.totalPaid,
    required this.totalRemaining,
    required this.unpaidCount,
    required this.partialCount,
    required this.paidCount,
  });

  factory StudentFeeLedgerSummary.fromJson(Map<String, dynamic> json) =>
      StudentFeeLedgerSummary(
        totalOriginal: _num(json['total_original']),
        totalDiscount: _num(json['total_discount']),
        totalCharged: _num(json['total_charged']),
        totalPaid: _num(json['total_paid']),
        totalRemaining: _num(json['total_remaining']),
        unpaidCount: _id(json['unpaid_count']),
        partialCount: _id(json['partial_count']),
        paidCount: _id(json['paid_count']),
      );
}

/// Single student's fee ledger for one academic year.
class StudentFeeLedger {
  final int studentId;
  final String studentName;
  final String? emisNumber;
  final int? classId;
  final String? className;
  final int academicYearId;
  final String academicYearName;
  final StudentFeeLedgerSummary summary;
  final List<FeeRecord> fees;

  const StudentFeeLedger({
    required this.studentId,
    required this.studentName,
    this.emisNumber,
    this.classId,
    this.className,
    required this.academicYearId,
    required this.academicYearName,
    required this.summary,
    required this.fees,
  });

  factory StudentFeeLedger.fromJson(Map<String, dynamic> json) {
    final student = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : <String, dynamic>{};
    final year = (json['academic_year'] ?? json['academicYear']) is Map
        ? Map<String, dynamic>.from(
            (json['academic_year'] ?? json['academicYear']) as Map)
        : <String, dynamic>{};
    return StudentFeeLedger(
      studentId: _id(student['id']),
      studentName: (student['name'] ?? '').toString(),
      emisNumber: _strOpt(student['emis_number']),
      classId: student['class_id'] == null ? null : _id(student['class_id']),
      className: _strOpt(student['class_name']),
      academicYearId: _id(year['id']),
      academicYearName: (year['name'] ?? '').toString(),
      summary: StudentFeeLedgerSummary.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : const {},
      ),
      fees: (json['fees'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => FeeRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
