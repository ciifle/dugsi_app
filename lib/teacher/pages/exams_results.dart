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

  int get _totalExams => dummyExams.length;
  int get _upcomingExams => dummyExams
      .where((e) => !e.completed && e.date.isAfter(DateTime.now()))
      .length;
  int get _completedExams => dummyExams.where((e) => e.completed).length;
  int get _publishedResults => dummyResults.where((r) => r.published).length;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: kAccentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      Icons.assignment_rounded,
                      color: Colors.white,
                      size: 16, // REDUCED icon size
                    ),
                  ),
                  const SizedBox(width: 6), // REDUCED spacing
                  const Text(
                    "Exams & Results",
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
            // SEARCH ICON REMOVED
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16), // REDUCED from 20
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- OVERVIEW CARD ----------------
                _ExamResultsOverviewCard(
                  totalExams: _totalExams,
                  upcomingExams: _upcomingExams,
                  completedExams: _completedExams,
                  publishedResults: _publishedResults,
                ),

                const SizedBox(height: 20), // REDUCED from 24
                // ---------------- TOGGLE SECTION ----------------
                _ExamsResultsToggle(
                  selected: _tab,
                  onChanged: (tab) {
                    setState(() => _tab = tab);
                  },
                ),

                const SizedBox(height: 16), // REDUCED from 20
                // ---------------- HEADER ----------------
                _buildHeader(_tab),

                const SizedBox(height: 12), // REDUCED from 16
                // ---------------- LIST SECTION ----------------
                if (_tab == TeacherExamsTab.exams)
                  ...List.generate(
                    dummyExams.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                      ), // REDUCED from 16
                      child: _ExamCard(
                        exam: dummyExams[index],
                        onStudentsTap: () =>
                            _showSnackBar('View Students - Coming Soon'),
                        onEditTap: () =>
                            _showSnackBar('Edit Exam - Coming Soon'),
                        onMarksTap: () =>
                            _showSnackBar('Enter Marks - Coming Soon'),
                      ),
                    ),
                  )
                else
                  ...List.generate(
                    dummyResults.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                      ), // REDUCED from 16
                      child: _ResultCard(
                        result: dummyResults[index],
                        onViewTap: () =>
                            _showSnackBar('View Results - Coming Soon'),
                        onEditTap: () =>
                            _showSnackBar('Edit Marks - Coming Soon'),
                        onPublishTap: () => _showSnackBar(
                          dummyResults[index].published
                              ? 'Unpublish - Coming Soon'
                              : 'Publish - Coming Soon',
                        ),
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

  Widget _buildHeader(TeacherExamsTab tab) {
    final count = tab == TeacherExamsTab.exams
        ? dummyExams.length
        : dummyResults.length;
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
              padding: const EdgeInsets.all(4), // REDUCED padding
              decoration: BoxDecoration(
                color: kSoftOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6), // REDUCED radius
              ),
              child: Icon(
                icon,
                color: kSoftOrange,
                size: 14,
              ), // REDUCED icon size
            ),
            const SizedBox(width: 6), // REDUCED spacing
            Text(
              title,
              style: const TextStyle(
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
                'Overview',
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
                value: "$totalExams",
                color: kSoftPurple,
              ),
              _buildStatItem(
                icon: Icons.upcoming_rounded,
                label: "Upcoming",
                value: "$upcomingExams",
                color: kSoftBlue,
              ),
              _buildStatItem(
                icon: Icons.check_circle_rounded,
                label: "Completed",
                value: "$completedExams",
                color: kAccentColor,
              ),
              _buildStatItem(
                icon: Icons.publish_rounded,
                label: "Published",
                value: "$publishedResults",
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
          const SizedBox(width: 6), // REDUCED spacing
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
          padding: const EdgeInsets.symmetric(vertical: 6), // REDUCED padding
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(colors: [kSecondaryColor, kPrimaryColor])
                : null,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : kTextSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12, // REDUCED font size
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
    return completed ? kAccentColor : kSoftOrange;
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
              exam.icon,
              color: Colors.white,
              size: 22,
            ), // REDUCED icon size
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
                          exam.completed ? "Completed" : "Upcoming",
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
                "${exam.className} • ${exam.subject}",
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
                    icon: Icons.calendar_today_rounded,
                    value: _formatDate(exam.date),
                    color: kSoftPurple,
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
            size: 20, // REDUCED size
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.menu_book_rounded,
              label: "Syllabus",
              value: exam.syllabus,
              color: kSoftPurple,
            ),
            const SizedBox(height: 6), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.note_alt_rounded,
              label: "Notes",
              value: exam.notes,
              color: kSoftBlue,
            ),
            const SizedBox(height: 6), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.comment_rounded,
              label: "Remarks",
              value: exam.remarks,
              color: kSoftOrange,
            ),
            const SizedBox(height: 8), // REDUCED spacing
            Wrap(
              spacing: 6, // REDUCED spacing
              runSpacing: 6, // REDUCED spacing
              children: [
                _buildActionChip(
                  icon: Icons.people_rounded,
                  label: "Students",
                  color: kSoftPurple,
                  onTap: onStudentsTap,
                ),
                _buildActionChip(
                  icon: Icons.edit_rounded,
                  label: "Edit",
                  color: kSoftBlue,
                  onTap: onEditTap,
                ),
                _buildActionChip(
                  icon: Icons.grade_rounded,
                  label: "Marks",
                  color: kAccentColor,
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
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11, // REDUCED font size
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
    final statusColor = result.published ? kAccentColor : kSoftOrange;

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
              result.icon,
              color: Colors.white,
              size: 22,
            ), // REDUCED icon size
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
                          result.published ? "Published" : "Draft",
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
                "${result.className} • ${result.subject}",
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
                    icon: Icons.leaderboard_rounded,
                    value: "${result.average.toStringAsFixed(1)}%",
                    label: "Average",
                    color: kSoftPurple,
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
            size: 20, // REDUCED size
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.menu_book_rounded,
              label: "Syllabus",
              value: result.syllabus,
              color: kSoftPurple,
            ),
            const SizedBox(height: 6), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.note_alt_rounded,
              label: "Notes",
              value: result.notes,
              color: kSoftBlue,
            ),
            const SizedBox(height: 6), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.comment_rounded,
              label: "Remarks",
              value: result.remarks,
              color: kSoftOrange,
            ),
            const SizedBox(height: 8), // REDUCED spacing
            Wrap(
              spacing: 6, // REDUCED spacing
              runSpacing: 6, // REDUCED spacing
              children: [
                _buildActionChip(
                  icon: Icons.visibility_rounded,
                  label: "View",
                  color: kSoftPurple,
                  onTap: onViewTap,
                ),
                _buildActionChip(
                  icon: Icons.edit_rounded,
                  label: "Edit",
                  color: kSoftBlue,
                  onTap: onEditTap,
                ),
                _buildActionChip(
                  icon: result.published
                      ? Icons.undo_rounded
                      : Icons.publish_rounded,
                  label: result.published ? "Unpublish" : "Publish",
                  color: kAccentColor,
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
