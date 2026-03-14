import 'package:flutter/material.dart';
import 'package:kobac/services/teacher_service.dart';

// ---------- COLOR PALETTE (Matching Student Dashboard) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE6F0FF); // Light tint of blue
const Color kSoftGreen = Color(0xFFEDF7EB); // Light tint of green
const Color kDarkGreen = Color(0xFF3A7A30); // Darker shade of green
const Color kDarkBlue = Color(0xFF01255C); // Darker shade of blue
const Color kTextPrimary = Color(0xFF2D3436); // Dark gray
const Color kTextSecondary = Color(0xFF636E72); // Medium gray
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kSoftOrange = Color(0xFFF59E0B); // Amber
const Color kSuccessColor = Color(0xFF5AB04B); // Green for present
const Color kCardColor = Colors.white;

/// Normalize API day string to short form (Mon, Tue, ... Sun).
String _normalizeDay(String day) {
  final d = day.trim().toLowerCase();
  if (d.startsWith('mon')) return 'Mon';
  if (d.startsWith('tue')) return 'Tue';
  if (d.startsWith('wed')) return 'Wed';
  if (d.startsWith('thu')) return 'Thu';
  if (d.startsWith('fri')) return 'Fri';
  if (d.startsWith('sat')) return 'Sat';
  if (d.startsWith('sun')) return 'Sun';
  return day;
}

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
  int notificationCount = 0;

  /// Timetable from GET /api/teacher/dashboard; key = normalized day (Mon..Sun).
  Map<String, List<TeacherTimetableEntryModel>> _scheduleByDay = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() {
      _loading = true;
      _error = null;
      _scheduleByDay = {};
    });
    final result = await TeacherService().getDashboard();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is TeacherSuccess<TeacherDashboardModel>) {
        final timetables = result.data.timetables;
        final byDay = <String, List<TeacherTimetableEntryModel>>{};
        for (final d in daysOfWeek) {
          byDay[d] = [];
        }
        for (final t in timetables) {
          final day = _normalizeDay(t.day);
          if (byDay.containsKey(day)) {
            byDay[day]!.add(t);
          } else {
            byDay[day] = [t];
          }
        }
        _scheduleByDay = byDay;
        _error = null;
      } else {
        _error = (result as TeacherError).message;
      }
    });
  }

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
        return kPrimaryBlue;
      case 'Tue':
        return kPrimaryGreen;
      case 'Wed':
        return kSoftOrange;
      case 'Thu':
        return kDarkBlue;
      case 'Fri':
        return kPrimaryBlue;
      default:
        return kPrimaryGreen;
    }
  }

  List<Map<String, dynamic>> _dayScheduleFor(String day) {
    final list = _scheduleByDay[day] ?? [];
    return list.map((t) => {
      'class': t.classDisplayName,
      'subject': t.subjectDisplayName,
      'time': t.timeRange,
      'room': '—',
      'icon': Icons.class_rounded,
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = daysOfWeek[selectedDayIndex];
    final daySchedule = _loading || _error != null ? <Map<String, dynamic>>[] : _dayScheduleFor(selectedDay);

    if (_loading) {
      return Scaffold(
        backgroundColor: kSoftBlue,
        body: const Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: kSoftBlue,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 56, color: kTextSecondary),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: kTextPrimary)),
                const SizedBox(height: 24),
                TextButton.icon(onPressed: _loadTimetable, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'), style: TextButton.styleFrom(foregroundColor: kPrimaryBlue)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kSoftBlue,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR WITH GRADIENT ----------------
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: kPrimaryBlue,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                  stops: const [0.3, 0.7, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(bottom: 20),
                centerTitle: true,
                title: const Text(
                  "Weekly Schedule",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.only(left: 12, top: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(10),
              ),
            ),
            actions: [
              // ---------------- WORKING NOTIFICATION ICON ----------------
              Container(
                margin: const EdgeInsets.only(right: 12, top: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _showNotifications,
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(),
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: kErrorColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '$notificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- DAY SELECTOR SECTION ----------------
                _buildDaySelector(),

                const SizedBox(height: 20),

                // ---------------- SCHEDULE HEADER ----------------
                _buildScheduleHeader(selectedDay, daySchedule.length),

                const SizedBox(height: 16),

                // ---------------- CLASS CARDS ----------------
                if (daySchedule.isEmpty)
                  _buildEmptyState()
                else
                  ...List.generate(
                    daySchedule.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryBlue, kPrimaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_view_day_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Select Day",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(daysOfWeek.length, (index) {
              final day = daysOfWeek[index];
              final bool isSelected = selectedDayIndex == index;
              final Color dayColor = _getDayColor(day);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(
                    color: isSelected ? dayColor : Colors.grey.shade300,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryBlue, kPrimaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                day,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Schedule",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kPrimaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count class${count != 1 ? 'es' : ''}',
            style: TextStyle(
              color: kPrimaryGreen,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSoftBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: kPrimaryBlue,
                size: 56,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "No classes scheduled",
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Enjoy your day off!",
              style: TextStyle(color: kTextSecondary, fontSize: 14),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left side - Icon with gradient
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryBlue, kPrimaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                classData['icon'] ?? Icons.class_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Right side - Class details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          classData['class'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                            fontSize: 16,
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
                          classData['subject'],
                          style: TextStyle(
                            color: kPrimaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: kPrimaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: kPrimaryBlue,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            classData['time'],
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: kSoftOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.meeting_room_rounded,
                              size: 14,
                              color: kSoftOrange,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Room ${classData['room']}",
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
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
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, kPrimaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kErrorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$notificationCount new',
                    style: TextStyle(
                      color: kErrorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Notifications list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notificationCount,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kSoftBlue,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.info_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notification ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'This is a sample notification message.',
                                style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 12,
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
