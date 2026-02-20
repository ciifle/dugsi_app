import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------- WONDERFUL COLOR PALETTE (Matching Dashboard) ----------
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

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- STUNNING APP BAR ----------------
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.quiz_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Quizzes",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------------- QUIZ SUMMARY CARD ----------------
                      _QuizSummaryCard(
                        total: totalQuizCount,
                        upcoming: upcomingQuizCount,
                        completed: completedQuizCount,
                        missed: missedQuizCount,
                      ),

                      const SizedBox(height: 20),

                      // ---------------- FILTER SECTION ----------------
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
    );
  }

  Widget _buildFilterSection() {
    final filters = ['All', 'Upcoming', 'Completed', 'Missed'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.filter_list_rounded,
                color: kSoftPurple,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Filter by Status",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              final bool isSelected = selectedFilter == filter;
              final Color filterColor = _getFilterColor(filter);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
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
                  backgroundColor: kSurfaceColor,
                  selectedColor: filterColor,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(
                    color: isSelected ? filterColor : Colors.grey.shade300,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizzesHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kSoftOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.assignment_rounded,
                color: kSoftOrange,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Assigned Quizzes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextPrimaryColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kSoftPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count quiz${count != 1 ? 'zes' : ''}',
            style: TextStyle(
              color: kSoftPurple,
              fontWeight: FontWeight.w600,
              fontSize: 11,
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
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: kSoftPurple,
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
        return kSoftPurple;
      case 'Upcoming':
        return kSoftBlue;
      case 'Completed':
        return kSuccessColor;
      case 'Missed':
        return kErrorColor;
      default:
        return kSecondaryColor;
    }
  }
}

// ---------------- QUIZ SUMMARY CARD ----------------
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
                'Quiz Overview',
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
                color: kSoftBlue,
              ),
              _buildStatItem(
                icon: Icons.check_circle_rounded,
                label: "Completed",
                value: "$completed",
                color: kSuccessColor,
              ),
              _buildStatItem(
                icon: Icons.warning_rounded,
                label: "Missed",
                value: "$missed",
                color: kErrorColor,
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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

// ---------------- QUIZ CARD ----------------
class _QuizCard extends StatelessWidget {
  final Quiz quiz;

  const _QuizCard({required this.quiz});

  Color get _statusColor {
    switch (quiz.status) {
      case QuizStatus.upcoming:
        return kSoftBlue;
      case QuizStatus.completed:
        return kSuccessColor;
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
          color: quiz.status == QuizStatus.missed
              ? kErrorColor.withOpacity(0.2)
              : Colors.grey.shade100,
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
            borderRadius: BorderRadius.circular(20),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: Container(
            width: 48,
            height: 48,
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
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
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
                quiz.subject,
                style: TextStyle(color: kTextSecondaryColor, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.score_rounded,
                    size: 14,
                    color: kTextSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${quiz.totalMarks} marks",
                    style: TextStyle(color: kTextSecondaryColor, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.timer_rounded,
                    size: 14,
                    color: kTextSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${quiz.durationMinutes} min",
                    style: TextStyle(color: kTextSecondaryColor, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: kTextSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDate(quiz.scheduledDateTime),
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
            color: _statusColor,
            size: 22,
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            _QuizDetails(quiz: quiz),
            const SizedBox(height: 16),
            _QuizActionButton(quiz: quiz),
          ],
        ),
      ),
    );
  }
}

// ---------------- QUIZ DETAILS ----------------
class _QuizDetails extends StatelessWidget {
  final Quiz quiz;

  const _QuizDetails({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.menu_book_rounded,
            label: "Instructions",
            value: quiz.instructions,
            color: kSoftPurple,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.help_outline_rounded,
            label: "Questions",
            value: "${quiz.numberOfQuestions} questions",
            color: kSoftBlue,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.check_circle_outline_rounded,
            label: "Passing Marks",
            value: "${quiz.passingMarks}/${quiz.totalMarks}",
            color: kSuccessColor,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.person_rounded,
            label: "Teacher",
            value: quiz.teacherName,
            color: kSoftOrange,
          ),
        ],
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
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: kTextSecondaryColor,
                  fontSize: 11,
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

// ---------------- QUIZ ACTION BUTTON ----------------
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
        color = kSuccessColor;
        onPressed = () {
          // Navigate to quiz
        };
        break;
      case QuizStatus.completed:
        label = "View Result";
        color = kSoftPurple;
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
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
