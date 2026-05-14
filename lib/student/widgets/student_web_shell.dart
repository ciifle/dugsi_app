import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/messages/chat_screen.dart';
import 'package:kobac/messages/messages_screen.dart';
import 'package:kobac/messages/new_message_screen.dart';
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
      case 'messages':
        return 'Messages';
      case 'newMessage':
        return 'New Message';
      case 'chat':
        if (_selectedArguments is Map) {
          final name = (_selectedArguments as Map)['name'];
          if (name is String && name.trim().isNotEmpty) {
            return name.trim();
          }
        }
        return 'Chat';
      case 'profile':
        return 'Profile';
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
      case 'messages':
        return 'Your conversations and new messages.';
      case 'newMessage':
        return 'Choose a recipient to start a conversation.';
      case 'chat':
        return 'Send and receive messages without leaving the portal.';
      case 'profile':
        return 'Your student account details.';
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
          preselectedFeeId: _selectedArguments is int ? _selectedArguments as int : null,
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
      case 'messages':
        return MessagesScreen(
          embedInParent: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'newMessage':
        return NewMessageScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'chat':
        if (_selectedArguments is Map) {
          final args = _selectedArguments as Map;
          final userId = args['userId'];
          final name = args['name']?.toString() ?? 'Chat';
          if (userId is int) {
            return ChatScreen(
              userId: userId,
              name: name,
              embedBodyOnly: true,
              onNavigateToPage: _navigateToPage,
            );
          }
        }
        return MessagesScreen(
          embedInParent: true,
          onNavigateToPage: _navigateToPage,
        );
      case 'profile':
        return StudentProfileScreen(
          embedBodyOnly: true,
          onNavigateToPage: _navigateToPage,
        );
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
