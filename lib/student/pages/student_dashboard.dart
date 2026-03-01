import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/student/pages/exam_schedule.dart';
import 'package:kobac/student/pages/student_attendance.dart';
import 'package:kobac/student/pages/student_fees.dart';
import 'package:kobac/student/pages/student_notices.dart';
import 'package:kobac/student/pages/student_profile.dart';
import 'package:kobac/student/pages/student_result.dart';
import 'package:kobac/student/pages/student_marks_screen.dart';
import 'package:kobac/student/pages/student_timetable_screen.dart';
import 'package:kobac/student/pages/student_pay_fee_screen.dart';
import 'package:kobac/student/pages/student_payments_screen.dart';
import 'package:kobac/student/widgets/student_drawer.dart';

// ---------- COLOR PALETTE (Only two colors) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE6F0FF); // Light tint of blue
const Color kSoftGreen = Color(0xFFEDF7EB); // Light tint of green
const Color kDarkGreen = Color(0xFF3A7A30); // Darker shade of green
const Color kDarkBlue = Color(0xFF01255C); // Darker shade of blue
const Color kTextPrimary = Color(0xFF2D3436); // Dark gray (keep neutral)
const Color kTextSecondary = Color(0xFF636E72); // Medium gray (keep neutral)
const Color kCardColor = Colors.white;

// ---------- DASHBOARD DATA ----------
class _FeatureCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final void Function(BuildContext context)? onTap;

  const _FeatureCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

// ---------------- DASHBOARD SCREEN ----------------
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Define all the screens for bottom navigation
  late final List<Widget> _screens = [
    const _DashboardHomeContent(),
    StudentExamScheduleScreen(),
    const AllNoticesScreen(), // This now shows the actual AllNoticesScreen
    StudentProfileScreen(),
  ];

  final List<_FeatureCardData> _featureCards = [
    _FeatureCardData(
      title: 'View Timetable',
      subtitle: "Today's schedule",
      icon: Icons.schedule_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentTimetableScreen()),
      ),
    ),
    _FeatureCardData(
      title: 'My Marks',
      subtitle: 'Grades by exam',
      icon: Icons.grade_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentMarksScreen()),
      ),
    ),
    _FeatureCardData(
      title: 'Exam Results',
      subtitle: 'Result reports',
      icon: Icons.stars_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StudentResultsScreen()),
      ),
    ),
    _FeatureCardData(
      title: 'Fees',
      subtitle: 'Payment status',
      icon: Icons.account_balance_wallet_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentFeesScreen()),
      ),
    ),
    _FeatureCardData(
      title: 'Pay Fee',
      subtitle: 'Make a payment',
      icon: Icons.payment_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentPayFeeScreen()),
      ),
    ),
    _FeatureCardData(
      title: 'Attendance',
      subtitle: 'My attendance',
      icon: Icons.calendar_month_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentAttendanceScreen()),
      ),
    ),
    _FeatureCardData(
      title: 'Notices',
      subtitle: 'Announcements',
      icon: Icons.campaign_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AllNoticesScreen()),
      ),
    ),
  ];

  // Navigation items
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.calendar_month_rounded, 'label': 'Schedule'},
    {'icon': Icons.notifications_rounded, 'label': 'Notices'},
    {'icon': Icons.person_rounded, 'label': 'Profile'},
  ];

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(), // Drawer opens from left
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            items: _navItems.map((item) {
              return BottomNavigationBarItem(
                icon: Icon(item['icon']),
                label: item['label'],
              );
            }).toList(),
            currentIndex: _selectedIndex,
            onTap: _onNavItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: kPrimaryBlue,
            unselectedItemColor: kTextSecondary.withOpacity(0.6),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
          ),
        ),
      ),
    );
  }
}

// Dashboard Home Content — API-driven, clean layout
class _DashboardHomeContent extends StatefulWidget {
  const _DashboardHomeContent({Key? key}) : super(key: key);

  @override
  State<_DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<_DashboardHomeContent> {
  static const List<String> _kDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  static String _initialsFromName(String name) {
    if (name.isEmpty || name == 'Student') return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final a = parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
      final b = parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';
      return '$a$b';
    }
    return parts.first.isNotEmpty && parts.first.length >= 1
        ? parts.first[0].toUpperCase()
        : '?';
  }

  late Future<StudentResult<List<StudentTimetableSlotModel>>> _timetableTodayFuture;
  late Future<StudentResult<List<StudentNoticeModel>>> _noticesFuture;
  late Future<StudentResult<List<StudentFeeModel>>> _feesFuture;

  @override
  void initState() {
    super.initState();
    final wd = DateTime.now().weekday;
    final todayIndex = (wd == DateTime.sunday ? 7 : wd) - 1;
    final todayDay = _kDays[todayIndex.clamp(0, 6)];
    _timetableTodayFuture = StudentService().getTimetable(day: todayDay);
    _noticesFuture = StudentService().listNotices();
    _feesFuture = StudentService().listFees();
  }

  Future<void> _refresh() async {
    await context.read<AuthProvider>().refreshMe();
    if (!mounted) return;
    setState(() {
      final wd = DateTime.now().weekday;
      final todayIndex = (wd == DateTime.sunday ? 7 : wd) - 1;
      _timetableTodayFuture = StudentService().getTimetable(day: _kDays[todayIndex.clamp(0, 6)]);
      _noticesFuture = StudentService().listNotices();
      _feesFuture = StudentService().listFees();
    });
  }

  static final List<_FeatureCardData> _quickActions = [
    _FeatureCardData(title: 'Timetable', subtitle: "Today's schedule", icon: Icons.schedule_rounded, onTap: (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const StudentTimetableScreen()))),
    _FeatureCardData(title: 'My Marks', subtitle: 'Grades by exam', icon: Icons.grade_rounded, onTap: (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const StudentMarksScreen()))),
    _FeatureCardData(title: 'Exam Results', subtitle: 'Result reports', icon: Icons.stars_rounded, onTap: (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => StudentResultsScreen()))),
    _FeatureCardData(title: 'Fees', subtitle: 'Payment status', icon: Icons.account_balance_wallet_rounded, onTap: (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const StudentFeesScreen()))),
    _FeatureCardData(title: 'Payments', subtitle: 'Payment history', icon: Icons.payment_rounded, onTap: (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const StudentPaymentsScreen()))),
    _FeatureCardData(title: 'Attendance', subtitle: 'My attendance', icon: Icons.calendar_month_rounded, onTap: (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const StudentAttendanceScreen()))),
    _FeatureCardData(title: 'Notices', subtitle: 'Announcements', icon: Icons.campaign_rounded, onTap: (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const AllNoticesScreen()))),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: kPrimaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---------- SECTION 1: Header (from GET /api/auth/me profile) ----------
                Builder(
                  builder: (context) {
                    final auth = context.watch<AuthProvider>();
                    final prof = auth.studentProfile;
                    final user = auth.user;
                    final name = prof?.studentName?.trim().isNotEmpty == true ? prof!.studentName! : (user?.name ?? 'Student');
                    final className = prof?.className ?? '—';
                    final emis = prof?.emisNumber ?? user?.emisNumber ?? '—';
                    final initials = _initialsFromName(name);
                    return Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryBlue.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            kPrimaryBlue,
                            kPrimaryBlue,
                            kDarkBlue,
                          ],
                          stops: const [0.3, 0.7, 1.0],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Subtle top highlight
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 100,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(40),
                                  bottomRight: Radius.circular(40),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left: circular hamburger
                              GestureDetector(
                                onTap: () => Scaffold.of(context).openDrawer(),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Center: welcome, name, pill (class • EMIS) — centered like original
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Welcome back! 👋',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'Class: $className • EMIS: $emis',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right: circular white avatar (like original)
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: kPrimaryBlue,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // ---------- SECTION 2: Today's Timetable Preview ----------
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's classes",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentTimetableScreen())),
                        style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
                        child: const Text('View Full Timetable'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<StudentResult<List<StudentTimetableSlotModel>>>(
                  future: _timetableTodayFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryBlue))),
                        ),
                      );
                    }
                    final list = snap.data is StudentSuccess<List<StudentTimetableSlotModel>>
                        ? (snap.data as StudentSuccess<List<StudentTimetableSlotModel>>).data
                        : <StudentTimetableSlotModel>[];
                    list.sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
                    final showList = list.take(3).toList();
                    if (showList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 40, color: kTextSecondary.withOpacity(0.5)),
                              const SizedBox(width: 16),
                              Text('No classes today', style: TextStyle(fontSize: 15, color: kTextSecondary)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: showList.map((s) {
                          final subj = s.subject?['name']?.toString() ?? '—';
                          final teacher = s.teacher?['fullName']?.toString() ?? s.teacher?['name']?.toString() ?? '—';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: kPrimaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    s.startTime ?? '—',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryBlue),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(subj, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)),
                                      Text(teacher, style: TextStyle(fontSize: 13, color: kTextSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),

                // ---------- SECTION 3: Quick Actions (2x grid) ----------
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: List.generate(
                      _quickActions.length,
                      (i) => _DashboardFeatureCard(card: _quickActions[i], index: i),
                    ),
                  ),
                ),

                // ---------- SECTION 4: Latest Notices (same design as All Notices) ----------
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Notices',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary),
                      ),
                      TextButton(
                        onPressed: () {
                          context.findAncestorStateOfType<_StudentDashboardScreenState>()?._onNavItemTapped(2);
                        },
                        style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
                        child: const Text('View All Notices'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<StudentResult<List<StudentNoticeModel>>>(
                  future: _noticesFuture,
                  builder: (context, snap) {
                    final list = snap.data is StudentSuccess<List<StudentNoticeModel>>
                        ? (snap.data as StudentSuccess<List<StudentNoticeModel>>).data
                        : <StudentNoticeModel>[];
                    final showList = list.take(2).toList();
                    if (showList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kPrimaryBlue.withOpacity(0.08)),
                            boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.campaign_rounded, size: 28, color: kTextSecondary.withOpacity(0.7)),
                              const SizedBox(width: 12),
                              Text('No notices yet', style: TextStyle(fontSize: 14, color: kTextSecondary)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: showList
                            .map((n) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _DashboardNoticeCard(
                                    notice: n,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AllNoticesScreen()),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),

                // ---------- SECTION 5: Fees Summary (hide if 403) ----------
                FutureBuilder<StudentResult<List<StudentFeeModel>>>(
                  future: _feesFuture,
                  builder: (context, snap) {
                    if (snap.data is StudentError && (snap.data as StudentError).statusCode == 403) {
                      return const SizedBox.shrink();
                    }
                    if (snap.connectionState == ConnectionState.waiting || snap.data is! StudentSuccess<List<StudentFeeModel>>) {
                      return const SizedBox.shrink();
                    }
                    final fees = (snap.data as StudentSuccess<List<StudentFeeModel>>).data;
                    num remaining = 0;
                    int unpaidCount = 0;
                    for (final f in fees) {
                      remaining += f.remainingAmount;
                      if (f.status == 'UNPAID' || f.status == 'PARTIAL') unpaidCount++;
                    }
                    if (fees.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kPrimaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: kPrimaryBlue, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fees summary',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Remaining: $remaining',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                                  ),
                                ],
                              ),
                            ),
                            if (unpaidCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kPrimaryGreen.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unpaidCount unpaid',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimaryGreen),
                                ),
                              ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentFeesScreen())),
                              style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
                              child: const Text('View'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Notice card for dashboard (same design as All Notices screen)
class _DashboardNoticeCard extends StatelessWidget {
  final StudentNoticeModel notice;
  final VoidCallback? onTap;

  const _DashboardNoticeCard({required this.notice, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = notice.content ?? '';
    final preview = content.length > 120 ? '${content.substring(0, 120).trim()}…' : content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPrimaryBlue.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: kPrimaryBlue.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [kPrimaryBlue, kPrimaryGreen],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: kTextPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (notice.createdAt != null && notice.createdAt!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kSoftBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                notice.createdAt!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kDarkBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          preview,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: kTextSecondary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: kTextSecondary.withOpacity(0.6),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- FEATURE CARD ----------------
class _DashboardFeatureCard extends StatelessWidget {
  final _FeatureCardData card;
  final int index;

  const _DashboardFeatureCard({required this.card, required this.index});

  Color _getCardColor(int index) {
    return index.isEven ? kPrimaryBlue : kPrimaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getCardColor(index);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => card.onTap!(context),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(card.icon, color: cardColor, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                card.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

