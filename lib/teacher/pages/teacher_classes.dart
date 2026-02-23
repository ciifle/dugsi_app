import 'package:flutter/material.dart';
import 'package:kobac/teacher/pages/assignments_screen.dart';
import 'package:kobac/teacher/pages/attendance_mark.dart';
import 'package:kobac/teacher/pages/exams_results.dart';
import 'package:kobac/teacher/pages/students_screen.dart';

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

class TeacherMyClassesScreen extends StatefulWidget {
  const TeacherMyClassesScreen({Key? key}) : super(key: key);

  @override
  State<TeacherMyClassesScreen> createState() => _TeacherMyClassesScreenState();
}

class _TeacherMyClassesScreenState extends State<TeacherMyClassesScreen> {
  final String teacherName = "Mrs. Olivia Bennett";
  final String subtitle = "Your assigned subject classes are listed below.";
  final List<String> filterTypes = [
    "All",
    "Primary",
    "Secondary",
    "Higher Secondary",
  ];
  int selectedFilter = 0;

  // Search functionality
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> allClasses = [
    {
      "category": "Primary",
      "className": "Grade 3 – B",
      "subject": "Mathematics",
      "totalStudents": 27,
      "weeklyPeriods": 5,
      "timing": "8:30 AM - 9:20 AM",
      "syllabus":
          "Numbers, Addition & Subtraction, Basic Geometry, Problem Solving.",
      "classTeacher": "Yes",
      "notes": "Support required for slow learners.",
      "icon": Icons.calculate_rounded,
    },
    {
      "category": "Secondary",
      "className": "Grade 8 – A",
      "subject": "Science",
      "totalStudents": 32,
      "weeklyPeriods": 6,
      "timing": "10:15 AM - 11:05 AM",
      "syllabus": "Physics (Force, Energy), Chemistry (Mixtures), Biology.",
      "classTeacher": "No",
      "notes": "Lab work planned for next week.",
      "icon": Icons.science_rounded,
    },
    {
      "category": "Secondary",
      "className": "Grade 7 – C",
      "subject": "Mathematics",
      "totalStudents": 29,
      "weeklyPeriods": 5,
      "timing": "9:20 AM - 10:10 AM",
      "syllabus": "Algebra, Fractions, Ratios.",
      "classTeacher": "No",
      "notes": "",
      "icon": Icons.calculate_rounded,
    },
    {
      "category": "Higher Secondary",
      "className": "Grade 12 – Sci.",
      "subject": "Biology",
      "totalStudents": 18,
      "weeklyPeriods": 8,
      "timing": "11:15 AM - 12:05 PM",
      "syllabus":
          "Human Physiology, Plant Biology, Ecology, Genetics overview.",
      "classTeacher": "No",
      "notes": "Additional assignments sent to students.",
      "icon": Icons.biotech_rounded,
    },
    {
      "category": "Primary",
      "className": "Grade 5 – A",
      "subject": "Science",
      "totalStudents": 30,
      "weeklyPeriods": 4,
      "timing": "1:00 PM - 1:50 PM",
      "syllabus": "Plants, Animals, Water cycle.",
      "classTeacher": "Yes",
      "notes": "",
      "icon": Icons.science_rounded,
    },
  ];

  List<Map<String, dynamic>> get filteredClasses {
    // First apply search filter
    List<Map<String, dynamic>> searchFiltered = allClasses;
    if (_searchQuery.isNotEmpty) {
      searchFiltered = allClasses.where((classItem) {
        final query = _searchQuery.toLowerCase();
        return classItem['className'].toLowerCase().contains(query) ||
            classItem['subject'].toLowerCase().contains(query) ||
            classItem['category'].toLowerCase().contains(query);
      }).toList();
    }

    // Then apply category filter
    if (selectedFilter == 0) return searchFiltered;
    final type = filterTypes[selectedFilter];
    return searchFiltered.where((c) => c['category'] == type).toList();
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

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'All':
        return kPrimaryBlue;
      case 'Primary':
        return kPrimaryBlue;
      case 'Secondary':
        return kPrimaryGreen;
      case 'Higher Secondary':
        return kSoftOrange;
      default:
        return kPrimaryBlue;
    }
  }

  // Navigation methods
  void _navigateToStudents(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherStudentManagementScreen()),
    );
  }

  void _navigateToAttendance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherAttendanceScreen()),
    );
  }

  void _navigateToAssignments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherAssignmentsScreen()),
    );
  }

  void _navigateToResults(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherExamsResultsScreen()),
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
                        "My Classes",
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
                            hintText: 'Search classes...',
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
                  totalClasses: allClasses.length,
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
                      'Found ${filteredClasses.length} class${filteredClasses.length != 1 ? 'es' : ''}',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---------------- CLASSES HEADER ----------------
                if (_searchQuery.isEmpty)
                  _buildClassesHeader(filteredClasses.length),

                const SizedBox(height: 12),

                // ---------------- CLASS CARDS ----------------
                if (filteredClasses.isNotEmpty)
                  ...List.generate(
                    filteredClasses.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ClassCard(
                        classData: filteredClasses[index],
                        onStudentsTap: () => _navigateToStudents(context),
                        onAttendanceTap: () => _navigateToAttendance(context),
                        onAssignmentsTap: () => _navigateToAssignments(context),
                        onResultsTap: () => _navigateToResults(context),
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
              "Filter by Class Type",
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
            children: List.generate(filterTypes.length, (index) {
              final filter = filterTypes[index];
              final bool isSelected = selectedFilter == index;
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
                      selectedFilter = index;
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
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildClassesHeader(int count) {
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
                Icons.class_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Class List",
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
            '$count classes',
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
                    : Icons.class_outlined,
                color: kPrimaryBlue,
                size: 56,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No classes found'
                  : 'No classes available',
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
                  : 'Add classes to get started',
              style: TextStyle(color: kTextSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- TEACHER INTRO CARD ----------------
class _TeacherIntroCard extends StatelessWidget {
  final String teacherName;
  final int totalClasses;
  final String subtitle;

  const _TeacherIntroCard({
    required this.teacherName,
    required this.totalClasses,
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
                    "Total Classes: $totalClasses",
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
}

// ---------------- CLASS CARD ----------------
class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final VoidCallback onStudentsTap;
  final VoidCallback onAttendanceTap;
  final VoidCallback onAssignmentsTap;
  final VoidCallback onResultsTap;

  const _ClassCard({
    required this.classData,
    required this.onStudentsTap,
    required this.onAttendanceTap,
    required this.onAssignmentsTap,
    required this.onResultsTap,
  });

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Primary':
        return kPrimaryBlue;
      case 'Secondary':
        return kPrimaryGreen;
      case 'Higher Secondary':
        return kSoftOrange;
      default:
        return kPrimaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(classData['category']);

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
                colors: [categoryColor, categoryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              classData['icon'] ?? Icons.class_rounded,
              color: Colors.white,
              size: 24,
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
                      classData['className'],
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
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      classData['category'],
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                classData['subject'],
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
                    icon: Icons.people_rounded,
                    value: "${classData['totalStudents']}",
                    label: "Students",
                    color: kPrimaryBlue,
                  ),
                  _buildInfoChip(
                    icon: Icons.schedule_rounded,
                    value: "${classData['weeklyPeriods']}",
                    label: "Periods",
                    color: kSoftOrange,
                  ),
                  _buildInfoChip(
                    icon: Icons.access_time_rounded,
                    value: classData['timing'].split(' ')[0],
                    label: "Time",
                    color: kPrimaryGreen,
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: categoryColor,
            size: 24,
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.menu_book_rounded,
              label: "Syllabus",
              value: classData['syllabus'],
              color: kPrimaryBlue,
            ),
            if (classData['classTeacher'] == 'Yes')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDetailRow(
                  icon: Icons.star_rounded,
                  label: "Class Teacher",
                  value: "You are the class teacher",
                  color: kSoftOrange,
                ),
              ),
            if (classData['notes'] != null &&
                classData['notes'].toString().isNotEmpty)
              _buildDetailRow(
                icon: Icons.note_alt_rounded,
                label: "Notes",
                value: classData['notes'],
                color: kPrimaryGreen,
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
                  icon: Icons.check_circle_rounded,
                  label: "Attendance",
                  color: kPrimaryGreen,
                  onTap: onAttendanceTap,
                ),
                _buildActionChip(
                  icon: Icons.assignment_rounded,
                  label: "Assignments",
                  color: kSoftOrange,
                  onTap: onAssignmentsTap,
                ),
                _buildActionChip(
                  icon: Icons.assessment_rounded,
                  label: "Results",
                  color: kErrorColor,
                  onTap: onResultsTap,
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
      padding: const EdgeInsets.only(bottom: 8),
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
