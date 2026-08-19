import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/teacher/pages/assignments_screen.dart';
import 'package:kobac/teacher/pages/attendance_mark.dart';
import 'package:kobac/teacher/pages/teacher_classes_screen.dart';
import 'package:kobac/teacher/pages/teacher_dashboard.dart';
import 'package:kobac/teacher/pages/teacher_marks_screen.dart';
import 'package:kobac/teacher/pages/teacher_profile.dart';
import 'package:kobac/teacher/pages/teacher_students_list_screen.dart';
import 'package:kobac/teacher/pages/change_password_page.dart';
import 'package:kobac/teacher/widgets/teacher_mobile_ui.dart';
import 'package:kobac/teacher/widgets/teacher_web_ui.dart';

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
  final Map<String, String>? teacher;

  /// The label of the currently-active root destination (e.g. 'Dashboard',
  /// 'Classes', 'My Assignments', 'Profile'), so the matching menu row can
  /// get a slightly stronger brand treatment. Optional — the drawer renders
  /// fine with no item highlighted when this is omitted.
  final String? currentLabel;

  /// Switches the Teacher mobile shell's active root page for a root-level
  /// menu label (every item except Change Password). When provided, root
  /// items no longer push a standalone route — they route through the same
  /// persistent shell the bottom navbar and Quick Actions use, so the
  /// navbar/header never disappear. Falls back to pushing a route (old
  /// behavior) if omitted, e.g. if the drawer is ever used outside the
  /// shell.
  final void Function(String rootLabel)? onNavigateRoot;

  const TeacherDrawer({
    Key? key,
    this.teacher,
    this.currentLabel,
    this.onNavigateRoot,
  }) : super(key: key);

  static const _menuItems = [
    _MenuItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      color: kPrimaryBlue,
    ),
    _MenuItem(
      icon: Icons.assignment_rounded,
      label: 'My Assignments',
      color: kPrimaryGreen,
    ),
    _MenuItem(icon: Icons.class_rounded, label: 'Classes', color: kPrimaryBlue),
    _MenuItem(
      icon: Icons.people_rounded,
      label: 'My Students',
      color: kSoftOrange,
    ),
    _MenuItem(
      icon: Icons.assignment_turned_in_rounded,
      label: 'Take Attendance',
      color: kPrimaryBlue,
    ),
    _MenuItem(icon: Icons.grade_rounded, label: 'Marks', color: kSoftOrange),
    _MenuItem(icon: Icons.person_rounded, label: 'Profile', color: kSoftOrange),
    _MenuItem(
      icon: Icons.lock_outline_rounded,
      label: 'Change Password',
      color: kPrimaryBlue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      width: MediaQuery.of(context).size.width * 0.8,
      child: Container(
        decoration: const BoxDecoration(
          color: teacherWebBg,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 22,
              offset: Offset(3, 0),
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 4),
                // The menu list is the only part that scrolls — Logout and
                // the footer are pinned outside it, so they stay reachable
                // without scrolling on tall phones and the list simply
                // scrolls internally (never overflows) on short ones.
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildMenuSection(
                      title: "MAIN",
                      items: _menuItems,
                      context: context,
                    ),
                  ),
                ),
                _buildLogoutSection(context),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.name ?? teacher?['name'] ?? 'Teacher';
    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'T';
    final email = user?.email ?? user?.emisNumber ?? teacher?['email'] ?? '—';
    final roleLabel = user != null
        ? user.role.replaceAll('_', ' ')
        : (teacher?['role'] ?? 'Teacher');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: teacherWebBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryBlue.withValues(alpha: 0.08),
                    border: Border.all(
                      color: kPrimaryBlue.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    initials.isEmpty ? 'T' : initials,
                    style: const TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleLabel.toUpperCase(),
                          style: const TextStyle(
                            color: kDarkGreen,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: teacherWebBorder),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 13,
                  color: kTextSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: kTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 2),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: kTextSecondary.withValues(alpha: 0.7),
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...items.map(
          (item) => _buildDrawerItem(
            icon: item.icon,
            label: item.label,
            color: item.color,
            selected: item.label == currentLabel,
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
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: selected ? kPrimaryBlue.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? kPrimaryBlue.withValues(alpha: 0.35)
                    : teacherWebBorder,
              ),
              boxShadow: selected
                  ? const []
                  : const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: selected ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? kPrimaryBlue : kTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: kPrimaryGreen,
                    size: 17,
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: kTextSecondary.withValues(alpha: 0.5),
                    size: 19,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Logout, visually separated from the navigation list by a divider and
  /// pinned outside the scrollable menu area (see build()) so it never
  /// requires scrolling to reach and can never overflow.
  Widget _buildLogoutSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: teacherWebBorder),
        ),
        const SizedBox(height: 8),
        _buildLogoutButton(context),
        const SizedBox(height: 6),
      ],
    );
  }

  // FIXED LOGOUT BUTTON - DIRECT TO LOGIN PAGE
  Widget _buildLogoutButton(BuildContext context) {
    return TeacherDrawerLogoutCard(
      onTap: () {
        // First, close the drawer
        Navigator.pop(context);

        // Use a microtask to ensure the drawer is closed before navigation
        Future.microtask(() async {
          try {
            await context.read<AuthProvider>().logout();
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
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: kPrimaryBlue,
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
    // Every root-level destination routes through the persistent Teacher
    // shell (same mechanism as the bottom navbar and Quick Actions) so the
    // navbar/header never disappear. Change Password is a true detail page
    // and always falls through to the push below.
    if (label != 'Change Password' && onNavigateRoot != null) {
      onNavigateRoot!(label);
      return;
    }
    Widget? screen;
    switch (label) {
      case 'Dashboard':
        screen = const TeacherDashboardScreen();
        break;
      case 'My Assignments':
        screen = const TeacherAssignmentsScreen();
        break;
      case 'Classes':
        screen = const TeacherClassesScreen();
        break;
      case 'My Students':
        screen = const TeacherStudentsListScreen();
        break;
      case 'Take Attendance':
        screen = const TeacherAttendanceScreen();
        break;
      case 'Marks':
        screen = const TeacherMarksScreen();
        break;
      // Messaging temporarily disabled from active UI/navigation.
      case 'Profile':
        screen = const TeacherProfileScreen();
        break;
      case 'Change Password':
        screen = const TeacherChangePasswordPage();
        break;
      default:
        return;
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen!));
    }
  }
}
