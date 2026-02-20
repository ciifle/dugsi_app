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
        return kSoftPurple;
      case 'Primary':
        return kSoftBlue;
      case 'Secondary':
        return kAccentColor;
      case 'Higher Secondary':
        return kSoftOrange;
      default:
        return kSecondaryColor;
    }
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
            expandedHeight: _isSearching ? 80 : 90, // REDUCED from 120
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
                            Icons.class_rounded,
                            color: Colors.white,
                            size: 16, // REDUCED icon size
                          ),
                        ),
                        const SizedBox(width: 6), // REDUCED spacing
                        const Text(
                          "My Classes",
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
                      size: 18,
                    ), // REDUCED size
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
                      size: 18,
                    ), // REDUCED size
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
                            hintText: 'Search classes...',
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
                  totalClasses: allClasses.length,
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
                      'Found ${filteredClasses.length} class${filteredClasses.length != 1 ? 'es' : ''}',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 12, // REDUCED font size
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---------------- CLASSES HEADER ----------------
                if (_searchQuery.isEmpty)
                  _buildClassesHeader(filteredClasses.length),

                const SizedBox(height: 12), // REDUCED from 16
                // ---------------- CLASS CARDS ----------------
                if (filteredClasses.isNotEmpty)
                  ...List.generate(
                    filteredClasses.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ), // REDUCED from 16
                      child: _ClassCard(classData: filteredClasses[index]),
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
              "Filter by Class Type",
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
            children: List.generate(filterTypes.length, (index) {
              final filter = filterTypes[index];
              final bool isSelected = selectedFilter == index;
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
                      selectedFilter = index;
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
              padding: const EdgeInsets.all(4), // REDUCED padding
              decoration: BoxDecoration(
                color: kSoftOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6), // REDUCED radius
              ),
              child: const Icon(
                Icons.class_rounded,
                color: kSoftOrange,
                size: 14, // REDUCED icon size
              ),
            ),
            const SizedBox(width: 6), // REDUCED spacing
            const Text(
              "Class List",
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
            '$count classes',
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
                    : Icons.class_outlined,
                color: kSoftPurple,
                size: 36, // REDUCED icon size
              ),
            ),
            const SizedBox(height: 12), // REDUCED spacing
            Text(
              _searchQuery.isNotEmpty
                  ? 'No classes found'
                  : 'No classes available',
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
                  : 'Add classes to get started',
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
              borderRadius: BorderRadius.circular(14), // REDUCED radius
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
                  ), // REDUCED padding
                  decoration: BoxDecoration(
                    color: kSoftPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10), // REDUCED radius
                  ),
                  child: Text(
                    "Total Classes: $totalClasses",
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
}

// ---------------- CLASS CARD ----------------
class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;

  const _ClassCard({required this.classData});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Primary':
        return kSoftBlue;
      case 'Secondary':
        return kAccentColor;
      case 'Higher Secondary':
        return kSoftOrange;
      default:
        return kSoftPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(classData['category']);

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
                colors: [categoryColor, categoryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12), // REDUCED radius
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.3),
                  blurRadius: 5, // REDUCED blur
                  offset: const Offset(0, 2), // REDUCED offset
                ),
              ],
            ),
            child: Icon(
              classData['icon'] ?? Icons.class_rounded,
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
                      classData['className'],
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
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12), // REDUCED radius
                    ),
                    child: Text(
                      classData['category'],
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 9, // REDUCED font size
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3), // REDUCED spacing
              Text(
                classData['subject'],
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
                    icon: Icons.people_rounded,
                    value: "${classData['totalStudents']}",
                    label: "Students",
                    color: kSoftPurple,
                  ),
                  _buildInfoChip(
                    icon: Icons.schedule_rounded,
                    value: "${classData['weeklyPeriods']}",
                    label: "Periods",
                    color: kSoftOrange,
                  ),
                  _buildInfoChip(
                    icon: Icons.access_time_rounded,
                    value: classData['timing'].split(
                      ' ',
                    )[0], // Just show start time
                    label: "Time",
                    color: kSoftBlue,
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: kSecondaryColor,
            size: 20, // REDUCED size
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8), // REDUCED spacing
            _buildDetailRow(
              icon: Icons.menu_book_rounded,
              label: "Syllabus",
              value: classData['syllabus'],
              color: kSoftPurple,
            ),
            if (classData['classTeacher'] == 'Yes')
              Padding(
                padding: const EdgeInsets.only(bottom: 6), // REDUCED padding
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
                color: kSoftPink,
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
                ),
                _buildActionChip(
                  icon: Icons.check_circle_rounded,
                  label: "Attendance",
                  color: kSoftBlue,
                ),
                _buildActionChip(
                  icon: Icons.assignment_rounded,
                  label: "Assignments",
                  color: kAccentColor,
                ),
                _buildActionChip(
                  icon: Icons.assessment_rounded,
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
      padding: const EdgeInsets.only(bottom: 6), // REDUCED padding
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
        borderRadius: BorderRadius.circular(16), // REDUCED radius
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
            borderRadius: BorderRadius.circular(16), // REDUCED radius
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
