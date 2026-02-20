import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------- WONDERFUL COLOR PALETTE (Matching Dashboard) ----------
const Color kPrimaryColor = Color(0xFF1E3A8A); // Deep indigo
const Color kSecondaryColor = Color(0xFF3B82F6); // Bright blue
const Color kAccentColor = Color(0xFF10B981); // Emerald green
const Color kSoftPurple = Color(0xFF8B5CF6); // Light purple
const Color kSoftPink = Color(0xFFEC4899); // Pink
const Color kSoftOrange = Color(0xFFF59E0B); // Amber
const Color kSoftBlue = Color(0xFF3B82F6); // Sky blue
const Color kSuccessColor = Color(0xFF059669); // Dark green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kBackgroundColor = Color(0xFFF8FAFC); // Light background
const Color kSurfaceColor = Colors.white;
const Color kTextPrimaryColor = Color(0xFF1E293B); // Dark slate
const Color kTextSecondaryColor = Color(0xFF64748B); // Medium slate

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [Color(0xFF1E3A8A), Color(0xFF3B82F6)];
const List<Color> kSuccessGradient = [Color(0xFF10B981), Color(0xFF34D399)];
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

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR WITH SEARCH FUNCTIONALITY ----------------
          SliverAppBar(
            expandedHeight: _isSearching ? 80 : 100,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              title: _isSearching
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Activities",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryColor, kSecondaryColor],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isSearching)
                // Close button when searching
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _stopSearch,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                )
              else
                // Search button when not searching
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _startSearch,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
            // Search bar that appears when searching
            bottom: _isSearching
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
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
                            hintText: 'Search activities...',
                            hintStyle: TextStyle(
                              color: kTextSecondaryColor,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: kSecondaryColor,
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
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            color: kTextPrimaryColor,
                            fontSize: 14,
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
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------------- ACTIVITY SUMMARY CARD ----------------
                      _ActivitySummaryCard(
                        total: getTotal(),
                        completed: getCompleted(),
                        pending: getPending(),
                        overdue: getOverdue(),
                      ),

                      const SizedBox(height: 20),

                      // ---------------- FILTER CHIPS ----------------
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
    );
  }

  Widget _buildActivitiesHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.list_alt_rounded,
                color: kSoftPurple,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: kTextPrimaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kSoftOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count items',
            style: TextStyle(
              color: kSoftOrange,
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
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.inbox_rounded,
                color: kSoftPurple,
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

// ---------- WIDGETS ----------

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSoftPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: kSoftPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Activity Summary',
                style: TextStyle(
                  color: kTextPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryInfo(
                label: 'Total',
                count: total,
                color: kSoftPurple,
                icon: Icons.assignment_rounded,
              ),
              _SummaryInfo(
                label: 'Completed',
                count: completed,
                color: kSuccessColor,
                icon: Icons.check_circle_rounded,
              ),
              _SummaryInfo(
                label: 'Pending',
                count: pending,
                color: kWarningColor,
                icon: Icons.pending_rounded,
              ),
              _SummaryInfo(
                label: 'Overdue',
                count: overdue,
                color: kErrorColor,
                icon: Icons.warning_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryInfo extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryInfo({
    Key? key,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: kTextSecondaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
              backgroundColor: kSurfaceColor,
              selectedColor: kSecondaryColor,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(
                color: isSelected ? kSecondaryColor : Colors.grey.shade300,
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
        return kSuccessColor;
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
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDueSoon
              ? kWarningColor.withOpacity(0.3)
              : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: kAccentColor.withOpacity(0.07),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type),
              size: 22,
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
                        fontSize: 15,
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getStatusIcon(activity.status),
                          color: statusColor,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                activity.subject,
                style: TextStyle(color: kTextSecondaryColor, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: isOverdue
                        ? kErrorColor
                        : isDueSoon
                        ? kWarningColor
                        : kTextSecondaryColor,
                  ),
                  const SizedBox(width: 4),
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
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kSoftPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity.type,
                      style: TextStyle(
                        color: kSoftPurple,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: kSecondaryColor,
            size: 22,
          ),
          children: [
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            // Description
            _buildDetailRow(
              icon: Icons.description_rounded,
              label: 'Description',
              value: activity.description,
              color: kSoftBlue,
            ),
            const SizedBox(height: 8),
            // Submission info if available
            if (activity.submissionDate != null) ...[
              _buildDetailRow(
                icon: Icons.check_circle_rounded,
                label: 'Submitted',
                value: DateFormat(
                  'dd MMM yyyy',
                ).format(activity.submissionDate!),
                color: kSuccessColor,
              ),
              const SizedBox(height: 8),
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
            children: [
              Text(
                label,
                style: TextStyle(
                  color: kTextSecondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(color: kTextPrimaryColor, fontSize: 13),
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
        return kSoftBlue;
      case "Classwork":
        return kSoftPink;
      case "Practical":
        return kAccentColor;
      default:
        return kSecondaryColor;
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
