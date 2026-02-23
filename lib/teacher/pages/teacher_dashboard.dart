import 'package:flutter/material.dart';
import 'package:kobac/school_admin/pages/mesaage_screen.dart';
import 'package:kobac/teacher/pages/assignments_screen.dart';
import 'package:kobac/teacher/pages/attendance_mark.dart';
import 'package:kobac/teacher/pages/notices_screen.dart';
import 'package:kobac/teacher/pages/quizzes_screen.dart';
import 'package:kobac/teacher/pages/teacher_classes.dart';
import 'package:kobac/teacher/pages/teacher_drawer.dart';

// =======================
//  TEACHER DASHBOARD COLORS - MATCHING STUDENT DASHBOARD
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
const Color kCardColor = Colors.white;

/// Teacher Dashboard Screen
class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Teacher Data
  final Map<String, String> teacher = {
    'name': "Mr. Imran Yusuf",
    'role': "Mathematics Teacher",
    'avatarUrl': "",
    'initials': "MI",
  };

  final int totalClasses = 5;
  final int todayClasses = 2;
  final int totalStudents = 143;
  final int pendingTasks = 3;
  final int notificationCount = 3; // Still keeping this for other uses

  final List<Map<String, String>> todaysClasses = const [
    {
      'className': '10 A',
      'subject': 'Mathematics',
      'time': '09:00 AM - 09:45 AM',
      'notes': 'Quiz today (Ch.3)',
      'room': 'Room 201',
    },
    {
      'className': '11 B',
      'subject': 'Statistics',
      'time': '11:15 AM - 12:00 PM',
      'notes': 'Assignment solution discussion',
      'room': 'Room 305',
    },
  ];

  String _formatDate(DateTime date) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final String todayStr = _formatDate(DateTime.now());
    final bool isSmallScreen = MediaQuery.of(context).size.width < 410;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kSoftBlue,
      drawer: TeacherDrawer(teacher: teacher),
      body: Container(
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
              // Header
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
                          // Hamburger Menu Icon
                          GestureDetector(
                            onTap: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Welcome Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Welcome back! 👋",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Teacher Dashboard",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    teacher['role']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Circle Avatar - WITHOUT NOTIFICATION NUMBER
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
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: Text(
                                teacher['initials']!,
                                style: TextStyle(
                                  color: kPrimaryBlue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildStatsGrid(),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: 24)),

              // Quick Actions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryBlue, kPrimaryGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "✨ Quick Actions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "4 items",
                          style: TextStyle(
                            color: kPrimaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 16)),

              // Quick Actions Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _QuickActionCard(
                      icon: _quickActions[index]['icon'] as IconData,
                      label: _quickActions[index]['label'] as String,
                      color: _getActionColor(index),
                      onTap: () {
                        _navigateToScreen(
                          context,
                          _quickActions[index]['route'] as Widget,
                        );
                      },
                    ),
                    childCount: _quickActions.length,
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: 24)),

              // Today's Classes Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryBlue, kPrimaryGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.class_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "📚 Today's Classes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeacherMyClassesScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryGreen,
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          "View All",
                          style: TextStyle(
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

              // Today's Classes Cards
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: index == todaysClasses.length - 1 ? 12 : 12,
                    ),
                    child: _TodayClassCard(
                      classData: todaysClasses[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherMyClassesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  childCount: todaysClasses.length,
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: 24)),

              // Notices Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryBlue, kPrimaryGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "📢 Latest Notices",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeacherNoticesScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryGreen,
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          "View All",
                          style: TextStyle(
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

              // Notice Cards
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: index == _notices.length - 1 ? 80 : 12,
                    ),
                    child: _NoticeCard(
                      notice: _notices[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherNoticesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  childCount: _notices.length,
                ),
              ),
            ],
          ),
        ),
      ),

      // Chat FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryGreen,
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => MessageScreen()));
        },
        child: const Icon(
          Icons.chat_bubble_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _quickActions = [
    {
      'icon': Icons.how_to_reg_rounded,
      'label': 'Attendance',
      'route': TeacherAttendanceScreen(),
    },
    {
      'icon': Icons.assignment_rounded,
      'label': 'Assignments',
      'route': TeacherAssignmentsScreen(),
    },
    {
      'icon': Icons.quiz_rounded,
      'label': 'Quizzes',
      'route': TeacherQuizzesScreen(),
    },
    {
      'icon': Icons.campaign_rounded,
      'label': 'Notices',
      'route': TeacherNoticesScreen(),
    },
  ];

  final List<Map<String, String>> _notices = const [
    {
      'title': 'Staff Meeting',
      'description': 'Staff meeting this Friday at 2 PM in conference room',
      'time': '2 hours ago',
      'date': '12 Jun',
    },
    {
      'title': 'Exam Duty Schedule',
      'description': 'Exam duty schedule released for final term',
      'time': 'Yesterday',
      'date': '10 Jun',
    },
    {
      'title': 'New Curriculum Guidelines',
      'description': 'Updated curriculum guidelines available for download',
      'time': '2 days ago',
      'date': '08 Jun',
    },
  ];

  Color _getActionColor(int index) {
    final colors = [kPrimaryBlue, kPrimaryGreen, kSoftOrange, kDarkBlue];
    return colors[index % colors.length];
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.class_rounded,
            value: '$totalClasses',
            label: 'Total Classes',
            color: kPrimaryBlue,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.people_rounded,
            value: '$totalStudents',
            label: 'Students',
            color: kPrimaryGreen,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.today_rounded,
            value: '$todayClasses',
            label: "Today's",
            color: kSoftOrange,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.pending_actions_rounded,
            value: '$pendingTasks',
            label: 'Pending',
            color: kErrorColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade300);
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}

// Quick Action Card
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Today's Class Card
class _TodayClassCard extends StatelessWidget {
  final Map<String, String> classData;
  final VoidCallback onTap;

  const _TodayClassCard({required this.classData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryBlue, kPrimaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      classData['time']!.split(' - ')[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'to',
                      style: TextStyle(color: Colors.white70, fontSize: 8),
                    ),
                    Text(
                      classData['time']!.split(' - ')[1],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${classData['className']} - ${classData['subject']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: kTextPrimary,
                            ),
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
                            classData['room']!,
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
                    Row(
                      children: [
                        Icon(
                          Icons.note_alt_rounded,
                          size: 12,
                          color: kTextSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            classData['notes']!,
                            style: TextStyle(
                              fontSize: 11,
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
            ],
          ),
        ),
      ),
    );
  }
}

// Notice Card
class _NoticeCard extends StatelessWidget {
  final Map<String, String> notice;
  final VoidCallback onTap;

  const _NoticeCard({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: kPrimaryBlue,
                  size: 24,
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
                            notice['title']!,
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
                            notice['date']!,
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
                      notice['description']!,
                      style: TextStyle(
                        fontSize: 12,
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
                          notice['time']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: kTextSecondary.withOpacity(0.5),
                          ),
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
