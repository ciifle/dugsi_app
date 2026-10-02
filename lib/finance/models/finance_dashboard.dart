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

/// School-wide fee dashboard summary for one academic year. All values are
/// factual aggregates computed server-side from GENERATED fees rows —
/// never projected/invented from class_fee_settings.
class FinanceDashboard {
  final int academicYearId;
  final String academicYearName;
  final num totalCharged;
  final num totalPaid;
  final num totalOutstanding;
  final num totalDiscount;
  final int paidFees;
  final int partialFees;
  final int unpaidFees;
  final int fullyDiscountedFeeCount;
  final num collectionsToday;
  final num collectionsThisMonth;

  const FinanceDashboard({
    required this.academicYearId,
    required this.academicYearName,
    required this.totalCharged,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.totalDiscount,
    required this.paidFees,
    required this.partialFees,
    required this.unpaidFees,
    required this.fullyDiscountedFeeCount,
    required this.collectionsToday,
    required this.collectionsThisMonth,
  });

  factory FinanceDashboard.fromJson(Map<String, dynamic> json) {
    final rawYear = json['academicYear'] ?? json['academic_year'];
    final year = rawYear is Map
        ? Map<String, dynamic>.from(rawYear)
        : <String, dynamic>{};
    return FinanceDashboard(
      academicYearId: _id(year['id']),
      academicYearName: (year['name'] ?? '').toString(),
      totalCharged: _num(json['total_charged']),
      totalPaid: _num(json['total_paid']),
      totalOutstanding: _num(json['total_outstanding']),
      totalDiscount: _num(json['total_discount']),
      paidFees: _id(json['paid_fees']),
      partialFees: _id(json['partial_fees']),
      unpaidFees: _id(json['unpaid_fees']),
      fullyDiscountedFeeCount: _id(json['fully_discounted_fee_count']),
      collectionsToday: _num(json['collections_today']),
      collectionsThisMonth: _num(json['collections_this_month']),
    );
  }
}
