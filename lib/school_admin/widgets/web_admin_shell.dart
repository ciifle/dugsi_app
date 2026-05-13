import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/school_admin/widgets/web_sidebar.dart';
import 'package:kobac/school_admin/widgets/web_top_bar.dart';
import 'package:kobac/school_admin/widgets/web_dashboard.dart';
import 'package:kobac/school_admin/pages/admin_students.dart';
import 'package:kobac/school_admin/pages/create_student_screen.dart';
import 'package:kobac/school_admin/pages/edit_student_screen.dart';
import 'package:kobac/school_admin/pages/student_detail_screen.dart';
import 'package:kobac/school_admin/pages/create_teacher_screen.dart';
import 'package:kobac/school_admin/pages/edit_teacher_screen.dart';
import 'package:kobac/school_admin/pages/teacher_screen.dart';
import 'package:kobac/school_admin/pages/teachers_screen.dart';
import 'package:kobac/school_admin/pages/admin_classes.dart';
import 'package:kobac/school_admin/pages/admin_class_details_screen.dart';
import 'package:kobac/school_admin/pages/admin_subjects_screen.dart';
import 'package:kobac/school_admin/pages/admin_attendance_screen.dart';
import 'package:kobac/school_admin/pages/admin_fees_screen.dart';
import 'package:kobac/services/fees_service.dart';
import 'package:kobac/school_admin/pages/mesaage_screen.dart';
import 'package:kobac/school_admin/pages/payments_screen.dart';
import 'package:kobac/school_admin/pages/class_subject_management_screen.dart';
import 'package:kobac/school_admin/pages/admin_class_subjects_screen.dart';

import 'package:kobac/school_admin/pages/admin_timetable_screen.dart';
import 'package:kobac/school_admin/pages/admin_exams_screen.dart';
import 'package:kobac/school_admin/pages/admin_marks_screen.dart';
import 'package:kobac/school_admin/pages/admin_notices_screen.dart';

import 'package:kobac/school_admin/pages/admin_profile.dart';
import 'package:kobac/school_admin/pages/notifications_page.dart';

/// Responsive admin shell for desktop/web layout
/// Shows sidebar + top bar + main content area
class WebAdminShell extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  final Function(String)? onSearch;
  final Function(String)? onNavigate;

  const WebAdminShell({
    Key? key,
    this.navigatorKey,
    this.onSearch,
    this.onNavigate,
  }) : super(key: key);

  @override
  State<WebAdminShell> createState() => _WebAdminShellState();
}

class _WebAdminShellState extends State<WebAdminShell> {
  String _selectedPage = 'dashboard';
  Object? _selectedArguments;

  void _navigateToPage(String pageKey, {Object? arguments}) {
    setState(() {
      _selectedPage = pageKey;
      _selectedArguments = arguments;
    });
  }

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().logout();
  }

  String _getTitle(String pageKey) {
    switch (pageKey) {
      case 'dashboard':
        return 'Dashboard';
      case 'students':
        return 'Students';
      case 'addStudent':
        return 'Add Student';
      case 'teachers':
        return 'Teachers';
      case 'addTeacher':
        return 'Add Teacher';
      case 'classes':
        return 'Classes';
      case 'addClass':
        return 'Add Class';
      case 'subjects':
        return 'Subjects';
      case 'addSubject':
        return 'Add Subject';
      case 'classSubjects':
        return 'Class Subjects';
      case 'attendance':
        return 'Attendance';
      case 'fees':
        return 'Fees';
      case 'payments':
        return 'Payments';
      case 'messages':
        return 'Messages';
      case 'composeMessage':
        return 'Compose Message';

      case 'timetable':
        return 'Timetable';
      case 'exams':
        return 'Exams';
      case 'marks':
        return 'Marks';
      case 'notices':
        return 'Notices';
      case 'notifications':
        return 'Notifications';
      case 'profile':
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  String? _getSubtitle(String pageKey) {
    switch (pageKey) {
      case 'dashboard':
        return "Here's what's happening in your school today.";
      case 'addStudent':
        return "Create a new student record";
      case 'addTeacher':
        return "Create a new teacher record";
      case 'addClass':
        return 'Create a new class record';
      case 'addSubject':
        return 'Create a new subject record';
      default:
        return null;
    }
  }

  Widget _buildBody() {
    switch (_selectedPage) {
      case 'dashboard':
        return WebDashboard(onNavigateToPage: _navigateToPage);
      case 'students':
        return AdminStudentsScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'addStudent':
        int? initClassId;
        if (_selectedArguments is Map) {
          initClassId = (_selectedArguments as Map)['initialClassId'] as int?;
        }
        return CreateStudentScreen(
          initialClassId: initClassId,
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'studentDetail':
        return StudentDetailPage(
          studentId: _selectedArguments as int,
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'editStudent':
        return EditStudentScreen(
          studentId: _selectedArguments as int,
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'teachers':
        return TeacherListScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'addTeacher':
        return CreateTeacherScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'teacherDetail':
        return TeacherDetailsPage(
          teacherId: _selectedArguments as int,
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'editTeacher':
        return EditTeacherScreen(
          teacherId: _selectedArguments as int,
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'classes':
        return AdminClassesPage(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'addClass':
        return AddClassScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'classDetail':
        final args = _selectedArguments as Map<String, dynamic>;
        return AdminClassDetailsScreen(
          classId: args['classId'] as int,
          className: args['className'] as String,
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'classSubjects':
        if (_selectedArguments is Map<String, dynamic>) {
          final args = _selectedArguments as Map<String, dynamic>;
          return ClassSubjectManagementScreen(
            classId: args['classId'] as int,
            className: args['className'] as String,
            embedBodyOnly: true,
            onNavigateToPage: _navigateToPage,
          );
        }
        return AdminClassSubjectsScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'subjects':
        return AdminSubjectsScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'addSubject':
        return AddSubjectScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'attendance':
        return AdminAttendanceScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'fees':
        return AdminFeesScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'payments':
        return const PaymentsScreen(embedInParent: true);
      case 'feeDetail':
        return FeeDetailScreen(
          fee: _selectedArguments as FeeModel,
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'messages':
        return MessageScreen(embedInParent: true);
      case 'timetable':
        return AdminTimetableScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );

      case 'exams':
        return AdminExamsScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'marks':
        return AdminMarksScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'notices':
        return AdminNoticesScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'notifications':
        return NotificationsPage(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );

      case 'profile':
        return AdminProfilePage(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      default:
        return WebDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidebarWidth = screenWidth >= 1200 ? 260.0 : 220.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F7),
      body: Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: WebSidebar(
              width: sidebarWidth,
              selectedPage: _selectedPage,
              onNavigate: widget.onNavigate ?? _navigateToPage,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                WebTopBar(
                  title: _getTitle(_selectedPage),
                  subtitle: _getSubtitle(_selectedPage),
                  onSearch: widget.onSearch,
                  onNavigateToPage: _navigateToPage,
                  onLogout: _handleLogout,
                ),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
