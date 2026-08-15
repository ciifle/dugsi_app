import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/student/widgets/student_web_shell.dart';
import 'package:kobac/student/widgets/student_web_ui.dart';
import 'package:kobac/student/widgets/student_learning_ui.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/student/pages/student_attendance.dart';
import 'package:kobac/student/pages/student_fees.dart';
import 'package:kobac/student/pages/student_profile.dart';
import 'package:kobac/student/pages/student_result.dart';
import 'package:kobac/student/pages/student_marks_screen.dart';
import 'package:kobac/student/pages/student_timetable_screen.dart';
import 'package:kobac/student/pages/student_pay_fee_screen.dart';
import 'package:kobac/student/widgets/student_drawer.dart';
import 'package:kobac/student/pages/student_notices.dart';
import 'package:kobac/student/pages/academic_performance_page.dart';
import 'package:kobac/services/academic_performance_service.dart';

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
class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isStudentDesktopWeb(context)) {
      return const StudentWebShell();
    }

    return ChangeNotifierProvider(
      create: (_) => _StudentDashboardScreenState(),
      child: const _StudentDashboardScreenView(),
    );
  }
}

class _StudentDashboardScreenView extends StatelessWidget {
  const _StudentDashboardScreenView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<_StudentDashboardScreenState>();
    return Scaffold(
      key: state._scaffoldKey,
      drawer: AppDrawer(onSelectTab: state._onNavItemTapped),
      body: IndexedStack(index: state._selectedIndex, children: state._screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: studentLine),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22023471),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            items: state._navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final selected = index == state._selectedIndex;
              return BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected ? studentBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x32023471),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    item['icon'],
                    color: selected ? Colors.white : studentMuted,
                    size: 21,
                  ),
                ),
                label: item['label'],
              );
            }).toList(),
            currentIndex: state._selectedIndex,
            onTap: state._onNavItemTapped,
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

class _StudentDashboardScreenState with ChangeNotifier {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Expose the scaffold key for access by child widgets
  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;

  // Define all screens for bottom navigation (only 4 items in navbar)
  late final List<Widget> _screens = [
    _DashboardHomeContent(navigateToTab: _onNavItemTapped),
    const StudentAttendanceScreen(),
    const AcademicPerformancePage(),
    StudentProfileScreen(),
  ];

  // Navigation items (only 4 items)
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.calendar_month_rounded, 'label': 'Attendance'},
    {'icon': Icons.insights_rounded, 'label': 'Performance'},
    {'icon': Icons.person_rounded, 'label': 'Profile'},
  ];

  void _onNavItemTapped(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}

// Dashboard Home Content — API-driven, clean layout
class _DashboardHomeContent extends StatefulWidget {
  final void Function(int index) navigateToTab;

  const _DashboardHomeContent({Key? key, required this.navigateToTab})
    : super(key: key);

  @override
  State<_DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<_DashboardHomeContent> {
  static const List<String> _kDays = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

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

  late Future<StudentResult<List<StudentTimetableSlotModel>>>
  _timetableTodayFuture;
  late Future<PerformanceResult<StudentAcademicPerformance>> _performanceFuture;
  late Future<StudentResult<List<StudentNoticeModel>>> _noticesFuture;
  late Future<StudentResult<List<StudentFeeModel>>> _feesFuture;

  late final List<_FeatureCardData> _featureCards;

  @override
  void initState() {
    super.initState();

    // Initialize feature cards after widget is available (ALL ORIGINAL CARDS)
    _featureCards = [
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
        title: 'Academic Performance',
        subtitle: 'Academic progress',
        icon: Icons.insights_rounded,
        onTap: (context) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AcademicPerformancePage()),
        ),
      ),
      _FeatureCardData(
        title: 'Attendance',
        subtitle: 'My attendance',
        icon: Icons.calendar_month_rounded,
        onTap: (context) => widget.navigateToTab(1),
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

    final wd = DateTime.now().weekday;
    final todayIndex = (wd == DateTime.sunday ? 7 : wd) - 1;
    final todayDay = _kDays[todayIndex.clamp(0, 6)];
    _timetableTodayFuture = StudentService().getTimetable(day: todayDay);
    _performanceFuture = AcademicPerformanceService().performance();
    _noticesFuture = StudentService().listNotices();
    _feesFuture = StudentService().listFees();
  }

  Future<void> _refresh() async {
    await context.read<AuthProvider>().refreshMe();
    if (!mounted) return;
    setState(() {
      final wd = DateTime.now().weekday;
      final todayIndex = (wd == DateTime.sunday ? 7 : wd) - 1;
      _timetableTodayFuture = StudentService().getTimetable(
        day: _kDays[todayIndex.clamp(0, 6)],
      );
      _performanceFuture = AcademicPerformanceService().performance();
      _noticesFuture = StudentService().listNotices();
      _feesFuture = StudentService().listFees();
    });
  }

  List<_FeatureCardData> _visibleQuickActions(BuildContext context) {
    const quickTitles = {
      'View Timetable',
      'My Marks',
      'Exam Results',
      'Attendance',
    };
    return _featureCards
        .where((card) => quickTitles.contains(card.title))
        .toList();
  }

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
                // ---------- STUDENT LEARNING HUB HEADER ----------
                Builder(
                  builder: (context) {
                    final auth = context.watch<AuthProvider>();
                    final profile = auth.studentProfile;
                    final user = auth.user;
                    final name = profile?.studentName?.trim().isNotEmpty == true
                        ? profile!.studentName!.trim()
                        : (user?.name ?? 'Student');
                    final firstName = name.trim().split(RegExp(r'\s+')).first;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Column(
                        children: [
                          StudentPageHeader(
                            title: 'Good morning,',
                            subtitle: firstName,
                            onMenu: () => context
                                .read<_StudentDashboardScreenState>()
                                ._scaffoldKey
                                .currentState
                                ?.openDrawer(),
                          ),
                          const SizedBox(height: 18),
                          StudentIdentityCard(
                            name: name,
                            className: profile?.className ?? 'Not assigned',
                            emis:
                                profile?.emisNumber ??
                                user?.emisNumber ??
                                'Not available',
                            onTap: () => widget.navigateToTab(3),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (false)
                  Builder(
                    builder: (context) {
                      final auth = context.watch<AuthProvider>();
                      final prof = auth.studentProfile;
                      final user = auth.user;
                      final name = prof?.studentName?.trim().isNotEmpty == true
                          ? prof!.studentName!
                          : (user?.name ?? 'Student');
                      final className = prof?.className ?? '—';
                      final emis = prof?.emisNumber ?? user?.emisNumber ?? '—';
                      final initials = _initialsFromName(name);
                      return Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        decoration: BoxDecoration(
                          color: studentWebBg,
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryBlue.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                const SizedBox(height: 20),
                                // Menu button and profile avatar row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Menu button to open drawer
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: kPrimaryBlue.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.menu_rounded,
                                          color: kPrimaryBlue,
                                        ),
                                        onPressed: () {
                                          // Access the dashboard state through the provider and open drawer
                                          final dashboardState = context
                                              .read<
                                                _StudentDashboardScreenState
                                              >();
                                          dashboardState
                                              ._scaffoldKey
                                              .currentState
                                              ?.openDrawer();
                                        },
                                        tooltip: 'Menu',
                                      ),
                                    ),
                                    // Profile avatar
                                    Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: kSoftBlue,
                                        border: Border.all(
                                          color: kPrimaryBlue.withOpacity(0.12),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: kPrimaryBlue.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: kPrimaryBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 48,
                                    ), // Spacer to balance the menu button
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Name
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryBlue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                // Class & EMIS
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        className,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'EMIS: $emis',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                // ---------- ACADEMIC PERFORMANCE ----------
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const StudentSectionHeader(
                    title: 'Academic Performance',
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<PerformanceResult<StudentAcademicPerformance>>(
                  future: _performanceFuture,
                  builder: (context, snapshot) {
                    final success =
                        snapshot.data
                            is PerformanceSuccess<StudentAcademicPerformance>;
                    final performance = success
                        ? (snapshot.data
                                  as PerformanceSuccess<
                                    StudentAcademicPerformance
                                  >)
                              .data
                        : null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _AcademicPerformanceFeatureCard(
                        loading:
                            snapshot.connectionState == ConnectionState.waiting,
                        percentage: performance?.percentage,
                        grade: performance?.grade,
                        status: performance?.status,
                        position: performance?.position,
                        academicYear: performance?.yearName,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AcademicPerformancePage(),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                FutureBuilder<StudentResult<List<StudentTimetableSlotModel>>>(
                  future: _timetableTodayFuture,
                  builder: (context, snapshot) {
                    final classes =
                        snapshot.data
                            is StudentSuccess<List<StudentTimetableSlotModel>>
                        ? List<StudentTimetableSlotModel>.from(
                            (snapshot.data
                                    as StudentSuccess<
                                      List<StudentTimetableSlotModel>
                                    >)
                                .data,
                          )
                        : <StudentTimetableSlotModel>[];
                    classes.sort(
                      (a, b) =>
                          (a.startTime ?? '').compareTo(b.startTime ?? ''),
                    );
                    if (classes.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final next = classes.first;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: StudentNextClassCard(
                        time:
                            '${next.startTime ?? '--:--'} – ${next.endTime ?? '--:--'}',
                        subject: next.subject?['name']?.toString() ?? 'Class',
                        teacher:
                            next.teacher?['fullName']?.toString() ??
                            next.teacher?['name']?.toString() ??
                            'Teacher not available',
                        onViewTimetable: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentTimetableScreen(),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // ---------- TODAY'S SCHEDULE ----------
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's classes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentTimetableScreen(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryBlue,
                        ),
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
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryBlue.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kPrimaryBlue,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final list =
                        snap.data
                            is StudentSuccess<List<StudentTimetableSlotModel>>
                        ? (snap.data
                                  as StudentSuccess<
                                    List<StudentTimetableSlotModel>
                                  >)
                              .data
                        : <StudentTimetableSlotModel>[];
                    list.sort(
                      (a, b) =>
                          (a.startTime ?? '').compareTo(b.startTime ?? ''),
                    );
                    final showList = list.take(3).toList();
                    if (showList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryBlue.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 40,
                                color: kTextSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'No classes today',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: kTextSecondary,
                                ),
                              ),
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
                          final teacher =
                              s.teacher?['fullName']?.toString() ??
                              s.teacher?['name']?.toString() ??
                              '—';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimaryBlue.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    s.startTime ?? '—',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kPrimaryBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subj,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: kTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        teacher,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: kTextSecondary,
                                        ),
                                      ),
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

                // ---------- QUICK ACCESS ----------
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
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
                      _visibleQuickActions(context).length,
                      (i) => _DashboardFeatureCard(
                        card: _visibleQuickActions(context)[i],
                        index: i,
                      ),
                    ),
                  ),
                ),

                // ---------- SECTION 4: Latest Notices ----------
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Notices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AllNoticesScreen(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryBlue,
                        ),
                        child: const Text('View All Notices'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<StudentResult<List<StudentNoticeModel>>>(
                  future: _noticesFuture,
                  builder: (context, snap) {
                    final list =
                        snap.data is StudentSuccess<List<StudentNoticeModel>>
                        ? (snap.data
                                  as StudentSuccess<List<StudentNoticeModel>>)
                              .data
                        : <StudentNoticeModel>[];
                    final showList = list.take(2).toList();
                    if (showList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 32,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: kPrimaryBlue.withOpacity(0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryBlue.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.campaign_rounded,
                                size: 28,
                                color: kTextSecondary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'No notices yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: kTextSecondary,
                                ),
                              ),
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
                            .map(
                              (n) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _DashboardNoticeCard(
                                  notice: n,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AllNoticesScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),

                // ---------- SECTION 5: Fees Summary ----------
                FutureBuilder<StudentResult<List<StudentFeeModel>>>(
                  future: _feesFuture,
                  builder: (context, snap) {
                    if (snap.data is StudentError &&
                        (snap.data as StudentError).statusCode == 403) {
                      return const SizedBox.shrink();
                    }
                    if (snap.connectionState == ConnectionState.waiting ||
                        snap.data is! StudentSuccess<List<StudentFeeModel>>) {
                      return const SizedBox.shrink();
                    }
                    final fees =
                        (snap.data as StudentSuccess<List<StudentFeeModel>>)
                            .data;
                    num remaining = 0;
                    int unpaidCount = 0;
                    for (final fee in fees) {
                      if (fee.status?.toUpperCase() == 'UNPAID') {
                        remaining += fee.amount ?? 0;
                        unpaidCount++;
                      }
                    }
                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kCardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryBlue.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kPrimaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: kPrimaryBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fees summary',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: kTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Remaining: $remaining',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (unpaidCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryGreen.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unpaidCount unpaid',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryGreen,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StudentFeesScreen(),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: kPrimaryBlue,
                              ),
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

// Notice card for dashboard
class _DashboardNoticeCard extends StatelessWidget {
  final StudentNoticeModel notice;
  final VoidCallback? onTap;

  const _DashboardNoticeCard({required this.notice, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = notice.content ?? '';
    final preview = content.length > 120
        ? '${content.substring(0, 120).trim()}…'
        : content;
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
                    color: kPrimaryBlue,
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
                          if (notice.createdAt != null &&
                              notice.createdAt!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
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

class _AcademicPerformanceFeatureCard extends StatelessWidget {
  final bool loading;
  final double? percentage;
  final String? grade;
  final String? status;
  final int? position;
  final String? academicYear;
  final VoidCallback onTap;

  const _AcademicPerformanceFeatureCard({
    required this.loading,
    required this.percentage,
    required this.grade,
    required this.status,
    required this.position,
    required this.academicYear,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = percentage != null;
    final passed = status?.toLowerCase() != 'fail';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: studentLine),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22023471),
                blurRadius: 22,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 74,
                decoration: BoxDecoration(
                  color: studentBlue,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x34023471),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Academic Performance',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: studentBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (academicYear?.isNotEmpty == true)
                          Text(
                            academicYear!,
                            style: const TextStyle(
                              color: studentMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (loading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: studentBlue,
                        ),
                      )
                    else if (available)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${percentage!.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: studentInk,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (grade?.isNotEmpty == true)
                            Text(
                              'Grade $grade',
                              style: const TextStyle(
                                color: studentBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (status?.isNotEmpty == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: passed ? studentGreen : Colors.red,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                status!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          if (position != null)
                            Text(
                              'Position $position',
                              style: const TextStyle(
                                color: studentMuted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      )
                    else
                      const Text(
                        'Performance not available yet',
                        style: TextStyle(color: studentMuted, fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Text(
                          'View performance',
                          style: TextStyle(
                            color: studentBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: studentBlue,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
    return StudentActionTile(
      icon: card.icon,
      title: card.title,
      subtitle: card.subtitle,
      accent: index.isEven ? studentBlue : studentGreen,
      onTap: () => card.onTap?.call(context),
    );
  }
}
