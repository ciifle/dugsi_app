/// Exam Fee Custom models (School Admin).
///
/// Field names mirror the backend's examFee.service.js serializers. Money may
/// arrive as a number or a DECIMAL string; it is parsed defensively, never
/// rounded to whole units, and compared in integer cents. Totals and statuses
/// are always the backend's — Flutter never derives financial totals.

const List<String> kExamFeePaymentMethods = ['CASH', 'MOBILE', 'BANK', 'CARD'];

const String kFeeUnpaid = 'UNPAID';
const String kFeePartial = 'PARTIAL';
const String kFeePaid = 'PAID';
const String kFeeWaived = 'WAIVED';

int _int(dynamic v) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0);

int? _intOrNull(dynamic v) {
  final parsed = _int(v);
  return parsed > 0 ? parsed : null;
}

String? _str(dynamic v) {
  if (v == null) return null;
  final text = v.toString().trim();
  return text.isEmpty ? null : text;
}

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

List<Map<String, dynamic>> _maps(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

/// Money from a number or numeric string; 0 when absent.
double examFeeMoney(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}'.trim()) ?? 0;
}

double? _moneyOrNull(dynamic v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'.trim()));

/// Exact cents for comparisons (6.50 -> 650; never 7).
int toCents(double value) => (value * 100).round();

/// User input -> amount, accepting "6.5", "6.50", "1,250.00". Null if invalid.
double? parseMoneyInput(String text) {
  final clean = text.replaceAll(',', '').trim();
  if (clean.isEmpty) return null;
  if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(clean)) return null;
  return double.tryParse(clean);
}

/// "6.5" -> "6.50" for prefilling inputs (no thousands separators).
String moneyInputText(double value) => value.toStringAsFixed(2);

// --- Scope -----------------------------------------------------------------

class ExamFeeScope {
  final int? academicYearId;
  final String? academicYearName;
  final int? examId;
  final String? examName;
  final int? classId;
  final String? className;

  const ExamFeeScope({
    this.academicYearId,
    this.academicYearName,
    this.examId,
    this.examName,
    this.classId,
    this.className,
  });

  factory ExamFeeScope.fromJson(Map<String, dynamic> json) {
    final y = _map(json['academic_year']);
    final e = _map(json['exam']);
    final c = _map(json['class']);
    return ExamFeeScope(
      academicYearId: _intOrNull(y?['id']),
      academicYearName: _str(y?['name']),
      examId: _intOrNull(e?['id']),
      examName: _str(e?['name']),
      classId: _intOrNull(c?['id']),
      className: _str(c?['name']),
    );
  }
}

// --- Settings ----------------------------------------------------------------

class ExamFeeSetting {
  final int id;
  final double amount;
  final String? updatedAt;

  const ExamFeeSetting({required this.id, required this.amount, this.updatedAt});

  static ExamFeeSetting? tryParse(dynamic raw) {
    final json = _map(raw);
    final id = _intOrNull(json?['id']);
    if (json == null || id == null) return null;
    return ExamFeeSetting(
      id: id,
      amount: examFeeMoney(json['amount']),
      updatedAt: _str(json['updated_at']),
    );
  }
}

class ExamFeeClassSetting {
  final int classId;
  final String className;
  final bool configured;
  final ExamFeeSetting? setting;
  final int generatedCount;

  const ExamFeeClassSetting({
    required this.classId,
    required this.className,
    required this.configured,
    this.setting,
    this.generatedCount = 0,
  });

  factory ExamFeeClassSetting.fromJson(Map<String, dynamic> json) {
    final setting = ExamFeeSetting.tryParse(json['setting']);
    return ExamFeeClassSetting(
      classId: _int(json['class_id']),
      className: _str(json['class_name']) ?? 'Class',
      configured: json['configured'] == true || setting != null,
      setting: setting,
      generatedCount: _int(json['generated_count']),
    );
  }
}

class ExamFeeSettingsResult {
  final ExamFeeScope scope;
  final List<ExamFeeClassSetting> classes;
  const ExamFeeSettingsResult({required this.scope, required this.classes});

  static ExamFeeSettingsResult? tryParse(dynamic raw) {
    final json = _map(raw);
    if (json == null || json['classes'] is! List) return null;
    return ExamFeeSettingsResult(
      scope: ExamFeeScope.fromJson(json),
      classes: _maps(json['classes']).map(ExamFeeClassSetting.fromJson).toList(),
    );
  }
}

// --- Generation --------------------------------------------------------------

class ExamFeeStudentRef {
  final int studentId;
  final String? name;
  final String? emisNumber;
  final String? className;
  final double? amount;
  final String? status;
  final bool inOtherClass;
  final bool differsFromCurrentSetting;

  const ExamFeeStudentRef({
    required this.studentId,
    this.name,
    this.emisNumber,
    this.className,
    this.amount,
    this.status,
    this.inOtherClass = false,
    this.differsFromCurrentSetting = false,
  });

  factory ExamFeeStudentRef.fromJson(Map<String, dynamic> json) =>
      ExamFeeStudentRef(
        studentId: _int(json['student_id']),
        name: _str(json['student_name']),
        emisNumber: _str(json['emis_number']),
        className: _str(json['class_name']),
        amount: _moneyOrNull(json['amount']),
        status: _str(json['status']),
        inOtherClass: json['in_other_class'] == true,
        differsFromCurrentSetting: json['differs_from_current_setting'] == true,
      );

  String get displayName => name ?? 'Student #$studentId';
}

class GenerationPreview {
  final ExamFeeScope scope;
  final double? currentAmount;
  final bool canGenerate;
  final String? message;
  final int eligible;
  final int willGenerate;
  final int alreadyGenerated;
  final int alreadyGeneratedInOtherClass;
  final int differsFromCurrentSetting;
  final List<ExamFeeStudentRef> studentsToGenerate;
  final List<ExamFeeStudentRef> alreadyGeneratedStudents;

  const GenerationPreview({
    required this.scope,
    this.currentAmount,
    this.canGenerate = false,
    this.message,
    this.eligible = 0,
    this.willGenerate = 0,
    this.alreadyGenerated = 0,
    this.alreadyGeneratedInOtherClass = 0,
    this.differsFromCurrentSetting = 0,
    this.studentsToGenerate = const [],
    this.alreadyGeneratedStudents = const [],
  });

  static GenerationPreview? tryParse(dynamic raw) {
    final json = _map(raw);
    final counts = _map(json?['counts']);
    if (json == null || counts == null) return null;
    return GenerationPreview(
      scope: ExamFeeScope.fromJson(json),
      currentAmount: _moneyOrNull(json['current_amount']),
      canGenerate: json['can_generate'] == true,
      message: _str(json['message']),
      eligible: _int(counts['eligible']),
      willGenerate: _int(counts['will_generate']),
      alreadyGenerated: _int(counts['already_generated']),
      alreadyGeneratedInOtherClass: _int(counts['already_generated_in_other_class']),
      differsFromCurrentSetting: _int(counts['differs_from_current_setting']),
      studentsToGenerate:
          _maps(json['students_to_generate']).map(ExamFeeStudentRef.fromJson).toList(),
      alreadyGeneratedStudents:
          _maps(json['already_generated']).map(ExamFeeStudentRef.fromJson).toList(),
    );
  }
}

class GenerationResult {
  final double amount;
  final int eligible;
  final int created;
  final int alreadyGenerated;
  final int differsFromCurrentSetting;

  const GenerationResult({
    this.amount = 0,
    this.eligible = 0,
    this.created = 0,
    this.alreadyGenerated = 0,
    this.differsFromCurrentSetting = 0,
  });

  factory GenerationResult.fromJson(Map<String, dynamic> json) => GenerationResult(
    amount: examFeeMoney(json['amount']),
    eligible: _int(json['eligible']),
    created: _int(json['created']),
    alreadyGenerated: _int(json['already_generated']),
    differsFromCurrentSetting: _int(json['differs_from_current_setting']),
  );
}

// --- Register / summary ----------------------------------------------------

class StudentExamFee {
  /// student_exam_fee_id — the id every fee/payment endpoint uses.
  final int id;
  final int studentId;
  final String? studentName;
  final String? emisNumber;
  final double originalAmount;
  final double amount;
  final double paidAmount;
  final double remainingAmount;

  /// UNPAID / PARTIAL / PAID / WAIVED, as the backend sends it.
  final String status;
  final String? adjustmentReason;
  final String? waiverReason;
  final String? enrollmentStatus;

  const StudentExamFee({
    required this.id,
    required this.studentId,
    this.studentName,
    this.emisNumber,
    this.originalAmount = 0,
    this.amount = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.status = kFeeUnpaid,
    this.adjustmentReason,
    this.waiverReason,
    this.enrollmentStatus,
  });

  factory StudentExamFee.fromJson(Map<String, dynamic> json) => StudentExamFee(
    id: _int(json['student_exam_fee_id'] ?? json['id']),
    studentId: _int(json['student_id']),
    studentName: _str(json['student_name']),
    emisNumber: _str(json['emis_number']),
    originalAmount: examFeeMoney(json['original_amount']),
    amount: examFeeMoney(json['amount']),
    paidAmount: examFeeMoney(json['paid_amount']),
    remainingAmount: examFeeMoney(json['remaining_amount']),
    status: (_str(json['status']) ?? kFeeUnpaid).toUpperCase(),
    adjustmentReason: _str(json['adjustment_reason']),
    waiverReason: _str(json['waiver_reason']),
    enrollmentStatus: _str(json['enrollment_status']),
  );

  String get displayName => studentName ?? 'Student #$studentId';

  bool get isWaived => status == kFeeWaived;
  bool get isPaid => status == kFeePaid;

  /// Collect: open balance on a non-waived fee.
  bool get canCollect =>
      !isWaived && !isPaid && toCents(remainingAmount) > 0;

  /// Bulk selection follows the same rule as Collect.
  bool get selectable => canCollect;

  /// Waive: the backend refuses fees that already have payments.
  bool get canWaive => !isWaived && toCents(paidAmount) == 0 && !isPaid;

  bool get canUnwaive => isWaived;

  /// Custom amount: refused by the backend while waived.
  bool get canCustomize => !isWaived;

  bool get isCustomized => toCents(amount) != toCents(originalAmount) && !isWaived;
}

class ExamFeeSummary {
  final int generatedStudents;
  final int notGeneratedStudents;
  final double totalOriginal;
  final double totalCharged;
  final double totalCollected;
  final double outstanding;
  final int paidCount;
  final int partialCount;
  final int unpaidCount;
  final int waivedCount;
  final double totalWaivedValue;

  const ExamFeeSummary({
    this.generatedStudents = 0,
    this.notGeneratedStudents = 0,
    this.totalOriginal = 0,
    this.totalCharged = 0,
    this.totalCollected = 0,
    this.outstanding = 0,
    this.paidCount = 0,
    this.partialCount = 0,
    this.unpaidCount = 0,
    this.waivedCount = 0,
    this.totalWaivedValue = 0,
  });

  factory ExamFeeSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ExamFeeSummary();
    return ExamFeeSummary(
      generatedStudents: _int(json['generated_students']),
      notGeneratedStudents: _int(json['not_generated_students']),
      totalOriginal: examFeeMoney(json['total_original']),
      totalCharged: examFeeMoney(json['total_charged']),
      totalCollected: examFeeMoney(json['total_collected']),
      outstanding: examFeeMoney(json['outstanding']),
      paidCount: _int(json['paid_count']),
      partialCount: _int(json['partial_count']),
      unpaidCount: _int(json['unpaid_count']),
      waivedCount: _int(json['waived_count']),
      totalWaivedValue: examFeeMoney(json['total_waived_value']),
    );
  }
}

class ExamFeeRegister {
  final ExamFeeScope scope;
  final ExamFeeSetting? setting;
  final ExamFeeSummary summary;

  /// Generated fees (financial records).
  final List<StudentExamFee> students;

  /// Enrolled students with no fee for this exam — never UNPAID.
  final List<ExamFeeStudentRef> notGenerated;
  final List<ExamFeeStudentRef> generatedInOtherClass;

  const ExamFeeRegister({
    required this.scope,
    this.setting,
    this.summary = const ExamFeeSummary(),
    this.students = const [],
    this.notGenerated = const [],
    this.generatedInOtherClass = const [],
  });

  static ExamFeeRegister? tryParse(dynamic raw) {
    final json = _map(raw);
    if (json == null || json['students'] is! List) return null;
    return ExamFeeRegister(
      scope: ExamFeeScope.fromJson(json),
      setting: ExamFeeSetting.tryParse(json['setting']),
      summary: ExamFeeSummary.fromJson(_map(json['summary'])),
      students: _maps(json['students'])
          .map(StudentExamFee.fromJson)
          .where((s) => s.id > 0)
          .toList(),
      notGenerated: _maps(json['not_generated']).map(ExamFeeStudentRef.fromJson).toList(),
      generatedInOtherClass: _maps(
        json['generated_in_other_class'],
      ).map(ExamFeeStudentRef.fromJson).toList(),
    );
  }
}

// --- Payments ----------------------------------------------------------------

class ExamFeePayment {
  final int id;
  final String? receiptNumber;
  final double amount;
  final String? method;
  final String? referenceNumber;
  final String? notes;
  final String? paidAt;
  final String? recordedByName;
  final int? studentExamFeeId;
  final int? studentId;
  final String? studentName;
  final String? emisNumber;
  final String? examName;
  final String? className;
  final String? academicYearName;

  const ExamFeePayment({
    required this.id,
    this.receiptNumber,
    this.amount = 0,
    this.method,
    this.referenceNumber,
    this.notes,
    this.paidAt,
    this.recordedByName,
    this.studentExamFeeId,
    this.studentId,
    this.studentName,
    this.emisNumber,
    this.examName,
    this.className,
    this.academicYearName,
  });

  factory ExamFeePayment.fromJson(Map<String, dynamic> json) {
    final student = _map(json['student']);
    return ExamFeePayment(
      id: _int(json['id']),
      receiptNumber: _str(json['receipt_number']),
      amount: examFeeMoney(json['amount']),
      method: _str(json['method']),
      referenceNumber: _str(json['reference_number']),
      notes: _str(json['notes']),
      paidAt: _str(json['paid_at']),
      recordedByName: _str(_map(json['recorded_by'])?['name']),
      studentExamFeeId: _intOrNull(json['student_exam_fee_id']),
      studentId: _intOrNull(student?['id']),
      studentName: _str(student?['name']),
      emisNumber: _str(student?['emis_number']),
      examName: _str(_map(json['exam'])?['name']),
      className: _str(_map(json['class'])?['name']),
      academicYearName: _str(_map(json['academic_year'])?['name']),
    );
  }

  /// "2026-10-02T09:15:00.000Z" -> "2026-10-02 09:15" (local).
  String get paidAtLabel {
    final parsed = DateTime.tryParse(paidAt ?? '');
    if (parsed == null) return paidAt ?? '—';
    final d = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class ExamFeePaymentPage {
  final List<ExamFeePayment> payments;
  final int page;
  final int limit;
  final int total;
  const ExamFeePaymentPage({
    this.payments = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
  });

  static ExamFeePaymentPage? tryParse(dynamic raw) {
    final json = _map(raw);
    if (json == null || json['payments'] is! List) return null;
    final p = _map(json['pagination']);
    final payments = _maps(json['payments']).map(ExamFeePayment.fromJson).toList();
    return ExamFeePaymentPage(
      payments: payments,
      page: p == null ? 1 : _int(p['page']).clamp(1, 1 << 30),
      limit: p == null ? payments.length : _int(p['limit']),
      total: p == null ? payments.length : _int(p['total']),
    );
  }
}

/// POST /payments response.
class PaymentRecordResult {
  final ExamFeePayment payment;
  final double remainingAmount;
  final String? status;
  const PaymentRecordResult({
    required this.payment,
    this.remainingAmount = 0,
    this.status,
  });

  static PaymentRecordResult? tryParse(dynamic raw) {
    final json = _map(raw);
    final payment = _map(json?['payment']);
    if (json == null || payment == null) return null;
    final fee = _map(json['fee']);
    return PaymentRecordResult(
      payment: ExamFeePayment.fromJson(payment),
      remainingAmount: examFeeMoney(fee?['remaining_amount']),
      status: _str(fee?['status']),
    );
  }
}

/// POST /collections response.
class BulkCollectionResult {
  final int paymentCount;
  final double totalCollected;
  final List<ExamFeePayment> payments;
  const BulkCollectionResult({
    this.paymentCount = 0,
    this.totalCollected = 0,
    this.payments = const [],
  });

  static BulkCollectionResult? tryParse(dynamic raw) {
    final json = _map(raw);
    if (json == null) return null;
    final results = _maps(json['results']);
    return BulkCollectionResult(
      paymentCount: _int(json['payment_count']),
      totalCollected: examFeeMoney(json['total_collected']),
      payments: [
        for (final r in results)
          if (_map(r['payment']) != null) ExamFeePayment.fromJson(_map(r['payment'])!),
      ],
    );
  }
}

/// One entry of a bulk validation failure (nothing was recorded).
class BulkEntryError {
  final int? index;
  final int? studentId;
  final String? code;
  final String message;
  const BulkEntryError({this.index, this.studentId, this.code, required this.message});

  factory BulkEntryError.fromJson(Map<String, dynamic> json) => BulkEntryError(
    index: _intOrNull(json['index']) ?? (json['index'] == 0 ? 0 : null),
    studentId: _intOrNull(json['student_id']),
    code: _str(json['code']),
    message: _str(json['message']) ?? 'This entry could not be collected.',
  );
}

class BulkCollectEntry {
  final int studentId;
  final double amount;
  const BulkCollectEntry(this.studentId, this.amount);
  Map<String, dynamic> toJson() => {'student_id': studentId, 'amount': amount};
}

/// GET /student-fees/:id
class StudentFeeDetail {
  final StudentExamFee fee;
  final String? examName;
  final String? className;
  final String? academicYearName;
  final String? adjustmentReason;
  final String? adjustedBy;
  final String? waiverReason;
  final String? waivedBy;
  final List<ExamFeePayment> payments;

  const StudentFeeDetail({
    required this.fee,
    this.examName,
    this.className,
    this.academicYearName,
    this.adjustmentReason,
    this.adjustedBy,
    this.waiverReason,
    this.waivedBy,
    this.payments = const [],
  });

  static StudentFeeDetail? tryParse(dynamic raw) {
    final json = _map(raw);
    final fee = _map(json?['fee']);
    if (json == null || fee == null) return null;
    final student = _map(json['student']);
    final adjustment = _map(json['adjustment']);
    final waiver = _map(json['waiver']);
    return StudentFeeDetail(
      fee: StudentExamFee.fromJson({
        ...fee,
        'student_name': fee['student_name'] ?? student?['name'],
        'emis_number': fee['emis_number'] ?? student?['emis_number'],
      }),
      examName: _str(_map(json['exam'])?['name']),
      className: _str(_map(json['class'])?['name']),
      academicYearName: _str(_map(json['academic_year'])?['name']),
      adjustmentReason: _str(adjustment?['reason']),
      adjustedBy: _str(_map(adjustment?['by'])?['name']),
      waiverReason: _str(waiver?['reason']),
      waivedBy: _str(_map(waiver?['by'])?['name']),
      payments: _maps(json['payments']).map(ExamFeePayment.fromJson).toList(),
    );
  }
}
