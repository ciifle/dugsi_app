import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/models/auth_me_models.dart';
import 'package:kobac/models/auth_user.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/dummy_school_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/school_admin/pages/change_password_page.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFE8ECF2);
const double kCardRadius = 20.0;

class AdminProfilePage extends StatefulWidget {
  final bool openedFromDrawer;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AdminProfilePage({
    super.key,
    this.openedFromDrawer = false,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  Future<Map<String, String>?>? _adminDataFuture;
  Future<Map<String, int>>? _statsFuture;
  bool _adminDataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adminDataLoaded) {
      _adminDataLoaded = true;
      final auth = context.read<AuthProvider>();
      _adminDataFuture = _loadAdminData(auth.user, auth.schoolAdminProfile);
      _statsFuture = _loadStats();
    }
  }

  Future<void> _refreshProfile() async {
    setState(() => _adminDataLoaded = false);
    final auth = context.read<AuthProvider>();
    await auth.refreshMe();
    if (mounted) {
      setState(() {
        _adminDataLoaded = false;
        _adminDataFuture = _loadAdminData(auth.user, auth.schoolAdminProfile);
        _statsFuture = _loadStats();
      });
    }
  }

  Future<Map<String, String>?> _loadAdminData(AuthUser? user, dynamic profile) async {
    if (user == null) return null;

    String schoolName = '';
    final schoolId = profile is SchoolAdminProfile && profile.schoolId != null
        ? profile.schoolId
        : user.schoolId;
    if (schoolId != null) {
      try {
        final school = await DummySchoolService().getSchoolById(schoolId.toString());
        if (school != null) schoolName = school.name ?? '';
      } catch (e) {
        debugPrint('Error loading school: $e');
      }
    }

    final name = (profile is SchoolAdminProfile && profile.name != null && profile.name!.isNotEmpty)
        ? profile.name!
        : user.name;
    final roleStr = user.role.replaceAll('_', ' ').toUpperCase();
    final email = (profile is SchoolAdminProfile && profile.email != null && profile.email!.isNotEmpty)
        ? profile.email!
        : (user.email ?? user.emisNumber ?? '');

    return {
      'name': name,
      'role': roleStr,
      'email': email,
      'phone': '',
      'school': schoolName,
      'username': name.replaceAll(' ', '_').toLowerCase(),
    };
  }

  Future<Map<String, int>> _loadStats() async {
    try {
      int students = 0;
      final studentsResult = await StudentsService().listStudents();
      if (studentsResult is StudentSuccess<List<StudentModel>>) {
        students = studentsResult.data.length;
      }
      int teachers = 0;
      final teachersResult = await TeachersService().listTeachers();
      if (teachersResult is TeacherSuccess<List<TeacherModel>>) {
        teachers = teachersResult.data.length;
      }
      int classes = 0;
      final classesResult = await ClassesService().listClasses();
      if (classesResult is ClassSuccess<List<ClassModel>>) {
        classes = classesResult.data.length;
      }
      return {'students': students, 'teachers': teachers, 'classes': classes};
    } catch (_) {
      return {'students': 0, 'teachers': 0, 'classes': 0};
    }
  }

  String _initialsFrom(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  void _openEditProfile() {}

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  Widget _buildProfileBody(BuildContext context, AsyncSnapshot<Map<String, String>?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
    }
    final data = snapshot.data;
    if (data == null) return const Center(child: Text('User not found'));

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) {
      return _buildDesktopProfileBody(context, data);
    }
    return _buildMobileProfileBody(context, data);
  }

  Widget _buildMobileProfileBody(BuildContext context, Map<String, String> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileCard(context, data),
          const SizedBox(height: 20),
          _buildSummaryCards(context),
          const SizedBox(height: 12),
          _buildResetPasswordTile(context),
          const SizedBox(height: 20),
          _buildLogoutButton(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDesktopProfileBody(BuildContext context, Map<String, String> data) {
    final phone = data['phone']?.trim() ?? '';
    final school = data['school']?.trim() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDesktopHeroCard(context, data),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final accountCard = _ProfileSectionCard(
                title: 'Account Details',
                children: [
                  _InfoRow(label: 'Full Name', value: data['name'] ?? '—'),
                  _InfoRow(label: 'Role', value: data['role'] ?? '—'),
                  _InfoRow(label: 'Email', value: data['email'] ?? '—'),
                  if (phone.isNotEmpty) _InfoRow(label: 'Phone', value: phone),
                  if (school.isNotEmpty) _InfoRow(label: 'School', value: school),
                ],
              );

              final actionsCard = _ProfileSectionCard(
                title: 'Actions',
                children: [
                  _ActionRow(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onTap: _openEditProfile,
                  ),
                  _ActionRow(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    onTap: _logout,
                    danger: true,
                  ),
                ],
              );

              if (constraints.maxWidth >= 980) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: accountCard),
                    const SizedBox(width: 20),
                    Expanded(child: actionsCard),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  accountCard,
                  const SizedBox(height: 16),
                  actionsCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeroCard(BuildContext context, Map<String, String> data) {
    final initials = _initialsFrom(data['name'] ?? '');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final profileInfo = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: kPrimaryBlue.withOpacity(0.08),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: kPrimaryBlue,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: kPrimaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? '—',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kPrimaryBlue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['role'] ?? '—',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['email'] ?? '—',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Align(
            alignment: isWide ? Alignment.centerRight : Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _openEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: profileInfo),
                actions,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              profileInfo,
              const SizedBox(height: 16),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Map<String, String> data) {
    final initials = _initialsFrom(data['name'] ?? '');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.white, blurRadius: 18, offset: const Offset(-6, -6), spreadRadius: 0.5),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 28, offset: const Offset(10, 12)),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(5, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryGreen.withOpacity(0.6), width: 2.5),
                      boxShadow: [
                        BoxShadow(color: Colors.white, blurRadius: 8, offset: const Offset(-2, -2)),
                        BoxShadow(color: kPrimaryBlue.withOpacity(0.15), blurRadius: 12, offset: const Offset(3, 3)),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF5B9BD5).withOpacity(0.2),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFF023471),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: kPrimaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name']!,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['role']!,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['email']!,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.white, blurRadius: 8, offset: const Offset(-2, -2)),
                BoxShadow(color: kPrimaryBlue.withOpacity(0.2), blurRadius: 12, offset: const Offset(3, 3)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _openEditProfile,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 20, color: kPrimaryBlue),
                      const SizedBox(width: 8),
                      Text('Edit Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kPrimaryBlue)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _statsFuture ?? Future.value({'students': 0, 'teachers': 0, 'classes': 0}),
      builder: (context, snap) {
        final stats = snap.data ?? {'students': 0, 'teachers': 0, 'classes': 0};
        return Row(
          children: [
            Expanded(child: _SummaryCard(label: 'STUDENTS', value: '${stats['students'] ?? 0}', icon: Icons.people_alt_rounded, color: kPrimaryBlue)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(label: 'TEACHERS', value: '${stats['teachers'] ?? 0}', icon: Icons.school_rounded, color: kPrimaryGreen)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(label: 'CLASSES', value: '${stats['classes'] ?? 0}', icon: Icons.class_rounded, color: kPrimaryBlue)),
          ],
        );
      },
    );
  }

  Widget _buildResetPasswordTile(BuildContext context) {
    return _ProfileActionTile(
      icon: Icons.lock_reset_rounded,
      label: 'Reset Password',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kCardRadius),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.white, blurRadius: 8, offset: const Offset(-2, -2)),
              BoxShadow(color: Colors.redAccent.withOpacity(0.15), blurRadius: 14, offset: const Offset(4, 6)),
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(2, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
              const SizedBox(width: 10),
              Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.redAccent)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final futureBody = FutureBuilder<Map<String, String>?>(
      future: _adminDataFuture ?? Future.value(null),
      builder: (context, snapshot) => _buildProfileBody(context, snapshot),
    );
    if (widget.embedBodyOnly) {
      return Container(color: const Color(0xFFF8F9FC), child: futureBody);
    }
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: true,
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.white, blurRadius: 6, offset: const Offset(-2, -2)),
                  BoxShadow(color: kPrimaryBlue.withOpacity(0.2), blurRadius: 10, offset: const Offset(2, 2)),
                ],
              ),
              child: const Icon(Icons.settings_rounded, color: kPrimaryBlue, size: 22),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: kPrimaryGreen,
        child: futureBody,
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kPrimaryBlue),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kPrimaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade700 : kPrimaryBlue;
    return Material(
      color: danger ? Colors.red.shade50 : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.white, blurRadius: 10, offset: const Offset(-3, -3)),
              BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 16, offset: const Offset(4, 6)),
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(2, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.white, blurRadius: 6, offset: const Offset(-2, -2)),
                    BoxShadow(color: kPrimaryBlue.withOpacity(0.15), blurRadius: 8, offset: const Offset(2, 2)),
                  ],
                ),
                child: Icon(icon, color: kPrimaryBlue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kPrimaryBlue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.white, blurRadius: 12, offset: const Offset(-4, -4), spreadRadius: 0.5),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(6, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(3, 5)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(color: Colors.white, blurRadius: 6, offset: const Offset(-2, -2)),
                BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(2, 2)),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
        ],
      ),
    );
  }
}
