import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/web_sidebar.dart';
import 'package:kobac/school_admin/widgets/web_top_bar.dart';
import 'package:kobac/school_admin/widgets/web_dashboard.dart';
import 'package:kobac/school_admin/pages/admin_students.dart';
import 'package:kobac/school_admin/pages/create_student_screen.dart';
import 'package:kobac/school_admin/pages/teachers_screen.dart';
import 'package:kobac/school_admin/pages/admin_classes.dart';
import 'package:kobac/school_admin/pages/admin_subjects_screen.dart';
import 'package:kobac/school_admin/pages/admin_attendance_screen.dart';
import 'package:kobac/school_admin/pages/admin_fees_screen.dart';
import 'package:kobac/school_admin/pages/mesaage_screen.dart';
import 'package:kobac/school_admin/pages/admin_assignments_screen.dart';
import 'package:kobac/school_admin/pages/admin_timetable_screen.dart';
import 'package:kobac/school_admin/pages/admin_exams_screen.dart';
import 'package:kobac/school_admin/pages/admin_marks_screen.dart';
import 'package:kobac/school_admin/pages/admin_notices_screen.dart';
import 'package:kobac/school_admin/pages/settings_page.dart';
import 'package:kobac/school_admin/pages/admin_profile.dart';

/// Responsive admin shell for desktop/web layout
/// Shows sidebar + top bar + main content area
class WebAdminShell extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  final Function(String)? onSearch;

  const WebAdminShell({
    Key? key,
    this.navigatorKey,
    this.onSearch,
  }) : super(key: key);

  @override
  State<WebAdminShell> createState() => _WebAdminShellState();
}

class _WebAdminShellState extends State<WebAdminShell> {
  String _selectedPage = 'dashboard';

  void _navigateToPage(String pageKey) {
    setState(() {
      _selectedPage = pageKey;
    });
  }

  String _getTitle(String pageKey) {
    switch (pageKey) {
      case 'dashboard':
        return 'Dashboard';
      case 'students':
        return 'Students';
      case 'teachers':
        return 'Teachers';
      case 'classes':
        return 'Classes';
      case 'subjects':
        return 'Subjects';
      case 'attendance':
        return 'Attendance';
      case 'fees':
        return 'Fees';
      case 'messages':
        return 'Messages';
      case 'assignments':
        return 'Assignments';
      case 'timetable':
        return 'Timetable';
      case 'exams':
        return 'Exams';
      case 'marks':
        return 'Marks';
      case 'notices':
        return 'Notices';
      case 'settings':
        return 'Settings';
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
      default:
        return null;
    }
  }

  Widget _buildBody() {
    switch (_selectedPage) {
      case 'dashboard':
        return WebDashboard();
      case 'students':
        return AdminStudentsScreen();
      case 'addStudent':
        return CreateStudentScreen(embedBodyOnly: true);
      case 'teachers':
        return TeacherListScreen();
      case 'classes':
        return AdminClassesPage();
      case 'subjects':
        return AdminSubjectsScreen();
      case 'attendance':
        return AdminAttendanceScreen();
      case 'fees':
        return AdminFeesScreen();
      case 'messages':
        return MessageScreen(embedInParent: true);
      case 'assignments':
        return AdminAssignmentsScreen();
      case 'timetable':
        return AdminTimetableScreen();
      case 'exams':
        return AdminExamsScreen();
      case 'marks':
        return AdminMarksScreen();
      case 'notices':
        return AdminNoticesScreen();
      case 'settings':
        return SettingsPage();
      case 'profile':
        return AdminProfilePage(embedBodyOnly: true);
      default:
        return WebDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F7),
      body: Row(
        children: [
          // Fixed left sidebar
          WebSidebar(
            selectedPage: _selectedPage,
            onNavigate: _navigateToPage,
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top header bar
                WebTopBar(
                  title: _getTitle(_selectedPage),
                  subtitle: _getSubtitle(_selectedPage),
                  onSearch: widget.onSearch,
                ),
                // Page content
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

/// Check if the current layout should use desktop design
bool isDesktopLayout(BuildContext context) {
  return MediaQuery.of(context).size.width >= 1200;
}

/// Check if the current layout should use tablet design
bool isTabletLayout(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= 800 && width < 1200;
}

/// Check if the current layout should use mobile design
bool isMobileLayout(BuildContext context) {
  return MediaQuery.of(context).size.width < 800;
}
