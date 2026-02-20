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
const Color kTextSecondary = Color(0xFF636E72); // Medium slate

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
    // First apply search
    List<Assignment> searchFiltered = dummyAssignments;
    if (_searchQuery.isNotEmpty) {
      searchFiltered = dummyAssignments.where((a) {
        final query = _searchQuery.toLowerCase();
        return a.title.toLowerCase().contains(query) ||
            a.subject.toLowerCase().contains(query) ||
            a.className.toLowerCase().contains(query);
      }).toList();
    }

    // Then apply category filter
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
        return kSoftBlue;
      case AssignmentStatus.submitted:
        return kSoftPurple;
      case AssignmentStatus.reviewed:
        return kAccentColor;
      case AssignmentStatus.overdue:
        return kSoftPink;
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
    final filtered = filteredAssignments;

    return Scaffold(
      backgroundColor: kBackgroundEnd,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR WITH SEARCH (SMALLER SIZE) ----------------
          SliverAppBar(
            expandedHeight: _isSearching ? 90 : 100, // REDUCED from 120
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 16,
                bottom: 10,
              ), // REDUCED padding
              title: _isSearching
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5), // REDUCED padding
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              8,
                            ), // REDUCED radius
                          ),
                          child: const Icon(
                            Icons.assignment_rounded,
                            color: Colors.white,
                            size: 16, // REDUCED icon size
                          ),
                        ),
                        const SizedBox(width: 6), // REDUCED spacing
                        const Text(
                          "Assignments",
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
            actions: [
              if (_isSearching)
                Container(
                  margin: const EdgeInsets.only(right: 12), // REDUCED margin
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ), // REDUCED size
                    onPressed: _stopSearch,
                    padding: const EdgeInsets.all(6), // REDUCED padding
                    constraints: const BoxConstraints(),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 12), // REDUCED margin
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 18,
                    ), // REDUCED size
                    onPressed: _startSearch,
                    padding: const EdgeInsets.all(6), // REDUCED padding
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
            bottom: _isSearching
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(50), // REDUCED height
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        4,
                        12,
                        8,
                      ), // REDUCED padding
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // REDUCED radius
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
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
                              fontSize: 12, // REDUCED font size
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: kSoftPurple,
                              size: 16, // REDUCED icon size
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: kTextSecondary,
                                      size: 14, // REDUCED size
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _updateSearchQuery('');
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, // REDUCED padding
                              vertical: 8, // REDUCED padding
                            ),
                          ),
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 12, // REDUCED font size
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16), // REDUCED from 20
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- SUMMARY CARD ----------------
                _AssignmentSummaryCard(assignments: dummyAssignments),

                const SizedBox(height: 20), // REDUCED from 24
                // ---------------- FILTER SECTION ----------------
                _buildFilterSection(),

                const SizedBox(height: 16), // REDUCED from 20
                // ---------------- SEARCH RESULT COUNT ----------------
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Found ${filtered.length} assignment${filtered.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 12, // REDUCED font size
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---------------- ASSIGNMENTS HEADER ----------------
                if (_searchQuery.isEmpty)
                  _buildAssignmentsHeader(filtered.length),

                const SizedBox(height: 12), // REDUCED from 16
                // ---------------- ASSIGNMENT CARDS ----------------
                if (filtered.isNotEmpty)
                  ...List.generate(
                    filtered.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                      ), // REDUCED from 16
                      child: _AssignmentCard(assignment: filtered[index]),
                    ),
                  )
                else
                  _buildEmptyState(),

                const SizedBox(height: 20), // REDUCED from 24
                // ---------------- CREATE BUTTON ----------------
                _CreateAssignmentCTAButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Create New Assignment"),
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
    final filters = ['All', 'Active', 'Submitted', 'Reviewed', 'Overdue'];

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

  Widget _buildAssignmentsHeader(int count) {
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
                Icons.assignment_rounded,
                color: kSoftOrange,
                size: 14, // REDUCED icon size
              ),
            ),
            const SizedBox(width: 6), // REDUCED spacing
            const Text(
              "Assignment List",
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
              child: Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.assignment_rounded,
                color: kSoftPurple,
                size: 36, // REDUCED icon size
              ),
            ),
            const SizedBox(height: 12), // REDUCED spacing
            Text(
              _searchQuery.isNotEmpty
                  ? 'No assignments found'
                  : 'No assignments',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 14, // REDUCED font size
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try different search terms'
                  : 'Create your first assignment',
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
      case 'Submitted':
        return kAccentColor;
      case 'Reviewed':
        return kSoftOrange;
      case 'Overdue':
        return kSoftPink;
      default:
        return kSecondaryColor;
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
                'Assignment Overview',
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
                icon: Icons.pending_rounded,
                label: "Active",
                value: "$active",
                color: kSoftBlue,
              ),
              _buildStatItem(
                icon: Icons.check_circle_rounded,
                label: "Reviewed",
                value: "$reviewed",
                color: kAccentColor,
              ),
              _buildStatItem(
                icon: Icons.warning_rounded,
                label: "Overdue",
                value: "$overdue",
                color: kSoftPink,
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

// ---------------- ASSIGNMENT CARD ----------------
class _AssignmentCard extends StatefulWidget {
  final Assignment assignment;
  const _AssignmentCard({required this.assignment});

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  bool _expanded = false;

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.active:
        return kSoftBlue;
      case AssignmentStatus.submitted:
        return kSoftPurple;
      case AssignmentStatus.reviewed:
        return kAccentColor;
      case AssignmentStatus.overdue:
        return kSoftPink;
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
          onExpansionChanged: (v) => setState(() => _expanded = v),
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
              a.icon,
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
                      a.title,
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
                "${a.className} • ${a.subject}",
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
                    icon: Icons.event_rounded,
                    value: a.dueDate,
                    label: "Due",
                    color: kSoftPurple,
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
            size: 20, // REDUCED size
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.description_rounded,
              label: "Description",
              value: a.description,
              color: kSoftPurple,
            ),
            const SizedBox(height: 6), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.assignment_rounded,
              label: "Instructions",
              value: a.instructions,
              color: kSoftBlue,
            ),
            if (a.attachedInfo != null) ...[
              const SizedBox(height: 6), // REDUCED spacing
              _buildDetailRow(
                icon: Icons.attach_file_rounded,
                label: "Attached Info",
                value: a.attachedInfo!,
                color: kAccentColor,
              ),
            ],
            if (a.teacherNotes != null) ...[
              const SizedBox(height: 6), // REDUCED spacing
              _buildDetailRow(
                icon: Icons.note_alt_rounded,
                label: "Teacher Notes",
                value: a.teacherNotes!,
                color: kSoftOrange,
              ),
            ],
            const SizedBox(height: 8), // REDUCED spacing
            Wrap(
              spacing: 6, // REDUCED spacing
              runSpacing: 6, // REDUCED spacing
              children: [
                _buildActionChip(
                  icon: Icons.visibility_rounded,
                  label: "Submissions",
                  color: kSoftPurple,
                ),
                _buildActionChip(
                  icon: Icons.grade_rounded,
                  label: "Grade",
                  color: kSoftBlue,
                ),
                _buildActionChip(
                  icon: Icons.edit_rounded,
                  label: "Edit",
                  color: kAccentColor,
                ),
                _buildActionChip(
                  icon: Icons.update_rounded,
                  label: "Extend",
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
              Icon(icon, color: Colors.white, size: 12), // REDUCED icon size
              const SizedBox(width: 3), // REDUCED spacing
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10, // REDUCED font size
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
            blurRadius: 6, // REDUCED blur
            offset: const Offset(0, 3), // REDUCED offset
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14), // REDUCED radius
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
                  "Create New Assignment",
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
