import 'package:flutter/material.dart';

// ---------- WONDERFUL COLOR PALETTE (Matching Student Dashboard) ----------
const Color kPrimaryColor = Color(0xFF2A2E45); // Deep charcoal
const Color kSecondaryColor = Color(0xFF6C5CE7); // Rich purple
const Color kAccentColor = Color(0xFF00B894); // Mint green
const Color kSoftPurple = Color(0xFFA29BFE); // Light purple
const Color kSoftPink = Color(0xFFFF7675); // Soft pink
const Color kSoftOrange = Color(0xFFFDCB6E); // Warm orange
const Color kSoftBlue = Color(0xFF74B9FF); // Sky blue
const Color kBackgroundStart = Color(0xFFE8EEF9); // Light blue-gray
const Color kBackgroundEnd = Color(0xFFF5F0FF); // Light purple
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF2D3436); // Dark gray
const Color kTextSecondary = Color(0xFF636E72); // Medium gray

class TeacherWeeklyScheduleScreen extends StatefulWidget {
  const TeacherWeeklyScheduleScreen({Key? key}) : super(key: key);

  @override
  State<TeacherWeeklyScheduleScreen> createState() =>
      _TeacherWeeklyScheduleScreenState();
}

class _TeacherWeeklyScheduleScreenState
    extends State<TeacherWeeklyScheduleScreen> {
  final List<String> daysOfWeek = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  int selectedDayIndex = DateTime.now().weekday % 7; // Monday=0, Sunday=6
  int notificationCount = 3; // Dummy notification count

  // Dummy schedule data with VALID Flutter icons
  final Map<String, List<Map<String, dynamic>>> weeklySchedule = {
    'Mon': [
      {
        "class": "Grade 10-A",
        "subject": "Mathematics",
        "time": "08:00 - 09:30",
        "room": "101",
        "icon": Icons.calculate_rounded,
      },
      {
        "class": "Grade 11-B",
        "subject": "Algebra II",
        "time": "10:00 - 11:30",
        "room": "210",
        "icon": Icons.functions_rounded,
      },
    ],
    'Tue': [
      {
        "class": "Grade 12-C",
        "subject": "Calculus",
        "time": "09:00 - 10:30",
        "room": "305",
        "icon": Icons.show_chart_rounded,
      },
    ],
    'Wed': [
      {
        "class": "Grade 9-A",
        "subject": "Geometry",
        "time": "08:00 - 09:30",
        "room": "114",
        "icon": Icons.category_rounded,
      },
      {
        "class": "Grade 10-A",
        "subject": "Trigonometry",
        "time": "11:00 - 12:30",
        "room": "102",
        "icon": Icons.change_circle_rounded,
      },
    ],
    'Thu': [
      {
        "class": "Grade 11-B",
        "subject": "Pre-Calculus",
        "time": "10:00 - 11:30",
        "room": "209",
        "icon": Icons.insights_rounded,
      },
    ],
    'Fri': [
      {
        "class": "Grade 9-A",
        "subject": "Statistics",
        "time": "09:00 - 10:30",
        "room": "115",
        "icon": Icons.bar_chart_rounded,
      },
      {
        "class": "Grade 12-C",
        "subject": "Advanced Calculus",
        "time": "12:00 - 13:30",
        "room": "304",
        "icon": Icons.auto_graph_rounded,
      },
    ],
    'Sat': [],
    'Sun': [],
  };

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _NotificationSheet(notificationCount: notificationCount),
    );
  }

  Color _getDayColor(String day) {
    switch (day) {
      case 'Mon':
        return kSoftPurple;
      case 'Tue':
        return kSoftBlue;
      case 'Wed':
        return kAccentColor;
      case 'Thu':
        return kSoftOrange;
      case 'Fri':
        return kSoftPink;
      default:
        return kSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = daysOfWeek[selectedDayIndex];
    final daySchedule = weeklySchedule[selectedDay] ?? [];

    return Scaffold(
      backgroundColor: kBackgroundEnd,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR (SMALLER SIZE) ----------------
          SliverAppBar(
            expandedHeight: 90, // REDUCED from 120
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 16,
                bottom: 10,
              ), // REDUCED padding
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5), // REDUCED padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8), // REDUCED radius
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 16, // REDUCED icon size
                    ),
                  ),
                  const SizedBox(width: 6), // REDUCED spacing
                  const Text(
                    "Weekly Schedule",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // REDUCED font size
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryColor, kSecondaryColor, kSoftPurple],
                    stops: const [0.1, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ), // REDUCED size
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // ---------------- WORKING NOTIFICATION ICON ----------------
              Container(
                margin: const EdgeInsets.only(right: 12), // REDUCED margin
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 18,
                      ), // REDUCED size
                      onPressed: _showNotifications,
                      padding: const EdgeInsets.all(6), // REDUCED padding
                      constraints: const BoxConstraints(),
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: kSoftPink,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Center(
                            child: Text(
                              '$notificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16), // REDUCED from 20
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- DAY SELECTOR SECTION ----------------
                _buildDaySelector(),

                const SizedBox(height: 20), // REDUCED from 24
                // ---------------- SCHEDULE HEADER ----------------
                _buildScheduleHeader(selectedDay, daySchedule.length),

                const SizedBox(height: 14), // REDUCED from 16
                // ---------------- CLASS CARDS ----------------
                if (daySchedule.isEmpty)
                  _buildEmptyState()
                else
                  ...List.generate(
                    daySchedule.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                      ), // REDUCED from 16
                      child: _ClassCard(classData: daySchedule[index]),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4), // REDUCED padding
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6), // REDUCED radius
              ),
              child: const Icon(
                Icons.calendar_view_day_rounded,
                color: kSoftPurple,
                size: 14, // REDUCED icon size
              ),
            ),
            const SizedBox(width: 6), // REDUCED spacing
            const Text(
              "Select Day",
              style: TextStyle(
                fontSize: 13, // REDUCED font size
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10), // REDUCED from 12
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(daysOfWeek.length, (index) {
              final day = daysOfWeek[index];
              final bool isSelected = selectedDayIndex == index;
              final Color dayColor = _getDayColor(day);

              return Padding(
                padding: const EdgeInsets.only(right: 6), // REDUCED spacing
                child: FilterChip(
                  label: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11, // REDUCED font size
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedDayIndex = index;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: dayColor,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // REDUCED radius
                  ),
                  side: BorderSide(
                    color: isSelected ? dayColor : Colors.grey.shade300,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ), // REDUCED padding
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleHeader(String day, int count) {
    final dayColor = _getDayColor(day);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4), // REDUCED padding
              decoration: BoxDecoration(
                color: dayColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6), // REDUCED radius
              ),
              child: Text(
                day,
                style: TextStyle(
                  color: dayColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // REDUCED font size
                ),
              ),
            ),
            const SizedBox(width: 6), // REDUCED spacing
            Text(
              "Schedule",
              style: const TextStyle(
                fontSize: 14, // REDUCED font size
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ), // REDUCED padding
          decoration: BoxDecoration(
            color: kSoftPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16), // REDUCED radius
          ),
          child: Text(
            '$count class${count != 1 ? 'es' : ''}',
            style: TextStyle(
              color: kSoftPurple,
              fontWeight: FontWeight.w600,
              fontSize: 10, // REDUCED font size
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30), // REDUCED padding
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12), // REDUCED padding
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: kSoftPurple,
                size: 36, // REDUCED icon size
              ),
            ),
            const SizedBox(height: 12), // REDUCED spacing
            const Text(
              "No classes scheduled",
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 14, // REDUCED font size
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Enjoy your day off!",
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 12, // REDUCED font size
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- CLASS CARD ----------------
class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;

  const _ClassCard({required this.classData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // REDUCED radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10, // REDUCED blur
            offset: const Offset(0, 3), // REDUCED offset
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14), // REDUCED padding
        child: Row(
          children: [
            // Left side - Icon with gradient
            Container(
              width: 42, // REDUCED size
              height: 42, // REDUCED size
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kSoftPurple, kSoftBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12), // REDUCED radius
                boxShadow: [
                  BoxShadow(
                    color: kSoftPurple.withOpacity(0.3),
                    blurRadius: 5, // REDUCED blur
                    offset: const Offset(0, 2), // REDUCED offset
                  ),
                ],
              ),
              child: Icon(
                classData['icon'] ?? Icons.class_rounded,
                color: Colors.white,
                size: 22, // REDUCED icon size
              ),
            ),
            const SizedBox(width: 12), // REDUCED spacing
            // Right side - Class details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    classData['class'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                      fontSize: 14, // REDUCED font size
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3), // REDUCED spacing
                  Text(
                    classData['subject'],
                    style: TextStyle(
                      color: kSoftPurple,
                      fontSize: 12, // REDUCED font size
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6), // REDUCED spacing
                  Wrap(
                    spacing: 12, // REDUCED spacing
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: kTextSecondary,
                          ), // REDUCED size
                          const SizedBox(width: 3), // REDUCED spacing
                          Text(
                            classData['time'],
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 11, // REDUCED font size
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8), // REDUCED spacing
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.meeting_room_rounded,
                            size: 12,
                            color: kTextSecondary,
                          ), // REDUCED size
                          const SizedBox(width: 3), // REDUCED spacing
                          Text(
                            "Room ${classData['room']}",
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 11, // REDUCED font size
                            ),
                          ),
                        ],
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

// ---------------- NOTIFICATION SHEET ----------------
class _NotificationSheet extends StatelessWidget {
  final int notificationCount;

  const _NotificationSheet({required this.notificationCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kSoftPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: kSoftPurple,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kSoftPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$notificationCount new',
                    style: TextStyle(
                      color: kSoftPink,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Notifications list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notificationCount,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBackgroundEnd,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kSoftPurple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_rounded,
                            color: kSoftPurple,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notification ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'This is a sample notification message.',
                                style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 11,
                                ),
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
          ),
        ],
      ),
    );
  }
}
