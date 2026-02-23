import 'package:flutter/material.dart';
import 'package:kobac/teacher/pages/assignments_screen.dart';
import 'package:kobac/teacher/pages/attendance_mark.dart';
import 'package:kobac/teacher/pages/exams_results.dart';

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

  // Navigation methods
  void _navigateToAttendance(BuildContext context, Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherAttendanceScreen()),
    ).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viewing attendance for ${student.name}'),
          backgroundColor: kPrimaryBlue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  void _navigateToAssignments(BuildContext context, Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherAssignmentsScreen()),
    ).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viewing assignments for ${student.name}'),
          backgroundColor: kPrimaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  void _navigateToGrades(BuildContext context, Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherExamsResultsScreen()),
    ).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viewing grades for ${student.name}'),
          backgroundColor: kSoftOrange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  void _sendMessage(BuildContext context, Student student) {
    // Show message dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController messageController = TextEditingController();

        return AlertDialog(
          title: Text(
            'Message to ${student.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kPrimaryBlue,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kPrimaryBlue, width: 2),
                ),
              ),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Cancel', style: TextStyle(color: kTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message sent to ${student.name}'),
                    backgroundColor: kSuccessColor,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
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
                        "Students",
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
                            hintText: 'Search students...',
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
                // ---------------- TEACHER INTRO CARD ----------------
                _TeacherIntroCard(
                  teacherName: teacherName,
                  totalStudents: allStudents.length,
                  subtitle: subtitle,
                ),

                const SizedBox(height: 20),

                // ---------------- FILTER SECTION ----------------
                _buildFilterSection(),

                const SizedBox(height: 16),

                // ---------------- SEARCH RESULT COUNT ----------------
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Found ${filteredStudents.length} student${filteredStudents.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---------------- STUDENTS HEADER ----------------
                if (_searchQuery.isEmpty)
                  _buildStudentsHeader(filteredStudents.length),

                const SizedBox(height: 12),

                // ---------------- STUDENT CARDS ----------------
                if (filteredStudents.isNotEmpty)
                  ...List.generate(
                    filteredStudents.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StudentCard(
                        student: filteredStudents[index],
                        onAttendanceTap: () => _navigateToAttendance(
                          context,
                          filteredStudents[index],
                        ),
                        onAssignmentsTap: () => _navigateToAssignments(
                          context,
                          filteredStudents[index],
                        ),
                        onGradesTap: () =>
                            _navigateToGrades(context, filteredStudents[index]),
                        onMessageTap: () =>
                            _sendMessage(context, filteredStudents[index]),
                      ),
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
              "Filter Students",
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
              final bool isSelected = selectedFilter == filter;
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
                      selectedFilter = filter;
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

  Widget _buildStudentsHeader(int count) {
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
                Icons.people_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Student List",
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
            '$count students',
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
                    : Icons.people_outline_rounded,
                color: kPrimaryBlue,
                size: 56,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No students found'
                  : 'No students available',
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
                  : 'Add students to get started',
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
      case 'Grade 6':
        return kPrimaryBlue;
      case 'Grade 7':
        return kPrimaryGreen;
      case 'Top':
        return kSuccessColor;
      case 'Needs Attention':
        return kErrorColor;
      default:
        return kPrimaryBlue;
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  teacherName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Total: $totalStudents",
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
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
  final VoidCallback onAttendanceTap;
  final VoidCallback onAssignmentsTap;
  final VoidCallback onGradesTap;
  final VoidCallback onMessageTap;

  const _StudentCard({
    required this.student,
    required this.onAttendanceTap,
    required this.onAssignmentsTap,
    required this.onGradesTap,
    required this.onMessageTap,
  });

  Color _getPerformanceColor(String performance) {
    return performance == "Top" ? kSuccessColor : kErrorColor;
  }

  @override
  Widget build(BuildContext context) {
    final performanceColor = _getPerformanceColor(student.performance);

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
                colors: [performanceColor, performanceColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: performanceColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(student.icon, color: Colors.white, size: 24),
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
                      color: performanceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          student.performance == "Top"
                              ? Icons.star_rounded
                              : Icons.warning_rounded,
                          color: performanceColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          student.performance == "Top" ? "Top" : "Attention",
                          style: TextStyle(
                            color: performanceColor,
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
                "${student.grade} • Sec ${student.section}",
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
                    icon: Icons.event_available_rounded,
                    value: "${student.attendance}%",
                    label: "Attendance",
                    color: kPrimaryBlue,
                  ),
                  _buildInfoChip(
                    icon: Icons.assignment_rounded,
                    value: "${student.pendingAssignments}",
                    label: "Pending",
                    color: student.pendingAssignments > 0
                        ? kSoftOrange
                        : kSuccessColor,
                  ),
                  _buildInfoChip(
                    icon: Icons.grade_rounded,
                    value: student.averageGrade,
                    label: "Average",
                    color: kPrimaryGreen,
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: kPrimaryBlue,
            size: 24,
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.email_outlined,
              label: "Contact",
              value: student.contact,
              color: kPrimaryBlue,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.note_alt_rounded,
              label: "Remarks",
              value: student.remarks,
              color: kSoftOrange,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.flag_rounded,
              label: "Special Attention",
              value: student.specialAttention,
              color: kPrimaryGreen,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  icon: Icons.check_circle_rounded,
                  label: "Attendance",
                  color: kPrimaryBlue,
                  onTap: onAttendanceTap,
                ),
                _buildActionChip(
                  icon: Icons.assignment_rounded,
                  label: "Assignments",
                  color: kPrimaryGreen,
                  onTap: onAssignmentsTap,
                ),
                _buildActionChip(
                  icon: Icons.grade_rounded,
                  label: "Grades",
                  color: kSoftOrange,
                  onTap: onGradesTap,
                ),
                _buildActionChip(
                  icon: Icons.message_rounded,
                  label: "Message",
                  color: kErrorColor,
                  onTap: onMessageTap,
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
