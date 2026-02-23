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

// ================
//  ENUMS & MODELS
// ================
enum AssignmentStatus { active, submitted, reviewed, overdue }

class Assignment {
  final String id;
  final String title;
  final String className;
  final String subject;
  final String dueDate;
  final int submittedCount;
  final int totalCount;
  final AssignmentStatus status;
  final String description;
  final String instructions;
  final String? attachedInfo;
  final String? teacherNotes;
  final IconData icon;

  Assignment({
    required this.id,
    required this.title,
    required this.className,
    required this.subject,
    required this.dueDate,
    required this.submittedCount,
    required this.totalCount,
    required this.status,
    required this.description,
    required this.instructions,
    this.attachedInfo,
    this.teacherNotes,
    required this.icon,
  });
}

// ============
//  DUMMY DATA
// ============
final List<Assignment> dummyAssignments = [
  Assignment(
    id: 'a1',
    title: 'Algebra Practice Sheet',
    className: '9A',
    subject: 'Mathematics',
    dueDate: '2024-06-10',
    submittedCount: 20,
    totalCount: 25,
    status: AssignmentStatus.active,
    description: 'Solve questions 1-10 from the given worksheet.',
    instructions: 'Show all work. Submit on LMS or as hard copy.',
    attachedInfo: 'Worksheet PDF provided via LMS.',
    teacherNotes: 'Focus on factorization techniques.',
    icon: Icons.calculate_rounded,
  ),
  Assignment(
    id: 'a2',
    title: 'Essay: Water Conservation',
    className: '8B',
    subject: 'English',
    dueDate: '2024-05-25',
    submittedCount: 28,
    totalCount: 28,
    status: AssignmentStatus.reviewed,
    description: 'Write an essay of 300 words about water conservation.',
    instructions: 'Type or write neatly. Review grammar and punctuation.',
    attachedInfo: null,
    teacherNotes: 'Best submissions will be displayed on notice board.',
    icon: Icons.menu_book_rounded,
  ),
  Assignment(
    id: 'a3',
    title: 'Physics Lab: Motion',
    className: '10C',
    subject: 'Physics',
    dueDate: '2024-06-02',
    submittedCount: 13,
    totalCount: 18,
    status: AssignmentStatus.overdue,
    description: 'Lab report on the experiment conducted in class.',
    instructions: 'Follow standard format. Include data tables.',
    attachedInfo: 'Lab handout distributed in class.',
    teacherNotes: null,
    icon: Icons.science_rounded,
  ),
  Assignment(
    id: 'a4',
    title: 'Urdu Spelling Quiz',
    className: '7A',
    subject: 'Urdu',
    dueDate: '2024-06-08',
    submittedCount: 0,
    totalCount: 19,
    status: AssignmentStatus.active,
    description: 'Prepare for the spelling quiz of week 8.',
    instructions: 'Revise all vocabulary from chapter 4.',
    attachedInfo: null,
    teacherNotes: null,
    icon: Icons.translate_rounded,
  ),
];

// =========================
//   MAIN SCREEN WIDGET
// =========================
class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  String _selectedFilter = 'All';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Assignment> get filteredAssignments {
    List<Assignment> searchFiltered = dummyAssignments;
    if (_searchQuery.isNotEmpty) {
      searchFiltered = dummyAssignments.where((a) {
        final query = _searchQuery.toLowerCase();
        return a.title.toLowerCase().contains(query) ||
            a.subject.toLowerCase().contains(query) ||
            a.className.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedFilter == 'All') return searchFiltered;
    switch (_selectedFilter) {
      case 'Active':
        return searchFiltered
            .where((a) => a.status == AssignmentStatus.active)
            .toList();
      case 'Submitted':
        return searchFiltered
            .where((a) => a.status == AssignmentStatus.submitted)
            .toList();
      case 'Reviewed':
        return searchFiltered
            .where((a) => a.status == AssignmentStatus.reviewed)
            .toList();
      case 'Overdue':
        return searchFiltered
            .where((a) => a.status == AssignmentStatus.overdue)
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

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.active:
        return kPrimaryBlue;
      case AssignmentStatus.submitted:
        return kSoftOrange;
      case AssignmentStatus.reviewed:
        return kPrimaryGreen;
      case AssignmentStatus.overdue:
        return kErrorColor;
    }
  }

  String _getStatusText(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.active:
        return 'Active';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.reviewed:
        return 'Reviewed';
      case AssignmentStatus.overdue:
        return 'Overdue';
    }
  }

  // Navigation methods for action buttons
  void _viewSubmissions(Assignment assignment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing submissions for: ${assignment.title}'),
        backgroundColor: kPrimaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: Navigate to submissions screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => SubmissionsScreen(assignment: assignment)));
  }

  void _gradeAssignment(Assignment assignment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grading: ${assignment.title}'),
        backgroundColor: kPrimaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: Navigate to grade screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => GradeScreen(assignment: assignment)));
  }

  void _editAssignment(Assignment assignment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing: ${assignment.title}'),
        backgroundColor: kSoftOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: Navigate to edit screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => EditAssignmentScreen(assignment: assignment)));
  }

  void _extendDeadline(Assignment assignment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Extending deadline for: ${assignment.title}'),
        backgroundColor: kErrorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: Show date picker or navigate to extend screen
    // _showDatePicker(context, assignment);
  }

  void _showDatePicker(BuildContext context, Assignment assignment) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((selectedDate) {
      if (selectedDate != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deadline extended to: ${selectedDate.toString().split(' ')[0]}',
            ),
            backgroundColor: kPrimaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredAssignments;

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
                        "Assignments",
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
                            hintText: 'Search assignments...',
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
                _AssignmentSummaryCard(assignments: dummyAssignments),

                const SizedBox(height: 20),

                // ---------------- FILTER SECTION ----------------
                _buildFilterSection(),

                const SizedBox(height: 16),

                // ---------------- SEARCH RESULT COUNT ----------------
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Found ${filtered.length} assignment${filtered.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---------------- ASSIGNMENTS HEADER ----------------
                if (_searchQuery.isEmpty)
                  _buildAssignmentsHeader(filtered.length),

                const SizedBox(height: 12),

                // ---------------- ASSIGNMENT CARDS ----------------
                if (filtered.isNotEmpty)
                  ...List.generate(
                    filtered.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AssignmentCard(
                        assignment: filtered[index],
                        onSubmissionsTap: () =>
                            _viewSubmissions(filtered[index]),
                        onGradeTap: () => _gradeAssignment(filtered[index]),
                        onEditTap: () => _editAssignment(filtered[index]),
                        onExtendTap: () => _extendDeadline(filtered[index]),
                      ),
                    ),
                  )
                else
                  _buildEmptyState(),

                const SizedBox(height: 20),

                // ---------------- CREATE BUTTON ----------------
                _CreateAssignmentCTAButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Create New Assignment"),
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
    final filters = ['All', 'Active', 'Submitted', 'Reviewed', 'Overdue'];

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

  Widget _buildAssignmentsHeader(int count) {
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
                Icons.assignment_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Assignment List",
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
                    : Icons.assignment_rounded,
                color: kPrimaryBlue,
                size: 56,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No assignments found'
                  : 'No assignments',
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
                  : 'Create your first assignment',
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
      case 'Submitted':
        return kSoftOrange;
      case 'Reviewed':
        return kPrimaryGreen;
      case 'Overdue':
        return kErrorColor;
      default:
        return kPrimaryBlue;
    }
  }
}

// ---------------- SUMMARY CARD ----------------
class _AssignmentSummaryCard extends StatelessWidget {
  final List<Assignment> assignments;
  const _AssignmentSummaryCard({required this.assignments});

  @override
  Widget build(BuildContext context) {
    int total = assignments.length;
    int active = assignments
        .where((a) => a.status == AssignmentStatus.active)
        .length;
    int reviewed = assignments
        .where((a) => a.status == AssignmentStatus.reviewed)
        .length;
    int overdue = assignments
        .where((a) => a.status == AssignmentStatus.overdue)
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
                'Assignment Overview',
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
                icon: Icons.pending_rounded,
                label: "Active",
                value: "$active",
                color: kPrimaryBlue,
              ),
              _buildStatItem(
                icon: Icons.check_circle_rounded,
                label: "Reviewed",
                value: "$reviewed",
                color: kPrimaryGreen,
              ),
              _buildStatItem(
                icon: Icons.warning_rounded,
                label: "Overdue",
                value: "$overdue",
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

// ---------------- ASSIGNMENT CARD ----------------
class _AssignmentCard extends StatefulWidget {
  final Assignment assignment;
  final VoidCallback onSubmissionsTap;
  final VoidCallback onGradeTap;
  final VoidCallback onEditTap;
  final VoidCallback onExtendTap;

  const _AssignmentCard({
    required this.assignment,
    required this.onSubmissionsTap,
    required this.onGradeTap,
    required this.onEditTap,
    required this.onExtendTap,
  });

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  bool _expanded = false;

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.active:
        return kPrimaryBlue;
      case AssignmentStatus.submitted:
        return kSoftOrange;
      case AssignmentStatus.reviewed:
        return kPrimaryGreen;
      case AssignmentStatus.overdue:
        return kErrorColor;
    }
  }

  String _getStatusText(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.active:
        return 'Active';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.reviewed:
        return 'Reviewed';
      case AssignmentStatus.overdue:
        return 'Overdue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final statusColor = _getStatusColor(a.status);
    final statusText = _getStatusText(a.status);

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
          onExpansionChanged: (v) => setState(() => _expanded = v),
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
            child: Icon(a.icon, color: Colors.white, size: 24),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.title,
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
                "${a.className} • ${a.subject}",
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
                    icon: Icons.event_rounded,
                    value: a.dueDate,
                    label: "Due",
                    color: kPrimaryBlue,
                  ),
                  _buildInfoChip(
                    icon: Icons.people_rounded,
                    value: "${a.submittedCount}/${a.totalCount}",
                    label: "Submitted",
                    color: kSoftOrange,
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            _expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: statusColor,
            size: 24,
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.description_rounded,
              label: "Description",
              value: a.description,
              color: kPrimaryBlue,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.assignment_rounded,
              label: "Instructions",
              value: a.instructions,
              color: kPrimaryBlue,
            ),
            if (a.attachedInfo != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.attach_file_rounded,
                label: "Attached Info",
                value: a.attachedInfo!,
                color: kPrimaryGreen,
              ),
            ],
            if (a.teacherNotes != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.note_alt_rounded,
                label: "Teacher Notes",
                value: a.teacherNotes!,
                color: kSoftOrange,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  icon: Icons.visibility_rounded,
                  label: "Submissions",
                  color: kPrimaryBlue,
                  onTap: widget.onSubmissionsTap,
                ),
                _buildActionChip(
                  icon: Icons.grade_rounded,
                  label: "Grade",
                  color: kPrimaryGreen,
                  onTap: widget.onGradeTap,
                ),
                _buildActionChip(
                  icon: Icons.edit_rounded,
                  label: "Edit",
                  color: kSoftOrange,
                  onTap: widget.onEditTap,
                ),
                _buildActionChip(
                  icon: Icons.update_rounded,
                  label: "Extend",
                  color: kErrorColor,
                  onTap: widget.onExtendTap,
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

// ---------------- CREATE BUTTON ----------------
class _CreateAssignmentCTAButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateAssignmentCTAButton({required this.onPressed});

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
                  "Create New Assignment",
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
