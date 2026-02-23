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

// ================== DATA MODELS ==================

enum TeacherExamsTab { exams, results }

class Exam {
  final String name;
  final String className;
  final String subject;
  final DateTime date;
  final String duration;
  final bool completed;
  final String syllabus;
  final String notes;
  final String remarks;
  final IconData icon;

  Exam({
    required this.name,
    required this.className,
    required this.subject,
    required this.date,
    required this.duration,
    required this.completed,
    required this.syllabus,
    required this.notes,
    required this.remarks,
    required this.icon,
  });
}

class ExamResult {
  final String name;
  final String className;
  final String subject;
  final double average;
  final double passPercent;
  final bool published;
  final String syllabus;
  final String notes;
  final String remarks;
  final IconData icon;

  ExamResult({
    required this.name,
    required this.className,
    required this.subject,
    required this.average,
    required this.passPercent,
    required this.published,
    required this.syllabus,
    required this.notes,
    required this.remarks,
    required this.icon,
  });
}

// ================== DUMMY DATA ===================

final List<Exam> dummyExams = [
  Exam(
    name: 'Midterm Examination',
    className: 'Grade 8',
    subject: 'Mathematics',
    date: DateTime.now().add(const Duration(days: 7)),
    duration: '90 min',
    completed: false,
    syllabus: 'Chapters 1-6: Algebra, Trigonometry, Calculus',
    notes: 'Focus on algebra. Calculator allowed.',
    remarks: 'Include calculator section.',
    icon: Icons.calculate_rounded,
  ),
  Exam(
    name: 'Semester Final',
    className: 'Grade 8',
    subject: 'Science',
    date: DateTime.now().subtract(const Duration(days: 10)),
    duration: '120 min',
    completed: true,
    syllabus: 'Full year: Physics, Chemistry, Biology',
    notes: 'Diagram questions mandatory.',
    remarks: 'Split into 2 sections.',
    icon: Icons.science_rounded,
  ),
  Exam(
    name: 'Weekly Quiz',
    className: 'Grade 7',
    subject: 'History',
    date: DateTime.now().add(const Duration(days: 2)),
    duration: '30 min',
    completed: false,
    syllabus: 'World Wars: Causes and Consequences',
    notes: 'Short questions. No negative marking.',
    remarks: 'Focus on key events.',
    icon: Icons.history_edu_rounded,
  ),
];

final List<ExamResult> dummyResults = [
  ExamResult(
    name: 'Midterm Examination',
    className: 'Grade 8',
    subject: 'Mathematics',
    average: 67.8,
    passPercent: 82.7,
    published: false,
    syllabus: 'Chapters 1-6',
    notes: 'Students found Q5 challenging.',
    remarks: 'Consider revision before finals.',
    icon: Icons.assessment_rounded,
  ),
  ExamResult(
    name: 'Semester Final',
    className: 'Grade 8',
    subject: 'Science',
    average: 74.2,
    passPercent: 89.5,
    published: true,
    syllabus: 'Full year',
    notes: 'Practical scored well.',
    remarks: 'Continue lab sessions.',
    icon: Icons.bar_chart_rounded,
  ),
];

// =============== MAIN SCREEN CLASS ===============

class TeacherExamsResultsScreen extends StatefulWidget {
  const TeacherExamsResultsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherExamsResultsScreen> createState() =>
      _TeacherExamsResultsScreenState();
}

class _TeacherExamsResultsScreenState extends State<TeacherExamsResultsScreen> {
  TeacherExamsTab _tab = TeacherExamsTab.exams;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int get _totalExams => dummyExams.length;
  int get _upcomingExams => dummyExams
      .where((e) => !e.completed && e.date.isAfter(DateTime.now()))
      .length;
  int get _completedExams => dummyExams.where((e) => e.completed).length;
  int get _publishedResults => dummyResults.where((r) => r.published).length;

  List<Exam> get filteredExams {
    if (_searchQuery.isEmpty) return dummyExams;
    return dummyExams.where((e) {
      final query = _searchQuery.toLowerCase();
      return e.name.toLowerCase().contains(query) ||
          e.className.toLowerCase().contains(query) ||
          e.subject.toLowerCase().contains(query);
    }).toList();
  }

  List<ExamResult> get filteredResults {
    if (_searchQuery.isEmpty) return dummyResults;
    return dummyResults.where((r) {
      final query = _searchQuery.toLowerCase();
      return r.name.toLowerCase().contains(query) ||
          r.className.toLowerCase().contains(query) ||
          r.subject.toLowerCase().contains(query);
    }).toList();
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

  // Navigation methods for action buttons
  void _viewStudents(Exam exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing students for: ${exam.name}'),
        backgroundColor: kPrimaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: Navigate to students list screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => StudentsScreen(exam: exam)));
  }

  void _editExam(Exam exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing: ${exam.name}'),
        backgroundColor: kPrimaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: Navigate to edit exam screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => EditExamScreen(exam: exam)));
  }

  void _enterMarks(Exam exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Entering marks for: ${exam.name}'),
        backgroundColor: kSoftOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: Navigate to marks entry screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => MarksEntryScreen(exam: exam)));
  }

  void _viewResults(ExamResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing results: ${result.name}'),
        backgroundColor: kPrimaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: Navigate to view results screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ViewResultsScreen(result: result)));
  }

  void _editMarks(ExamResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing marks: ${result.name}'),
        backgroundColor: kPrimaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: Navigate to edit marks screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => EditMarksScreen(result: result)));
  }

  void _togglePublish(ExamResult result) {
    setState(() {
      // In a real app, you would update the actual data
      // Here we're just showing a snackbar
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.published
              ? 'Unpublishing: ${result.name}'
              : 'Publishing: ${result.name}',
        ),
        backgroundColor: kSoftOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: Toggle publish status in database
  }

  @override
  Widget build(BuildContext context) {
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
                        "Exams & Results",
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
                            hintText: 'Search exams or results...',
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
                // ---------------- OVERVIEW CARD ----------------
                _ExamResultsOverviewCard(
                  totalExams: _totalExams,
                  upcomingExams: _upcomingExams,
                  completedExams: _completedExams,
                  publishedResults: _publishedResults,
                ),

                const SizedBox(height: 20),

                // ---------------- TOGGLE SECTION ----------------
                _ExamsResultsToggle(
                  selected: _tab,
                  onChanged: (tab) {
                    setState(() => _tab = tab);
                  },
                ),

                const SizedBox(height: 16),

                // ---------------- SEARCH RESULT COUNT ----------------
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      _tab == TeacherExamsTab.exams
                          ? 'Found ${filteredExams.length} exam${filteredExams.length != 1 ? 's' : ''}'
                          : 'Found ${filteredResults.length} result${filteredResults.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---------------- HEADER ----------------
                if (_searchQuery.isEmpty)
                  _buildHeader(
                    _tab,
                    _tab == TeacherExamsTab.exams
                        ? filteredExams.length
                        : filteredResults.length,
                  ),

                const SizedBox(height: 12),

                // ---------------- LIST SECTION ----------------
                if (_tab == TeacherExamsTab.exams)
                  ...List.generate(
                    filteredExams.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExamCard(
                        exam: filteredExams[index],
                        onStudentsTap: () =>
                            _viewStudents(filteredExams[index]),
                        onEditTap: () => _editExam(filteredExams[index]),
                        onMarksTap: () => _enterMarks(filteredExams[index]),
                      ),
                    ),
                  )
                else
                  ...List.generate(
                    filteredResults.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ResultCard(
                        result: filteredResults[index],
                        onViewTap: () => _viewResults(filteredResults[index]),
                        onEditTap: () => _editMarks(filteredResults[index]),
                        onPublishTap: () =>
                            _togglePublish(filteredResults[index]),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TeacherExamsTab tab, int count) {
    final title = tab == TeacherExamsTab.exams ? "Exam List" : "Results List";
    final icon = tab == TeacherExamsTab.exams
        ? Icons.event_available_rounded
        : Icons.assessment_rounded;

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
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
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
}

// ================= OVERVIEW CARD =================

class _ExamResultsOverviewCard extends StatelessWidget {
  final int totalExams;
  final int upcomingExams;
  final int completedExams;
  final int publishedResults;

  const _ExamResultsOverviewCard({
    required this.totalExams,
    required this.upcomingExams,
    required this.completedExams,
    required this.publishedResults,
  });

  @override
  Widget build(BuildContext context) {
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
                'Overview',
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
                value: "$totalExams",
                color: kPrimaryBlue,
              ),
              _buildStatItem(
                icon: Icons.upcoming_rounded,
                label: "Upcoming",
                value: "$upcomingExams",
                color: kSoftOrange,
              ),
              _buildStatItem(
                icon: Icons.check_circle_rounded,
                label: "Completed",
                value: "$completedExams",
                color: kPrimaryGreen,
              ),
              _buildStatItem(
                icon: Icons.publish_rounded,
                label: "Published",
                value: "$publishedResults",
                color: kPrimaryBlue,
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

// ==================== TOGGLE =====================

class _ExamsResultsToggle extends StatelessWidget {
  final TeacherExamsTab selected;
  final ValueChanged<TeacherExamsTab> onChanged;

  const _ExamsResultsToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            text: 'Exams',
            selected: selected == TeacherExamsTab.exams,
            onTap: () => onChanged(TeacherExamsTab.exams),
          ),
          const SizedBox(width: 6),
          _ToggleButton(
            text: 'Results',
            selected: selected == TeacherExamsTab.results,
            onTap: () => onChanged(TeacherExamsTab.results),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [kPrimaryBlue, kPrimaryGreen],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : kTextSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================ EXAM CARD WITH WORKING BUTTONS ================

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final VoidCallback onStudentsTap;
  final VoidCallback onEditTap;
  final VoidCallback onMarksTap;

  const _ExamCard({
    required this.exam,
    required this.onStudentsTap,
    required this.onEditTap,
    required this.onMarksTap,
  });

  Color _getStatusColor(bool completed) {
    return completed ? kPrimaryGreen : kSoftOrange;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = dt.difference(now).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Tomorrow";
    if (difference == -1) return "Yesterday";
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(exam.completed);

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
            child: Icon(exam.icon, color: Colors.white, size: 24),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exam.name,
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
                          exam.completed ? "Completed" : "Upcoming",
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
                "${exam.className} • ${exam.subject}",
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
                    icon: Icons.calendar_today_rounded,
                    value: _formatDate(exam.date),
                    color: kPrimaryBlue,
                  ),
                  _buildInfoChip(
                    icon: Icons.timer_rounded,
                    value: exam.duration,
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
              icon: Icons.menu_book_rounded,
              label: "Syllabus",
              value: exam.syllabus,
              color: kPrimaryBlue,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.note_alt_rounded,
              label: "Notes",
              value: exam.notes,
              color: kPrimaryGreen,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.comment_rounded,
              label: "Remarks",
              value: exam.remarks,
              color: kSoftOrange,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  icon: Icons.people_rounded,
                  label: "Students",
                  color: kPrimaryBlue,
                  onTap: onStudentsTap,
                ),
                _buildActionChip(
                  icon: Icons.edit_rounded,
                  label: "Edit",
                  color: kPrimaryGreen,
                  onTap: onEditTap,
                ),
                _buildActionChip(
                  icon: Icons.grade_rounded,
                  label: "Marks",
                  color: kSoftOrange,
                  onTap: onMarksTap,
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
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
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
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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

// ================ RESULT CARD WITH WORKING BUTTONS ================

class _ResultCard extends StatelessWidget {
  final ExamResult result;
  final VoidCallback onViewTap;
  final VoidCallback onEditTap;
  final VoidCallback onPublishTap;

  const _ResultCard({
    required this.result,
    required this.onViewTap,
    required this.onEditTap,
    required this.onPublishTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = result.published ? kPrimaryGreen : kSoftOrange;

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
            child: Icon(result.icon, color: Colors.white, size: 24),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.name,
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
                          result.published ? "Published" : "Draft",
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
                "${result.className} • ${result.subject}",
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
                    icon: Icons.leaderboard_rounded,
                    value: "${result.average.toStringAsFixed(1)}%",
                    label: "Average",
                    color: kPrimaryBlue,
                  ),
                  _buildInfoChip(
                    icon: Icons.percent_rounded,
                    value: "${result.passPercent.toStringAsFixed(1)}%",
                    label: "Pass",
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
              icon: Icons.menu_book_rounded,
              label: "Syllabus",
              value: result.syllabus,
              color: kPrimaryBlue,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.note_alt_rounded,
              label: "Notes",
              value: result.notes,
              color: kPrimaryGreen,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.comment_rounded,
              label: "Remarks",
              value: result.remarks,
              color: kSoftOrange,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  icon: Icons.visibility_rounded,
                  label: "View",
                  color: kPrimaryBlue,
                  onTap: onViewTap,
                ),
                _buildActionChip(
                  icon: Icons.edit_rounded,
                  label: "Edit",
                  color: kPrimaryGreen,
                  onTap: onEditTap,
                ),
                _buildActionChip(
                  icon: result.published
                      ? Icons.undo_rounded
                      : Icons.publish_rounded,
                  label: result.published ? "Unpublish" : "Publish",
                  color: kSoftOrange,
                  onTap: onPublishTap,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
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
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
