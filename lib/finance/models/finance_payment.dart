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

const List<String> kPaymentMethods = ['CASH', 'CARD', 'MOBILE', 'BANK'];

class FinanceRecordedBy {
  final int id;
  final String? name;
  const FinanceRecordedBy({required this.id, this.name});
  factory FinanceRecordedBy.fromJson(Map<String, dynamic> json) =>
      FinanceRecordedBy(id: _id(json['id']), name: _strOpt(json['name']));
}

/// An immutable payment collection record with joined fee/student/class
/// context — the shape returned by GET (list/get/student-history). Never
/// editable or deletable.
class FinancePaymentRecord {
  final int id;
  final String receiptNumber;
  final num amount;
  final String method;
  final String? referenceNumber;
  final String? notes;
  final String paidAt;
  final FinanceRecordedBy recordedBy;
  final int feeId;
  final String? billingCycle;
  final int? billingYear;
  final int? billingMonth;
  final int? academicYearId;
  final int studentId;
  final String studentName;
  final String? emisNumber;
  final int classId;
  final String className;

  const FinancePaymentRecord({
    required this.id,
    required this.receiptNumber,
    required this.amount,
    required this.method,
    this.referenceNumber,
    this.notes,
    required this.paidAt,
    required this.recordedBy,
    required this.feeId,
    this.billingCycle,
    this.billingYear,
    this.billingMonth,
    this.academicYearId,
    required this.studentId,
    required this.studentName,
    this.emisNumber,
    required this.classId,
    required this.className,
  });

  factory FinancePaymentRecord.fromJson(Map<String, dynamic> json) {
    final fee = json['fee'] is Map
        ? Map<String, dynamic>.from(json['fee'] as Map)
        : <String, dynamic>{};
    final student = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : <String, dynamic>{};
    final klass = json['class'] is Map
        ? Map<String, dynamic>.from(json['class'] as Map)
        : <String, dynamic>{};
    return FinancePaymentRecord(
      id: _id(json['id']),
      receiptNumber: (json['receipt_number'] ?? '').toString(),
      amount: _num(json['amount']),
      method: (json['method'] ?? '').toString(),
      referenceNumber: _strOpt(json['reference_number']),
      notes: _strOpt(json['notes']),
      paidAt: (json['paid_at'] ?? '').toString(),
      recordedBy: FinanceRecordedBy.fromJson(
        json['recorded_by'] is Map
            ? Map<String, dynamic>.from(json['recorded_by'] as Map)
            : const {},
      ),
      feeId: _id(fee['id']),
      billingCycle: _strOpt(fee['billing_cycle']),
      billingYear: fee['billing_year'] == null ? null : _id(fee['billing_year']),
      billingMonth:
          fee['billing_month'] == null ? null : _id(fee['billing_month']),
      academicYearId:
          fee['academic_year_id'] == null ? null : _id(fee['academic_year_id']),
      studentId: _id(student['id']),
      studentName: (student['name'] ?? '').toString(),
      emisNumber: _strOpt(student['emis_number']),
      classId: _id(klass['id']),
      className: (klass['name'] ?? '').toString(),
    );
  }
}

/// The fee's balance immediately after a payment. original_amount/
/// discount_percentage/discount_amount/amount are never changed by a
/// payment — only these fields are.
class FinancePaymentFeeBalance {
  final int id;
  final num amount;
  final num paidAmount;
  final num remainingAmount;
  final String status;

  const FinancePaymentFeeBalance({
    required this.id,
    required this.amount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
  });

  factory FinancePaymentFeeBalance.fromJson(Map<String, dynamic> json) =>
      FinancePaymentFeeBalance(
        id: _id(json['id']),
        amount: _num(json['amount']),
        paidAmount: _num(json['paid_amount']),
        remainingAmount: _num(json['remaining_amount']),
        status: (json['status'] ?? 'UNPAID').toString(),
      );
}

/// Response of POST /payments — a DELIBERATELY different, flatter shape
/// than [FinancePaymentRecord]: `payment.fee_id` is flat (no nested
/// billing-period/student/class — the caller already has that context from
/// the fee they selected before submitting).
class FinancePaymentCollectionResult {
  final int paymentId;
  final String receiptNumber;
  final int feeId;
  final num amount;
  final String method;
  final String? referenceNumber;
  final String? notes;
  final String paidAt;
  final FinanceRecordedBy recordedBy;
  final FinancePaymentFeeBalance fee;

  const FinancePaymentCollectionResult({
    required this.paymentId,
    required this.receiptNumber,
    required this.feeId,
    required this.amount,
    required this.method,
    this.referenceNumber,
    this.notes,
    required this.paidAt,
    required this.recordedBy,
    required this.fee,
  });

  factory FinancePaymentCollectionResult.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] is Map
        ? Map<String, dynamic>.from(json['payment'] as Map)
        : <String, dynamic>{};
    return FinancePaymentCollectionResult(
      paymentId: _id(payment['id']),
      receiptNumber: (payment['receipt_number'] ?? '').toString(),
      feeId: _id(payment['fee_id']),
      amount: _num(payment['amount']),
      method: (payment['method'] ?? '').toString(),
      referenceNumber: _strOpt(payment['reference_number']),
      notes: _strOpt(payment['notes']),
      paidAt: (payment['paid_at'] ?? '').toString(),
      recordedBy: FinanceRecordedBy.fromJson(
        payment['recorded_by'] is Map
            ? Map<String, dynamic>.from(payment['recorded_by'] as Map)
            : const {},
      ),
      fee: FinancePaymentFeeBalance.fromJson(
        json['fee'] is Map
            ? Map<String, dynamic>.from(json['fee'] as Map)
            : const {},
      ),
    );
  }
}

class FinancePaymentPage {
  final List<FinancePaymentRecord> payments;
  final int page;
  final int limit;
  final int total;

  const FinancePaymentPage({
    required this.payments,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory FinancePaymentPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] is Map
        ? Map<String, dynamic>.from(json['pagination'] as Map)
        : <String, dynamic>{};
    return FinancePaymentPage(
      payments: (json['payments'] as List? ?? const [])
          .whereType<Map>()
          .map((e) =>
              FinancePaymentRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      page: _id(pagination['page']) == 0 ? 1 : _id(pagination['page']),
      limit: _id(pagination['limit']) == 0 ? 50 : _id(pagination['limit']),
      total: _id(pagination['total']),
    );
  }
}

class FinancePaymentHistory {
  final int studentId;
  final String studentName;
  final String? emisNumber;
  final num totalPaid;
  final int paymentCount;
  final List<FinancePaymentRecord> payments;

  const FinancePaymentHistory({
    required this.studentId,
    required this.studentName,
    this.emisNumber,
    required this.totalPaid,
    required this.paymentCount,
    required this.payments,
  });

  factory FinancePaymentHistory.fromJson(Map<String, dynamic> json) {
    final student = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : <String, dynamic>{};
    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : <String, dynamic>{};
    return FinancePaymentHistory(
      studentId: _id(student['id']),
      studentName: (student['name'] ?? '').toString(),
      emisNumber: _strOpt(student['emis_number']),
      totalPaid: _num(summary['total_paid']),
      paymentCount: _id(summary['payment_count']),
      payments: (json['payments'] as List? ?? const [])
          .whereType<Map>()
          .map((e) =>
              FinancePaymentRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
