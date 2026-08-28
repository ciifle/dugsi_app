import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/student/pages/student_attendance.dart';
import 'package:kobac/student/pages/student_fees.dart';
import 'package:kobac/student/pages/student_marks_screen.dart';
import 'package:kobac/student/pages/student_notices.dart';
import 'package:kobac/student/pages/student_pay_fee_screen.dart';
import 'package:kobac/student/pages/student_payments_screen.dart';
import 'package:kobac/student/pages/student_profile.dart';
import 'package:kobac/student/pages/student_result.dart';
import 'package:kobac/student/pages/student_timetable_screen.dart';
import 'package:kobac/student/pages/student_total_page.dart';
import 'package:kobac/student/pages/change_password_page.dart';
import 'package:kobac/student/pages/academic_performance_page.dart';
import 'package:kobac/student/pages/academic_history_page.dart';
import 'package:kobac/student/widgets/student_web_dashboard.dart';
import 'package:kobac/student/widgets/student_web_sidebar.dart';
import 'package:kobac/student/widgets/student_web_top_bar.dart';

class StudentWebShell extends StatefulWidget {
  const StudentWebShell({super.key});

  @override
  State<StudentWebShell> createState() => _StudentWebShellState();
}

class _StudentWebShellState extends State<StudentWebShell> {
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
      case 'timetable':
        return 'Timetable';
      case 'marks':
        return 'Marks';
      case 'marksTotal':
        return 'Total Marks';
      case 'results':
        return 'Results';
      case 'fees':
        return 'Fees';
      case 'payments':
        return 'Payments';
      case 'payFee':
        return 'Pay Fee';
      case 'attendance':
        return 'Attendance';
      case 'notices':
        return 'Notices';
      case 'profile':
        return 'Profile';
      case 'performance':
        return 'Academic Performance';
      case 'changePassword':
        return 'Change Password';
      case 'academicHistory':
        return 'Academic History';
      default:
        return 'Dashboard';
    }
  }

  String? _getSubtitle(String pageKey) {
    switch (pageKey) {
      case 'dashboard':
        return 'Your learning overview and quick actions.';
      case 'timetable':
        return 'Weekly class schedule.';
      case 'marks':
        return 'Review marks by exam.';
      case 'marksTotal':
        return 'Weighted totals across exams.';
      case 'results':
        return 'Exam result reports.';
      case 'fees':
        return 'Fee balances and payment status.';
      case 'payments':
        return 'Your payment history.';
      case 'payFee':
        return 'Submit a fee payment.';
      case 'attendance':
        return 'Monthly attendance records.';
      case 'notices':
        return 'School announcements.';
      case 'profile':
        return 'Your student account details.';
      case 'performance':
        return 'Your released academic results and class ranking.';
      case 'changePassword':
        return 'Update your student account password securely.';
      case 'academicHistory':
        return 'View your current and previous academic years.';
      default:
        return null;
    }
  }

  Widget _buildBody() {
    switch (_selectedPage) {
      case 'timetable':
        return StudentTimetableScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'marks':
        return StudentMarksScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'marksTotal':
        if (_selectedArguments is StudentMarksTotalArguments) {
          final arguments = _selectedArguments as StudentMarksTotalArguments;
          return StudentTotalPage(
            marks: arguments.marks,
            academicYearId: arguments.academicYearId,
            embedBodyOnly: true,
            onNavigateToPage: _navigateToPage,
          );
        }
        if (_selectedArguments is List<StudentMarkModel>) {
          return StudentTotalPage(
            marks: _selectedArguments as List<StudentMarkModel>,
            embedBodyOnly: true,
            onNavigateToPage: _navigateToPage,
          );
        }
        return StudentMarksScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'results':
        return StudentResultsScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'fees':
        return StudentFeesScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'payments':
        return StudentPaymentsScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'payFee':
        return StudentPayFeeScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
          preselectedFeeId: _selectedArguments is int
              ? _selectedArguments as int
              : null,
        );
      case 'attendance':
        return StudentAttendanceScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'notices':
        return AllNoticesScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      // Messaging temporarily disabled from active UI/navigation.
      case 'profile':
        return StudentProfileScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'performance':
        return const AcademicPerformancePage(embedBodyOnly: true);
      case 'changePassword':
        return const ChangePasswordPage(embedBodyOnly: true);
      case 'academicHistory':
        return const StudentAcademicHistoryPage(embedBodyOnly: true);
      case 'dashboard':
      default:
        return StudentWebDashboard(onNavigateToPage: _navigateToPage);
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
            child: StudentWebSidebar(
              width: sidebarWidth,
              selectedPage: _selectedPage,
              onNavigate: _navigateToPage,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                StudentWebTopBar(
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
