import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------- COLOR PALETTE (Matching Dashboard) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE0E9F5); // Light tint of blue
const Color kSoftGreen = Color(0xFFE4F1E2); // Light tint of green
const Color kDarkGreen = Color(0xFF3D8C30); // Darker shade of green
const Color kDarkBlue = Color(0xFF011A3D); // Darker shade of blue
const Color kSoftPurple = Color(0xFF4A6FA5); // Soft blue-purple
const Color kSoftPink = Color(0xFF7CB86E); // Soft green-pink
const Color kSoftOrange = Color(0xFFF59E0B); // Amber for warning
const Color kSuccessColor = Color(0xFF3D8C30); // Darker green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kBackgroundColor = Color(0xFFF5F8FC); // Light background
const Color kSurfaceColor = Colors.white;
const Color kTextPrimaryColor = Color(0xFF1A1E1F); // Dark slate
const Color kTextSecondaryColor = Color(0xFF4F5A5E); // Medium slate

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [kPrimaryBlue, kPrimaryGreen];
const List<Color> kSuccessGradient = [kPrimaryGreen, kDarkGreen];
const List<Color> kWarningGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];

class StudentExamScheduleScreen extends StatefulWidget {
  const StudentExamScheduleScreen({Key? key}) : super(key: key);

  @override
  State<StudentExamScheduleScreen> createState() =>
      _StudentExamScheduleScreenState();
}

class _StudentExamScheduleScreenState extends State<StudentExamScheduleScreen> {
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
      "color": kPrimaryBlue,
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
      "color": kSoftPurple,
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
      "color": kSuccessColor,
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
      "color": kSoftOrange,
    },
  ];

  DateTime? _selectedDate;

  List<Map<String, dynamic>> getFilteredExams() {
    if (_selectedDate == null) {
      return _exams;
    }

    return _exams.where((exam) {
      final examDate = exam['date'] as DateTime;
      return examDate.year == _selectedDate!.year &&
          examDate.month == _selectedDate!.month &&
          examDate.day == _selectedDate!.day;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2025, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: kTextPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Showing exams for ${DateFormat('MMMM d, yyyy').format(picked)}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: kPrimaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredExams = getFilteredExams();

    final int totalCount = filteredExams.length;
    final int upcomingCount = filteredExams
        .where((e) => e['status'] == 'Upcoming')
        .length;
    final int completedCount = filteredExams
        .where((e) => e['status'] == 'Completed')
        .length;

    // Group exams by date
    final Map<DateTime, List<Map<String, dynamic>>> examsByDate = {};
    for (final exam in filteredExams) {
      final dt = exam['date'] as DateTime;
      final grouped = DateTime(dt.year, dt.month, dt.day);
      examsByDate.putIfAbsent(grouped, () => []).add(exam);
    }

    final List<DateTime> sortedDates = examsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kSoftBlue, kSoftGreen],
          stops: [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar with Date Filter
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 40),
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
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Exam Schedule",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Upcoming Exams",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Calendar Icon
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Show active filter if date selected
                    if (_selectedDate != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filtered: ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _clearDateFilter,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats Card
                  _buildStatsCard(totalCount, upcomingCount, completedCount),

                  const SizedBox(height: 24),

                  // Exams by Date
                  if (sortedDates.isEmpty)
                    _buildEmptyState()
                  else
                    ...sortedDates.map(
                      (date) => _ExamDateSection(
                        date: date,
                        exams: examsByDate[date]!,
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stats Card
  Widget _buildStatsCard(int total, int upcoming, int completed) {
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
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryBlue, kPrimaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _selectedDate != null ? 'Filtered Overview' : 'Exam Overview',
                style: TextStyle(
                  color: kTextPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _buildEnhancedStatItem(
                icon: Icons.list_alt_rounded,
                label: "Total",
                value: "$total",
                color: kPrimaryBlue,
                bgColor: kSoftBlue,
              ),
              const SizedBox(width: 12),
              _buildEnhancedStatItem(
                icon: Icons.upcoming_rounded,
                label: "Upcoming",
                value: "$upcoming",
                color: kPrimaryGreen,
                bgColor: kSoftGreen,
              ),
              const SizedBox(width: 12),
              _buildEnhancedStatItem(
                icon: Icons.check_circle_rounded,
                label: "Completed",
                value: "$completed",
                color: kSoftOrange,
                bgColor: kSoftOrange.withOpacity(0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
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
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kSoftBlue, kSoftGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: kPrimaryBlue,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedDate != null
                  ? 'No exams on this date'
                  : 'No exams found',
              style: TextStyle(
                color: kTextPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedDate != null
                  ? 'Try selecting a different date'
                  : 'Check back later for exam schedule',
              style: TextStyle(color: kTextSecondaryColor, fontSize: 14),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _clearDateFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Clear Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Exam Date Section
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 18,
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
        ),
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

// Exam Card
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
    final Color cardColor = exam['color'] ?? kPrimaryBlue;

    String location = exam['isOnline'] ? "Online" : (exam['room'] ?? "TBA");
    IconData locationIcon = exam['isOnline']
        ? Icons.laptop_rounded
        : Icons.meeting_room_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.1),
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
            borderRadius: BorderRadius.circular(24),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cardColor, cardColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
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
                  fontSize: 22,
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
                          ? kPrimaryGreen.withOpacity(0.1)
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
                          color: isUpcoming ? kPrimaryGreen : kSoftOrange,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exam['status'],
                          style: TextStyle(
                            color: isUpcoming ? kPrimaryGreen : kSoftOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                exam['subject'],
                style: TextStyle(
                  color: cardColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kPrimaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: kPrimaryBlue,
                    ),
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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kPrimaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(locationIcon, size: 12, color: kPrimaryGreen),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        color: kTextSecondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: cardColor,
              size: 22,
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildEnhancedDetailRow(
              icon: Icons.info_outline_rounded,
              label: "Instructions",
              value: exam['instructions'],
              color: kPrimaryBlue,
            ),
            const SizedBox(height: 12),
            _buildEnhancedDetailRow(
              icon: Icons.menu_book_rounded,
              label: "Syllabus",
              value: exam['syllabus'],
              color: kPrimaryGreen,
            ),
            const SizedBox(height: 12),
            _buildEnhancedDetailRow(
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

  Widget _buildEnhancedDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: kTextPrimaryColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
