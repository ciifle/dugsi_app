import 'package:flutter/material.dart';
import 'package:kobac/student/pages/academic_activity.dart';
import 'package:kobac/student/pages/exam_schedule.dart';
import 'package:kobac/student/pages/student_attendance.dart';
import 'package:kobac/student/pages/student_fees.dart';
import 'package:kobac/student/pages/student_notices.dart';
import 'package:kobac/student/pages/student_profile.dart';
import 'package:kobac/student/pages/student_quizzes.dart';
import 'package:kobac/student/pages/student_result.dart';
import 'package:kobac/student/widgets/student_drawer.dart';
// Import the AllNoticesScreen

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

class _NoticeData {
  final String title;
  final String description;
  final String time;
  final String date;

  const _NoticeData({
    required this.title,
    required this.description,
    required this.time,
    required this.date,
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
      title: 'Results',
      subtitle: 'Academic performance',
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
      title: 'Attendance',
      subtitle: '85% this month',
      icon: Icons.calendar_month_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentAttendanceScreen()),
      ),
    ),
    _FeatureCardData(
      title: 'Academic',
      subtitle: 'Course updates',
      icon: Icons.auto_stories_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const StudentAcademicActivityScreen(),
        ),
      ),
    ),
    _FeatureCardData(
      title: 'Quizzes',
      subtitle: '2 pending',
      icon: Icons.quiz_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentQuizzesScreen()),
      ),
    ),
    _FeatureCardData(
      title: 'Exam Schedule',
      subtitle: 'Next: Math',
      icon: Icons.event_available_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StudentExamScheduleScreen()),
      ),
    ),
  ];

  final double _attendancePercent = 0.87;

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

// Dashboard Home Content
class _DashboardHomeContent extends StatefulWidget {
  const _DashboardHomeContent({Key? key}) : super(key: key);

  @override
  State<_DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<_DashboardHomeContent> {
  final double _attendancePercent = 0.87;

  final List<_FeatureCardData> _featureCards = [
    _FeatureCardData(
      title: 'Results',
      subtitle: 'Academic performance',
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
      title: 'Attendance',
      subtitle: '85% this month',
      icon: Icons.calendar_month_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentAttendanceScreen()),
      ),
    ),
    _FeatureCardData(
      title: 'Academic',
      subtitle: 'Course updates',
      icon: Icons.auto_stories_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const StudentAcademicActivityScreen(),
        ),
      ),
    ),
    _FeatureCardData(
      title: 'Quizzes',
      subtitle: '2 pending',
      icon: Icons.quiz_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentQuizzesScreen()),
      ),
    ),
    _FeatureCardData(
      title: 'Exam Schedule',
      subtitle: 'Next: Math',
      icon: Icons.event_available_rounded,
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StudentExamScheduleScreen()),
      ),
    ),
  ];

  final List<_NoticeData> _notices = const [
    _NoticeData(
      title: "🏛️ Campus Closure",
      description:
          "University will be closed for maintenance this Friday, June 12th.",
      time: "2 hours ago",
      date: "12 Jun",
    ),
    _NoticeData(
      title: "📝 Exam Registration",
      description:
          "Last date to submit exam forms is June 18th. Late fee applies after.",
      time: "Yesterday",
      date: "10 Jun",
    ),
    _NoticeData(
      title: "📚 New Arrivals",
      description: "Check out 50+ new books added to the library this week.",
      time: "2 days ago",
      date: "08 Jun",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kSoftBlue, kSoftGreen],
          stops: [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ---------------- HEADER (Blue background) ----------------
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                    stops: const [0.3, 0.7, 1.0],
                  ),
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
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Hamburger Menu Icon - Opens drawer (LEFT SIDE)
                        GestureDetector(
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Welcome Text (CENTER)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Welcome back! 👋",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Student Dashboard",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Text(
                                    "B.Tech Computer Science • 3rd Year",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Circle Avatar - Does nothing (no GestureDetector)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 32,
                            backgroundImage: AssetImage('assets/Loogo.jpeg'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- ATTENDANCE CARD ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildAttendanceCard(),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(top: 24)),

            // ---------------- FEATURES SECTION HEADER ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "✨ Quick Actions",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${_featureCards.length} items",
                        style: TextStyle(
                          color: kPrimaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 16)),

            // ---------------- FEATURE CARDS GRID ----------------
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _DashboardFeatureCard(
                    card: _featureCards[index],
                    index: index,
                  ),
                  childCount: _featureCards.length,
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(top: 24)),

            // ---------------- NOTICES SECTION HEADER ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "📢 Latest Notices",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to notices tab (index 2)
                        final parentState = context
                            .findAncestorStateOfType<
                              _StudentDashboardScreenState
                            >();
                        parentState?._onNavItemTapped(2);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimaryGreen,
                      ),
                      child: const Text(
                        "View All",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 16)),

            // ---------------- NOTICE CARDS ----------------
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: index == _notices.length - 1 ? 12 : 12,
                  ),
                  child: _NoticeCard(notice: _notices[index]),
                ),
                childCount: _notices.length,
              ),
            ),

            // ---------------- STATS CARDS AT BOTTOM ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: kPrimaryGreen.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(-5, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [kPrimaryBlue, kPrimaryGreen],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.analytics_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Academic Overview",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Stats Row
                        Row(
                          children: [
                            _buildEnhancedStatCard(
                              icon: Icons.menu_book_rounded,
                              value: "24",
                              label: "Courses",
                              color: kPrimaryBlue,
                              bgColor: kSoftBlue,
                            ),
                            const SizedBox(width: 16),
                            _buildEnhancedStatCard(
                              icon: Icons.emoji_events_rounded,
                              value: "3.8",
                              label: "CGPA",
                              color: kPrimaryGreen,
                              bgColor: kSoftGreen,
                            ),
                            const SizedBox(width: 16),
                            _buildEnhancedStatCard(
                              icon: Icons.credit_card_rounded,
                              value: "\$450",
                              label: "Due",
                              color: kDarkBlue,
                              bgColor: kSoftBlue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Progress indicator
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kPrimaryGreen.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Overall Performance",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryBlue,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  "Top 15%",
                                  style: TextStyle(
                                    color: kPrimaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, kSoftGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📊 Attendance Overview",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${(_attendancePercent * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                        height: 0.9,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "of classes\nattended",
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextSecondary,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _attendancePercent >= 0.75
                        ? kPrimaryGreen.withOpacity(0.1)
                        : kPrimaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _attendancePercent >= 0.75
                            ? Icons.check_circle_rounded
                            : Icons.trending_up_rounded,
                        color: _attendancePercent >= 0.75
                            ? kPrimaryGreen
                            : kPrimaryBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _attendancePercent >= 0.75 ? "Excellent!" : "Improving",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _attendancePercent >= 0.75
                              ? kPrimaryGreen
                              : kPrimaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _attendancePercent,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGreen),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${(_attendancePercent * 100).toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                    ),
                    const Text(
                      "present",
                      style: TextStyle(
                        fontSize: 11,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

// ---------------- NOTICE CARD ----------------
class _NoticeCard extends StatelessWidget {
  final _NoticeData notice;
  const _NoticeCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kSoftBlue, kSoftGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              notice.title.split(' ')[0],
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notice.title.substring(notice.title.indexOf(' ') + 1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: kPrimaryBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notice.date,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notice.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: kTextSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: kTextSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      notice.time,
                      style: TextStyle(
                        fontSize: 10,
                        color: kTextSecondary.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
