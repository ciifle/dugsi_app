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
const Color kTextSecondary = Color(0xFF636E72); // Medium gray

class TeacherStudentManagementScreen extends StatefulWidget {
  const TeacherStudentManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeacherStudentManagementScreen> createState() =>
      _TeacherStudentManagementScreenState();
}

class _TeacherStudentManagementScreenState
    extends State<TeacherStudentManagementScreen> {
  final String teacherName = "Mrs. Katherine Johnson";
  final String subtitle = "Manage your students efficiently!";

  // Search functionality
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Student> allStudents = [
    Student(
      name: "Ava Carter",
      grade: "Grade 6",
      section: "A",
      attendance: 97,
      pendingAssignments: 1,
      averageGrade: "A+",
      performance: "Top",
      contact: "ava.carter@example.com, +1 (123) 555-0100",
      remarks: "Has shown excellent progress.",
      specialAttention: "None",
      icon: Icons.star_rounded,
    ),
    Student(
      name: "Liam Brown",
      grade: "Grade 6",
      section: "B",
      attendance: 82,
      pendingAssignments: 3,
      averageGrade: "B-",
      performance: "Needs Attention",
      contact: "liam.brown@example.com, +1 (123) 555-0101",
      remarks: "Needs encouragement for homework.",
      specialAttention: "Monitor participation",
      icon: Icons.person_rounded,
    ),
    Student(
      name: "Sofia Patel",
      grade: "Grade 7",
      section: "A",
      attendance: 90,
      pendingAssignments: 0,
      averageGrade: "A",
      performance: "Top",
      contact: "sofia.patel@example.com, +1 (123) 555-0102",
      remarks: "Great leadership skills.",
      specialAttention: "Encourage peer mentoring",
      icon: Icons.emoji_events_rounded,
    ),
    Student(
      name: "Ethan Lee",
      grade: "Grade 7",
      section: "A",
      attendance: 70,
      pendingAssignments: 4,
      averageGrade: "C",
      performance: "Needs Attention",
      contact: "ethan.lee@example.com, +1 (123) 555-0103",
      remarks: "Struggles with math concepts.",
      specialAttention: "Assign extra math sessions",
      icon: Icons.school_rounded,
    ),
    Student(
      name: "Maya Johnson",
      grade: "Grade 6",
      section: "A",
      attendance: 95,
      pendingAssignments: 0,
      averageGrade: "A",
      performance: "Top",
      contact: "maya.j@example.com, +1 (123) 555-0104",
      remarks: "Excellent participation.",
      specialAttention: "None",
      icon: Icons.auto_awesome_rounded,
    ),
    Student(
      name: "Noah Williams",
      grade: "Grade 7",
      section: "B",
      attendance: 88,
      pendingAssignments: 2,
      averageGrade: "B+",
      performance: "Needs Attention",
      contact: "noah.w@example.com, +1 (123) 555-0105",
      remarks: "Needs to focus more.",
      specialAttention: "Extra reading sessions",
      icon: Icons.menu_book_rounded,
    ),
  ];

  final List<String> gradeFilters = ["Grade 6", "Grade 7"];
  final List<String> performanceFilters = ["Top", "Needs Attention"];
  String selectedFilter = "All";

  List<Student> get filteredStudents {
    // First apply search filter
    List<Student> searchFiltered = allStudents;
    if (_searchQuery.isNotEmpty) {
      searchFiltered = allStudents.where((student) {
        final query = _searchQuery.toLowerCase();
        return student.name.toLowerCase().contains(query) ||
            student.grade.toLowerCase().contains(query) ||
            student.section.toLowerCase().contains(query) ||
            student.performance.toLowerCase().contains(query);
      }).toList();
    }

    // Then apply category filter
    if (selectedFilter == "All") return searchFiltered;
    if (gradeFilters.contains(selectedFilter)) {
      return searchFiltered.where((s) => s.grade == selectedFilter).toList();
    }
    if (performanceFilters.contains(selectedFilter)) {
      return searchFiltered
          .where((s) => s.performance == selectedFilter)
          .toList();
    }
    return searchFiltered;
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

  @override
  Widget build(BuildContext context) {
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
                            Icons.people_rounded,
                            color: Colors.white,
                            size: 16, // REDUCED icon size
                          ),
                        ),
                        const SizedBox(width: 6), // REDUCED spacing
                        const Text(
                          "Students",
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
                size: 20, // REDUCED size
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isSearching)
                // Close button when searching
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
                      size: 18, // REDUCED size
                    ),
                    onPressed: _stopSearch,
                    padding: const EdgeInsets.all(6), // REDUCED padding
                    constraints: const BoxConstraints(),
                  ),
                )
              else
                // Search button when not searching
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
                      size: 18, // REDUCED size
                    ),
                    onPressed: _startSearch,
                    padding: const EdgeInsets.all(6), // REDUCED padding
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
            // Search bar that appears when searching
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
                              blurRadius: 4, // REDUCED blur
                              offset: const Offset(0, 1), // REDUCED offset
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: _updateSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search students...',
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
                // ---------------- TEACHER INTRO CARD ----------------
                _TeacherIntroCard(
                  teacherName: teacherName,
                  totalStudents: allStudents.length,
                  subtitle: subtitle,
                ),

                const SizedBox(height: 16), // REDUCED from 20
                // ---------------- FILTER SECTION ----------------
                _buildFilterSection(),

                const SizedBox(height: 16), // REDUCED from 20
                // ---------------- SEARCH RESULT COUNT ----------------
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Found ${filteredStudents.length} student${filteredStudents.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 12, // REDUCED font size
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---------------- STUDENTS HEADER ----------------
                if (_searchQuery.isEmpty)
                  _buildStudentsHeader(filteredStudents.length),

                const SizedBox(height: 12), // REDUCED from 16
                // ---------------- STUDENT CARDS ----------------
                if (filteredStudents.isNotEmpty)
                  ...List.generate(
                    filteredStudents.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                      ), // REDUCED from 16
                      child: _StudentCard(student: filteredStudents[index]),
                    ),
                  )
                else
                  _buildEmptyState(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = ["All", ...gradeFilters, ...performanceFilters];

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
              "Filter Students",
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
              final bool isSelected = selectedFilter == filter;
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
                      selectedFilter = filter;
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
                    horizontal: 8, // REDUCED padding
                    vertical: 4, // REDUCED padding
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

  Widget _buildStudentsHeader(int count) {
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
                Icons.people_rounded,
                color: kSoftOrange,
                size: 14, // REDUCED icon size
              ),
            ),
            const SizedBox(width: 6), // REDUCED spacing
            const Text(
              "Student List",
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
            '$count students',
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
                    : Icons.people_outline_rounded,
                color: kSoftPurple,
                size: 36, // REDUCED icon size
              ),
            ),
            const SizedBox(height: 12), // REDUCED spacing
            Text(
              _searchQuery.isNotEmpty
                  ? 'No students found'
                  : 'No students available',
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
                  : 'Add students to get started',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 12,
              ), // REDUCED font size
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
      case 'Grade 6':
        return kSoftBlue;
      case 'Grade 7':
        return kAccentColor;
      case 'Top':
        return kSoftOrange;
      case 'Needs Attention':
        return kSoftPink;
      default:
        return kSecondaryColor;
    }
  }
}

// ---------------- TEACHER INTRO CARD ----------------
class _TeacherIntroCard extends StatelessWidget {
  final String teacherName;
  final int totalStudents;
  final String subtitle;

  const _TeacherIntroCard({
    required this.teacherName,
    required this.totalStudents,
    required this.subtitle,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // REDUCED padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kSoftPurple, kSoftBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16), // REDUCED radius
              boxShadow: [
                BoxShadow(
                  color: kSoftPurple.withOpacity(0.3),
                  blurRadius: 6, // REDUCED blur
                  offset: const Offset(0, 2), // REDUCED offset
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 22, // REDUCED icon size
            ),
          ),
          const SizedBox(width: 12), // REDUCED spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  teacherName,
                  style: const TextStyle(
                    fontSize: 15, // REDUCED font size
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3), // REDUCED spacing
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kSoftPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10), // REDUCED radius
                  ),
                  child: Text(
                    "Total: $totalStudents",
                    style: TextStyle(
                      color: kSoftPurple,
                      fontSize: 10, // REDUCED font size
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 3), // REDUCED spacing
                Text(
                  subtitle,
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                  ), // REDUCED font size
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- STUDENT CARD ----------------
class _StudentCard extends StatelessWidget {
  final Student student;

  const _StudentCard({required this.student});

  Color _getPerformanceColor(String performance) {
    return performance == "Top" ? kAccentColor : kSoftPink;
  }

  @override
  Widget build(BuildContext context) {
    final performanceColor = _getPerformanceColor(student.performance);

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
                colors: [performanceColor, performanceColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12), // REDUCED radius
              boxShadow: [
                BoxShadow(
                  color: performanceColor.withOpacity(0.3),
                  blurRadius: 5, // REDUCED blur
                  offset: const Offset(0, 2), // REDUCED offset
                ),
              ],
            ),
            child: Icon(
              student.icon,
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
                      student.name,
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
                      horizontal: 6, // REDUCED padding
                      vertical: 3, // REDUCED padding
                    ),
                    decoration: BoxDecoration(
                      color: performanceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16), // REDUCED radius
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          student.performance == "Top"
                              ? Icons.star_rounded
                              : Icons.warning_rounded,
                          color: performanceColor,
                          size: 10, // REDUCED icon size
                        ),
                        const SizedBox(width: 3), // REDUCED spacing
                        Text(
                          student.performance == "Top" ? "Top" : "Attention",
                          style: TextStyle(
                            color: performanceColor,
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
                "${student.grade} • Sec ${student.section}",
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                ), // REDUCED font size
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6), // REDUCED spacing
              Wrap(
                spacing: 8, // REDUCED spacing
                runSpacing: 6, // REDUCED spacing
                children: [
                  _buildInfoChip(
                    icon: Icons.event_available_rounded,
                    value: "${student.attendance}%",
                    label: "Att",
                    color: kSoftPurple,
                  ),
                  _buildInfoChip(
                    icon: Icons.assignment_rounded,
                    value: "${student.pendingAssignments}",
                    label: "Pend",
                    color: student.pendingAssignments > 0
                        ? kSoftOrange
                        : kAccentColor,
                  ),
                  _buildInfoChip(
                    icon: Icons.grade_rounded,
                    value: student.averageGrade,
                    label: "Grade",
                    color: kSoftBlue,
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: kSecondaryColor,
            size: 20, // REDUCED size
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.email_outlined,
              label: "Contact",
              value: student.contact,
              color: kSoftPurple,
            ),
            const SizedBox(height: 6), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.note_alt_rounded,
              label: "Remarks",
              value: student.remarks,
              color: kSoftOrange,
            ),
            const SizedBox(height: 6), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.flag_rounded,
              label: "Special",
              value: student.specialAttention,
              color: kSoftPink,
            ),
            const SizedBox(height: 8), // REDUCED spacing
            Wrap(
              spacing: 6, // REDUCED spacing
              runSpacing: 6, // REDUCED spacing
              children: [
                _buildActionChip(
                  icon: Icons.check_circle_rounded,
                  label: "Attend",
                  color: kSoftPurple,
                ),
                _buildActionChip(
                  icon: Icons.assignment_rounded,
                  label: "Assign",
                  color: kSoftBlue,
                ),
                _buildActionChip(
                  icon: Icons.grade_rounded,
                  label: "Grade",
                  color: kAccentColor,
                ),
                _buildActionChip(
                  icon: Icons.message_rounded,
                  label: "Msg",
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
                  fontSize: 8,
                ), // REDUCED font size
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
                    fontSize: 11,
                  ), // REDUCED font size
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

// Dummy student model
class Student {
  final String name;
  final String grade;
  final String section;
  final int attendance;
  final int pendingAssignments;
  final String averageGrade;
  final String performance;
  final String contact;
  final String remarks;
  final String specialAttention;
  final IconData icon;

  Student({
    required this.name,
    required this.grade,
    required this.section,
    required this.attendance,
    required this.pendingAssignments,
    required this.averageGrade,
    required this.performance,
    required this.contact,
    required this.remarks,
    required this.specialAttention,
    required this.icon,
  });
}
