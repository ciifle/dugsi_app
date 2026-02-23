import 'package:flutter/material.dart';
import 'package:kobac/services/local_auth_service.dart';
import 'package:kobac/services/dummy_school_service.dart';

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

  @override
  void initState() {
    super.initState();
    _adminDataFuture = _loadAdminData();
    _statsFuture = _loadStats();
  }

  Future<Map<String, String>?> _loadAdminData() async {
    final user = await LocalAuthService().getCurrentUser();
    if (user == null) return null;

    String schoolName = '';
    if (user.schoolId != null) {
      try {
        final school = await DummySchoolService().getSchoolById(user.schoolId!);
        if (school != null) schoolName = school.name ?? '';
      } catch (e) {
        debugPrint('Error loading school: $e');
      }
    }

    return {
      'name': user.name ?? 'Admin',
      'role': user.role.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
      'email': user.email ?? user.emisNumber ?? '',
      'phone': user.phone ?? '',
      'school': schoolName,
      'username': (user.name ?? 'admin').replaceAll(' ', '_').toLowerCase(),
    };
  }

  Future<Map<String, int>> _loadStats() async {
    try {
      final students = await DummySchoolService().getStudentCount();
      final teachers = await DummySchoolService().getTeacherCount();
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
          _buildSectionTitle("Personal Info"),
          const SizedBox(height: 12),
          _buildPersonalInfoList(data),
          const SizedBox(height: 24),
          _buildSectionTitle("Quick Actions"),
          const SizedBox(height: 12),
          _buildQuickActions(context),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kPrimaryBlue),
    );
  }

  Widget _buildPersonalInfoList(Map<String, String> data) {
    final items = [
      _PersonalInfoItem(icon: Icons.person_outline_rounded, label: data['username'] ?? 'username'),
      _PersonalInfoItem(icon: Icons.phone_outlined, label: data['phone']!.isEmpty ? '—' : data['phone']!),
      _PersonalInfoItem(icon: Icons.school_outlined, label: data['school']!.isEmpty ? '—' : data['school']!),
    ];
    return Column(
      children: items.map((e) => _PersonalInfoTile(icon: e.icon, value: e.label)).toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.people_rounded,
            label: "Manage Users",
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.lock_reset_rounded,
            label: "Reset Password",
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await LocalAuthService().logout();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
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
      body: futureBody,
    );
  }
}

class _PersonalInfoItem {
  final IconData icon;
  final String label;
  _PersonalInfoItem({required this.icon, required this.label});
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

class _PersonalInfoTile extends StatelessWidget {
  final IconData icon;
  final String value;

  const _PersonalInfoTile({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kPrimaryBlue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
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
              Icon(icon, color: kPrimaryBlue, size: 28),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryBlue),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
