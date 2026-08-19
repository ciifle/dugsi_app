import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/school_admin/widgets/quick_action_card.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/teacher_service.dart';
import 'package:kobac/teacher/widgets/teacher_web_ui.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kPrimaryGreen = Color(0xFF5AB04B);
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
      return _dashboard!.assignedClasses
          .map((c) => c.displayName)
          .toSet()
          .length;
    }
    return _dashboard!.assignments
        .map((a) => a.classDisplayName)
        .toSet()
        .length;
  }

  /// One row per unique class, joining subject names taught in that class
  /// from the same assignments list already loaded for the dashboard — no
  /// extra API calls, no invented fields (there is no student-count field on
  /// the class model, so that column is intentionally omitted).
  List<({String name, String subjects})> get _classOverviewRows {
    if (_dashboard == null) return const [];
    final names = <String>[];
    if (_dashboard!.assignedClasses.isNotEmpty) {
      for (final c in _dashboard!.assignedClasses) {
        if (!names.contains(c.displayName)) names.add(c.displayName);
      }
    } else {
      for (final a in _dashboard!.assignments) {
        if (!names.contains(a.classDisplayName)) names.add(a.classDisplayName);
      }
    }
    return names.map((name) {
      final subjects = _dashboard!.assignments
          .where((a) => a.classDisplayName == name)
          .map((a) => a.subjectName)
          .where((s) => s.isNotEmpty)
          .toSet()
          .join(', ');
      return (name: name, subjects: subjects.isEmpty ? '—' : subjects);
    }).toList();
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
        : (user?.name?.trim().isNotEmpty == true
              ? user!.name.trim()
              : 'Teacher');
    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'T';

    return Container(
      color: teacherWebBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(name, initials),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: _kPrimaryBlue),
                ),
              )
            else if (_error != null)
              TeacherWebCard(
                child: TeacherErrorState(
                  message: _error!,
                  onRetry: _loadDashboard,
                ),
              )
            else ...[
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildClassesOverview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String initials) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _kPrimaryBlue,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Welcome back! Here's what's happening today.",
                style: TextStyle(
                  fontSize: 13.5,
                  color: teacherWebTextSecondary,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: _kPrimaryBlue.withValues(alpha: 0.08),
          child: Text(
            initials.isEmpty ? 'T' : initials,
            style: const TextStyle(
              color: _kPrimaryBlue,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final cards = [
      TeacherStatCard(
        icon: Icons.class_rounded,
        label: 'Total Classes',
        value: '$_uniqueClassesCount',
        color: _kPrimaryBlue,
        onTap: () => _navigate('classes'),
      ),
      TeacherStatCard(
        icon: Icons.assignment_rounded,
        label: 'Assignments',
        value: '${_dashboard?.assignments.length ?? 0}',
        color: _kPrimaryGreen,
        onTap: () => _navigate('assignments'),
      ),
      TeacherStatCard(
        icon: Icons.people_rounded,
        label: 'Assigned Classes',
        value: '${_dashboard?.assignedClasses.length ?? 0}',
        color: _kSoftOrange,
        onTap: () => _navigate('classes'),
      ),
      TeacherStatCard(
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
        final cols = width >= 980
            ? 4
            : width >= 650
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 150,
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
        description: 'Mark or view attendance',
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _kPrimaryBlue,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cols = width >= 1100
                ? 5
                : width >= 850
                ? 4
                : width >= 600
                ? 2
                : 1;
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

  Widget _buildClassesOverview() {
    final rows = _classOverviewRows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Classes Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _kPrimaryBlue,
          ),
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          const TeacherWebCard(
            child: TeacherEmptyState(
              icon: Icons.class_outlined,
              title: 'No assigned classes',
              message: 'Classes you are assigned to teach will appear here.',
            ),
          )
        else
          TeacherWebCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const TeacherWebTableHeader(
                  columns: ['Class', 'Subject(s)', ''],
                ),
                for (final row in rows)
                  TeacherWebTableRow(
                    onTap: () => _navigate('classes'),
                    cells: [
                      Text(
                        row.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _kPrimaryBlue,
                        ),
                      ),
                      Text(
                        row.subjects,
                        style: const TextStyle(color: teacherWebTextSecondary),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _navigate('classes'),
                          child: const Text('View Students'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
