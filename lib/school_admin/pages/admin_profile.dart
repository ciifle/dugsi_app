import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/models/auth_me_models.dart';
import 'package:kobac/models/auth_user.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/dummy_school_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/school_admin/pages/change_password_page.dart';
import 'package:kobac/school_admin/pages/manage_users_screen.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFE8ECF2);
const double kCardRadius = 20.0;

class AdminProfilePage extends StatefulWidget {
  final bool openedFromDrawer;
  final bool embedBodyOnly;
  const AdminProfilePage({super.key, this.openedFromDrawer = false, this.embedBodyOnly = false});

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
      return {'students': students, 'teachers': teachers, 'classes': 12};
    } catch (_) {
      return {'students': 0, 'teachers': 0, 'classes': 12};
    }
  }

  Widget _buildProfileBody(BuildContext context, AsyncSnapshot<Map<String, String>?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
    }
    final data = snapshot.data;
    if (data == null) return const Center(child: Text("User not found"));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileCard(context, data),
          const SizedBox(height: 20),
          _buildSummaryCards(context),
          const SizedBox(height: 24),
          _buildManageUsersTile(context),
          const SizedBox(height: 12),
          _buildResetPasswordTile(context),
          const SizedBox(height: 20),
          _buildLogoutButton(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Map<String, String> data) {
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
                      backgroundColor: kPrimaryBlue.withOpacity(0.08),
                      backgroundImage: const AssetImage('assets/images/profile.jpg'),
                      child: const Icon(Icons.person, size: 40, color: kPrimaryBlue),
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
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 20, color: kPrimaryBlue),
                      const SizedBox(width: 8),
                      Text("Edit Profile", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kPrimaryBlue)),
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
      future: _statsFuture ?? Future.value({'students': 0, 'teachers': 0, 'classes': 12}),
      builder: (context, snap) {
        final stats = snap.data ?? {'students': 0, 'teachers': 0, 'classes': 12};
        return Row(
          children: [
            Expanded(child: _SummaryCard(label: "STUDENTS", value: "${stats['students'] ?? 0}", growth: "+12%", icon: Icons.people_alt_rounded, color: kPrimaryBlue)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(label: "TEACHERS", value: "${stats['teachers'] ?? 0}", growth: "+2%", icon: Icons.school_rounded, color: kPrimaryGreen)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(label: "CLASSES", value: "${stats['classes'] ?? 0}", growth: "+8%", icon: Icons.class_rounded, color: kPrimaryBlue)),
          ],
        );
      },
    );
  }

  Widget _buildManageUsersTile(BuildContext context) {
    return _ProfileActionTile(
      icon: Icons.people_rounded,
      label: "Manage Users",
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
      ),
    );
  }

  Widget _buildResetPasswordTile(BuildContext context) {
    return _ProfileActionTile(
      icon: Icons.lock_reset_rounded,
      label: "Reset Password",
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
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
              Text("Logout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.redAccent)),
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
      return Container(color: kBgColor, child: futureBody);
    }
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text(
          "My Profile",
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
  final String growth;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.growth, required this.icon, required this.color});

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
          const SizedBox(height: 2),
          Text(growth, style: const TextStyle(fontSize: 11, color: kPrimaryGreen, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

