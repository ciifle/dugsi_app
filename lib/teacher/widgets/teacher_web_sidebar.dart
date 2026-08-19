import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/teacher/widgets/teacher_web_ui.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kInactive = Color(0xFF6B6B6B);

class TeacherWebSidebar extends StatelessWidget {
  final String selectedPage;
  final void Function(String pageKey, {Object? arguments}) onNavigate;
  final VoidCallback? onLogout;
  final double width;

  const TeacherWebSidebar({
    super.key,
    required this.selectedPage,
    required this.onNavigate,
    this.onLogout,
    this.width = 260,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.name?.trim().isNotEmpty == true
        ? user!.name.trim()
        : 'Teacher';

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/dugsi logo-04.png',
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _TeacherNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  pageKey: 'dashboard',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _TeacherNavItem(
                  icon: Icons.class_rounded,
                  label: 'My Classes',
                  pageKey: 'classes',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _TeacherNavItem(
                  icon: Icons.assignment_rounded,
                  label: 'Assignments',
                  pageKey: 'assignments',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _TeacherNavItem(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Attendance',
                  pageKey: 'attendance',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _TeacherNavItem(
                  icon: Icons.schedule_rounded,
                  label: 'Timetable',
                  pageKey: 'timetable',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _TeacherNavItem(
                  icon: Icons.grade_rounded,
                  label: 'Marks',
                  pageKey: 'marks',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                // Messaging temporarily disabled from active UI/navigation.
                _TeacherNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  pageKey: 'profile',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _TeacherNavItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  pageKey: 'changePassword',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: teacherWebTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Divider(height: 1, color: teacherWebBorder),
          if (onLogout != null) TeacherLogoutCard(onTap: onLogout!),
        ],
      ),
    );
  }
}

class _TeacherNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String pageKey;
  final String selectedPage;
  final void Function(String pageKey, {Object? arguments}) onNavigate;

  const _TeacherNavItem({
    required this.icon,
    required this.label,
    required this.pageKey,
    required this.selectedPage,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedPage == pageKey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onNavigate(pageKey),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected
                  ? _kPrimaryBlue.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? _kPrimaryBlue : _kInactive,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected
                            ? _kPrimaryBlue
                            : const Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
