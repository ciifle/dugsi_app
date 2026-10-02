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

/// One class's fee configuration for one academic year.
/// When [configured] is false, amount/billingCycle/isActive/feeSettingId are
/// all null (never 0) — 0 is itself a valid configured fee (a free class).
class ClassFee {
  final int classId;
  final String className;
  final bool configured;
  final int? feeSettingId;
  final num? amount;
  final String? billingCycle;
  final bool? isActive;

  const ClassFee({
    required this.classId,
    required this.className,
    required this.configured,
    this.feeSettingId,
    this.amount,
    this.billingCycle,
    this.isActive,
  });

  factory ClassFee.fromJson(Map<String, dynamic> json) => ClassFee(
    classId: _id(json['class_id']),
    className: (json['class_name'] ?? '').toString(),
    configured: json['configured'] == true,
    feeSettingId: json['fee_setting_id'] != null
        ? _id(json['fee_setting_id'])
        : null,
    amount: _numOpt(json['amount']),
    billingCycle: json['billing_cycle'] as String?,
    isActive: _boolOpt(json['is_active']),
  );
}

const List<String> kBillingCycles = ['MONTHLY', 'TERM', 'YEARLY'];
