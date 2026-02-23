import 'package:flutter/material.dart';

// ---------- COLOR PALETTE (Only two colors) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue (KEEPING)
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green (KEEPING)

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE0E9F5); // Lighter tint of blue
const Color kSoftGreen = Color(0xFFE4F1E2); // Lighter tint of green
const Color kDarkGreen = Color(0xFF3D8C30); // Darker shade of green
const Color kDarkBlue = Color(0xFF011A3D); // Darker shade of blue
const Color kTextPrimary = Color(0xFF1A1E1F); // Darker gray for readability
const Color kTextSecondary = Color(0xFF4F5A5E); // Medium gray
const Color kSurfaceColor = Colors.white;
const Color kBackgroundColor = Color(0xFFF5F8FC); // Lighter background

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [kPrimaryBlue, kPrimaryGreen];
const List<Color> kSuccessGradient = [kPrimaryGreen, Color(0xFF6EC05C)];
const List<Color> kWarningGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];

// Dummy Data Models
class QuizResult {
  final String quizName;
  final String subject;
  final int totalMarks;
  final int obtainedMarks;
  final List<QuestionResult> questionResults;
  final String teacherRemarks;

  QuizResult({
    required this.quizName,
    required this.subject,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.questionResults,
    required this.teacherRemarks,
  });

  double get percentage =>
      totalMarks == 0 ? 0 : (obtainedMarks / totalMarks) * 100;

  bool get isPassed => percentage >= 40.0;

  String get grade {
    if (percentage >= 90) return "A+";
    if (percentage >= 80) return "A";
    if (percentage >= 70) return "B+";
    if (percentage >= 60) return "B";
    if (percentage >= 50) return "C";
    if (percentage >= 40) return "D";
    return "F";
  }

  String get performanceLevel {
    if (percentage >= 90) return "Outstanding";
    if (percentage >= 75) return "Excellent";
    if (percentage >= 60) return "Good";
    if (percentage >= 40) return "Satisfactory";
    return "Needs Improvement";
  }
}

class QuestionResult {
  final int number;
  final int obtained;
  final int max;
  final bool isCorrect;

  QuestionResult({
    required this.number,
    required this.obtained,
    required this.max,
    required this.isCorrect,
  });
}

// Dummy quiz result for demo
final QuizResult kDummyResult = QuizResult(
  quizName: "Mid-Term Mathematics Quiz",
  subject: "Mathematics",
  totalMarks: 20,
  obtainedMarks: 16,
  questionResults: [
    QuestionResult(number: 1, obtained: 2, max: 2, isCorrect: true),
    QuestionResult(number: 2, obtained: 1, max: 2, isCorrect: false),
    QuestionResult(number: 3, obtained: 2, max: 2, isCorrect: true),
    QuestionResult(number: 4, obtained: 2, max: 2, isCorrect: true),
    QuestionResult(number: 5, obtained: 2, max: 2, isCorrect: true),
    QuestionResult(number: 6, obtained: 0, max: 2, isCorrect: false),
    QuestionResult(number: 7, obtained: 2, max: 2, isCorrect: true),
    QuestionResult(number: 8, obtained: 1, max: 2, isCorrect: false),
    QuestionResult(number: 9, obtained: 2, max: 2, isCorrect: true),
    QuestionResult(number: 10, obtained: 2, max: 2, isCorrect: true),
  ],
  teacherRemarks:
      "Excellent work! Your understanding of core concepts is strong. Practice more on calculus problems to improve further.",
);

class StudentQuizResultScreen extends StatelessWidget {
  final QuizResult result;

  StudentQuizResultScreen({Key? key, QuizResult? result})
    : result = result ?? kDummyResult,
      super(key: key);

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
                                "Quiz Results",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                result.quizName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Trophy Icon
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.emoji_events_rounded,
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
                  // ---------------- ACHIEVEMENT BANNER (Redesigned) ----------------
                  _buildAchievementBanner(result),

                  const SizedBox(height: 20),

                  // ---------------- PERFORMANCE CARD (Redesigned) ----------------
                  _buildPerformanceCard(result),

                  const SizedBox(height: 20),

                  // ---------------- STATISTICS GRID (Redesigned) ----------------
                  _buildStatisticsGrid(result),

                  const SizedBox(height: 24),

                  // ---------------- SECTION HEADER (Redesigned) ----------------
                  _buildSectionHeader(
                    icon: Icons.analytics_rounded,
                    title: "Question Analysis",
                    subtitle: "Detailed breakdown of your answers",
                  ),

                  const SizedBox(height: 16),

                  // ---------------- QUESTION CARDS (Redesigned) ----------------
                  ...List.generate(
                    result.questionResults.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildQuestionCard(
                        question: result.questionResults[index],
                        index: index + 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------------- SECTION HEADER (Redesigned) ----------------
                  _buildSectionHeader(
                    icon: Icons.feedback_rounded,
                    title: "Teacher's Feedback",
                    subtitle: "Personalized remarks for improvement",
                  ),

                  const SizedBox(height: 16),

                  // ---------------- FEEDBACK CARD (Redesigned) ----------------
                  _buildFeedbackCard(result.teacherRemarks),

                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // REDESIGNED ACHIEVEMENT BANNER
  Widget _buildAchievementBanner(QuizResult result) {
    final level = result.performanceLevel;
    final color = result.percentage >= 75
        ? kPrimaryGreen
        : result.percentage >= 40
        ? kPrimaryBlue
        : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, kSoftGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: result.percentage >= 75
                    ? [kPrimaryGreen, kDarkGreen]
                    : result.percentage >= 40
                    ? [kPrimaryBlue, kDarkBlue]
                    : [Colors.redAccent, Colors.red],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              result.percentage >= 75
                  ? Icons.emoji_events_rounded
                  : result.percentage >= 40
                  ? Icons.trending_up_rounded
                  : Icons.auto_graph_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${result.percentage.toStringAsFixed(1)}% Overall Score",
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    result.isPassed ? "✅ Passed" : "⚠️ Needs Improvement",
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // REDESIGNED PERFORMANCE CARD
  Widget _buildPerformanceCard(QuizResult result) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, kSoftBlue.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          // Header with enhanced design
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
                  Icons.quiz_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.subject,
                      style: TextStyle(
                        fontSize: 14,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      result.quizName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Score and Grade - Enhanced Layout
          Row(
            children: [
              // Circular Progress with enhanced design
              Expanded(
                flex: 3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (result.isPassed ? kPrimaryGreen : kPrimaryBlue)
                                    .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        value: result.percentage / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          result.isPassed ? kPrimaryGreen : kPrimaryBlue,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${result.percentage.toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: result.isPassed
                                ? kPrimaryGreen
                                : kPrimaryBlue,
                          ),
                        ),
                        const Text(
                          "Score",
                          style: TextStyle(fontSize: 11, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Grade and Marks - Enhanced Cards
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildEnhancedInfoRow(
                      icon: Icons.grade_rounded,
                      label: "Grade",
                      value: result.grade,
                      color: kPrimaryBlue,
                      gradientColors: [kSoftBlue, kPrimaryBlue],
                    ),
                    const SizedBox(height: 12),
                    _buildEnhancedInfoRow(
                      icon: Icons.stars_rounded,
                      label: "Marks",
                      value: "${result.obtainedMarks}/${result.totalMarks}",
                      color: kPrimaryGreen,
                      gradientColors: [kSoftGreen, kPrimaryGreen],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced Info Row with better styling
  Widget _buildEnhancedInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors.map((c) => c.withOpacity(0.1)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // REDESIGNED STATISTICS GRID
  Widget _buildStatisticsGrid(QuizResult result) {
    final correct = result.questionResults.where((q) => q.isCorrect).length;
    final wrong = result.questionResults.length - correct;
    final accuracy = (correct / result.questionResults.length * 100)
        .toStringAsFixed(0);

    return Row(
      children: [
        Expanded(
          child: _buildEnhancedStatItem(
            icon: Icons.check_circle_rounded,
            value: "$correct",
            label: "Correct",
            color: kPrimaryGreen,
            bgColor: kSoftGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEnhancedStatItem(
            icon: Icons.cancel_rounded,
            value: "$wrong",
            label: "Wrong",
            color: kPrimaryBlue,
            bgColor: kSoftBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEnhancedStatItem(
            icon: Icons.trending_up_rounded,
            value: "$accuracy%",
            label: "Accuracy",
            color: kPrimaryGreen,
            bgColor: kSoftGreen,
          ),
        ),
      ],
    );
  }

  // Enhanced Stat Item with better visuals
  Widget _buildEnhancedStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: kTextSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  // REDESIGNED SECTION HEADER
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // REDESIGNED QUESTION CARD
  Widget _buildQuestionCard({
    required QuestionResult question,
    required int index,
  }) {
    final isCorrect = question.isCorrect;
    final Color cardColor = isCorrect ? kPrimaryGreen : kPrimaryBlue;

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
          color: isCorrect ? kSoftGreen : kSoftBlue,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Question Number with enhanced design
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCorrect
                          ? [kPrimaryGreen, kDarkGreen]
                          : [kPrimaryBlue, kDarkBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: cardColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "Q$index",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details with enhanced layout
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCorrect
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: cardColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCorrect ? "Correct" : "Incorrect",
                                  style: TextStyle(
                                    color: cardColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kSoftBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Max: ${question.max}",
                              style: TextStyle(
                                color: kTextSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Marks Obtained",
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "${question.obtained}/${question.max}",
                            style: TextStyle(
                              color: cardColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: question.obtained / question.max,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),

                // Arrow with enhanced design
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: cardColor,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // REDESIGNED FEEDBACK CARD
  Widget _buildFeedbackCard(String remarks) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, kSoftGreen],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Teacher's Feedback",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    remarks,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
