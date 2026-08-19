import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/school_admin/widgets/quick_action_card.dart';
import 'package:kobac/teacher/widgets/teacher_mobile_ui.dart';
import 'package:kobac/teacher/widgets/teacher_web_shell.dart';
import 'package:kobac/teacher/widgets/teacher_web_ui.dart';
import 'package:kobac/teacher/pages/assignments_screen.dart';
import 'package:kobac/teacher/pages/attendance_mark.dart';
import 'package:kobac/teacher/pages/teacher_classes_screen.dart';
import 'package:kobac/teacher/pages/teacher_marks_screen.dart';
import 'package:kobac/teacher/pages/teacher_profile.dart';
import 'package:kobac/teacher/pages/teacher_drawer.dart';
import 'package:kobac/teacher/pages/teacher_students_list_screen.dart';
import 'package:kobac/teacher/pages/weakly_schedule.dart';
import 'package:kobac/services/teacher_service.dart';

// =======================
//  TEACHER DASHBOARD — real data from GET /api/teacher/dashboard.
// =======================
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE6F0FF);
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF636E72);
const Color kErrorColor = Color(0xFFEF4444);
const Color kSoftOrange = Color(0xFFF59E0B);

/// Root Teacher entry point: PWA gets the persistent sidebar+header shell,
/// mobile gets a bottom-nav shell (Dashboard / My Classes / Assignments /
/// Profile) — mirrors the pattern already shipped for Student
/// (lib/student/pages/student_dashboard.dart), since Teacher previously had
/// no bottom navigation to preserve.
class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isDesktopWebAdminLayout(context)) {
      return const TeacherWebShell();
    }
    return const _TeacherMobileShell();
  }
}

/// Every Teacher mobile "root" destination — reachable from the bottom
/// navbar, the drawer, and/or Dashboard Quick Actions — rendered inside the
/// ONE persistent [_TeacherMobileShell] (single Scaffold, single bottom
/// navbar, single drawer). Only true detail/sub-pages (class student list,
/// assignment detail, Change Password) are still pushed as separate routes.
enum _TeacherRootPage {
  dashboard(
    tabIndex: 0,
    title: 'Dashboard',
    subtitle: "Welcome back! Here's what's happening today.",
    drawerLabel: 'Dashboard',
  ),
  classes(
    tabIndex: 1,
    title: 'My Classes',
    subtitle: 'Classes assigned to you',
    drawerLabel: 'Classes',
  ),
  assignments(
    tabIndex: 2,
    title: 'Assignments',
    subtitle: 'Your teaching assignments',
    drawerLabel: 'My Assignments',
  ),
  profile(
    tabIndex: 3,
    title: 'Profile',
    subtitle: 'Your account & settings',
    drawerLabel: 'Profile',
  ),
  // Reachable from the drawer/Quick Actions only — not a bottom-nav tab.
  myStudents(
    tabIndex: null,
    title: 'My Students',
    subtitle: 'Students in your assigned classes',
    drawerLabel: 'My Students',
  ),
  attendance(
    tabIndex: null,
    title: 'Take Attendance',
    subtitle: 'Mark or review attendance',
    drawerLabel: 'Take Attendance',
  ),
  timetable(
    tabIndex: null,
    title: 'Timetable',
    subtitle: 'Your weekly schedule',
    drawerLabel: null, // not currently a drawer destination
  ),
  marks(
    tabIndex: null,
    title: 'Marks',
    subtitle: 'Enter or view marks',
    drawerLabel: 'Marks',
  );

  final int? tabIndex;
  final String title;
  final String subtitle;
  final String? drawerLabel;

  const _TeacherRootPage({
    required this.tabIndex,
    required this.title,
    required this.subtitle,
    required this.drawerLabel,
  });
}

class _TeacherMobileShell extends StatefulWidget {
  const _TeacherMobileShell();

  @override
  State<_TeacherMobileShell> createState() => _TeacherMobileShellState();
}

class _TeacherMobileShellState extends State<_TeacherMobileShell> {
  _TeacherRootPage _current = _TeacherRootPage.dashboard;
  // The last active bottom-nav tab — kept selected in the navbar while a
  // secondary root page (My Students/Attendance/Timetable/Marks) is shown,
  // since none of the four tabs actually represents those pages.
  int _lastTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _navItems = [
    (icon: Icons.dashboard_rounded, label: 'Dashboard'),
    (icon: Icons.class_rounded, label: 'My Classes'),
    (icon: Icons.assignment_rounded, label: 'Assignments'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  late final List<Widget> _tabScreens = [
    _TeacherDashboardHome(onOpenRootPage: openRootPage),
    const TeacherClassesScreen(showAppBar: false),
    const TeacherAssignmentsScreen(showAppBar: false),
    const TeacherProfileScreen(showAppBar: false),
  ];

  /// The single, shared entry point for switching the shell's active root
  /// page — used identically by the bottom navbar, the drawer, and
  /// Dashboard Quick Actions, so none of them push a standalone route for
  /// a root Teacher destination.
  void openRootPage(_TeacherRootPage page) {
    setState(() {
      _current = page;
      if (page.tabIndex != null) _lastTabIndex = page.tabIndex!;
    });
  }

  void _openDrawerRootPage(String drawerLabel) {
    final page = _TeacherRootPage.values.firstWhere(
      (p) => p.drawerLabel == drawerLabel,
      orElse: () => _TeacherRootPage.dashboard,
    );
    openRootPage(page);
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _onNavTapped(int index) {
    final page = _TeacherRootPage.values.firstWhere((p) => p.tabIndex == index);
    openRootPage(page);
  }

  Widget _buildBody() {
    if (_current.tabIndex != null) {
      return IndexedStack(index: _current.tabIndex!, children: _tabScreens);
    }
    switch (_current) {
      case _TeacherRootPage.myStudents:
        return const TeacherStudentsListScreen(showAppBar: false);
      case _TeacherRootPage.attendance:
        return const TeacherAttendanceScreen(showAppBar: false);
      case _TeacherRootPage.timetable:
        return const TeacherWeeklyScheduleScreen(showAppBar: false);
      case _TeacherRootPage.marks:
        return const TeacherMarksScreen(showAppBar: false);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: teacherWebBg,
      drawer: TeacherDrawer(
        currentLabel: _current.drawerLabel,
        onNavigateRoot: _openDrawerRootPage,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TeacherRootPageHeader(
                title: _current.title,
                subtitle: _current.subtitle,
                onMenuTap: _openDrawer,
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: teacherWebBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22023471),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            items: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final selected = index == _lastTabIndex;
              return BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected ? kPrimaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x32023471),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    item.icon,
                    color: selected ? Colors.white : kTextSecondary,
                    size: 21,
                  ),
                ),
                label: item.label,
              );
            }).toList(),
            currentIndex: _lastTabIndex,
            onTap: _onNavTapped,
            backgroundColor: Colors.white,
            selectedItemColor: kPrimaryBlue,
            unselectedItemColor: kTextSecondary.withValues(alpha: 0.7),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
          ),
        ),
      ),
    );
  }
}

/// Dashboard tab content — loads GET /api/teacher/dashboard once and derives
/// every number shown from real fields on [TeacherDashboardModel].
class _TeacherDashboardHome extends StatefulWidget {
  final ValueChanged<_TeacherRootPage> onOpenRootPage;

  const _TeacherDashboardHome({required this.onOpenRootPage});

  @override
  State<_TeacherDashboardHome> createState() => _TeacherDashboardHomeState();
}

class _TeacherDashboardHomeState extends State<_TeacherDashboardHome> {
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

  List<TeacherAssignmentModel> get _assignments =>
      _dashboard?.assignments ?? [];
  List<TeacherAssignedClassModel> get _assignedClasses =>
      _dashboard?.assignedClasses ?? [];
  List<TeacherTimetableEntryModel> get _timetables =>
      _dashboard?.timetables ?? [];

  @override
  Widget build(BuildContext context) {
    final bottomClearance = MediaQuery.of(context).padding.bottom + 32;
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: kPrimaryBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(20, 4, 20, bottomClearance),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: kPrimaryBlue),
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
            _buildStatsGrid(context),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            const Text(
              'Assigned Classes',
              style: TextStyle(
                fontSize: 17,
                color: kPrimaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildAssignedClassesSection(),
            const SizedBox(height: 20),
            const Text(
              'Assignments',
              style: TextStyle(
                fontSize: 17,
                color: kPrimaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildAssignmentsSection(),
            const SizedBox(height: 20),
            const Text(
              'Timetable',
              style: TextStyle(
                fontSize: 17,
                color: kPrimaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildTimetableSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final cards = [
      TeacherStatCard(
        icon: Icons.class_rounded,
        value: '$_uniqueClassesCount',
        label: 'Total Classes',
        color: kPrimaryBlue,
        onTap: () => widget.onOpenRootPage(_TeacherRootPage.classes),
      ),
      TeacherStatCard(
        icon: Icons.assignment_rounded,
        value: '${_assignments.length}',
        label: 'Assignments',
        color: kPrimaryGreen,
        onTap: () => widget.onOpenRootPage(_TeacherRootPage.assignments),
      ),
      TeacherStatCard(
        icon: Icons.people_rounded,
        value: '${_assignedClasses.length}',
        label: 'Assigned Classes',
        color: kSoftOrange,
        onTap: () => widget.onOpenRootPage(_TeacherRootPage.classes),
      ),
      TeacherStatCard(
        icon: Icons.calendar_month_rounded,
        value: '${_timetables.length}',
        label: 'Timetable',
        color: kPrimaryBlue,
        onTap: () => widget.onOpenRootPage(_TeacherRootPage.timetable),
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 128,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      QuickActionCard(
        icon: Icons.class_rounded,
        iconColor: kPrimaryBlue,
        title: 'My Classes',
        description: 'View classes',
        onTap: () => widget.onOpenRootPage(_TeacherRootPage.classes),
      ),
      QuickActionCard(
        icon: Icons.assignment_rounded,
        iconColor: kPrimaryGreen,
        title: 'Assignments',
        description: 'View assignments',
        onTap: () => widget.onOpenRootPage(_TeacherRootPage.assignments),
      ),
      QuickActionCard(
        icon: Icons.how_to_reg_rounded,
        iconColor: kPrimaryBlue,
        title: 'Attendance',
        description: 'Mark attendance',
        onTap: () => widget.onOpenRootPage(_TeacherRootPage.attendance),
      ),
      QuickActionCard(
        icon: Icons.schedule_rounded,
        iconColor: kPrimaryGreen,
        title: 'Timetable',
        description: 'Weekly schedule',
        onTap: () => widget.onOpenRootPage(_TeacherRootPage.timetable),
      ),
      QuickActionCard(
        icon: Icons.grade_rounded,
        iconColor: kSoftOrange,
        title: 'Marks',
        description: 'Enter marks',
        onTap: () => widget.onOpenRootPage(_TeacherRootPage.marks),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 17,
            color: kPrimaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.45,
          children: actions,
        ),
      ],
    );
  }

  Widget _buildAssignedClassesSection() {
    final classes = _assignedClasses.isNotEmpty
        ? _assignedClasses.map((c) => c.displayName).toSet().toList()
        : _assignments.map((a) => a.classDisplayName).toSet().toList();
    if (classes.isEmpty) {
      return const TeacherWebCard(
        child: TeacherEmptyState(
          icon: Icons.class_outlined,
          title: 'No classes assigned',
        ),
      );
    }
    return TeacherWebCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: classes
            .map(
              (name) => Chip(
                label: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: kSoftBlue,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAssignmentsSection() {
    if (_assignments.isEmpty) {
      return const TeacherWebCard(
        child: TeacherEmptyState(
          icon: Icons.assignment_outlined,
          title: 'No assignments yet',
        ),
      );
    }
    return TeacherWebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _assignments
            .take(8)
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.subject_rounded,
                      size: 18,
                      color: kPrimaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${a.subjectName.isEmpty ? "—" : a.subjectName} — ${a.classDisplayName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: kTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTimetableSection() {
    if (_timetables.isEmpty) {
      return const TeacherWebCard(
        child: TeacherEmptyState(
          icon: Icons.calendar_month_outlined,
          title: 'No timetable entries',
        ),
      );
    }
    return TeacherWebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _timetables.take(6).map((t) {
          final timeStr = t.period != null
              ? (t.period!.name.isNotEmpty
                    ? t.period!.name
                    : 'P${t.period!.periodNumber}')
              : t.timeRange;

          String shiftStr = '';
          if (t.period?.shift.isNotEmpty == true) {
            final s = t.period!.shift.toLowerCase();
            shiftStr =
                ' (${s == 'morning' ? 'Morning' : (s == 'afternoon' ? 'Afternoon' : s)})';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${t.day} $timeStr$shiftStr — ${t.subjectDisplayName} — ${t.classDisplayName}',
              style: const TextStyle(fontSize: 13, color: kTextPrimary),
            ),
          );
        }).toList(),
      ),
    );
  }
}
