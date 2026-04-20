import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/models/auth_me_models.dart';
import 'package:kobac/services/auth_provider.dart';

// ---------- COLOR PALETTE (Matching Dashboard) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE0E9F5); // Light tint of blue
const Color kSoftGreen = Color(0xFFE4F1E2); // Light tint of green
const Color kDarkGreen = Color(0xFF3D8C30); // Darker shade of green
const Color kDarkBlue = Color(0xFF011A3D); // Darker shade of blue
const Color kSoftPurple = Color(0xFF4A6FA5); // Soft blue-purple
const Color kSoftPink = Color(0xFF7CB86E); // Soft green-pink
const Color kSoftOrange = Color(0xFFF59E0B); // Amber for warning
const Color kSuccessColor = Color(0xFF3D8C30); // Darker green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kBackgroundColor = Color(0xFFF5F8FC); // Light background
const Color kSurfaceColor = Colors.white;
const Color kTextPrimaryColor = Color(0xFF1A1E1F); // Dark slate
const Color kTextSecondaryColor = Color(0xFF4F5A5E); // Medium slate

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [kPrimaryBlue, kPrimaryGreen];
const List<Color> kSuccessGradient = [kPrimaryGreen, kDarkGreen];
const List<Color> kWarningGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({Key? key}) : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Future<void> _refresh() async {
    await context.read<AuthProvider>().refreshMe();
    if (mounted) setState(() {});
  }

  static const String _dash = '—';

  Map<String, String> _studentMapFromProfile(dynamic prof, dynamic user) {
    final p = prof is StudentProfile ? prof : null;
    return {
      'fullName': p?.studentName ?? user?.name ?? _dash,
      'studentID': p?.emisNumber ?? user?.emisNumber ?? (user != null ? 'ID ${user.id}' : _dash),
      'class': p?.className ?? _dash,
      'dob': p?.birthDate ?? _dash,
      'gender': p?.sex ?? _dash,
      'phone': p?.telephone ?? p?.phone ?? _dash,
      'email': user?.email ?? user?.emisNumber ?? p?.emisNumber ?? _dash,
      'schoolName': p?.schoolName ?? _dash,
      'guardianName': p?.guardianName ?? _dash,
      'guardianPhone': p?.telephone ?? _dash,
      'motherName': p?.motherName ?? _dash,
      'birthPlace': p?.birthPlace ?? _dash,
      'nationality': p?.nationality ?? _dash,
      'studentState': p?.studentState ?? _dash,
      'studentDistrict': p?.studentDistrict ?? _dash,
      'studentVillage': p?.studentVillage ?? _dash,
      'refugeeStatus': p?.refugeeStatus ?? _dash,
      'orphanStatus': p?.orphanStatus ?? _dash,
      'disabilityStatus': p?.disabilityStatus ?? _dash,
      'age': p?.age != null ? '${p!.age}' : _dash,
      'absenteeismStatus': p?.absenteeismStatus ?? _dash,
    };
  }

  /// Builds card rows only for keys that have a non-empty value (not placeholder).
  List<_CardRow> _rows(Map<String, String> student, List<({String label, String key})> entries) {
    return [
      for (final e in entries)
        if ((student[e.key] ?? _dash).trim().isNotEmpty && student[e.key] != _dash)
          _CardRow(label: e.label, value: student[e.key]!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final prof = auth.studentProfile;
    if (auth.profileError != null) {
      return _buildError(context, auth.profileError!, _refresh, is404: true);
    }
    final student = _studentMapFromProfile(prof, user);
    return _buildContent(context, student, onRefresh: _refresh);
  }

  Widget _buildError(BuildContext context, String message, VoidCallback onRetry, {bool is404 = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kSoftBlue, kSoftGreen],
          stops: [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  is404 ? Icons.person_off_rounded : Icons.error_outline_rounded,
                  size: 56,
                  color: kErrorColor.withOpacity(0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: kTextPrimaryColor),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, String> student, {VoidCallback? onRefresh}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kSoftBlue, kSoftGreen],
          stops: [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () async => onRefresh?.call(),
          color: kPrimaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 44),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "My Profile",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Personal Info",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ProfileHeaderCard(student: student),
                  const SizedBox(height: 20),
                  if (_rows(student, [
                    (label: "Date of Birth", key: 'dob'),
                    (label: "Gender", key: 'gender'),
                    (label: "Phone", key: 'phone'),
                    (label: "Email", key: 'email'),
                    (label: "Mother's name", key: 'motherName'),
                    (label: "Birth place", key: 'birthPlace'),
                    (label: "Nationality", key: 'nationality'),
                  ]).isNotEmpty) ...[
                    _InfoCard(
                      title: "Personal Information",
                      icon: Icons.person_outline_rounded,
                      gradientColor: kPrimaryBlue,
                      data: _rows(student, [
                        (label: "Date of Birth", key: 'dob'),
                        (label: "Gender", key: 'gender'),
                        (label: "Phone", key: 'phone'),
                        (label: "Email", key: 'email'),
                        (label: "Mother's name", key: 'motherName'),
                        (label: "Birth place", key: 'birthPlace'),
                        (label: "Nationality", key: 'nationality'),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_rows(student, [
                    (label: "School", key: 'schoolName'),
                    (label: "Class", key: 'class'),
                    (label: "EMIS Number", key: 'studentID'),
                    (label: "Age", key: 'age'),
                    (label: "Absenteeism status", key: 'absenteeismStatus'),
                  ]).isNotEmpty) ...[
                    _InfoCard(
                      title: "Academic Information",
                      icon: Icons.school_rounded,
                      gradientColor: kPrimaryGreen,
                      data: _rows(student, [
                        (label: "School", key: 'schoolName'),
                        (label: "Class", key: 'class'),
                        (label: "EMIS Number", key: 'studentID'),
                        (label: "Age", key: 'age'),
                        (label: "Absenteeism status", key: 'absenteeismStatus'),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_rows(student, [
                    (label: "Name", key: 'guardianName'),
                    (label: "Phone", key: 'guardianPhone'),
                  ]).isNotEmpty) ...[
                    _InfoCard(
                      title: "Guardian Information",
                      icon: Icons.family_restroom_rounded,
                      gradientColor: kSoftOrange,
                      data: _rows(student, [
                        (label: "Name", key: 'guardianName'),
                        (label: "Phone", key: 'guardianPhone'),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_rows(student, [
                    (label: "State / Region", key: 'studentState'),
                    (label: "District", key: 'studentDistrict'),
                    (label: "Village", key: 'studentVillage'),
                    (label: "Refugee status", key: 'refugeeStatus'),
                    (label: "Orphan status", key: 'orphanStatus'),
                    (label: "Disability status", key: 'disabilityStatus'),
                  ]).isNotEmpty) ...[
                    _InfoCard(
                      title: "Address & Status",
                      icon: Icons.location_on_rounded,
                      gradientColor: kSoftPurple,
                      data: _rows(student, [
                        (label: "State / Region", key: 'studentState'),
                        (label: "District", key: 'studentDistrict'),
                        (label: "Village", key: 'studentVillage'),
                        (label: "Refugee status", key: 'refugeeStatus'),
                        (label: "Orphan status", key: 'orphanStatus'),
                        (label: "Disability status", key: 'disabilityStatus'),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 24),
                  _buildLogoutButton(context),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await context.read<AuthProvider>().logout();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                kErrorColor.withOpacity(0.05),
                kErrorColor.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: kErrorColor.withOpacity(0.2), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kErrorColor, kErrorColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kErrorColor.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kErrorColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile Header Card
class _ProfileHeaderCard extends StatelessWidget {
  final Map<String, String> student;
  const _ProfileHeaderCard({required this.student});

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return "";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = student['fullName']!;
    final id = student['studentID']!;
    final className = student['class']!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, kSoftGreen],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          // Profile Image with Gradient Border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(name),
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              color: kTextPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.badge_rounded, size: 16, color: kPrimaryBlue),
                const SizedBox(width: 6),
                Text(
                  "ID: $id",
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryBlue, kPrimaryBlue.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  "Class $className",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Info Card
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color gradientColor;
  final List<_CardRow> data;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.gradientColor,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: gradientColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientColor, gradientColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(
            data.length,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i == data.length - 1 ? 0 : 14),
              child: data[i],
            ),
          ),
        ],
      ),
    );
  }
}

// Card Row
class _CardRow extends StatelessWidget {
  final String label;
  final String value;

  const _CardRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              color: kTextSecondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: kTextPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
