import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------- WONDERFUL COLOR PALETTE (Matching Dashboard) ----------
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

// Dummy Quiz Data
enum QuizStatus { upcoming, completed, missed }

class Quiz {
  final String title;
  final String subject;
  final int totalMarks;
  final int durationMinutes;
  final DateTime scheduledDateTime;
  final QuizStatus status;
  final String instructions;
  final int numberOfQuestions;
  final int passingMarks;
  final String teacherName;

  Quiz({
    required this.title,
    required this.subject,
    required this.totalMarks,
    required this.durationMinutes,
    required this.scheduledDateTime,
    required this.status,
    required this.instructions,
    required this.numberOfQuestions,
    required this.passingMarks,
    required this.teacherName,
  });
}

// Example quiz list (dummy data)
final List<Quiz> kDummyQuizzes = [
  Quiz(
    title: "Math Algebra Quiz",
    subject: "Mathematics",
    totalMarks: 20,
    durationMinutes: 30,
    scheduledDateTime: DateTime.now().add(const Duration(days: 1)),
    status: QuizStatus.upcoming,
    instructions: "Answer all questions carefully. Calculators allowed.",
    numberOfQuestions: 10,
    passingMarks: 12,
    teacherName: "Mr. Smith",
  ),
  Quiz(
    title: "English Grammar Test",
    subject: "English",
    totalMarks: 15,
    durationMinutes: 25,
    scheduledDateTime: DateTime.now().subtract(const Duration(days: 1)),
    status: QuizStatus.completed,
    instructions: "No hints. Check your spelling.",
    numberOfQuestions: 8,
    passingMarks: 8,
    teacherName: "Ms. Taylor",
  ),
  Quiz(
    title: "History Quiz - World War II",
    subject: "History",
    totalMarks: 25,
    durationMinutes: 40,
    scheduledDateTime: DateTime.now().subtract(const Duration(days: 2)),
    status: QuizStatus.missed,
    instructions: "All questions compulsory. Write concise answers.",
    numberOfQuestions: 12,
    passingMarks: 15,
    teacherName: "Mr. Lee",
  ),
  Quiz(
    title: "Science: Plant Biology",
    subject: "Science",
    totalMarks: 18,
    durationMinutes: 20,
    scheduledDateTime: DateTime.now().add(const Duration(hours: 6)),
    status: QuizStatus.upcoming,
    instructions: "Answer in your own words.",
    numberOfQuestions: 9,
    passingMarks: 10,
    teacherName: "Dr. Watson",
  ),
];

// Main Screen
class StudentQuizzesScreen extends StatefulWidget {
  const StudentQuizzesScreen({Key? key}) : super(key: key);

  @override
  State<StudentQuizzesScreen> createState() => _StudentQuizzesScreenState();
}

class _StudentQuizzesScreenState extends State<StudentQuizzesScreen>
    with SingleTickerProviderStateMixin {
  String selectedFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Quiz> getFilteredQuizzes() {
    if (selectedFilter == 'All') return List<Quiz>.from(kDummyQuizzes);
    if (selectedFilter == 'Upcoming') {
      return kDummyQuizzes
          .where((q) => q.status == QuizStatus.upcoming)
          .toList();
    }
    if (selectedFilter == 'Completed') {
      return kDummyQuizzes
          .where((q) => q.status == QuizStatus.completed)
          .toList();
    }
    if (selectedFilter == 'Missed') {
      return kDummyQuizzes.where((q) => q.status == QuizStatus.missed).toList();
    }
    return [];
  }

  int get totalQuizCount => kDummyQuizzes.length;
  int get upcomingQuizCount =>
      kDummyQuizzes.where((q) => q.status == QuizStatus.upcoming).length;
  int get completedQuizCount =>
      kDummyQuizzes.where((q) => q.status == QuizStatus.completed).length;
  int get missedQuizCount =>
      kDummyQuizzes.where((q) => q.status == QuizStatus.missed).length;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuizzes = getFilteredQuizzes();

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
            // ---------------- REDESIGNED APP BAR (Matching Dashboard) ----------------
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
                                "Quizzes",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Test Your Knowledge",
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
                        // Quiz Icon
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.quiz_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- MAIN CONTENT ----------------
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------------- REDESIGNED QUIZ SUMMARY CARD ----------------
                        _QuizSummaryCard(
                          total: totalQuizCount,
                          upcoming: upcomingQuizCount,
                          completed: completedQuizCount,
                          missed: missedQuizCount,
                        ),

                        const SizedBox(height: 20),

                        // ---------------- REDESIGNED FILTER SECTION ----------------
                        _buildFilterSection(),

                        const SizedBox(height: 24),

                        // ---------------- QUIZZES HEADER ----------------
                        _buildQuizzesHeader(filteredQuizzes.length),

                        const SizedBox(height: 16),

                        // ---------------- QUIZZES LIST ----------------
                        if (filteredQuizzes.isNotEmpty)
                          ...List.generate(
                            filteredQuizzes.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _QuizCard(quiz: filteredQuizzes[index]),
                            ),
                          )
                        else
                          _buildEmptyState(),
                      ],
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

  // REDESIGNED FILTER SECTION
  Widget _buildFilterSection() {
    final filters = ['All', 'Upcoming', 'Completed', 'Missed'];

    return Column(
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.filter_list_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Filter by Status",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              final bool isSelected = selectedFilter == filter;
              final Color filterColor = _getFilterColor(filter);

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kTextPrimaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: filterColor,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  side: BorderSide(
                    color: isSelected ? filterColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: isSelected ? 4 : 0,
                  shadowColor: filterColor.withOpacity(0.3),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // REDESIGNED QUIZZES HEADER
  Widget _buildQuizzesHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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
              Icons.assignment_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "Assigned Quizzes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextPrimaryColor,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count quiz${count != 1 ? 'zes' : ''}',
              style: TextStyle(
                color: kPrimaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // REDESIGNED EMPTY STATE
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kSoftBlue, kSoftGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: kPrimaryBlue,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No quizzes found",
              style: TextStyle(
                color: kTextPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Try selecting a different filter",
              style: TextStyle(color: kTextSecondaryColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'All':
        return kPrimaryBlue;
      case 'Upcoming':
        return kSoftOrange;
      case 'Completed':
        return kPrimaryGreen;
      case 'Missed':
        return kErrorColor;
      default:
        return kPrimaryBlue;
    }
  }
}

// ---------------- REDESIGNED QUIZ SUMMARY CARD ----------------
class _QuizSummaryCard extends StatelessWidget {
  final int total;
  final int upcoming;
  final int completed;
  final int missed;

  const _QuizSummaryCard({
    required this.total,
    required this.upcoming,
    required this.completed,
    required this.missed,
  });

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Quiz Overview',
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
                color: kSoftOrange,
                bgColor: kSoftOrange.withOpacity(0.1),
              ),
              const SizedBox(width: 12),
              _buildEnhancedStatItem(
                icon: Icons.check_circle_rounded,
                label: "Completed",
                value: "$completed",
                color: kPrimaryGreen,
                bgColor: kSoftGreen,
              ),
              const SizedBox(width: 12),
              _buildEnhancedStatItem(
                icon: Icons.warning_rounded,
                label: "Missed",
                value: "$missed",
                color: kErrorColor,
                bgColor: kErrorColor.withOpacity(0.1),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }
}

// ---------------- REDESIGNED QUIZ CARD ----------------
class _QuizCard extends StatelessWidget {
  final Quiz quiz;

  const _QuizCard({required this.quiz});

  Color get _statusColor {
    switch (quiz.status) {
      case QuizStatus.upcoming:
        return kSoftOrange;
      case QuizStatus.completed:
        return kPrimaryGreen;
      case QuizStatus.missed:
        return kErrorColor;
    }
  }

  String get _statusText {
    switch (quiz.status) {
      case QuizStatus.upcoming:
        return "Upcoming";
      case QuizStatus.completed:
        return "Completed";
      case QuizStatus.missed:
        return "Missed";
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Tomorrow";
    if (difference == -1) return "Yesterday";
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: quiz.status == QuizStatus.missed
              ? kErrorColor.withOpacity(0.3)
              : quiz.status == QuizStatus.upcoming
              ? kSoftOrange.withOpacity(0.3)
              : kPrimaryGreen.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: _statusColor.withOpacity(0.07),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_statusColor.withOpacity(0.8), _statusColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              quiz.status == QuizStatus.upcoming
                  ? Icons.access_time_rounded
                  : quiz.status == QuizStatus.completed
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
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
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _statusText,
                          style: TextStyle(
                            color: _statusColor,
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
                quiz.subject,
                style: TextStyle(
                  color: kTextSecondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                      Icons.score_rounded,
                      size: 12,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${quiz.totalMarks} marks",
                    style: TextStyle(color: kTextSecondaryColor, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kPrimaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.timer_rounded,
                      size: 12,
                      color: kPrimaryGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${quiz.durationMinutes} min",
                    style: TextStyle(color: kTextSecondaryColor, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kSoftOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: kSoftOrange,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDate(quiz.scheduledDateTime),
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
              color: _statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _statusColor,
              size: 20,
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            _QuizDetails(quiz: quiz),
            const SizedBox(height: 16),
            _QuizActionButton(quiz: quiz),
          ],
        ),
      ),
    );
  }
}

// ---------------- REDESIGNED QUIZ DETAILS ----------------
class _QuizDetails extends StatelessWidget {
  final Quiz quiz;

  const _QuizDetails({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kBackgroundColor, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildEnhancedDetailRow(
            icon: Icons.menu_book_rounded,
            label: "Instructions",
            value: quiz.instructions,
            color: kPrimaryBlue,
          ),
          const SizedBox(height: 12),
          _buildEnhancedDetailRow(
            icon: Icons.help_outline_rounded,
            label: "Questions",
            value: "${quiz.numberOfQuestions} questions",
            color: kPrimaryGreen,
          ),
          const SizedBox(height: 12),
          _buildEnhancedDetailRow(
            icon: Icons.check_circle_outline_rounded,
            label: "Passing Marks",
            value: "${quiz.passingMarks}/${quiz.totalMarks}",
            color: kSoftOrange,
          ),
          const SizedBox(height: 12),
          _buildEnhancedDetailRow(
            icon: Icons.person_rounded,
            label: "Teacher",
            value: quiz.teacherName,
            color: kSoftPurple,
          ),
        ],
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  value,
                  style: TextStyle(color: kTextPrimaryColor, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- REDESIGNED QUIZ ACTION BUTTON ----------------
class _QuizActionButton extends StatelessWidget {
  final Quiz quiz;

  const _QuizActionButton({required this.quiz});

  @override
  Widget build(BuildContext context) {
    String label;
    VoidCallback? onPressed;
    Color color;

    switch (quiz.status) {
      case QuizStatus.upcoming:
        label = "Start Quiz";
        color = kPrimaryGreen;
        onPressed = () {
          // Navigate to quiz
        };
        break;
      case QuizStatus.completed:
        label = "View Result";
        color = kPrimaryBlue;
        onPressed = () {
          // Navigate to result
        };
        break;
      case QuizStatus.missed:
        label = "Missed";
        color = kErrorColor;
        onPressed = null;
        break;
    }

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
