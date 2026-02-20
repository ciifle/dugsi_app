import 'package:flutter/material.dart';
import 'package:kobac/school_admin/pages/mesaage_screen.dart';
import 'package:kobac/services/local_auth_service.dart';
import 'package:kobac/shared/pages/login_screen.dart';
import 'package:kobac/teacher/pages/assignments_screen.dart';
import 'package:kobac/teacher/pages/attendance_mark.dart';
import 'package:kobac/teacher/pages/exams_results.dart';
import 'package:kobac/teacher/pages/notices_screen.dart';
import 'package:kobac/teacher/pages/notifications.dart';
import 'package:kobac/teacher/pages/quizzes_screen.dart';
import 'package:kobac/teacher/pages/students_screen.dart';
import 'package:kobac/teacher/pages/teacher_classes.dart';
import 'package:kobac/teacher/pages/teacher_profile.dart';
import 'package:kobac/teacher/pages/weakly_schedule.dart';

// =======================
//  TEACHER DASHBOARD COLORS - MODERN GRADIENT
// =======================
const Color kPrimaryColor = Color(0xFF2A2E45); // Deep charcoal
const Color kSecondaryColor = Color(0xFF6C5CE7); // Rich purple
const Color kAccentColor = Color(0xFF00B894); // Mint green
const Color kSoftPurple = Color(0xFFA29BFE); // Light purple
const Color kSoftPink = Color(0xFFFF7675); // Soft pink
const Color kSoftOrange = Color(0xFFFDCB6E); // Warm orange
const Color kSoftBlue = Color(0xFF74B9FF); // Sky blue
const Color kBackgroundStart = Color(0xFFE8EEF9); // Light blue-gray
const Color kBackgroundEnd = Color(0xFFF5F0FF); // Light purple
const Color kTextPrimary = Color(0xFF2D3436); // Dark gray
const Color kTextSecondary = Color(0xFF636E72); // Medium gray

/// Teacher Dashboard Screen - MERGED VERSION
class TeacherDashboardScreen extends StatefulWidget {
  TeacherDashboardScreen({Key? key}) : super(key: key);

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
  final int notificationCount = 3;

  final List<Map<String, String>> todaysClasses = const [
    {
      'className': '10 A',
      'subject': 'Mathematics',
      'time': '09:00 AM - 09:45 AM',
      'notes': 'Quiz today (Ch.3)',
      'syllabus': 'Algebraic Expressions',
      'room': 'Room 201',
    },
    {
      'className': '11 B',
      'subject': 'Statistics',
      'time': '11:15 AM - 12:00 PM',
      'notes': 'Assignment solution discussion',
      'syllabus': 'Probability Distributions',
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
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,

      // Background Gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBackgroundStart, kBackgroundEnd],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,

            // AppBar
            appBar: AppBar(
              backgroundColor: kPrimaryColor,
              elevation: 1.6,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Teacher Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              actions: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherNotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        top: 8,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: kSoftPink,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              '$notificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),

            // ==================== WONDERFUL DRAWER (NEW DESIGN) ====================
            drawer: _TeacherDrawer(teacher: teacher),

            // Body
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight - 100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Teacher Header Card
                      _TeacherHeaderCard(
                        teacher: teacher,
                        today: todayStr,
                        isSmall: isSmallScreen,
                      ),
                      const SizedBox(height: 16),

                      // Stats Grid
                      _StatsGrid(
                        totalClasses: totalClasses,
                        totalStudents: totalStudents,
                        todayClasses: todayClasses,
                        pendingTasks: pendingTasks,
                        isSmall: isSmallScreen,
                        context: context,
                      ),
                      const SizedBox(height: 16),

                      // Quick Actions
                      _QuickActionsSection(context: context),
                      const SizedBox(height: 16),

                      // Today's Classes Section
                      _TodaysClassesSection(
                        classes: todaysClasses,
                        context: context,
                      ),
                      const SizedBox(height: 16),

                      // Notices Section
                      _NoticesSection(context: context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Chat FAB
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => MessageScreen()),
                );
              },
              child: Icon(
                Icons.chat_bubble_outline,
                color: kAccentColor,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== TEACHER HEADER CARD ====================
class _TeacherHeaderCard extends StatelessWidget {
  final Map<String, String> teacher;
  final String today;
  final bool isSmall;

  const _TeacherHeaderCard({
    required this.teacher,
    required this.today,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryColor, kSecondaryColor, kSoftPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: isSmall ? 28 : 32,
              backgroundColor: Colors.white,
              child: Text(
                teacher['initials'] ??
                    (teacher['name']?.isNotEmpty == true
                        ? teacher['name']!
                              .split(' ')
                              .map((e) => e[0])
                              .take(2)
                              .join()
                        : ''),
                style: TextStyle(
                  color: kPrimaryColor,
                  fontSize: isSmall ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Teacher Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    teacher['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      teacher['role']!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        today,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
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
    );
  }
}

// ==================== STATS GRID ====================
class _StatsGrid extends StatelessWidget {
  final int totalClasses, totalStudents, todayClasses, pendingTasks;
  final bool isSmall;
  final BuildContext context;

  const _StatsGrid({
    required this.totalClasses,
    required this.totalStudents,
    required this.todayClasses,
    required this.pendingTasks,
    required this.isSmall,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: isSmall ? 1.3 : 1.5,
      children: [
        _StatCard(
          icon: Icons.class_rounded,
          label: 'Total\nClasses',
          value: '$totalClasses',
          color: kSoftPurple,
          onTap: () {
            Navigator.push(
              this.context,
              MaterialPageRoute(builder: (context) => TeacherMyClassesScreen()),
            );
          },
        ),
        _StatCard(
          icon: Icons.people_rounded,
          label: 'Total\nStudents',
          value: '$totalStudents',
          color: kSoftOrange,
          onTap: () {
            Navigator.push(
              this.context,
              MaterialPageRoute(
                builder: (context) => TeacherStudentManagementScreen(),
              ),
            );
          },
        ),
        _StatCard(
          icon: Icons.today_rounded,
          label: "Today's\nClasses",
          value: '$todayClasses',
          color: kAccentColor,
          onTap: () {
            Navigator.push(
              this.context,
              MaterialPageRoute(
                builder: (context) => TeacherWeeklyScheduleScreen(),
              ),
            );
          },
        ),
        _StatCard(
          icon: Icons.pending_actions_rounded,
          label: 'Pending\nTasks',
          value: '$pendingTasks',
          color: kSoftPink,
          onTap: () {
            Navigator.push(
              this.context,
              MaterialPageRoute(
                builder: (context) => TeacherAssignmentsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== QUICK ACTIONS ====================
class _QuickActionsSection extends StatelessWidget {
  final BuildContext context;

  const _QuickActionsSection({required this.context});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'icon': Icons.how_to_reg_rounded,
        'label': 'Take\nAttendance',
        'color': kSoftPurple,
        'route': TeacherAttendanceScreen(),
      },
      {
        'icon': Icons.assignment_rounded,
        'label': 'Create\nAssignment',
        'color': kSoftOrange,
        'route': TeacherAssignmentsScreen(),
      },
      {
        'icon': Icons.quiz_rounded,
        'label': 'Create\nQuiz',
        'color': kAccentColor,
        'route': TeacherQuizzesScreen(),
      },
      {
        'icon': Icons.campaign_rounded,
        'label': 'Publish\nNotice',
        'color': kSoftPink,
        'route': TeacherNoticesScreen(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
        ),
        Row(
          children: actions.map((action) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (action['color'] as Color).withOpacity(0.15),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        this.context,
                        MaterialPageRoute(
                          builder: (context) => action['route'] as Widget,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 2,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (action['color'] as Color).withOpacity(
                                0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              color: action['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action['label'] as String,
                            style: const TextStyle(
                              fontSize: 10,
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
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ==================== TODAY'S CLASSES ====================
class _TodaysClassesSection extends StatelessWidget {
  final List<Map<String, String>> classes;
  final BuildContext context;

  const _TodaysClassesSection({required this.classes, required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            "Today's Classes",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classData = classes[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (context) => TeacherMyClassesScreen(),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: kSoftPurple.withOpacity(0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kSoftPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.class_rounded,
                        color: kSoftPurple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                classData['className']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: kTextPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: kAccentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  classData['subject']!,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: kAccentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 10,
                                color: kTextSecondary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                classData['time']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: kTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.room, size: 10, color: kTextSecondary),
                              const SizedBox(width: 2),
                              Text(
                                classData['room'] ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.note_alt,
                                size: 10,
                                color: kTextSecondary,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  classData['notes']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: kTextSecondary,
                                  ),
                                  maxLines: 1,
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
            );
          },
        ),
      ],
    );
  }
}

// ==================== NOTICES SECTION ====================
class _NoticesSection extends StatelessWidget {
  final BuildContext context;

  const _NoticesSection({required this.context});

  final List<Map<String, String>> notices = const [
    {
      'title': 'Staff Meeting',
      'desc': 'Staff meeting this Friday at 2 PM',
      'time': '2h ago',
    },
    {
      'title': 'Exam Duty',
      'desc': 'Exam duty schedule released',
      'time': '1d ago',
    },
    {
      'title': 'New Curriculum',
      'desc': 'New guidelines available',
      'time': '2d ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Latest Notices',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final notice = notices[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (context) => TeacherNoticesScreen(),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: kSoftBlue.withOpacity(0.1), blurRadius: 5),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kSoftBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.campaign_rounded,
                        color: kSoftBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice['title']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notice['desc']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: kTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      notice['time']!,
                      style: TextStyle(fontSize: 9, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ==================== WONDERFUL DRAWER (NEW DESIGN) ====================
class _TeacherDrawer extends StatelessWidget {
  final Map<String, String> teacher;

  const _TeacherDrawer({required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, kBackgroundEnd.withOpacity(0.5)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ---------------- GLASS MORPHISM HEADER ----------------
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kPrimaryColor, kSecondaryColor, kSoftPurple],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: kSecondaryColor.withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -20,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Profile image with glow
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Text(
                                teacher['initials'] ??
                                    (teacher['name']?.isNotEmpty == true
                                        ? teacher['name']!
                                              .split(' ')
                                              .map((e) => e[0])
                                              .take(2)
                                              .join()
                                        : ''),
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            teacher['name']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
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
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---------------- MENU SECTIONS ----------------
            _buildMenuSection(
              title: "MAIN",
              items: [
                _MenuItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  color: kSoftPurple,
                ),
                _MenuItem(
                  icon: Icons.class_rounded,
                  label: 'My Classes',
                  color: kSoftBlue,
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
              items: [
                _MenuItem(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Attendance',
                  color: kAccentColor,
                ),
                _MenuItem(
                  icon: Icons.assignment_rounded,
                  label: 'Assignments',
                  color: kSoftPink,
                ),
                _MenuItem(
                  icon: Icons.quiz_rounded,
                  label: 'Quizzes',
                  color: kSoftPurple,
                ),
                _MenuItem(
                  icon: Icons.assessment_rounded,
                  label: 'Exams',
                  color: kSoftBlue,
                ),
              ],
              context: context,
            ),

            _buildMenuSection(
              title: "COMMUNICATION",
              items: [
                _MenuItem(
                  icon: Icons.campaign_rounded,
                  label: 'Notices',
                  color: kSoftOrange,
                ),
                _MenuItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                  color: kAccentColor,
                ),
                _MenuItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  color: kSoftPink,
                ),
              ],
              context: context,
            ),

            const Divider(height: 24, thickness: 1, indent: 20, endIndent: 20),

            // ---------------- LOGOUT SECTION ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await LocalAuthService().logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.1),
                          Colors.red.withOpacity(0.05),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.red,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
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
          (item) => _buildModernDrawerItem(
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

  Widget _buildModernDrawerItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, String label) {
    Widget screen;
    switch (label) {
      case 'Dashboard':
        screen = TeacherDashboardScreen();
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
