import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/teacher/pages/assignments_screen.dart';
import 'package:kobac/teacher/pages/attendance_mark.dart';
import 'package:kobac/teacher/pages/teacher_classes_screen.dart';
import 'package:kobac/teacher/pages/teacher_marks_screen.dart';
import 'package:kobac/teacher/pages/teacher_profile.dart';
import 'package:kobac/teacher/pages/change_password_page.dart';
import 'package:kobac/teacher/pages/weakly_schedule.dart';
import 'package:kobac/services/teacher_service.dart';
import 'package:kobac/teacher/widgets/teacher_web_dashboard.dart';
import 'package:kobac/teacher/widgets/teacher_web_sidebar.dart';
import 'package:kobac/teacher/widgets/teacher_web_top_bar.dart';

class TeacherWebShell extends StatefulWidget {
  const TeacherWebShell({super.key});

  @override
  State<TeacherWebShell> createState() => _TeacherWebShellState();
}

class _TeacherWebShellState extends State<TeacherWebShell> {
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
      case 'classes':
        return 'My Classes';
      case 'assignments':
        return 'Assignments';
      case 'attendance':
        return 'Attendance';
      case 'timetable':
        return 'Timetable';
      case 'marks':
        return 'Marks';
      case 'profile':
        return 'Profile';
      case 'changePassword':
        return 'Change Password';
      default:
        return 'Dashboard';
    }
  }

  String? _getSubtitle(String pageKey) {
    switch (pageKey) {
      case 'dashboard':
        return 'Your teaching overview and quick actions.';
      case 'assignments':
        return 'Subjects and classes assigned to you.';
      case 'attendance':
        return 'Mark and review attendance records.';
      case 'marks':
        return 'Enter and review student marks.';
      case 'changePassword':
        return 'Update your teacher account password securely.';
      default:
        return null;
    }
  }

  Widget _buildBody() {
    switch (_selectedPage) {
      case 'classes':
        return TeacherClassesScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'assignments':
        return TeacherAssignmentsScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
          initialDashboard: _selectedArguments is TeacherDashboardModel
              ? _selectedArguments as TeacherDashboardModel
              : null,
        );
      case 'attendance':
        return TeacherAttendanceScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'timetable':
        return TeacherWeeklyScheduleScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'marks':
        return TeacherMarksScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      // Messaging temporarily disabled from active UI/navigation.
      case 'profile':
        return TeacherProfileScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'changePassword':
        return const TeacherChangePasswordPage(embedBodyOnly: true);
      case 'dashboard':
      default:
        return TeacherWebDashboard(onNavigateToPage: _navigateToPage);
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
            child: TeacherWebSidebar(
              width: sidebarWidth,
              selectedPage: _selectedPage,
              onNavigate: _navigateToPage,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                TeacherWebTopBar(
                  title: _getTitle(_selectedPage),
                  subtitle: _getSubtitle(_selectedPage),
                  onNavigateToPage: _navigateToPage,
                  onLogout: _handleLogout,
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
