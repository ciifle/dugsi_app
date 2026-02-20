import 'package:flutter/material.dart';

// ---------- COLOR PALETTE (Only two colors) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE6F0FF); // Light tint of blue
const Color kSoftGreen = Color(0xFFEDF7EB); // Light tint of green
const Color kDarkGreen = Color(
  0xFF4A8F3C,
); // Darker shade of green (adjusted from original green)
const Color kDarkBlue = Color(
  0xFF012255,
); // Darker shade of blue (adjusted from original blue)
const Color kTextPrimary = Color(0xFF2D3436); // Dark gray (keep neutral)
const Color kTextSecondary = Color(0xFF636E72); // Medium gray (keep neutral)
const Color kSurfaceColor = Colors.white;
const Color kBackgroundColor = Color(0xFFF8FAFC); // Light background

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [kPrimaryBlue, kPrimaryGreen];
const List<Color> kSuccessGradient = [
  kPrimaryGreen,
  Color(0xFF7CCF6A),
]; // Lighter green (adjusted)
const List<Color> kWarningGradient = [
  Color(0xFFF59E0B),
  Color(0xFFFBBF24),
]; // Keep amber for warning

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
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- BEAUTIFUL APP BAR ----------------
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: kPrimaryBlue,
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
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Quiz Result",
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
                    colors: [kPrimaryBlue, kPrimaryGreen],
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
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- ACHIEVEMENT BANNER ----------------
                _buildAchievementBanner(result),

                const SizedBox(height: 20),

                // ---------------- PERFORMANCE CARD ----------------
                _buildPerformanceCard(result),

                const SizedBox(height: 20),

                // ---------------- STATISTICS GRID ----------------
                _buildStatisticsGrid(result),

                const SizedBox(height: 24),

                // ---------------- SECTION HEADER ----------------
                _buildSectionHeader(
                  icon: Icons.analytics_rounded,
                  title: "Question Analysis",
                  subtitle: "Detailed breakdown of your answers",
                ),

                const SizedBox(height: 16),

                // ---------------- QUESTION CARDS ----------------
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

                // ---------------- SECTION HEADER ----------------
                _buildSectionHeader(
                  icon: Icons.feedback_rounded,
                  title: "Teacher's Feedback",
                  subtitle: "Personalized remarks for improvement",
                ),

                const SizedBox(height: 16),

                // ---------------- FEEDBACK CARD ----------------
                _buildFeedbackCard(result.teacherRemarks),

                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ACHIEVEMENT BANNER
  Widget _buildAchievementBanner(QuizResult result) {
    final level = result.performanceLevel;
    final color = result.percentage >= 75
        ? kPrimaryGreen
        : result.percentage >= 40
        ? kPrimaryBlue
        : Colors.red; // Keep red for very low scores

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.percentage >= 75
                  ? Icons.emoji_events_rounded
                  : result.percentage >= 40
                  ? Icons.trending_up_rounded
                  : Icons.auto_graph_rounded,
              color: color,
              size: 28,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You scored ${result.percentage.toStringAsFixed(1)}% overall",
                  style: TextStyle(color: kTextSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PERFORMANCE CARD
  Widget _buildPerformanceCard(QuizResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kSurfaceColor, kBackgroundColor],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.quiz_rounded, color: kPrimaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.quizName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        result.subject,
                        style: TextStyle(
                          color: kPrimaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Score and Grade
          Row(
            children: [
              // Circular Progress
              Expanded(
                flex: 3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (result.isPassed ? kPrimaryGreen : kPrimaryBlue)
                                    .withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: result.percentage / 100,
                        strokeWidth: 8,
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: result.isPassed
                                ? kPrimaryGreen
                                : kPrimaryBlue,
                          ),
                        ),
                        Text(
                          "Score",
                          style: TextStyle(fontSize: 9, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Grade and Marks
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.grade_rounded,
                      label: "Grade",
                      value: result.grade,
                      color: kPrimaryBlue,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.stars_rounded,
                      label: "Marks",
                      value: "${result.obtainedMarks}/${result.totalMarks}",
                      color: kPrimaryGreen,
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

  // STATISTICS GRID
  Widget _buildStatisticsGrid(QuizResult result) {
    final correct = result.questionResults.where((q) => q.isCorrect).length;
    final wrong = result.questionResults.length - correct;
    final accuracy = (correct / result.questionResults.length * 100)
        .toStringAsFixed(0);

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.check_circle_rounded,
            value: "$correct",
            label: "Correct",
            color: kPrimaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            icon: Icons.cancel_rounded,
            value: "$wrong",
            label: "Wrong",
            color: kPrimaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            icon: Icons.trending_up_rounded,
            value: "$accuracy%",
            label: "Accuracy",
            color: kPrimaryGreen,
          ),
        ),
      ],
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

  // SECTION HEADER
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
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
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // QUESTION CARD
  Widget _buildQuestionCard({
    required QuestionResult question,
    required int index,
  }) {
    final isCorrect = question.isCorrect;

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Question Number
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCorrect
                          ? [kPrimaryGreen, Color(0xFF7CCF6A)] // Lighter green
                          : [kPrimaryBlue, kPrimaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "$index",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Marks: ",
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "${question.obtained}/${question.max}",
                            style: TextStyle(
                              color: isCorrect ? kPrimaryGreen : kPrimaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (isCorrect ? kPrimaryGreen : kPrimaryBlue)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: isCorrect ? kPrimaryGreen : kPrimaryBlue,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCorrect ? "Correct" : "Incorrect",
                              style: TextStyle(
                                color: isCorrect ? kPrimaryGreen : kPrimaryBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: kPrimaryBlue,
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

  // FEEDBACK CARD
  Widget _buildFeedbackCard(String remarks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryBlue.withOpacity(0.05),
            kPrimaryGreen.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote_rounded,
              color: kPrimaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Feedback",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  remarks,
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 14,
                    height: 1.5,
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
