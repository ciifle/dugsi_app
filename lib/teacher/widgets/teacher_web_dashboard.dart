import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/school_admin/widgets/quick_action_card.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/teacher_service.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kPrimaryGreen = Color(0xFF5AB04B);
const Color _kSoftBlue = Color(0xFFE6F0FF);
const Color _kSoftGreen = Color(0xFFEDF7EB);
const Color _kTextPrimary = Color(0xFF2D3436);
const Color _kTextSecondary = Color(0xFF636E72);
const Color _kSoftOrange = Color(0xFFF59E0B);

class TeacherWebDashboard extends StatefulWidget {
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const TeacherWebDashboard({super.key, this.onNavigateToPage});

  @override
  State<TeacherWebDashboard> createState() => _TeacherWebDashboardState();
}

class _TeacherWebDashboardState extends State<TeacherWebDashboard> {
  TeacherDashboardModel? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await TeacherService().getDashboard();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is TeacherSuccess<TeacherDashboardModel>) {
        _dashboard = result.data;
        _error = null;
      } else {
        _dashboard = null;
        _error = (result as TeacherError).message;
      }
    });
  }

  int get _uniqueClassesCount {
    if (_dashboard == null) return 0;
    if (_dashboard!.assignedClasses.isNotEmpty) {
      return _dashboard!.assignedClasses.map((c) => c.displayName).toSet().length;
    }
    return _dashboard!.assignments.map((a) => a.classDisplayName).toSet().length;
  }

  void _navigate(String pageKey) {
    widget.onNavigateToPage?.call(pageKey);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = auth.teacherProfile?.fullName?.trim().isNotEmpty == true
        ? auth.teacherProfile!.fullName!.trim()
        : (user?.name?.trim().isNotEmpty == true ? user!.name.trim() : 'Teacher');
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'T';
    final roleLabel = user != null ? user.role.replaceAll('_', ' ') : 'Teacher';

    return Container(
      color: const Color(0xFFF0F3F7),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(name, initials, roleLabel),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _kPrimaryBlue)))
            else if (_error != null)
              _buildErrorCard()
            else ...[
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildQuickActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHero(String name, String initials, String roleLabel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimaryBlue, _kPrimaryBlue, _kPrimaryGreen],
          stops: [0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPrimaryBlue.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back! 👋',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Text(
              initials.isEmpty ? 'T' : initials,
              style: const TextStyle(color: _kPrimaryBlue, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Column(
        children: [
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _kTextPrimary)),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadDashboard, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final cards = [
      _TeacherStatCard(
        icon: Icons.class_rounded,
        label: 'Total Classes',
        value: '$_uniqueClassesCount',
        color: _kPrimaryBlue,
        onTap: () => _navigate('classes'),
      ),
      _TeacherStatCard(
        icon: Icons.assignment_rounded,
        label: 'Assignments',
        value: '${_dashboard?.assignments.length ?? 0}',
        color: _kPrimaryGreen,
        onTap: () => _navigate('assignments'),
      ),
      _TeacherStatCard(
        icon: Icons.people_rounded,
        label: 'Assigned Classes',
        value: '${_dashboard?.assignedClasses.length ?? 0}',
        color: _kSoftOrange,
        onTap: () => _navigate('classes'),
      ),
      _TeacherStatCard(
        icon: Icons.calendar_month_rounded,
        label: 'Timetable',
        value: '${_dashboard?.timetables.length ?? 0}',
        color: _kPrimaryBlue,
        onTap: () => _navigate('timetable'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 980 ? 4 : width >= 650 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 172,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      QuickActionCard(
        icon: Icons.class_rounded,
        iconColor: _kPrimaryBlue,
        title: 'My Classes',
        description: 'View assigned classes',
        onTap: () => _navigate('classes'),
      ),
      QuickActionCard(
        icon: Icons.assignment_rounded,
        iconColor: _kPrimaryGreen,
        title: 'Assignments',
        description: 'View teaching assignments',
        onTap: () => _navigate('assignments'),
      ),
      QuickActionCard(
        icon: Icons.how_to_reg_rounded,
        iconColor: _kPrimaryBlue,
        title: 'Attendance',
        description: 'Take attendance',
        onTap: () => _navigate('attendance'),
      ),
      QuickActionCard(
        icon: Icons.schedule_rounded,
        iconColor: _kPrimaryGreen,
        title: 'Timetable',
        description: 'View weekly schedule',
        onTap: () => _navigate('timetable'),
      ),
      QuickActionCard(
        icon: Icons.grade_rounded,
        iconColor: _kSoftOrange,
        title: 'Marks',
        description: 'Enter or view marks',
        onTap: () => _navigate('marks'),
      ),
      QuickActionCard(
        icon: Icons.person_rounded,
        iconColor: _kPrimaryBlue,
        title: 'Profile',
        description: 'Teacher profile',
        onTap: () => _navigate('profile'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kPrimaryBlue),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cols = width >= 1100 ? 5 : width >= 850 ? 4 : width >= 600 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 84,
              ),
              itemBuilder: (context, index) => actions[index],
            );
          },
        ),
      ],
    );
  }
}

class _TeacherStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _TeacherStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kPrimaryBlue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: _kTextSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
