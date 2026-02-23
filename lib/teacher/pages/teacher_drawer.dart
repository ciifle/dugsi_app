import 'package:flutter/material.dart';
import 'package:kobac/services/local_auth_service.dart';
import 'package:kobac/shared/pages/login_screen.dart';
import 'package:kobac/teacher/pages/assignments_screen.dart';
import 'package:kobac/teacher/pages/attendance_mark.dart';
import 'package:kobac/teacher/pages/exams_results.dart';
import 'package:kobac/teacher/pages/notices_screen.dart';
import 'package:kobac/teacher/pages/quizzes_screen.dart';
import 'package:kobac/teacher/pages/students_screen.dart';
import 'package:kobac/teacher/pages/teacher_classes.dart';
import 'package:kobac/teacher/pages/teacher_dashboard.dart';
import 'package:kobac/teacher/pages/teacher_profile.dart';
import 'package:kobac/teacher/pages/weakly_schedule.dart';

// =======================
//  TEACHER DRAWER COLORS - MATCHING STUDENT DASHBOARD
// =======================
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE6F0FF);
const Color kSoftGreen = Color(0xFFEDF7EB);
const Color kDarkGreen = Color(0xFF3A7A30);
const Color kDarkBlue = Color(0xFF01255C);
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF636E72);
const Color kErrorColor = Color(0xFFEF4444);
const Color kSoftOrange = Color(0xFFF59E0B);

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}

// ==================== TEACHER DRAWER ====================
class TeacherDrawer extends StatelessWidget {
  final Map<String, String> teacher;

  const TeacherDrawer({Key? key, required this.teacher}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      width: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(3, 0),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildMenuSection(
                      title: "MAIN",
                      items: const [
                        _MenuItem(
                          icon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                          color: kPrimaryBlue,
                        ),
                        _MenuItem(
                          icon: Icons.class_rounded,
                          label: 'My Classes',
                          color: kPrimaryGreen,
                        ),
                        _MenuItem(
                          icon: Icons.people_rounded,
                          label: 'Students',
                          color: kSoftOrange,
                        ),
                      ],
                      context: context,
                    ),
                    _buildMenuSection(
                      title: "ACADEMICS",
                      items: const [
                        _MenuItem(
                          icon: Icons.assignment_turned_in_rounded,
                          label: 'Attendance',
                          color: kPrimaryBlue,
                        ),
                        _MenuItem(
                          icon: Icons.assignment_rounded,
                          label: 'Assignments',
                          color: kPrimaryGreen,
                        ),
                        _MenuItem(
                          icon: Icons.quiz_rounded,
                          label: 'Quizzes',
                          color: kSoftOrange,
                        ),
                        _MenuItem(
                          icon: Icons.assessment_rounded,
                          label: 'Exams',
                          color: kDarkBlue,
                        ),
                      ],
                      context: context,
                    ),
                    _buildMenuSection(
                      title: "COMMUNICATION",
                      items: const [
                        _MenuItem(
                          icon: Icons.campaign_rounded,
                          label: 'Notices',
                          color: kPrimaryBlue,
                        ),
                        _MenuItem(
                          icon: Icons.calendar_month_rounded,
                          label: 'Schedule',
                          color: kPrimaryGreen,
                        ),
                        _MenuItem(
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          color: kSoftOrange,
                        ),
                      ],
                      context: context,
                    ),
                    const SizedBox(height: 16),
                    _buildLogoutButton(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
          stops: [0.2, 0.6, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: Text(
                    teacher['initials']!,
                    style: const TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher['name']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            teacher['role']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ID: TCH230045',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItem> items,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kTextSecondary.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...items.map(
          (item) => _buildDrawerItem(
            icon: item.icon,
            label: item.label,
            color: item.color,
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, item.label);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kTextPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: kTextSecondary.withOpacity(0.4),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FIXED LOGOUT BUTTON - DIRECT TO LOGIN PAGE
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // First, close the drawer
            Navigator.pop(context);

            // Use a microtask to ensure the drawer is closed before navigation
            Future.microtask(() async {
              try {
                // Perform logout
                await LocalAuthService().logout();

                // Navigate to login screen and clear all routes
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: kErrorColor,
                    ),
                  );
                }
              }
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  kErrorColor.withOpacity(0.05),
                  kErrorColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: kErrorColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kErrorColor, kErrorColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kErrorColor.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kErrorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 10,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Kobac Teacher v1.0.0',
            style: TextStyle(
              color: kTextSecondary.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, String label) {
    Widget screen;
    switch (label) {
      case 'Dashboard':
        screen = const TeacherDashboardScreen();
        break;
      case 'My Classes':
        screen = TeacherMyClassesScreen();
        break;
      case 'Students':
        screen = TeacherStudentManagementScreen();
        break;
      case 'Attendance':
        screen = TeacherAttendanceScreen();
        break;
      case 'Assignments':
        screen = TeacherAssignmentsScreen();
        break;
      case 'Quizzes':
        screen = TeacherQuizzesScreen();
        break;
      case 'Exams':
        screen = TeacherExamsResultsScreen();
        break;
      case 'Notices':
        screen = TeacherNoticesScreen();
        break;
      case 'Schedule':
        screen = TeacherWeeklyScheduleScreen();
        break;
      case 'Profile':
        screen = TeacherProfileScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
