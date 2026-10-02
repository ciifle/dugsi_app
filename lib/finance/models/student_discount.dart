int _id(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

num? _numOpt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

bool? _boolOpt(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  return v.toString() == '1' || v.toString().toLowerCase() == 'true';
}

String? _strOpt(dynamic v) => v == null ? null : v.toString().trim();

/// A student's discount configuration for one academic year, plus the
/// backend's informational calculation preview (base/discount/effective
/// amount). All three preview fields are null — never 0 — when the
/// student's class has no configured active fee.
class StudentDiscount {
  final int studentId;
  final String studentName;
  final String? emisNumber;
  final int classId;
  final String className;
  final int academicYearId;
  final bool configured;
  final num? discountPercentage;
  final String? reason;
  final bool? isActive;
  final num? baseAmount;
  final num? discountAmount;
  final num? effectiveAmount;

  const StudentDiscount({
    required this.studentId,
    required this.studentName,
    this.emisNumber,
    required this.classId,
    required this.className,
    required this.academicYearId,
    required this.configured,
    this.discountPercentage,
    this.reason,
    this.isActive,
    this.baseAmount,
    this.discountAmount,
    this.effectiveAmount,
  });

  bool get isFullyFree => (discountPercentage ?? 0) >= 100;

  factory StudentDiscount.fromJson(Map<String, dynamic> json) =>
      StudentDiscount(
        studentId: _id(json['student_id']),
        studentName: (json['student_name'] ?? '').toString(),
        emisNumber: _strOpt(json['emis_number']),
        classId: _id(json['class_id']),
        className: (json['class_name'] ?? '').toString(),
        academicYearId: _id(json['academic_year_id']),
        configured: json['configured'] == true,
        discountPercentage: _numOpt(json['discount_percentage']),
        reason: _strOpt(json['reason']),
        isActive: _boolOpt(json['is_active']),
        baseAmount: _numOpt(json['base_amount']),
        discountAmount: _numOpt(json['discount_amount']),
        effectiveAmount: _numOpt(json['effective_amount']),
      );
}
