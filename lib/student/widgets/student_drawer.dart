import 'package:flutter/material.dart';
// Add import for AuthService and shared_preferences
import 'package:kobac/services/local_auth_service.dart';
import 'package:kobac/shared/pages/login_screen.dart';
import 'package:kobac/student/pages/academic_activity.dart';
import 'package:kobac/student/pages/exam_schedule.dart';
import 'package:kobac/student/pages/student_attendance.dart';
import 'package:kobac/student/pages/student_fees.dart';
import 'package:kobac/student/pages/student_notices.dart';
import 'package:kobac/student/pages/student_profile.dart';
import 'package:kobac/student/pages/student_quizzes.dart';
import 'package:kobac/student/pages/student_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------- Drawer Widget ------------------------
class AppDrawer extends StatelessWidget {
  AppDrawer({Key? key}) : super(key: key);

  final List<_DrawerItem> _items = [
    _DrawerItem(
      label: "Dashboard",
      icon: Icons.home,
      onTap: (context) {
        Navigator.of(context).pop();
      },
    ),
    _DrawerItem(
      label: "Results",
      icon: Icons.grade,
      onTap: (context) {
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 250), () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => StudentResultsScreen()));
        });
      },
    ),
    _DrawerItem(
      label: "Fees",
      icon: Icons.account_balance_wallet,
      onTap: (context) {
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 250), () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => StudentFeesScreen()));
        });
      },
    ),
    _DrawerItem(
      label: "Attendance",
      icon: Icons.event_available,
      onTap: (context) {
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 250), () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => StudentAttendanceScreen()));
        });
      },
    ),
    _DrawerItem(
      label: "Academic Activity",
      icon: Icons.school,
      onTap: (context) {
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 250), () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StudentAcademicActivityScreen()),
          );
        });
      },
    ),
    _DrawerItem(
      label: "Quizzes",
      icon: Icons.quiz,
      onTap: (context) {
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 250), () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => StudentQuizzesScreen()));
        });
      },
    ),
    _DrawerItem(
      label: "Exam Schedule",
      icon: Icons.schedule,
      onTap: (context) {
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 250), () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StudentExamScheduleScreen()),
          );
        });
      },
    ),
    _DrawerItem(
      label: "Notices",
      icon: Icons.notifications,
      onTap: (context) {
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 250), () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => StudentNoticesScreen()));
        });
      },
    ),
    _DrawerItem(
      label: "Profile",
      icon: Icons.person,
      onTap: (context) {
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 250), () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => StudentProfileScreen()));
        });
      },
    ),
    // --- ADD LOGOUT BUTTON HANDLER LOGIC HERE:
    _DrawerItem(
      label: "Logout",
      icon: Icons.exit_to_app,
      onTap: (context) async {
        // 1. Close drawer
        Navigator.of(context).pop();

        // 2. Logout logic
        await LocalAuthService().logout();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // 3. Ensure context is still valid
        if (!context.mounted) return;

        // 4. Navigate to login & clear stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemCount: _items.length,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final item = _items[index];
            return ListTile(
              leading: Icon(item.icon, color: const Color(0xFF5AB04B)),
              title: Text(
                item.label,
                style: const TextStyle(
                  color: Color(0xFF023471),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                if (item.onTap != null) {
                  item.onTap!(context);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _DrawerItem {
  final String label;
  final IconData icon;
  final void Function(BuildContext context)? onTap;
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
