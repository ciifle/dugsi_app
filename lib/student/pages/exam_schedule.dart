import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------- WONDERFUL COLOR PALETTE ----------
const Color kPrimaryColor = Color(0xFF1E3A8A); // Deep indigo
const Color kSecondaryColor = Color(0xFF3B82F6); // Bright blue
const Color kAccentColor = Color(0xFF10B981); // Emerald green
const Color kSoftPurple = Color(0xFF8B5CF6); // Light purple
const Color kSoftPink = Color(0xFFEC4899); // Pink
const Color kSoftOrange = Color(0xFFF59E0B); // Amber
const Color kSoftBlue = Color(0xFF3B82F6); // Sky blue
const Color kSuccessColor = Color(0xFF059669); // Dark green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kBackgroundColor = Color(0xFFF8FAFC); // Light background
const Color kSurfaceColor = Colors.white;
const Color kTextPrimaryColor = Color(0xFF1E293B); // Dark slate
const Color kTextSecondaryColor = Color(0xFF64748B); // Medium slate

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [Color(0xFF1E3A8A), Color(0xFF3B82F6)];
const List<Color> kSuccessGradient = [Color(0xFF10B981), Color(0xFF34D399)];
const List<Color> kWarningGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];

class StudentExamScheduleScreen extends StatelessWidget {
  StudentExamScheduleScreen({Key? key}) : super(key: key);

  // Dummy exam data
  final List<Map<String, dynamic>> _exams = [
    {
      "name": "Midterm Examination",
      "subject": "Mathematics",
      "date": DateTime(2024, 6, 18, 9, 0),
      "endTime": DateTime(2024, 6, 18, 11, 0),
      "duration": "2h",
      "room": "Room A201",
      "isOnline": false,
      "status": "Upcoming",
      "instructions": "Arrive 10 minutes early. Bring calculator and ID card.",
      "syllabus": "Chapters 1-6: Algebra, Trigonometry, Calculus.",
      "teacher": "Ms. Evelyn Harper",
      "color": kSoftPurple,
    },
    {
      "name": "Final Exam",
      "subject": "History",
      "date": DateTime(2024, 6, 22, 14, 0),
      "endTime": DateTime(2024, 6, 22, 17, 0),
      "duration": "3h",
      "room": "Online",
      "isOnline": true,
      "status": "Upcoming",
      "instructions": "Stable internet connection required. Webcam must be ON.",
      "syllabus": "World Wars, Industrial Revolution, Colonialism.",
      "teacher": "Mr. Alan Shepherd",
      "color": kSoftBlue,
    },
    {
      "name": "Quiz 2",
      "subject": "Physics",
      "date": DateTime(2024, 5, 28, 10, 30),
      "endTime": DateTime(2024, 5, 28, 11, 30),
      "duration": "1h",
      "room": "Room B102",
      "isOnline": false,
      "status": "Completed",
      "instructions": "No electronic devices allowed.",
      "syllabus": "Chapter 4: Newton's Laws. Chapter 5: Energy.",
      "teacher": "Dr. Wendy Lin",
      "color": kSoftOrange,
    },
    {
      "name": "Assignment Assessment",
      "subject": "Computer Science",
      "date": DateTime(2024, 5, 20, 16, 0),
      "endTime": DateTime(2024, 5, 20, 17, 30),
      "duration": "1.5h",
      "room": "Online",
      "isOnline": true,
      "status": "Completed",
      "instructions":
          "Individual work only. Code must be submitted before end time.",
      "syllabus": "Unit 3: Data structures. Unit 4: Algorithms.",
      "teacher": "Ms. Rebecca Storm",
      "color": kSoftPink,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final int totalCount = _exams.length;
    final int upcomingCount = _exams
        .where((e) => e['status'] == 'Upcoming')
        .length;
    final int completedCount = _exams
        .where((e) => e['status'] == 'Completed')
        .length;

    // Group exams by date
    final Map<DateTime, List<Map<String, dynamic>>> examsByDate = {};
    for (final exam in _exams) {
      final dt = exam['date'] as DateTime;
      final grouped = DateTime(dt.year, dt.month, dt.day);
      examsByDate.putIfAbsent(grouped, () => []).add(exam);
    }

    final List<DateTime> sortedDates = examsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- STUNNING APP BAR ----------------
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Exam Schedule",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryColor, kSecondaryColor],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- STATS CARD ----------------
                _buildStatsCard(totalCount, upcomingCount, completedCount),

                const SizedBox(height: 24),

                // ---------------- EXAMS BY DATE ----------------
                ...sortedDates.map(
                  (date) =>
                      _ExamDateSection(date: date, exams: examsByDate[date]!),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int total, int upcoming, int completed) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSoftPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: kSoftPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Exam Overview',
                style: TextStyle(
                  color: kTextPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.list_alt_rounded,
                label: "Total",
                value: "$total",
                color: kSoftPurple,
              ),
              _buildStatItem(
                icon: Icons.upcoming_rounded,
                label: "Upcoming",
                value: "$upcoming",
                color: kSuccessColor,
              ),
              _buildStatItem(
                icon: Icons.check_circle_rounded,
                label: "Completed",
                value: "$completed",
                color: kSoftOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
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
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: kTextSecondaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- EXAM DATE SECTION ----------------
class _ExamDateSection extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> exams;

  const _ExamDateSection({required this.date, required this.exams});

  String get _formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.isAtSameMomentAs(today)) return "Today";
    if (date.isAtSameMomentAs(tomorrow)) return "Tomorrow";
    if (date.isAtSameMomentAs(yesterday)) return "Yesterday";

    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kSoftOrange, kSoftPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formattedDate,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...exams.map(
          (exam) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ExamCard(exam: exam),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ---------------- EXAM CARD ----------------
class _ExamCard extends StatelessWidget {
  final Map<String, dynamic> exam;

  const _ExamCard({required this.exam});

  String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime date = exam['date'];
    final DateTime? endTime = exam['endTime'];
    final bool isUpcoming = exam['status'] == 'Upcoming';
    final Color cardColor = exam['color'] ?? kSoftPurple;

    String location = exam['isOnline'] ? "Online" : (exam['room'] ?? "TBA");
    IconData locationIcon = exam['isOnline']
        ? Icons.laptop_rounded
        : Icons.meeting_room_rounded;

    return Container(
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isUpcoming ? cardColor.withOpacity(0.3) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: cardColor.withOpacity(0.07),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cardColor, cardColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                exam['subject'][0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exam['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextPrimaryColor,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isUpcoming
                          ? kSuccessColor.withOpacity(0.1)
                          : kSoftOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUpcoming
                              ? Icons.access_time_rounded
                              : Icons.check_circle_rounded,
                          color: isUpcoming ? kSuccessColor : kSoftOrange,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exam['status'],
                          style: TextStyle(
                            color: isUpcoming ? kSuccessColor : kSoftOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                exam['subject'],
                style: TextStyle(
                  color: cardColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: kTextSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(date),
                    style: TextStyle(color: kTextSecondaryColor, fontSize: 12),
                  ),
                  if (endTime != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      "- ${_formatTime(endTime)}",
                      style: TextStyle(
                        color: kTextSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  Icon(locationIcon, size: 14, color: kTextSecondaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        color: kTextSecondaryColor,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: cardColor,
            size: 24,
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.info_outline_rounded,
              label: "Instructions",
              value: exam['instructions'],
              color: kSoftBlue,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.menu_book_rounded,
              label: "Syllabus",
              value: exam['syllabus'],
              color: kSoftPurple,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.person_rounded,
              label: "Teacher",
              value: exam['teacher'],
              color: kSoftOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: kTextSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(color: kTextPrimaryColor, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
