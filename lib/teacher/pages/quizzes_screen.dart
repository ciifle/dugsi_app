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
const Color kTextSecondary = Color(0xFF64748B); // Medium slate

// ================================
// QUIZ MODELS + DUMMY DATA
// ================================
enum QuizStatus { active, completed, draft }

class Quiz {
  final String id;
  final String title;
  final String className;
  final String subject;
  final int totalQuestions;
  final String timeLimit;
  final QuizStatus status;
  final String instructions;
  final String scoringRules;
  final String? notes;
  final IconData icon;

  Quiz({
    required this.id,
    required this.title,
    required this.className,
    required this.subject,
    required this.totalQuestions,
    required this.timeLimit,
    required this.status,
    required this.instructions,
    required this.scoringRules,
    this.notes,
    required this.icon,
  });
}

final List<Quiz> dummyQuizzes = [
  Quiz(
    id: 'q1',
    title: 'Mid-Term Algebra Quiz',
    className: 'Class 9A',
    subject: 'Mathematics',
    totalQuestions: 15,
    timeLimit: '40 min',
    status: QuizStatus.active,
    instructions:
        'Answer all questions. No calculators allowed. Read each question carefully.',
    scoringRules: '1 mark for each correct answer. No negative marking.',
    notes: 'Review trigonometry basics before quiz.',
    icon: Icons.calculate_rounded,
  ),
  Quiz(
    id: 'q2',
    title: 'Periodic Table Assessment',
    className: 'Class 9B',
    subject: 'Science',
    totalQuestions: 10,
    timeLimit: '25 min',
    status: QuizStatus.completed,
    instructions: 'Multiple choice format. Choose the most appropriate answer.',
    scoringRules: 'Correct = 2 marks. Incorrect = 0 marks.',
    notes: null,
    icon: Icons.science_rounded,
  ),
  Quiz(
    id: 'q3',
    title: 'Grammar Check',
    className: 'Class 8A',
    subject: 'English',
    totalQuestions: 20,
    timeLimit: '30 min',
    status: QuizStatus.draft,
    instructions: 'Fill in the blanks, and rewrite sentences as instructed.',
    scoringRules: 'Each correct blank = 0.5 mark.',
    notes: 'Remind students about subject-verb agreement rules.',
    icon: Icons.menu_book_rounded,
  ),
  Quiz(
    id: 'q4',
    title: 'Geography Map Lab',
    className: 'Class 10C',
    subject: 'Geography',
    totalQuestions: 5,
    timeLimit: '20 min',
    status: QuizStatus.active,
    instructions: 'Label the map features as per instructions.',
    scoringRules: 'Each correct label = 2 marks.',
    notes: null,
    icon: Icons.map_rounded,
  ),
  Quiz(
    id: 'q5',
    title: 'Chapter 4 Physics Quiz',
    className: 'Class 10B',
    subject: 'Physics',
    totalQuestions: 12,
    timeLimit: '35 min',
    status: QuizStatus.completed,
    instructions: 'Attempt all questions. Diagrams are not mandatory.',
    scoringRules: 'Each correct = 1 mark.',
    notes: null,
    icon: Icons.bolt_rounded,
  ),
];

// =============================================================
// MAIN SCREEN WIDGET: TeacherQuizzesScreen
// =============================================================
class TeacherQuizzesScreen extends StatefulWidget {
  const TeacherQuizzesScreen({Key? key}) : super(key: key);

  @override
  State<TeacherQuizzesScreen> createState() => _TeacherQuizzesScreenState();
}

class _TeacherQuizzesScreenState extends State<TeacherQuizzesScreen> {
  String _selectedFilter = 'All';

  List<Quiz> get filteredQuizzes {
    switch (_selectedFilter) {
      case 'Active':
        return dummyQuizzes
            .where((q) => q.status == QuizStatus.active)
            .toList();
      case 'Completed':
        return dummyQuizzes
            .where((q) => q.status == QuizStatus.completed)
            .toList();
      case 'Draft':
        return dummyQuizzes.where((q) => q.status == QuizStatus.draft).toList();
      default:
        return dummyQuizzes;
    }
  }

  Color _getStatusColor(QuizStatus status) {
    switch (status) {
      case QuizStatus.active:
        return kSoftBlue;
      case QuizStatus.completed:
        return kAccentColor;
      case QuizStatus.draft:
        return kSoftOrange;
    }
  }

  String _getStatusText(QuizStatus status) {
    switch (status) {
      case QuizStatus.active:
        return 'Active';
      case QuizStatus.completed:
        return 'Completed';
      case QuizStatus.draft:
        return 'Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredQuizzes;

    return Scaffold(
      backgroundColor: kBackgroundEnd,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR (SMALLER SIZE, NO SEARCH) ----------------
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
                      Icons.quiz_rounded,
                      color: Colors.white,
                      size: 16, // REDUCED icon size
                    ),
                  ),
                  const SizedBox(width: 6), // REDUCED spacing
                  const Text(
                    "Quizzes",
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
            // NO SEARCH ICON - REMOVED
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16), // REDUCED from 20
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- SUMMARY CARD ----------------
                _QuizSummaryCard(quizzes: dummyQuizzes),

                const SizedBox(height: 20), // REDUCED from 24
                // ---------------- FILTER SECTION ----------------
                _buildFilterSection(),

                const SizedBox(height: 16), // REDUCED from 20
                // ---------------- QUIZZES HEADER ----------------
                _buildQuizzesHeader(filtered.length),

                const SizedBox(height: 12), // REDUCED from 16
                // ---------------- QUIZ CARDS ----------------
                if (filtered.isNotEmpty)
                  ...List.generate(
                    filtered.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                      ), // REDUCED from 16
                      child: _QuizCard(quiz: filtered[index]),
                    ),
                  )
                else
                  _buildEmptyState(),

                const SizedBox(height: 20), // REDUCED from 24
                // ---------------- CREATE BUTTON ----------------
                _CreateQuizCTAButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Create New Quiz"),
                        backgroundColor: kAccentColor,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16), // REDUCED from 20
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = ['All', 'Active', 'Completed', 'Draft'];

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
                Icons.filter_list_rounded,
                color: kSoftPurple,
                size: 14, // REDUCED icon size
              ),
            ),
            const SizedBox(width: 6), // REDUCED spacing
            const Text(
              "Filter by Status",
              style: TextStyle(
                fontSize: 13, // REDUCED font size
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // REDUCED from 12
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              final bool isSelected = _selectedFilter == filter;
              final Color filterColor = _getFilterColor(filter);

              return Padding(
                padding: const EdgeInsets.only(right: 6), // REDUCED spacing
                child: FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11, // REDUCED font size
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: filterColor,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // REDUCED radius
                  ),
                  side: BorderSide(
                    color: isSelected ? filterColor : Colors.grey.shade300,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ), // REDUCED padding
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              padding: const EdgeInsets.all(4), // REDUCED padding
              decoration: BoxDecoration(
                color: kSoftOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6), // REDUCED radius
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: kSoftOrange,
                size: 14, // REDUCED icon size
              ),
            ),
            const SizedBox(width: 6), // REDUCED spacing
            const Text(
              "Quiz List",
              style: TextStyle(
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
            '$count items',
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
                Icons.quiz_rounded,
                color: kSoftPurple,
                size: 36, // REDUCED icon size
              ),
            ),
            const SizedBox(height: 12), // REDUCED spacing
            const Text(
              'No quizzes',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 14, // REDUCED font size
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create your first quiz',
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

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'All':
        return kSoftPurple;
      case 'Active':
        return kSoftBlue;
      case 'Completed':
        return kAccentColor;
      case 'Draft':
        return kSoftOrange;
      default:
        return kSecondaryColor;
    }
  }
}

// ---------------- SUMMARY CARD ----------------
class _QuizSummaryCard extends StatelessWidget {
  final List<Quiz> quizzes;
  const _QuizSummaryCard({required this.quizzes});

  @override
  Widget build(BuildContext context) {
    int total = quizzes.length;
    int active = quizzes.where((q) => q.status == QuizStatus.active).length;
    int completed = quizzes
        .where((q) => q.status == QuizStatus.completed)
        .length;

    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // REDUCED radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15, // REDUCED blur
            offset: const Offset(0, 5), // REDUCED offset
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ), // REDUCED border width
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // REDUCED padding
                decoration: BoxDecoration(
                  color: kSoftPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: kSoftPurple,
                  size: 16,
                ), // REDUCED icon size
              ),
              const SizedBox(width: 8), // REDUCED spacing
              const Text(
                'Quiz Overview',
                style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15, // REDUCED font size
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // REDUCED from 20
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
                icon: Icons.flash_on_rounded,
                label: "Active",
                value: "$active",
                color: kSoftBlue,
              ),
              _buildStatItem(
                icon: Icons.check_circle_rounded,
                label: "Completed",
                value: "$completed",
                color: kAccentColor,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4), // REDUCED padding
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 12), // REDUCED icon size
          ),
          const SizedBox(height: 4), // REDUCED spacing
          Text(
            value,
            style: TextStyle(
              fontSize: 14, // REDUCED font size
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 9, // REDUCED font size
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

  Color _getStatusColor(QuizStatus status) {
    switch (status) {
      case QuizStatus.active:
        return kSoftBlue;
      case QuizStatus.completed:
        return kAccentColor;
      case QuizStatus.draft:
        return kSoftOrange;
    }
  }

  String _getStatusText(QuizStatus status) {
    switch (status) {
      case QuizStatus.active:
        return 'Active';
      case QuizStatus.completed:
        return 'Completed';
      case QuizStatus.draft:
        return 'Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(quiz.status);
    final statusText = _getStatusText(quiz.status);

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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(12), // REDUCED padding
          childrenPadding: const EdgeInsets.fromLTRB(
            12,
            0,
            12,
            12,
          ), // REDUCED padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Container(
            width: 42, // REDUCED size
            height: 42, // REDUCED size
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12), // REDUCED radius
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 5, // REDUCED blur
                  offset: const Offset(0, 2), // REDUCED offset
                ),
              ],
            ),
            child: Icon(
              quiz.icon,
              color: Colors.white,
              size: 22, // REDUCED icon size
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                        fontSize: 14, // REDUCED font size
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6), // REDUCED spacing
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ), // REDUCED padding
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12), // REDUCED radius
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5, // REDUCED size
                          height: 5, // REDUCED size
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3), // REDUCED spacing
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 9, // REDUCED font size
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3), // REDUCED spacing
              Text(
                "${quiz.className} • ${quiz.subject}",
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 12, // REDUCED font size
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6), // REDUCED spacing
              Wrap(
                spacing: 8, // REDUCED spacing
                runSpacing: 6, // REDUCED spacing
                children: [
                  _buildInfoChip(
                    icon: Icons.format_list_numbered_rounded,
                    value: "${quiz.totalQuestions}",
                    label: "Qns",
                    color: kSoftPurple,
                  ),
                  _buildInfoChip(
                    icon: Icons.timer_rounded,
                    value: quiz.timeLimit,
                    label: "Time",
                    color: kSoftOrange,
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: statusColor,
            size: 20, // REDUCED size
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.info_rounded,
              label: "Instructions",
              value: quiz.instructions,
              color: kSoftPurple,
            ),
            const SizedBox(height: 6), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.rule_rounded,
              label: "Scoring",
              value: quiz.scoringRules,
              color: kSoftBlue,
            ),
            if (quiz.notes != null) ...[
              const SizedBox(height: 6), // REDUCED spacing
              _buildDetailRow(
                icon: Icons.note_alt_rounded,
                label: "Notes",
                value: quiz.notes!,
                color: kSoftOrange,
              ),
            ],
            const SizedBox(height: 8), // REDUCED spacing
            Wrap(
              spacing: 6, // REDUCED spacing
              runSpacing: 6, // REDUCED spacing
              children: [
                _buildActionChip(
                  icon: Icons.list_alt_rounded,
                  label: "Questions",
                  color: kSoftPurple,
                ),
                _buildActionChip(
                  icon: Icons.edit_rounded,
                  label: "Edit",
                  color: kSoftBlue,
                ),
                _buildActionChip(
                  icon: Icons.assignment_return_rounded,
                  label: "Assign",
                  color: kAccentColor,
                ),
                _buildActionChip(
                  icon: Icons.bar_chart_rounded,
                  label: "Results",
                  color: kSoftOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ), // REDUCED padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10), // REDUCED radius
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12), // REDUCED icon size
          const SizedBox(width: 3), // REDUCED spacing
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11, // REDUCED font size
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 8, // REDUCED font size
                ),
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3), // REDUCED padding
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 12), // REDUCED icon size
          ),
          const SizedBox(width: 6), // REDUCED spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 10, // REDUCED font size
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 11, // REDUCED font size
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14), // REDUCED radius
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ), // REDUCED padding
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14), // REDUCED radius
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 3, // REDUCED blur
                offset: const Offset(0, 1), // REDUCED offset
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 11), // REDUCED icon size
              const SizedBox(width: 3), // REDUCED spacing
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9, // REDUCED font size
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- CREATE BUTTON ----------------
class _CreateQuizCTAButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateQuizCTAButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44, // REDUCED height
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccentColor, kAccentColor.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14), // REDUCED radius
        boxShadow: [
          BoxShadow(
            color: kAccentColor.withOpacity(0.3),
            blurRadius: 5, // REDUCED blur
            offset: const Offset(0, 2), // REDUCED offset
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ), // REDUCED icon size
                SizedBox(width: 6), // REDUCED spacing
                Text(
                  "Create New Quiz",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13, // REDUCED font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
