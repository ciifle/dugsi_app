import 'package:intl/intl.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'finance_payment.dart';

int _id(dynamic value) => int.parse(value.toString());
num? _money(dynamic value) =>
    value == null ? null : num.parse(value.toString());

class FinanceStudent {
  final int studentId, classId, academicYearId;
  final String studentName, className;
  final String? emisNumber;
  FinanceStudent.fromJson(Map<String, dynamic> j)
    : studentId = _id(j['student_id']),
      classId = _id(j['class_id']),
      academicYearId = _id(j['academic_year_id']),
      studentName = j['student_name'] as String,
      className = j['class_name'] as String,
      emisNumber = j['emis_number'] as String?;
}

class FinanceStudentPage {
  final List<FinanceStudent> students;
  final int page, limit, total;
  FinanceStudentPage.fromJson(Map<String, dynamic> j)
    : students = (j['students'] as List)
          .map((s) => FinanceStudent.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      page = _id(j['pagination']['page']),
      limit = _id(j['pagination']['limit']),
      total = _id(j['pagination']['total']);
}

class CollectionPeriod {
  final int year, month;
  const CollectionPeriod(this.year, this.month);
  String get key => '$year-$month';
  String get label => DateFormat('MMMM yyyy').format(DateTime(year, month));
  static List<CollectionPeriod> forYear(AcademicYear year) {
    final start = year.startDate, end = year.endDate;
    if (start == null || end == null || end.isBefore(start)) return [];
    final result = <CollectionPeriod>[];
    var date = DateTime(start.year, start.month);
    final last = DateTime(end.year, end.month);
    while (!date.isAfter(last)) {
      result.add(CollectionPeriod(date.year, date.month));
      date = DateTime(date.year, date.month + 1);
    }
    return result;
  }
}

class CollectionStudent {
  final int studentId;
  final int? feeId;
  final String studentName, status;
  final String? emisNumber;
  final num? originalAmount,
      discountPercentage,
      amountDue,
      paidAmount,
      remainingAmount;
  final bool requiresFeeGeneration;
  CollectionStudent.fromJson(Map<String, dynamic> j)
    : studentId = _id(j['student_id']),
      feeId = j['fee_id'] == null ? null : _id(j['fee_id']),
      studentName = j['student_name'] as String,
      emisNumber = j['emis_number'] as String?,
      status = j['status'] as String,
      requiresFeeGeneration = j['requires_fee_generation'] == true,
      originalAmount = _money(j['original_amount']),
      discountPercentage = _money(j['discount_percentage']),
      amountDue = _money(j['amount_due']),
      paidAmount = _money(j['paid_amount']),
      remainingAmount = _money(j['remaining_amount']);
  bool get canCollect =>
      !requiresFeeGeneration &&
      feeId != null &&
      (status == 'UNPAID' || status == 'PARTIAL') &&
      (remainingAmount ?? 0) > 0;
}

class ClassCollectionRegister {
  final int academicYearId, classId;
  final String className;
  final CollectionPeriod period;
  final List<CollectionStudent> students;
  ClassCollectionRegister.fromJson(Map<String, dynamic> j)
    : academicYearId = _id(j['academicYear']['id']),
      classId = _id(j['class']['id']),
      className = j['class']['name'] as String,
      period = CollectionPeriod(
        _id(j['billingPeriod']['year']),
        _id(j['billingPeriod']['month']),
      ),
      students = (j['students'] as List)
          .map((s) => CollectionStudent.fromJson(Map<String, dynamic>.from(s)))
          .toList();
}

class CollectionPaymentInput {
  final int studentId;
  final String method;
  final num? amount;
  final String? referenceNumber, notes;
  const CollectionPaymentInput({
    required this.studentId,
    required this.method,
    this.amount,
    this.referenceNumber,
    this.notes,
  });
  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'method': method,
    if (amount != null) 'amount': amount,
    if (referenceNumber != null) 'reference_number': referenceNumber,
    if (notes != null) 'notes': notes,
  };
}

class BulkCollectionRequest {
  final int academicYearId, classId;
  final CollectionPeriod period;
  final List<CollectionPaymentInput> payments;
  const BulkCollectionRequest({
    required this.academicYearId,
    required this.classId,
    required this.period,
    required this.payments,
  });
  Map<String, dynamic> toJson() => {
    'academic_year_id': academicYearId,
    'class_id': classId,
    'billing_month': period.month,
    'billing_year': period.year,
    'payments': payments.map((p) => p.toJson()).toList(),
  };
}

class BulkCollectionResult {
  final int count;
  final Map<int, FinancePaymentCollectionResult> payments;
  BulkCollectionResult.fromJson(Map<String, dynamic> j)
    : count = _id(j['count']),
      payments = {
        for (final p in j['payments'] as List)
          _id(p['student_id']): FinancePaymentCollectionResult.fromJson(
            Map<String, dynamic>.from(p),
          ),
      };
}

class CollectionValidationIssue {
  final int? studentId;
  final String code;
  CollectionValidationIssue.fromJson(Map<String, dynamic> j)
    : studentId = j['student_id'] == null
          ? null
          : int.tryParse(j['student_id'].toString()),
      code = j['code']?.toString() ?? 'INVALID_PAYMENT';
  String get message => switch (code) {
    'FEE_ALREADY_PAID' => 'Fee already paid.',
    'PAYMENT_EXCEEDS_BALANCE' => 'Payment exceeds remaining balance.',
    'FEE_GENERATION_REQUIRED' => 'Fee not generated.',
    'STUDENT_NOT_ENROLLED' =>
      'Student is no longer enrolled in this class and year.',
    'DUPLICATE_STUDENT' => 'Student selected more than once.',
    _ => 'Payment could not be recorded. Refresh and check this student.',
  };
}
