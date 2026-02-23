import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------- WONDERFUL COLOR PALETTE (Matching Dashboard) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE0E9F5); // Light tint of blue
const Color kSoftGreen = Color(0xFFE4F1E2); // Light tint of green
const Color kDarkGreen = Color(0xFF3D8C30); // Darker shade of green
const Color kDarkBlue = Color(0xFF011A3D); // Darker shade of blue
const Color kSoftPurple = Color(0xFF4A6FA5); // Soft blue-purple
const Color kSoftPink = Color(0xFF7CB86E); // Soft green-pink
const Color kSoftOrange = Color(0xFFF59E0B); // Amber for warning
const Color kSuccessColor = Color(0xFF3D8C30); // Darker green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kBackgroundColor = Color(0xFFF5F8FC); // Light background
const Color kSurfaceColor = Colors.white;
const Color kTextPrimaryColor = Color(0xFF1A1E1F); // Dark slate
const Color kTextSecondaryColor = Color(0xFF4F5A5E); // Medium slate

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [kPrimaryBlue, kPrimaryGreen];
const List<Color> kSuccessGradient = [kPrimaryGreen, kDarkGreen];
const List<Color> kWarningGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];

// ---------- DUMMY ACTIVITY DATA ----------
class AcademicActivity {
  final String title;
  final String subject;
  final String type;
  final DateTime dueDate;
  final String status;
  final String description;
  final DateTime? submissionDate;
  final String? teacherRemark;

  AcademicActivity({
    required this.title,
    required this.subject,
    required this.type,
    required this.dueDate,
    required this.status,
    required this.description,
    this.submissionDate,
    this.teacherRemark,
  });
}

final List<AcademicActivity> dummyActivities = [
  AcademicActivity(
    title: "Algebra Homework 1",
    subject: "Mathematics",
    type: "Homework",
    dueDate: DateTime.now().add(const Duration(days: 2)),
    status: "Pending",
    description: "Solve all exercises from Chapter 3 (pages 34-36).",
  ),
  AcademicActivity(
    title: "Physics Assignment",
    subject: "Physics",
    type: "Assignment",
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
    status: "Late",
    description: "Write a report on Newton's Laws of Motion.",
    submissionDate: null,
    teacherRemark: null,
  ),
  AcademicActivity(
    title: "Chemistry Project",
    subject: "Chemistry",
    type: "Project",
    dueDate: DateTime.now().add(const Duration(days: 10)),
    status: "Pending",
    description: "Prepare a project on polymers and plastics.",
  ),
  AcademicActivity(
    title: "Art Class Drawing",
    subject: "Art",
    type: "Classwork",
    dueDate: DateTime.now().subtract(const Duration(days: 5)),
    status: "Submitted",
    description: "Draw a landscape using watercolors.",
    submissionDate: DateTime.now().subtract(const Duration(days: 3)),
    teacherRemark: "Excellent color technique!",
  ),
  AcademicActivity(
    title: "Computer Lab Practical",
    subject: "Computer Science",
    type: "Practical",
    dueDate: DateTime.now().add(const Duration(days: 3)),
    status: "Pending",
    description: "Implement a calculator in Python.",
  ),
  AcademicActivity(
    title: "English Essay",
    subject: "English",
    type: "Assignment",
    dueDate: DateTime.now(),
    status: "Submitted",
    description: "Write a 500-word essay on Shakespeare.",
    submissionDate: DateTime.now().subtract(const Duration(days: 1)),
    teacherRemark: "Well structured analysis.",
  ),
];

// ---------- FILTER CHIP DATA ----------
const List<String> filterCategories = [
  'All',
  'Assignments',
  'Projects',
  'Homework',
];

// ---------- MAIN SCREEN ----------
class StudentAcademicActivityScreen extends StatefulWidget {
  const StudentAcademicActivityScreen({Key? key}) : super(key: key);

  @override
  State<StudentAcademicActivityScreen> createState() =>
      _StudentAcademicActivityScreenState();
}

class _StudentAcademicActivityScreenState
    extends State<StudentAcademicActivityScreen>
    with SingleTickerProviderStateMixin {
  String selectedCategory = 'All';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<AcademicActivity> getFilteredActivities() {
    // First filter by category
    List<AcademicActivity> categoryFiltered;

    if (selectedCategory == 'All') {
      categoryFiltered = dummyActivities;
    } else {
      categoryFiltered = dummyActivities.where((a) {
        if (selectedCategory == 'Assignments') {
          return a.type == 'Assignment';
        }
        if (selectedCategory == 'Projects') {
          return a.type == 'Project';
        }
        if (selectedCategory == 'Homework') {
          return a.type == 'Homework';
        }
        return false;
      }).toList();
    }

    // Then filter by search query if searching
    if (_searchQuery.isNotEmpty) {
      return categoryFiltered.where((activity) {
        final searchLower = _searchQuery.toLowerCase();
        return activity.title.toLowerCase().contains(searchLower) ||
            activity.subject.toLowerCase().contains(searchLower) ||
            activity.type.toLowerCase().contains(searchLower) ||
            activity.description.toLowerCase().contains(searchLower);
      }).toList();
    }

    return categoryFiltered;
  }

  // Safe summary statistic calculation
  int getTotal() => getFilteredActivities().length;
  int getCompleted() =>
      getFilteredActivities().where((a) => a.status == 'Submitted').length;
  int getPending() =>
      getFilteredActivities().where((a) => a.status == 'Pending').length;
  int getOverdue() =>
      getFilteredActivities().where((a) => a.status == 'Late').length;

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
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activitiesToShow = getFilteredActivities();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kSoftBlue, kSoftGreen],
          stops: [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ---------------- REDESIGNED APP BAR (Matching Dashboard) ----------------
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Academic Activities",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "My Tasks",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Search/Close Button
                        GestureDetector(
                          onTap: _isSearching ? _stopSearch : _startSearch,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                _isSearching
                                    ? Icons.close_rounded
                                    : Icons.search_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Search Bar (if searching)
                    if (_isSearching) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: _updateSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search activities...',
                            hintStyle: TextStyle(
                              color: kTextSecondaryColor,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: kPrimaryBlue,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: kTextSecondaryColor,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _updateSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(
                            color: kTextPrimaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ---------------- MAIN CONTENT ----------------
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------------- REDESIGNED ACTIVITY SUMMARY CARD ----------------
                        _ActivitySummaryCard(
                          total: getTotal(),
                          completed: getCompleted(),
                          pending: getPending(),
                          overdue: getOverdue(),
                        ),

                        const SizedBox(height: 20),

                        // ---------------- REDESIGNED FILTER CHIPS ----------------
                        _ActivityFilterChips(
                          selectedCategory: selectedCategory,
                          onCategoryChange: (cat) {
                            setState(() {
                              selectedCategory = cat;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // ---------------- SEARCH RESULT COUNT ----------------
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'Found ${activitiesToShow.length} result${activitiesToShow.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: kTextSecondaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // ---------------- ACTIVITIES HEADER ----------------
                        if (_searchQuery.isEmpty)
                          _buildActivitiesHeader(activitiesToShow.length),

                        const SizedBox(height: 12),

                        // ---------------- ACTIVITY LIST CARDS ----------------
                        if (activitiesToShow.isNotEmpty)
                          ...List.generate(
                            activitiesToShow.length,
                            (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AcademicActivityCard(
                                activity: activitiesToShow[i],
                              ),
                            ),
                          )
                        else
                          _buildEmptyState(),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.list_alt_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kTextPrimaryColor,
              fontSize: 18,
            ),
          ),
          const Spacer(),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kSoftBlue, kSoftGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.inbox_rounded,
                color: kPrimaryBlue,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching activities'
                  : 'No activities found',
              style: TextStyle(
                color: kTextPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try different search terms'
                  : 'Try selecting a different category',
              style: TextStyle(color: kTextSecondaryColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- REDESIGNED WIDGETS ----------

class _ActivitySummaryCard extends StatelessWidget {
  final int total;
  final int completed;
  final int pending;
  final int overdue;
  const _ActivitySummaryCard({
    Key? key,
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, kSoftGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryBlue, kPrimaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Activity Summary',
                style: TextStyle(
                  color: kTextPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _buildEnhancedSummaryItem(
                label: 'Total',
                count: total,
                color: kPrimaryBlue,
                icon: Icons.assignment_rounded,
                bgColor: kSoftBlue,
              ),
              const SizedBox(width: 12),
              _buildEnhancedSummaryItem(
                label: 'Completed',
                count: completed,
                color: kPrimaryGreen,
                icon: Icons.check_circle_rounded,
                bgColor: kSoftGreen,
              ),
              const SizedBox(width: 12),
              _buildEnhancedSummaryItem(
                label: 'Pending',
                count: pending,
                color: kWarningColor,
                icon: Icons.pending_rounded,
                bgColor: kWarningColor.withOpacity(0.1),
              ),
              const SizedBox(width: 12),
              _buildEnhancedSummaryItem(
                label: 'Overdue',
                count: overdue,
                color: kErrorColor,
                icon: Icons.warning_rounded,
                bgColor: kErrorColor.withOpacity(0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryItem({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: kTextSecondaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityFilterChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChange;
  const _ActivityFilterChips({
    Key? key,
    required this.selectedCategory,
    required this.onCategoryChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filterCategories.map((cat) {
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : kTextPrimaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onCategoryChange(cat),
              backgroundColor: Colors.white,
              selectedColor: kPrimaryBlue,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(
                color: isSelected ? kPrimaryBlue : Colors.grey.shade300,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// REDESIGNED ACTIVITY CARD
class _AcademicActivityCard extends StatelessWidget {
  final AcademicActivity activity;
  const _AcademicActivityCard({Key? key, required this.activity})
    : super(key: key);

  String getFormattedDueDate(DateTime dt) {
    final now = DateTime.now();
    final difference = dt.difference(now).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Tomorrow";
    if (difference == -1) return "Yesterday";
    if (difference > 1 && difference < 7) return "In $difference days";
    if (difference < 0 && difference > -7) return "${-difference} days ago";

    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return kWarningColor;
      case "Submitted":
        return kPrimaryGreen;
      case "Late":
        return kErrorColor;
      default:
        return kTextSecondaryColor;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case "Pending":
        return Icons.pending_rounded;
      case "Submitted":
        return Icons.check_circle_rounded;
      case "Late":
        return Icons.warning_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(activity.status);
    final isOverdue = activity.status == "Late";
    final isDueSoon =
        !isOverdue &&
        activity.dueDate.difference(DateTime.now()).inDays <= 2 &&
        activity.dueDate.difference(DateTime.now()).inDays > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDueSoon
              ? kWarningColor.withOpacity(0.3)
              : isOverdue
              ? kErrorColor.withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: kPrimaryGreen.withOpacity(0.07),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getActivityColor(activity.type),
                  _getActivityColor(activity.type).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextPrimaryColor,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getStatusIcon(activity.status),
                          color: statusColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.status,
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
              const SizedBox(height: 6),
              Text(
                activity.subject,
                style: TextStyle(
                  color: kTextSecondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          (isOverdue
                                  ? kErrorColor
                                  : isDueSoon
                                  ? kWarningColor
                                  : kPrimaryBlue)
                              .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: isOverdue
                          ? kErrorColor
                          : isDueSoon
                          ? kWarningColor
                          : kPrimaryBlue,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    getFormattedDueDate(activity.dueDate),
                    style: TextStyle(
                      color: isOverdue
                          ? kErrorColor
                          : isDueSoon
                          ? kWarningColor
                          : kTextSecondaryColor,
                      fontWeight: isOverdue || isDueSoon
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getActivityColor(activity.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activity.type,
                      style: TextStyle(
                        color: _getActivityColor(activity.type),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: kPrimaryGreen,
              size: 20,
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Description
            _buildDetailRow(
              icon: Icons.description_rounded,
              label: 'Description',
              value: activity.description,
              color: kPrimaryBlue,
            ),
            const SizedBox(height: 12),
            // Submission info if available
            if (activity.submissionDate != null) ...[
              _buildDetailRow(
                icon: Icons.check_circle_rounded,
                label: 'Submitted',
                value: DateFormat(
                  'dd MMM yyyy',
                ).format(activity.submissionDate!),
                color: kPrimaryGreen,
              ),
              const SizedBox(height: 12),
            ],
            // Teacher remarks if available
            if (activity.teacherRemark != null) ...[
              _buildDetailRow(
                icon: Icons.format_quote_rounded,
                label: 'Remark',
                value: activity.teacherRemark!,
                color: kSoftOrange,
              ),
            ],
          ],
        ),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: kTextSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: kTextPrimaryColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case "Assignment":
        return kSoftPurple;
      case "Project":
        return kSoftOrange;
      case "Homework":
        return kPrimaryBlue;
      case "Classwork":
        return kSoftPink;
      case "Practical":
        return kPrimaryGreen;
      default:
        return kPrimaryBlue;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case "Assignment":
        return Icons.assignment_rounded;
      case "Project":
        return Icons.engineering_rounded;
      case "Homework":
        return Icons.book_rounded;
      case "Classwork":
        return Icons.class_rounded;
      case "Practical":
        return Icons.science_rounded;
      default:
        return Icons.task_rounded;
    }
  }
}
