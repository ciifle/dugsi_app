int _id(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String? _strOpt(dynamic v) => v == null ? null : v.toString().trim();

/// A FINANCE-role user scoped to the authenticated SCHOOL_ADMIN's school.
/// GET/POST/PATCH /api/school-admin/finance-users response shape.
class FinanceUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final int schoolId;
  final String? createdAt;
  final String? updatedAt;

  const FinanceUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.schoolId,
    this.createdAt,
    this.updatedAt,
  });

  factory FinanceUser.fromJson(Map<String, dynamic> json) => FinanceUser(
    id: _id(json['id']),
    name: (_strOpt(json['name']) ?? '').toString(),
    email: (_strOpt(json['email']) ?? '').toString(),
    role: (_strOpt(json['role']) ?? 'FINANCE').toString(),
    schoolId: _id(json['school_id'] ?? json['schoolId']),
    createdAt: _strOpt(json['created_at'] ?? json['createdAt']),
    updatedAt: _strOpt(json['updated_at'] ?? json['updatedAt']),
  );
}
