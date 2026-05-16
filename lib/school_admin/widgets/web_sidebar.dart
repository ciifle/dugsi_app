import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';

/// Desktop sidebar navigation
class WebSidebar extends StatefulWidget {
  final String selectedPage;
  final Function(String) onNavigate;
  final double width;

  const WebSidebar({
    Key? key,
    required this.selectedPage,
    required this.onNavigate,
    this.width = 280,
  }) : super(key: key);

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  String _expandedSection = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
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
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1),
              ),
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
                    onTap: () => _navigateToPage('dashboard'),
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
                    isExpanded: _expandedSection == 'teachers' ||
                        widget.selectedPage == 'teachers' ||
                        widget.selectedPage == 'addTeacher' ||
                        widget.selectedPage == 'editTeacher' ||
                        widget.selectedPage == 'teacherDetail',
                    onTap: () => _toggleSection('teachers'),
                    children: [
                      _SidebarItem(
                        title: 'All Teachers',
                        icon: Icons.school_outlined,
                        isActive: widget.selectedPage == 'teachers',
                        onTap: () => _navigateToPage('teachers'),
                      ),
                      _SidebarItem(
                        title: 'Add Teacher',
                        icon: Icons.person_add_rounded,
                        isActive: widget.selectedPage == 'addTeacher',
                        onTap: () => _navigateToPage('addTeacher'),
                      ),
                    ],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Classes',
                    icon: Icons.class_rounded,
                    isExpanded: _expandedSection == 'classes' ||
                        widget.selectedPage == 'classes' ||
                        widget.selectedPage == 'addClass' ||
                        widget.selectedPage == 'editClass' ||
                        widget.selectedPage == 'classDetail' ||
                        widget.selectedPage == 'classDetails',
                    onTap: () => _toggleSection('classes'),
                    children: [
                      _SidebarItem(
                        title: 'All Classes',
                        icon: Icons.class_outlined,
                        isActive: widget.selectedPage == 'classes',
                        onTap: () => _navigateToPage('classes'),
                      ),
                      _SidebarItem(
                        title: 'Add Class',
                        icon: Icons.add_circle_outline_rounded,
                        isActive: widget.selectedPage == 'addClass',
                        onTap: () => _navigateToPage('addClass'),
                      ),
                    ],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Subjects',
                    icon: Icons.menu_book_rounded,
                    isExpanded: _expandedSection == 'subjects' ||
                        widget.selectedPage == 'subjects' ||
                        widget.selectedPage == 'classSubjects' ||
                        widget.selectedPage == 'addSubject' ||
                        widget.selectedPage == 'editSubject',
                    onTap: () => _toggleSection('subjects'),
                    children: [
                      _SidebarItem(
                        title: 'All Subjects',
                        icon: Icons.menu_book_outlined,
                        isActive: widget.selectedPage == 'subjects',
                        onTap: () => _navigateToPage('subjects'),
                      ),
                      _SidebarItem(
                        title: 'Add Subject',
                        icon: Icons.add_circle_outline_rounded,
                        isActive: widget.selectedPage == 'addSubject',
                        onTap: () => _navigateToPage('addSubject'),
                      ),
                      _SidebarItem(
                        title: 'Class Subjects',
                        icon: Icons.library_books_outlined,
                        isActive: widget.selectedPage == 'classSubjects',
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
                    title: 'Timetable',
                    icon: Icons.schedule_rounded,
                    isExpanded: _expandedSection == 'timetable',
                    onTap: () => _navigateToPage('timetable'),
                    children: [],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Exams',
                    icon: Icons.quiz_outlined,
                    isExpanded: _expandedSection == 'exams',
                    onTap: () => _navigateToPage('exams'),
                    children: [],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Marks',
                    icon: Icons.grade_outlined,
                    isExpanded: _expandedSection == 'marks',
                    onTap: () => _navigateToPage('marks'),
                    children: [],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Notices',
                    icon: Icons.notifications_outlined,
                    isExpanded: _expandedSection == 'notices',
                    onTap: () => _navigateToPage('notices'),
                    children: [],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Notifications',
                    icon: Icons.notifications_outlined,
                    isExpanded: _expandedSection == 'notifications',
                    onTap: () => _navigateToPage('notifications'),
                    children: [],
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
