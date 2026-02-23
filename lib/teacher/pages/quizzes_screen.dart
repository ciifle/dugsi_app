import 'package:flutter/material.dart';

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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Quiz> get filteredQuizzes {
    List<Quiz> searchFiltered = dummyQuizzes;
    if (_searchQuery.isNotEmpty) {
      searchFiltered = dummyQuizzes.where((q) {
        final query = _searchQuery.toLowerCase();
        return q.title.toLowerCase().contains(query) ||
            q.subject.toLowerCase().contains(query) ||
            q.className.toLowerCase().contains(query);
      }).toList();
    }

    switch (_selectedFilter) {
      case 'Active':
        return searchFiltered
            .where((q) => q.status == QuizStatus.active)
            .toList();
      case 'Completed':
        return searchFiltered
            .where((q) => q.status == QuizStatus.completed)
            .toList();
      case 'Draft':
        return searchFiltered
            .where((q) => q.status == QuizStatus.draft)
            .toList();
      default:
        return searchFiltered;
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(QuizStatus status) {
    switch (status) {
      case QuizStatus.active:
        return kPrimaryBlue;
      case QuizStatus.completed:
        return kPrimaryGreen;
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
      backgroundColor: kSoftBlue,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR WITH GRADIENT ----------------
          SliverAppBar(
            expandedHeight: _isSearching ? 100 : 120,
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
                title: _isSearching
                    ? null
                    : const Text(
                        "Quizzes",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
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
              if (_isSearching)
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _stopSearch,
                    padding: const EdgeInsets.all(10),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _startSearch,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
            ],
            bottom: _isSearching
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: _updateSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search quizzes...',
                            hintStyle: TextStyle(
                              color: kTextSecondary,
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: kPrimaryBlue,
                              size: 22,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: kTextSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _updateSearchQuery('');
                                    },
                                    padding: EdgeInsets.zero,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- SUMMARY CARD ----------------
                _QuizSummaryCard(quizzes: dummyQuizzes),

                const SizedBox(height: 20),

                // ---------------- FILTER SECTION ----------------
                _buildFilterSection(),

                const SizedBox(height: 16),

                // ---------------- SEARCH RESULT COUNT ----------------
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Found ${filtered.length} quiz${filtered.length != 1 ? 'zes' : ''}',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---------------- QUIZZES HEADER ----------------
                if (_searchQuery.isEmpty) _buildQuizzesHeader(filtered.length),

                const SizedBox(height: 12),

                // ---------------- QUIZ CARDS ----------------
                if (filtered.isNotEmpty)
                  ...List.generate(
                    filtered.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuizCard(quiz: filtered[index]),
                    ),
                  )
                else
                  _buildEmptyState(),

                const SizedBox(height: 20),

                // ---------------- CREATE BUTTON ----------------
                _CreateQuizCTAButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Create New Quiz"),
                        backgroundColor: kPrimaryGreen,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
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
                Icons.filter_list_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Filter by Status",
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
            children: filters.map((filter) {
              final bool isSelected = _selectedFilter == filter;
              final Color filterColor = _getFilterColor(filter);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(
                    color: isSelected ? filterColor : Colors.grey.shade300,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                Icons.quiz_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Quiz List",
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
            '$count items',
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
              child: Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.quiz_rounded,
                color: kPrimaryBlue,
                size: 56,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'No quizzes found' : 'No quizzes',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try different search terms'
                  : 'Create your first quiz',
              style: TextStyle(color: kTextSecondary, fontSize: 14),
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
      case 'Active':
        return kPrimaryBlue;
      case 'Completed':
        return kPrimaryGreen;
      case 'Draft':
        return kSoftOrange;
      default:
        return kPrimaryBlue;
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quiz Overview',
                style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
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
                color: kPrimaryBlue,
              ),
              _buildStatItem(
                icon: Icons.flash_on_rounded,
                label: "Active",
                value: "$active",
                color: kPrimaryBlue,
              ),
              _buildStatItem(
                icon: Icons.check_circle_rounded,
                label: "Completed",
                value: "$completed",
                color: kPrimaryGreen,
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
          Text(label, style: TextStyle(color: kTextSecondary, fontSize: 11)),
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
        return kPrimaryBlue;
      case QuizStatus.completed:
        return kPrimaryGreen;
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(quiz.icon, color: Colors.white, size: 24),
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
                        fontSize: 16,
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "${quiz.className} • ${quiz.subject}",
                style: TextStyle(color: kTextSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.format_list_numbered_rounded,
                    value: "${quiz.totalQuestions}",
                    label: "Qns",
                    color: kPrimaryBlue,
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
            size: 24,
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.info_rounded,
              label: "Instructions",
              value: quiz.instructions,
              color: kPrimaryBlue,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.rule_rounded,
              label: "Scoring",
              value: quiz.scoringRules,
              color: kPrimaryBlue,
            ),
            if (quiz.notes != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.note_alt_rounded,
                label: "Notes",
                value: quiz.notes!,
                color: kSoftOrange,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  icon: Icons.list_alt_rounded,
                  label: "Questions",
                  color: kPrimaryBlue,
                ),
                _buildActionChip(
                  icon: Icons.edit_rounded,
                  label: "Edit",
                  color: kPrimaryGreen,
                ),
                _buildActionChip(
                  icon: Icons.assignment_return_rounded,
                  label: "Assign",
                  color: kSoftOrange,
                ),
                _buildActionChip(
                  icon: Icons.bar_chart_rounded,
                  label: "Results",
                  color: kErrorColor,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 9),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(color: kTextPrimary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryBlue, kPrimaryGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  "Create New Quiz",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
