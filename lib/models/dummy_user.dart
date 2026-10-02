
enum UserRole { schoolAdmin, teacher, student, parent, finance }

class DummyUser {
  final String id;
  final String email;
  final String password;
  final String name;
  final UserRole role;

  final String? phone;
  final String? schoolId;
  final String? emisNumber;

  const DummyUser({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.phone,
    this.schoolId, // nullable
    this.emisNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'phone': phone,
      'schoolId': schoolId,
      'emisNumber': emisNumber,
    };
  }

  factory DummyUser.fromJson(Map<String, dynamic> json) {
    return DummyUser(
      id: json['id'],
      email: json['email'],
      password: '', // Password not stored in session usually
      name: json['name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.student,
      ),
      phone: json['phone'],
      schoolId: json['schoolId'],
      emisNumber: json['emisNumber'],
    );
  }
}
