import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/teacher_service.dart';

// ---------- COLOR PALETTE (same as other teacher screens) ----------
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE6F0FF);
const Color kSoftGreen = Color(0xFFEDF7EB);
const Color kDarkBlue = Color(0xFF01255C);
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF636E72);
const Color kErrorColor = Color(0xFFEF4444);
const Color kSoftOrange = Color(0xFFF59E0B);

// =======================
//  TEACHER PROFILE SCREEN — data from AuthProvider + GET /api/teacher/assignments
// =======================

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({Key? key}) : super(key: key);

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  List<TeacherAssignmentModel> _assignments = [];
  bool _assignmentsLoading = true;
  String? _assignmentsError;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _assignmentsLoading = true;
      _assignmentsError = null;
    });
    final result = await TeacherService().listAssignments();
    if (!mounted) return;
    setState(() {
      _assignmentsLoading = false;
      if (result is TeacherSuccess<List<TeacherAssignmentModel>>) {
        _assignments = result.data;
        _assignmentsError = null;
      } else {
        _assignments = [];
        _assignmentsError = (result is TeacherError) ? (result as TeacherError).message : 'Could not load assignments.';
      }
    });
  }

  /// Unique class names from assignments. Never show "class 0"; use Unassigned.
  List<String> get _assignedClassNames {
    final seen = <int>{};
    final names = <String>[];
    for (final a in _assignments) {
      if (seen.add(a.classId)) {
        names.add(a.classDisplayName);
      }
    }
    return names;
  }

  /// Unique subject names from assignments.
  List<String> get _assignedSubjectNames {
    final seen = <int>{};
    final names = <String>[];
    for (final a in _assignments) {
      if (seen.add(a.subjectId)) {
        names.add(a.subjectName.isEmpty ? '—' : a.subjectName);
      }
    }
    return names;
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue)),
          content: const Text('Are you sure you want to logout?', style: TextStyle(color: kTextSecondary)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: kTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
                );
                try {
                  await context.read<AuthProvider>().logout();
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e'), backgroundColor: kErrorColor, behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kErrorColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    final auth = context.read<AuthProvider>();
    await auth.refreshMe();
    if (mounted) await _loadAssignments();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final prof = auth.teacherProfile;
    final name = prof?.fullName?.isNotEmpty == true ? prof!.fullName! : (user?.name ?? '—');
    final email = prof?.email?.isNotEmpty == true ? prof!.email! : (user?.email ?? user?.emisNumber ?? '—');
    final role = user != null ? user.role.replaceAll('_', ' ') : 'Teacher';
    final employeeId = user != null ? 'ID ${user.id}' : '—';

    return Scaffold(
      backgroundColor: kSoftBlue,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: kPrimaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: kPrimaryBlue,
            leading: Container(
              margin: const EdgeInsets.only(left: 12, top: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(10),
              ),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                  stops: const [0.3, 0.7, 1.0],
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(bottom: 20),
                centerTitle: true,
                title: const Text("My Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (auth.profileError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kErrorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kErrorColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: kErrorColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(auth.profileError!, style: const TextStyle(fontSize: 13, color: kTextPrimary))),
                        ],
                      ),
                    ),
                  ),
                _ProfileHeader(name: name, role: role, employeeId: employeeId),
                const SizedBox(height: 20),
                _InfoSectionCard(
                  title: "Basic Information",
                  icon: Icons.person_outline_rounded,
                  gradientColors: [kPrimaryBlue, kPrimaryGreen],
                  children: [
                    _ProfileInfoRow(icon: Icons.email_outlined, label: "Email", value: email, color: kPrimaryBlue),
                    if (prof?.phone != null && prof!.phone!.isNotEmpty)
                      _ProfileInfoRow(icon: Icons.phone_outlined, label: "Phone", value: prof.phone!, color: kPrimaryGreen),
                    if (prof?.gender != null && prof!.gender!.isNotEmpty)
                      _ProfileInfoRow(icon: Icons.person_outline, label: "Gender", value: prof.gender!, color: kSoftOrange),
                    if (prof?.address != null && prof!.address!.isNotEmpty)
                      _ProfileInfoRow(icon: Icons.location_on_outlined, label: "Address", value: prof.address!, color: kDarkBlue),
                    if (prof?.motherName != null && prof!.motherName!.isNotEmpty)
                      _ProfileInfoRow(icon: Icons.family_restroom_outlined, label: "Mother's name", value: prof.motherName!, color: kPrimaryBlue),
                    if (prof?.graduatedUniversity != null && prof!.graduatedUniversity!.isNotEmpty)
                      _ProfileInfoRow(icon: Icons.school_outlined, label: "University", value: prof.graduatedUniversity!, color: kPrimaryGreen),
                    if (prof?.schoolId != null && prof!.schoolId! > 0)
                      _ProfileInfoRow(icon: Icons.business_outlined, label: "School ID", value: '${prof.schoolId}', color: kSoftOrange),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoSectionCard(
                  title: "Professional Details",
                  icon: Icons.work_outline_rounded,
                  gradientColors: [kPrimaryGreen, kPrimaryBlue],
                  children: [
                    if (_assignmentsLoading)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kPrimaryBlue))))
                    else if (_assignmentsError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, size: 20, color: kErrorColor),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_assignmentsError!, style: const TextStyle(fontSize: 13, color: kTextSecondary))),
                          ],
                        ),
                      )
                    else ...[
                      _ProfileInfoWrapRow(icon: Icons.book_outlined, label: "Subjects", items: _assignedSubjectNames, color: kPrimaryBlue),
                      _ProfileInfoWrapRow(icon: Icons.class_outlined, label: "Classes", items: _assignedClassNames, color: kPrimaryGreen),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _LogoutCard(onLogout: () => _logout(context)),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String role;
  final String employeeId;

  const _ProfileHeader({required this.name, required this.role, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    final initials = name != '—' && name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'T';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [kPrimaryBlue, kPrimaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(
                  child: Text(initials, style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 36)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kPrimaryBlue, kPrimaryGreen], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(role, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: kSoftBlue, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.badge_rounded, size: 12, color: kPrimaryBlue),
                const SizedBox(width: 4),
                Text(employeeId, style: TextStyle(color: kPrimaryBlue, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final List<Widget> children;

  const _InfoSectionCard({required this.title, required this.icon, required this.gradientColors, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: gradientColors.first.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileInfoRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: kTextSecondary, fontSize: 13)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(value, style: TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoWrapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> items;
  final Color color;

  const _ProfileInfoWrapRow({required this.icon, required this.label, required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    final displayItems = items.isEmpty ? ['—'] : items;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: kTextSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: displayItems
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(item, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutCard({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kErrorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.logout_rounded, color: kErrorColor, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text("Logout", style: TextStyle(color: kErrorColor, fontWeight: FontWeight.w600, fontSize: 15))),
              Icon(Icons.arrow_forward_ios_rounded, color: kTextSecondary.withOpacity(0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
