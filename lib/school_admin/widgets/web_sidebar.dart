import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/school_admin/pages/admin_students.dart';
import 'package:kobac/school_admin/pages/admin_profile.dart';
import 'package:kobac/school_admin/pages/admin_subjects_screen.dart';
import 'package:kobac/school_admin/pages/admin_assignments_screen.dart';
import 'package:kobac/school_admin/pages/admin_timetable_screen.dart';
import 'package:kobac/school_admin/pages/admin_exams_screen.dart';
import 'package:kobac/school_admin/pages/admin_marks_screen.dart';
import 'package:kobac/school_admin/pages/admin_notices_screen.dart';
import 'package:kobac/school_admin/pages/admin_attendance_screen.dart';
import 'package:kobac/school_admin/pages/admin_fees_screen.dart';
import 'package:kobac/school_admin/pages/admin_classes.dart';
import 'package:kobac/school_admin/pages/teachers_screen.dart';
import 'package:kobac/school_admin/pages/create_student_screen.dart';
import 'package:kobac/school_admin/pages/create_teacher_screen.dart';
import 'package:kobac/school_admin/pages/mesaage_screen.dart';
import 'package:kobac/school_admin/pages/notifications_page.dart';
import 'package:kobac/school_admin/pages/settings_page.dart';
import 'package:kobac/school_admin/pages/change_password_page.dart';
import 'package:kobac/school_admin/pages/admin_class_subjects_screen.dart';
import 'package:kobac/school_admin/pages/admin_parents_screen.dart';
import 'package:kobac/school_admin/pages/payments_screen.dart';

/// Desktop sidebar navigation
class WebSidebar extends StatefulWidget {
  final String selectedPage;
  final Function(String) onNavigate;

  const WebSidebar({
    Key? key,
    required this.selectedPage,
    required this.onNavigate,
  }) : super(key: key);

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  String _expandedSection = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
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
          // Logo/App Name
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF023471).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF023471),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dugsi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF023471),
                        ),
                      ),
                      Text(
                        'ADMIN PORTAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B6B6B),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _SidebarSection(
                    title: 'Dashboard',
                    icon: Icons.dashboard_rounded,
                    isExpanded: _expandedSection == 'dashboard',
                    onTap: () => _toggleSection('dashboard'),
                    children: [],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Students',
                    icon: Icons.people_alt_rounded,
                    isExpanded: _expandedSection == 'students' || widget.selectedPage == 'students' || widget.selectedPage == 'addStudent',
                    onTap: () => _toggleSection('students'),
                    children: [
                      _SidebarItem(
                        title: 'All Students',
                        icon: Icons.people_outline_rounded,
                        isActive: widget.selectedPage == 'students',
                        onTap: () => _navigateToPage('students'),
                      ),
                      _SidebarItem(
                        title: 'Add Student',
                        icon: Icons.person_add_rounded,
                        isActive: widget.selectedPage == 'addStudent',
                        onTap: () => _navigateToPage('addStudent'),
                      ),
                    ],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Teachers',
                    icon: Icons.school_rounded,
                    isExpanded: _expandedSection == 'teachers',
                    onTap: () => _toggleSection('teachers'),
                    children: [
                      _SidebarItem(
                        title: 'All Teachers',
                        icon: Icons.school_outlined,
                        onTap: () => _navigateToPage('teachers'),
                      ),
                      _SidebarItem(
                        title: 'Add Teacher',
                        icon: Icons.person_add_rounded,
                        onTap: () => _navigateToPage('addTeacher'),
                      ),
                    ],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Classes',
                    icon: Icons.class_rounded,
                    isExpanded: _expandedSection == 'classes',
                    onTap: () => _toggleSection('classes'),
                    children: [
                      _SidebarItem(
                        title: 'All Classes',
                        icon: Icons.class_outlined,
                        onTap: () => _navigateToPage('classes'),
                      ),
                      _SidebarItem(
                        title: 'Class Subjects',
                        icon: Icons.menu_book_rounded,
                        onTap: () => _navigateToPage('classSubjects'),
                      ),
                    ],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Attendance',
                    icon: Icons.event_note_rounded,
                    isExpanded: _expandedSection == 'attendance',
                    onTap: () => _toggleSection('attendance'),
                    children: [
                      _SidebarItem(
                        title: 'Student Attendance',
                        icon: Icons.person_outline_rounded,
                        onTap: () => _navigateToPage('attendance'),
                      ),
                      _SidebarItem(
                        title: 'Teacher Attendance',
                        icon: Icons.school_outlined,
                        onTap: () => _navigateToPage('attendance'),
                      ),
                    ],
                  ),
                  if (context.watch<AuthProvider>().feesEnabled) ...[
                    const _SidebarDivider(),
                    _SidebarSection(
                      title: 'Fees',
                      icon: Icons.account_balance_wallet_rounded,
                      isExpanded: _expandedSection == 'fees',
                      onTap: () => _toggleSection('fees'),
                      children: [
                        _SidebarItem(
                          title: 'Fees',
                          icon: Icons.payment_outlined,
                          onTap: () => _navigateToPage('fees'),
                        ),
                        _SidebarItem(
                          title: 'Payments',
                          icon: Icons.receipt_long_outlined,
                          onTap: () => _navigateToPage('payments'),
                        ),
                      ],
                    ),
                  ],
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Messages',
                    icon: Icons.chat_bubble_outline_rounded,
                    isExpanded: _expandedSection == 'messages',
                    onTap: () => _toggleSection('messages'),
                    children: [
                      _SidebarItem(
                        title: 'All Messages',
                        icon: Icons.message_outlined,
                        onTap: () => _navigateToPage('messages'),
                      ),
                      _SidebarItem(
                        title: 'Compose Message',
                        icon: Icons.send_outlined,
                        onTap: () => _navigateToPage('composeMessage'),
                      ),
                    ],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Reports',
                    icon: Icons.insert_chart_outlined_rounded,
                    isExpanded: _expandedSection == 'reports',
                    onTap: () => _toggleSection('reports'),
                    children: [
                      _SidebarItem(
                        title: 'Attendance Reports',
                        icon: Icons.assessment_outlined,
                        onTap: () => _navigateToPage('reports'),
                      ),
                    ],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Settings',
                    icon: Icons.settings_outlined,
                    isExpanded: _expandedSection == 'settings',
                    onTap: () => _toggleSection('settings'),
                    children: [
                      _SidebarItem(
                        title: 'General Settings',
                        icon: Icons.settings_outlined,
                        onTap: () => _navigateToPage('settings'),
                      ),
                      _SidebarItem(
                        title: 'Change Password',
                        icon: Icons.lock_reset_rounded,
                        onTap: () => _navigateToPage('changePassword'),
                      ),
                    ],
                  ),
                  const _SidebarDivider(),
                  _SidebarItem(
                    title: 'Profile',
                    icon: Icons.person_outline_rounded,
                    onTap: () => _navigateToPage('profile'),
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Logout',
                    icon: Icons.logout_rounded,
                    isExpanded: false,
                    onTap: () async {
                      await context.read<AuthProvider>().logout();
                    },
                    children: [],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSection(String section) {
    setState(() {
      if (_expandedSection == section) {
        _expandedSection = '';
      } else {
        _expandedSection = section;
      }
    });
  }

  void _navigateToPage(String pageKey) {
    widget.onNavigate(pageKey);
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onTap;
  final List<Widget> children;

  const _SidebarSection({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isExpanded ? const Color(0xFF023471) : const Color(0xFF6B6B6B),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isExpanded ? const Color(0xFF023471) : const Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                if (children.isNotEmpty)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: const Color(0xFF6B6B6B),
                  ),
              ],
            ),
          ),
        ),
        if (isExpanded && children.isNotEmpty)
          Container(
            padding: const EdgeInsets.only(left: 60),
            child: Column(children: children),
          ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: isActive
            ? BoxDecoration(
                color: const Color(0xFF023471).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF023471) : const Color(0xFF6B6B6B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? const Color(0xFF023471) : const Color(0xFF2D2D2D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: const Color(0xFFE8ECF2),
    );
  }
}
