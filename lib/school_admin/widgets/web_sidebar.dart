import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/shared/widgets/school_brand_logo.dart';

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
    final examsEnabled = context.watch<AuthProvider>().examsEnabled;
    final school = context.watch<AuthProvider>().school;
    final schoolName = school?.name?.trim();
    return Container(
      width: widget.width - 16,
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF023471).withValues(alpha: .09),
            blurRadius: 26,
            offset: const Offset(4, 8),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    SchoolBrandLogo(logoUrl: school?.logoUrl, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        schoolName == null || schoolName.isEmpty
                            ? 'Dugsi'
                            : schoolName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF023471),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
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
                    isExpanded:
                        _expandedSection == 'students' ||
                        widget.selectedPage == 'students' ||
                        widget.selectedPage == 'addStudent',
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
                    isExpanded:
                        _expandedSection == 'teachers' ||
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
                    isExpanded:
                        _expandedSection == 'classes' ||
                        widget.selectedPage == 'classes' ||
                        widget.selectedPage == 'addClass' ||
                        widget.selectedPage == 'editClass' ||
                        widget.selectedPage == 'classDetail' ||
                        widget.selectedPage == 'classDetails' ||
                        widget.selectedPage == 'classMerge' ||
                        widget.selectedPage == 'levels' ||
                        widget.selectedPage == 'shifts',
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
                      _SidebarItem(
                        title: 'Class Merge',
                        icon: Icons.swap_horiz_rounded,
                        isActive: widget.selectedPage == 'classMerge',
                        onTap: () => _navigateToPage('classMerge'),
                      ),
                      _SidebarItem(
                        title: 'Levels',
                        icon: Icons.layers_outlined,
                        isActive: widget.selectedPage == 'levels',
                        onTap: () => _navigateToPage('levels'),
                      ),
                      _SidebarItem(
                        title: 'Shifts',
                        icon: Icons.schedule_rounded,
                        isActive: widget.selectedPage == 'shifts',
                        onTap: () => _navigateToPage('shifts'),
                      ),
                    ],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Subjects',
                    icon: Icons.menu_book_rounded,
                    isExpanded:
                        _expandedSection == 'subjects' ||
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
                    title: 'Academic Years',
                    icon: Icons.calendar_month_rounded,
                    isExpanded: _expandedSection == 'academicYears',
                    onTap: () => _navigateToPage('academicYears'),
                    children: [],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Examinations',
                    icon: Icons.event_seat_rounded,
                    isExpanded:
                        _expandedSection == 'examinations' ||
                        {
                          'exams',
                          'marks',
                          'examHalls',
                          'hallAllocation',
                          'hallReports',
                          'passCards',
                        }.contains(widget.selectedPage),
                    onTap: () => _toggleSection('examinations'),
                    children: [
                      _SidebarItem(
                        title: 'Exams',
                        icon: Icons.quiz_outlined,
                        isActive: widget.selectedPage == 'exams',
                        onTap: () => _navigateToPage('exams'),
                      ),
                      _SidebarItem(
                        title: 'Marks',
                        icon: Icons.grade_outlined,
                        isActive: widget.selectedPage == 'marks',
                        onTap: () => _navigateToPage('marks'),
                      ),
                      if (examsEnabled) ...[
                        _SidebarItem(
                          title: 'Exam Halls',
                          icon: Icons.meeting_room_outlined,
                          isActive: widget.selectedPage == 'examHalls',
                          onTap: () => _navigateToPage('examHalls'),
                        ),
                        _SidebarItem(
                          title: 'Hall Allocation',
                          icon: Icons.event_seat_outlined,
                          isActive: widget.selectedPage == 'hallAllocation',
                          onTap: () => _navigateToPage('hallAllocation'),
                        ),
                        _SidebarItem(
                          title: 'Hall Report',
                          icon: Icons.summarize_outlined,
                          isActive: widget.selectedPage == 'hallReports',
                          onTap: () => _navigateToPage('hallReports'),
                        ),
                        _SidebarItem(
                          title: 'Exam Pass Cards',
                          icon: Icons.badge_outlined,
                          isActive: widget.selectedPage == 'passCards',
                          onTap: () => _navigateToPage('passCards'),
                        ),
                      ],
                    ],
                  ),
                  const _SidebarDivider(),
                  _SidebarSection(
                    title: 'Student Promotions',
                    icon: Icons.trending_up_rounded,
                    isExpanded: _expandedSection == 'promotions',
                    onTap: () => _navigateToPage('promotions'),
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
                ],
              ),
            ),
          ),
          _LogoutCard(
            onTap: () async {
              await context.read<AuthProvider>().logout();
            },
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
    setState(() => _expandedSection = pageKey);
    widget.onNavigate(pageKey);
  }
}

class _LogoutCard extends StatefulWidget {
  final Future<void> Function() onTap;

  const _LogoutCard({required this.onTap});

  @override
  State<_LogoutCard> createState() => _LogoutCardState();
}

class _LogoutCardState extends State<_LogoutCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(14),
        transform: Matrix4.translationValues(
          0,
          _pressed ? 1 : (_hovered ? -2 : 0),
          0,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFC73737),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFC73737,
              ).withValues(alpha: _hovered ? .28 : .18),
              blurRadius: _hovered ? 20 : 14,
              offset: Offset(0, _hovered ? 8 : 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sign out of your account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFFFE4E4),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
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
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isExpanded ? const Color(0xFF023471) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isExpanded
                  ? const [BoxShadow(color: Color(0x33023471), blurRadius: 12)]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? Colors.white.withValues(alpha: .16)
                        : const Color(0xFFF1F5FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isExpanded ? Colors.white : const Color(0xFF023471),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isExpanded
                          ? Colors.white
                          : const Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                if (children.isNotEmpty)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: isExpanded ? Colors.white : const Color(0xFF6B6B6B),
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
    return Semantics(
      button: true,
      selected: isActive,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: isActive
                  ? BoxDecoration(
                      color: const Color(0xFF023471).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isActive
                        ? const Color(0xFF023471)
                        : const Color(0xFF6B6B6B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF023471)
                            : const Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Positioned(
                left: 12,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF023471),
                    borderRadius: BorderRadius.circular(2),
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
