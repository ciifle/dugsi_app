import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:kobac/models/dummy_user.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/school_admin/widgets/dashboard_stat_card.dart';
import 'package:kobac/school_admin/widgets/quick_action_card.dart';
import 'package:kobac/school_admin/pages/admin_students.dart';
import 'package:kobac/school_admin/pages/teachers_screen.dart';
import 'package:kobac/school_admin/pages/admin_subjects_screen.dart';
import 'package:kobac/school_admin/pages/admin_classes.dart';
import 'package:kobac/school_admin/pages/create_student_screen.dart';
import 'package:kobac/school_admin/pages/create_teacher_screen.dart';
import 'package:kobac/school_admin/pages/admin_attendance_screen.dart';
import 'package:kobac/school_admin/pages/admin_fees_screen.dart';
import 'package:kobac/school_admin/pages/admin_class_subjects_screen.dart';
import 'package:kobac/school_admin/pages/admin_assignments_screen.dart';
import 'package:kobac/school_admin/pages/admin_timetable_screen.dart';
import 'package:kobac/school_admin/pages/admin_exams_screen.dart';
import 'package:kobac/school_admin/pages/admin_marks_screen.dart';
import 'package:kobac/school_admin/pages/admin_notices_screen.dart';
import 'package:kobac/school_admin/pages/settings_page.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/school_admin/pages/academic_years_page.dart';
import 'package:intl/intl.dart';
import 'package:kobac/school_admin/pages/rankings_pages.dart';
import 'package:kobac/school_admin/widgets/dashboard_analytics.dart';
import 'package:kobac/school_admin/pages/student_promotions_page.dart';

/// Desktop dashboard with stat cards and quick actions
class WebDashboard extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const WebDashboard({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard> {
  int? _studentCount;
  int? _teacherCount;
  int? _subjectCount;
  int? _classCount;
  bool _loading = true;
  String _userName = "School Admin";
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicYearsProvider>().ensureLoaded();
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;

    if (user != null && user.userRole == UserRole.schoolAdmin) {
      setState(() {
        _userName = user.name;
      });

      // Load counts in parallel
      final futures = await Future.wait([
        StudentsService().listStudentPage(),
        TeachersService().listTeachers(),
        SubjectsService().listSubjects(),
        ClassesService().listClasses(),
      ]);

      if (!mounted) return;

      setState(() {
        if (futures[0] is StudentSuccess<StudentPage>) {
          _studentCount =
              (futures[0] as StudentSuccess<StudentPage>).data.total;
        }
        if (futures[1] is TeacherSuccess<List<TeacherModel>>) {
          _teacherCount =
              (futures[1] as TeacherSuccess<List<TeacherModel>>).data.length;
        }
        if (futures[2] is SubjectSuccess<List<SubjectModel>>) {
          _subjectCount =
              (futures[2] as SubjectSuccess<List<SubjectModel>>).data.length;
        }
        if (futures[3] is ClassSuccess<List<ClassModel>>) {
          _classCount =
              (futures[3] as ClassSuccess<List<ClassModel>>).data.length;
        }
        _loading = false;
      });
    }
  }

  void _navigateToPage(String pageKey, Widget fallbackPage) {
    final isDesktop = isDesktopWebAdminLayout(context);
    if (isDesktop && widget.onNavigateToPage != null) {
      widget.onNavigateToPage!(pageKey);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => fallbackPage));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _activeYearCard(),
          const SizedBox(height: 24),
          // Stat Cards Grid
          _buildStatCardsGrid(),
          const SizedBox(height: 24),

          const DashboardAnalyticsSection(),
          const SizedBox(height: 24),

          // Quick Actions Section
          _buildQuickActionsSection(),
          const SizedBox(height: 24),
          const DashboardUpdatesSection(),
        ],
      ),
    );
  }

  Widget _activeYearCard() {
    final provider = context.watch<AcademicYearsProvider>();
    final year = provider.activeYear;
    final dates = year?.startDate != null && year?.endDate != null
        ? '${DateFormat('dd MMM yyyy').format(year!.startDate!)} — ${DateFormat('dd MMM yyyy').format(year.endDate!)}'
        : 'Dates unavailable';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF084AA5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF023471).withValues(alpha: .2),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 12),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF084AA5),
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: provider.loading
                ? const LinearProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Academic Year',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDCEAFF),
                        ),
                      ),
                      Text(
                        year?.name ?? 'No active academic year',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (year != null)
                        Text(
                          dates,
                          style: const TextStyle(color: Color(0xFFDCEAFF)),
                        ),
                      const SizedBox(height: 5),
                      const Text(
                        'Current term  •  Term information unavailable',
                        style: TextStyle(
                          color: Color(0xFFBFD8FA),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Icon(
              Icons.auto_stories_rounded,
              size: 66,
              color: Color(0x66FFFFFF),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                _navigateToPage('academicYears', const AcademicYearsPage()),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF084AA5),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Manage Year'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardsGrid() {
    final statCards = [
      DashboardStatCard(
        icon: Icons.people_alt_rounded,
        iconColor: const Color(0xFF023471),
        label: 'Students',
        value: _loading ? '...' : _formatCount(_studentCount ?? 0),
        growth: '+12%',
        onTap: () => _navigateToPage('students', const AdminStudentsScreen()),
      ),
      DashboardStatCard(
        icon: Icons.school_rounded,
        iconColor: const Color(0xFF5AB04B),
        label: 'Teachers',
        value: _loading ? '...' : '${_teacherCount ?? 0}',
        growth: '+2%',
        onTap: () => _navigateToPage('teachers', const TeacherListScreen()),
      ),
      DashboardStatCard(
        icon: Icons.event_note_rounded,
        iconColor: const Color(0xFF2E7CC9),
        label: 'Attendance',
        value: _loading ? '...' : '92%',
        growth: '+5%',
        onTap: () =>
            _navigateToPage('attendance', const AdminAttendanceScreen()),
      ),
      DashboardStatCard(
        icon: Icons.class_rounded,
        iconColor: const Color(0xFF43983C),
        label: 'Classes',
        value: _loading ? '...' : '${_classCount ?? 0}',
        growth: '+3%',
        onTap: () => _navigateToPage('classes', const AdminClassesPage()),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 980
            ? 4
            : width >= 650
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statCards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 172,
          ),
          itemBuilder: (context, index) => statCards[index],
        );
      },
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF023471),
              ),
            ),
            TextButton(
              onPressed: () {
                // Customize functionality - could open a settings page
              },
              child: const Text(
                'Customize',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5AB04B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width >= 1100
                ? 5
                : width >= 850
                ? 4
                : width >= 600
                ? 2
                : 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quickActions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 84,
              ),
              itemBuilder: (context, index) => _quickActions[index],
            );
          },
        ),
      ],
    );
  }

  List<QuickActionCard> get _quickActions => [
    QuickActionCard(
      icon: Icons.person_add_rounded,
      iconColor: const Color(0xFF023471),
      title: 'Add Student',
      description: 'Register a new student',
      onTap: () => _navigateToPage('addStudent', const CreateStudentScreen()),
    ),
    QuickActionCard(
      icon: Icons.school_rounded,
      iconColor: const Color(0xFF5AB04B),
      title: 'Add Teacher',
      description: 'Register a new teacher',
      onTap: () => _navigateToPage('addTeacher', const CreateTeacherScreen()),
    ),
    QuickActionCard(
      icon: Icons.class_rounded,
      iconColor: const Color(0xFF2E7CC9),
      title: 'Add Class',
      description: 'Create a new class',
      onTap: () => _navigateToPage('addClass', const AddClassScreen()),
    ),
    QuickActionCard(
      icon: Icons.book_rounded,
      iconColor: const Color(0xFF5AB04B),
      title: 'Add Subject',
      description: 'Add a new subject',
      onTap: () => _navigateToPage('addSubject', const AddSubjectScreen()),
    ),
    QuickActionCard(
      icon: Icons.calendar_today_rounded,
      iconColor: const Color(0xFF5AB04B),
      title: 'Attendance',
      description: 'Track attendance',
      onTap: () => _navigateToPage('attendance', const AdminAttendanceScreen()),
    ),
    QuickActionCard(
      icon: Icons.attach_money_rounded,
      iconColor: const Color(0xFF2E7CC9),
      title: 'Fees',
      description: 'Manage fees',
      onTap: () => _navigateToPage('fees', const AdminFeesScreen()),
    ),
    // Messaging temporarily disabled from active UI/navigation.
    QuickActionCard(
      icon: Icons.schedule_rounded,
      iconColor: const Color(0xFF023471),
      title: 'Timetable',
      description: 'View timetable',
      onTap: () => _navigateToPage('timetable', const AdminTimetableScreen()),
    ),
    QuickActionCard(
      icon: Icons.quiz_rounded,
      iconColor: const Color(0xFF5AB04B),
      title: 'Exams',
      description: 'Manage exams',
      onTap: () => _navigateToPage('exams', const AdminExamsScreen()),
    ),
    QuickActionCard(
      icon: Icons.grade_rounded,
      iconColor: const Color(0xFF2E7CC9),
      title: 'Marks',
      description: 'Manage marks',
      onTap: () => _navigateToPage('marks', const AdminMarksScreen()),
    ),
    QuickActionCard(
      icon: Icons.emoji_events_rounded,
      iconColor: const Color(0xFF023471),
      title: 'Top Students',
      description: 'View the highest-performing students',
      onTap: () => _navigateToPage('topStudents', const TopStudentsPage()),
    ),
    QuickActionCard(
      icon: Icons.campaign_rounded,
      iconColor: const Color(0xFF5AB04B),
      title: 'Notices',
      description: 'Post notices',
      onTap: () => _navigateToPage('notices', const AdminNoticesScreen()),
    ),
    QuickActionCard(
      icon: Icons.calendar_month_rounded,
      iconColor: const Color(0xFF023471),
      title: 'Academic Years',
      description: 'Manage academic years',
      onTap: () => _navigateToPage('academicYears', const AcademicYearsPage()),
    ),
    QuickActionCard(
      icon: Icons.trending_up_rounded,
      iconColor: const Color(0xFF5AB04B),
      title: 'Promotions',
      description: 'Promote students',
      onTap: () => _navigateToPage('promotions', const StudentPromotionsPage()),
    ),
    QuickActionCard(
      icon: Icons.analytics_rounded,
      iconColor: const Color(0xFF2E7CC9),
      title: 'Reports',
      description: 'View performance reports',
      onTap: () => _navigateToPage('topStudents', const TopStudentsPage()),
    ),
    QuickActionCard(
      icon: Icons.settings_rounded,
      iconColor: const Color(0xFF023471),
      title: 'Settings',
      description: 'System settings',
      onTap: () => _navigateToPage('settings', SettingsPage()),
    ),
  ];

  String _formatCount(int n) {
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}k";
    return "$n";
  }
}
