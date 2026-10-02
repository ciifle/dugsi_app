int _id(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

int? _idOpt(dynamic v) => v == null ? null : _id(v);

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

/// Per-class breakdown of one generation preview/run. NOT_CONFIGURED and
/// TERM_UNSUPPORTED are informational only — they never block generation
/// for other classes.
class FeeGenerationClassSummary {
  final int classId;
  final String className;
  final String status; // CONFIGURED | NOT_CONFIGURED | TERM_UNSUPPORTED | CYCLE_MISMATCH
  final String? configuredBillingCycle;
  final num? amount;
  final int enrolledStudents;
  final int willGenerate;
  final int alreadyGenerated;
  final int discountedStudents;
  final int freeStudents;
  final num grossAmount;
  final num discountAmount;
  final num netAmount;

  const FeeGenerationClassSummary({
    required this.classId,
    required this.className,
    required this.status,
    this.configuredBillingCycle,
    this.amount,
    required this.enrolledStudents,
    required this.willGenerate,
    required this.alreadyGenerated,
    required this.discountedStudents,
    required this.freeStudents,
    required this.grossAmount,
    required this.discountAmount,
    required this.netAmount,
  });

  factory FeeGenerationClassSummary.fromJson(Map<String, dynamic> json) =>
      FeeGenerationClassSummary(
        classId: _id(json['class_id']),
        className: (json['class_name'] ?? '').toString(),
        status: (json['status'] ?? 'NOT_CONFIGURED').toString(),
        configuredBillingCycle: json['configured_billing_cycle'] as String?,
        amount: json['amount'] == null ? null : _num(json['amount']),
        enrolledStudents: _id(json['enrolled_students']),
        willGenerate: _id(json['will_generate']),
        alreadyGenerated: _id(json['already_generated']),
        discountedStudents: _id(json['discounted_students']),
        freeStudents: _id(json['free_students']),
        grossAmount: _num(json['gross_amount']),
        discountAmount: _num(json['discount_amount']),
        netAmount: _num(json['net_amount']),
      );
}

class FeeGenerationWarning {
  final String code;
  final int classId;
  final String className;

  const FeeGenerationWarning({
    required this.code,
    required this.classId,
    required this.className,
  });

  factory FeeGenerationWarning.fromJson(Map<String, dynamic> json) =>
      FeeGenerationWarning(
        code: (json['code'] ?? '').toString(),
        classId: _id(json['class_id']),
        className: (json['class_name'] ?? '').toString(),
      );
}

class FeeGenerationSummary {
  final int eligibleClasses;
  final int configuredClasses;
  final int unconfiguredClasses;
  final int totalStudents;
  final int willGenerate;
  final int alreadyGenerated;
  final int? created; // generate only
  final int? skippedExisting; // generate only
  final int discountedStudents;
  final int freeStudents;
  final num grossAmount;
  final num discountAmount;
  final num netAmount;

  const FeeGenerationSummary({
    required this.eligibleClasses,
    required this.configuredClasses,
    required this.unconfiguredClasses,
    required this.totalStudents,
    required this.willGenerate,
    required this.alreadyGenerated,
    this.created,
    this.skippedExisting,
    required this.discountedStudents,
    required this.freeStudents,
    required this.grossAmount,
    required this.discountAmount,
    required this.netAmount,
  });

  factory FeeGenerationSummary.fromJson(Map<String, dynamic> json) =>
      FeeGenerationSummary(
        eligibleClasses: _id(json['eligible_classes']),
        configuredClasses: _id(json['configured_classes']),
        unconfiguredClasses: _id(json['unconfigured_classes']),
        totalStudents: _id(json['total_students']),
        willGenerate: _id(json['will_generate']),
        alreadyGenerated: _id(json['already_generated']),
        created: _idOpt(json['created']),
        skippedExisting: _idOpt(json['skipped_existing']),
        discountedStudents: _id(json['discounted_students']),
        freeStudents: _id(json['free_students']),
        grossAmount: _num(json['gross_amount']),
        discountAmount: _num(json['discount_amount']),
        netAmount: _num(json['net_amount']),
      );
}

class FeeGenerationPeriod {
  final String billingCycle; // MONTHLY | YEARLY
  final int billingYear;
  final int billingMonth; // 1-12 for MONTHLY, 0 for YEARLY

  const FeeGenerationPeriod({
    required this.billingCycle,
    required this.billingYear,
    required this.billingMonth,
  });

  factory FeeGenerationPeriod.fromJson(Map<String, dynamic> json) =>
      FeeGenerationPeriod(
        billingCycle: (json['billing_cycle'] ?? 'MONTHLY').toString(),
        billingYear: _id(json['billing_year']),
        billingMonth: _id(json['billing_month']),
      );
}

/// Result of both POST /fees/generate/preview (no writes) and POST
/// /fees/generate (persists). Same shape; [FeeGenerationSummary.created]/
/// [FeeGenerationSummary.skippedExisting] are only populated by generate.
class FeeGenerationResult {
  final int academicYearId;
  final String academicYearName;
  final FeeGenerationPeriod period;
  final FeeGenerationSummary summary;
  final List<FeeGenerationClassSummary> classes;
  final List<FeeGenerationWarning> warnings;

  const FeeGenerationResult({
    required this.academicYearId,
    required this.academicYearName,
    required this.period,
    required this.summary,
    required this.classes,
    required this.warnings,
  });

  factory FeeGenerationResult.fromJson(Map<String, dynamic> json) {
    final rawYear = json['academicYear'] ?? json['academic_year'];
    final year = rawYear is Map
        ? Map<String, dynamic>.from(rawYear)
        : <String, dynamic>{};
    return FeeGenerationResult(
      academicYearId: _id(year['id']),
      academicYearName: (year['name'] ?? '').toString(),
      period: FeeGenerationPeriod.fromJson(
        json['period'] is Map
            ? Map<String, dynamic>.from(json['period'] as Map)
            : const {},
      ),
      summary: FeeGenerationSummary.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : const {},
      ),
      classes: (json['classes'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => FeeGenerationClassSummary.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      warnings: (json['warnings'] as List? ?? const [])
          .whereType<Map>()
          .map((e) =>
              FeeGenerationWarning.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
