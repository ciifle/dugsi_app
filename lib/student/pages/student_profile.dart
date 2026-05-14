import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/models/auth_me_models.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/student/widgets/student_web_ui.dart';

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
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const StudentProfileScreen({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

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
    if (widget.embedBodyOnly && isStudentDesktopWeb(context)) {
      return Container(
        color: studentWebBg,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: kPrimaryBlue,
          child: _buildDesktopProfileBody(context, student),
        ),
      );
    }
    return _buildContent(context, student, onRefresh: _refresh);
  }

  Widget _buildDesktopProfileBody(BuildContext context, Map<String, String> student) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: _DesktopStudentProfileCard(
            student: student,
            onLogout: () => context.read<AuthProvider>().logout(),
          ),
        ),
      ),
    );
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

class _DesktopStudentProfileCard extends StatelessWidget {
  final Map<String, String> student;
  final VoidCallback onLogout;

  const _DesktopStudentProfileCard({
    required this.student,
    required this.onLogout,
  });

  static const String _dash = '—';

  String _displayValue(String key) {
    final value = student[key]?.trim();
    if (value == null || value.isEmpty || value == _dash) {
      return _dash;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final detailEntries = <({String label, String key, IconData icon, Color accent})>[
      (label: 'Email', key: 'email', icon: Icons.email_outlined, accent: studentWebBlue),
      (label: 'Phone', key: 'phone', icon: Icons.phone_outlined, accent: studentWebGreen),
      (label: 'Gender', key: 'gender', icon: Icons.wc_outlined, accent: studentWebBlue),
      (label: 'Class', key: 'class', icon: Icons.school_outlined, accent: studentWebGreen),
      (label: 'Student ID', key: 'studentID', icon: Icons.badge_outlined, accent: studentWebBlue),
      (label: "Mother's name", key: 'motherName', icon: Icons.family_restroom_outlined, accent: studentWebGreen),
      (label: 'Date of birth', key: 'dob', icon: Icons.cake_outlined, accent: studentWebBlue),
      (label: 'Attendance status', key: 'absenteeismStatus', icon: Icons.event_available_outlined, accent: studentWebGreen),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DesktopProfileGradientHeader(student: student),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 14.0;
                    final twoColumns = constraints.maxWidth >= 640;
                    final tileWidth = twoColumns
                        ? (constraints.maxWidth - spacing) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final entry in detailEntries)
                          SizedBox(
                            width: tileWidth,
                            child: _DesktopProfileDetailTile(
                              label: entry.label,
                              value: _displayValue(entry.key),
                              icon: entry.icon,
                              accent: entry.accent,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                _DesktopProfileFooter(
                  attendanceStatus: _displayValue('absenteeismStatus'),
                  onLogout: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopProfileGradientHeader extends StatelessWidget {
  final Map<String, String> student;

  const _DesktopProfileGradientHeader({required this.student});

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _displayOrDash(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == '—') {
      return '—';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final name = _displayOrDash(student['fullName']);
    final className = _displayOrDash(student['class']);
    final studentId = _displayOrDash(student['studentID']);

    return Container(
      constraints: const BoxConstraints(minHeight: 178, maxHeight: 210),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [studentWebBlue, Color(0xFF0B5A8A), studentWebGreen],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials(name == '—' ? 'Student' : name),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: studentWebBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DesktopProfileHeaderBadge(
                      label: 'STUDENT',
                      background: Colors.white.withValues(alpha: 0.18),
                      foreground: Colors.white,
                    ),
                    if (className != '—')
                      _DesktopProfileHeaderBadge(
                        label: className,
                        background: Colors.white.withValues(alpha: 0.14),
                        foreground: Colors.white,
                        icon: Icons.school_outlined,
                      ),
                    if (studentId != '—')
                      _DesktopProfileHeaderBadge(
                        label: studentId,
                        background: Colors.white.withValues(alpha: 0.14),
                        foreground: Colors.white,
                        icon: Icons.badge_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopProfileHeaderBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const _DesktopProfileHeaderBadge({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopProfileDetailTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _DesktopProfileDetailTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: studentWebTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: studentWebTextPrimary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopProfileFooter extends StatelessWidget {
  final String attendanceStatus;
  final VoidCallback onLogout;

  const _DesktopProfileFooter({
    required this.attendanceStatus,
    required this.onLogout,
  });

  bool get _hasAttendanceStatus => attendanceStatus.trim().isNotEmpty && attendanceStatus != '—';

  bool get _isActiveStatus {
    final normalized = attendanceStatus.trim().toLowerCase();
    return normalized.contains('active') ||
        normalized.contains('present') ||
        normalized.contains('regular');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (_hasAttendanceStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: (_isActiveStatus ? studentWebGreen : kErrorColor).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (_isActiveStatus ? studentWebGreen : kErrorColor).withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isActiveStatus ? Icons.verified_rounded : Icons.info_outline_rounded,
                  size: 15,
                  color: _isActiveStatus ? studentWebGreen : kErrorColor,
                ),
                const SizedBox(width: 6),
                Text(
                  attendanceStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isActiveStatus ? studentWebGreen : kErrorColor,
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Logout'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kErrorColor,
            side: BorderSide(color: kErrorColor.withValues(alpha: 0.45)),
            backgroundColor: kErrorColor.withValues(alpha: 0.04),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
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
