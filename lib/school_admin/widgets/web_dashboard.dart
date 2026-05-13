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
import 'package:kobac/school_admin/pages/mesaage_screen.dart';
import 'package:kobac/school_admin/pages/admin_class_subjects_screen.dart';
import 'package:kobac/school_admin/pages/admin_assignments_screen.dart';
import 'package:kobac/school_admin/pages/admin_timetable_screen.dart';
import 'package:kobac/school_admin/pages/admin_exams_screen.dart';
import 'package:kobac/school_admin/pages/admin_marks_screen.dart';
import 'package:kobac/school_admin/pages/admin_notices_screen.dart';
import 'package:kobac/school_admin/pages/settings_page.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;

    if (user != null && user.userRole == UserRole.schoolAdmin) {
      setState(() {
        _userName = user.name;
        _loading = false;
      });

      // Load counts in parallel
      final futures = await Future.wait([
        StudentsService().listStudents(),
        TeachersService().listTeachers(),
        SubjectsService().listSubjects(),
        ClassesService().listClasses(),
      ]);

      if (!mounted) return;

      setState(() {
        if (futures[0] is StudentSuccess<List<StudentModel>>) {
          _studentCount = (futures[0] as StudentSuccess<List<StudentModel>>).data.length;
        }
        if (futures[1] is TeacherSuccess<List<TeacherModel>>) {
          _teacherCount = (futures[1] as TeacherSuccess<List<TeacherModel>>).data.length;
        }
        if (futures[2] is SubjectSuccess<List<SubjectModel>>) {
          _subjectCount = (futures[2] as SubjectSuccess<List<SubjectModel>>).data.length;
        }
        if (futures[3] is ClassSuccess<List<ClassModel>>) {
          _classCount = (futures[3] as ClassSuccess<List<ClassModel>>).data.length;
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
          // Stat Cards Grid
          _buildStatCardsGrid(),
          const SizedBox(height: 24),

          // Quick Actions Section
          _buildQuickActionsSection(),
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
        iconColor: const Color(0xFF8B5CF6),
        label: 'Attendance',
        value: _loading ? '...' : '92%',
        growth: '+5%',
        onTap: () => _navigateToPage('attendance', const AdminAttendanceScreen()),
      ),
      DashboardStatCard(
        icon: Icons.class_rounded,
        iconColor: const Color(0xFFF59E0B),
        label: 'Classes',
        value: _loading ? '...' : '${_classCount ?? 0}',
        growth: '+3%',
        onTap: () => _navigateToPage('classes', const AdminClassesPage()),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 980 ? 4 : width >= 650 ? 2 : 1;

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
            final crossAxisCount =
                width >= 1100 ? 5 : width >= 850 ? 4 : width >= 600 ? 2 : 1;

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
          iconColor: const Color(0xFFF59E0B),
          title: 'Add Class',
          description: 'Create a new class',
          onTap: () => _navigateToPage('addClass', const AddClassScreen()),
        ),
        QuickActionCard(
          icon: Icons.book_rounded,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Add Subject',
          description: 'Add a new subject',
          onTap: () => _navigateToPage('addSubject', const AddSubjectScreen()),
        ),
        QuickActionCard(
          icon: Icons.calendar_today_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Attendance',
          description: 'Track attendance',
          onTap: () => _navigateToPage('attendance', const AdminAttendanceScreen()),
        ),
        QuickActionCard(
          icon: Icons.attach_money_rounded,
          iconColor: const Color(0xFFEF4444),
          title: 'Fees',
          description: 'Manage fees',
          onTap: () => _navigateToPage('fees', const AdminFeesScreen()),
        ),
        QuickActionCard(
          icon: Icons.message_rounded,
          iconColor: const Color(0xFF06B6D4),
          title: 'Messages',
          description: 'Send messages',
          onTap: () => _navigateToPage('messages', const MessageScreen(embedInParent: false)),
        ),
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
          iconColor: const Color(0xFFF59E0B),
          title: 'Marks',
          description: 'Manage marks',
          onTap: () => _navigateToPage('marks', const AdminMarksScreen()),
        ),
        QuickActionCard(
          icon: Icons.campaign_rounded,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Notices',
          description: 'Post notices',
          onTap: () => _navigateToPage('notices', const AdminNoticesScreen()),
        ),
      ];

  String _formatCount(int n) {
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}k";
    return "$n";
  }
}
