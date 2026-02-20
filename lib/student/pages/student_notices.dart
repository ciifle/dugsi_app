import 'package:flutter/material.dart';

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

// Dummy Notice Data
class Notice {
  final String title;
  final String description;
  final DateTime date;
  final String category;
  final IconData icon;

  Notice({
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    required this.icon,
  });
}

final List<Notice> kDummyNotices = [
  Notice(
    title: "School Closed: National Holiday",
    description:
        "The school will remain closed on Monday, 24th June due to a national holiday. All scheduled classes and activities are cancelled. Please make sure to complete any pending assignments and enjoy your break!",
    date: DateTime(2024, 6, 20),
    category: "Important",
    icon: Icons.warning_amber_rounded,
  ),
  Notice(
    title: "Midterm Exam Schedule Released",
    description:
        "The Midterm Examination schedule has been uploaded to the Student Portal. Check exam dates, timings, and instructions. Carry your ID card for all exams.",
    date: DateTime(2024, 6, 18),
    category: "Exam",
    icon: Icons.event_available_rounded,
  ),
  Notice(
    title: "Inter-house Debate Competition",
    description:
        "Students interested in the Inter-house Debate Competition are required to register by Friday. Preliminary rounds start next week. For details, contact Ms. Carter.",
    date: DateTime(2024, 6, 16),
    category: "General",
    icon: Icons.mic_rounded,
  ),
  Notice(
    title: "Science Fair Projects Submission",
    description:
        "All science fair project reports must be submitted by 29th June. Late submissions will not be accepted. Please ensure your name and class are clearly mentioned.",
    date: DateTime(2024, 6, 14),
    category: "Important",
    icon: Icons.science_rounded,
  ),
  Notice(
    title: "Workshop: Exam Stress Management",
    description:
        "Join the wellness workshop on stress management for exams. Open to grades 9-12. Venue: AV Hall, Date: 21st June, Time: 2pm - 4pm.",
    date: DateTime(2024, 6, 13),
    category: "General",
    icon: Icons.psychology_rounded,
  ),
  Notice(
    title: "Mathematics Final Exam Venue Change",
    description:
        "The venue for the Mathematics final exam has changed from Room B102 to the Main Auditorium due to ongoing renovations. Please check your seat number before the exam.",
    date: DateTime(2024, 6, 11),
    category: "Exam",
    icon: Icons.calculate_rounded,
  ),
];

// Valid categories
const List<String> kNoticeCategories = ["All", "Important", "Exam", "General"];

class StudentNoticesScreen extends StatefulWidget {
  const StudentNoticesScreen({Key? key}) : super(key: key);

  @override
  State<StudentNoticesScreen> createState() => _StudentNoticesScreenState();
}

class _StudentNoticesScreenState extends State<StudentNoticesScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = "All";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Notice> get _filteredNotices {
    if (_selectedCategory == "All") return kDummyNotices;
    return kDummyNotices.where((n) => n.category == _selectedCategory).toList();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- STUNNING APP BAR ----------------
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Notices",
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
                      // ---------------- FILTER SECTION ----------------
                      _buildFilterSection(),

                      const SizedBox(height: 20),

                      // ---------------- NOTICES HEADER ----------------
                      _buildNoticesHeader(_filteredNotices.length),

                      const SizedBox(height: 16),

                      // ---------------- NOTICES LIST ----------------
                      ...List.generate(
                        _filteredNotices.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _NoticeCard(notice: _filteredNotices[index]),
                        ),
                      ),
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

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                Icons.filter_list_rounded,
                color: kSoftPurple,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Filter by Category",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kNoticeCategories.map((cat) {
              final bool isSelected = (_selectedCategory == cat);
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
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                  },
                  backgroundColor: kSurfaceColor,
                  selectedColor: _getCategoryColor(cat),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? _getCategoryColor(cat)
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNoticesHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kSoftOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: kSoftOrange,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Latest Notices",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextPrimaryColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kSoftPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count notice${count != 1 ? 's' : ''}',
            style: TextStyle(
              color: kSoftPurple,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Important":
        return kErrorColor;
      case "Exam":
        return kSoftBlue;
      case "General":
        return kSoftOrange;
      default:
        return kSecondaryColor;
    }
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  const _NoticeCard({required this.notice});

  Color get _badgeColor {
    switch (notice.category) {
      case "Important":
        return kErrorColor;
      case "Exam":
        return kSoftBlue;
      case "General":
      default:
        return kSoftOrange;
    }
  }

  String get _formattedDate {
    final now = DateTime.now();
    final difference = notice.date.difference(now).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";
    if (difference == -1) return "Tomorrow";
    if (difference > 1 && difference < 7)
      return "${notice.date.day} ${_getMonth(notice.date.month)}";
    return "${notice.date.day}/${notice.date.month}/${notice.date.year}";
  }

  String _getMonth(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: _badgeColor.withOpacity(0.07),
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
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_badgeColor.withOpacity(0.8), _badgeColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _badgeColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(notice.icon, color: Colors.white, size: 24),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notice.title,
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
                      color: _badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _badgeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notice.category,
                          style: TextStyle(
                            color: _badgeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: kTextSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formattedDate,
                    style: TextStyle(color: kTextSecondaryColor, fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: kTextSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getPreview(notice.description),
                      style: TextStyle(
                        color: kTextSecondaryColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _badgeColor,
            size: 22,
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _badgeColor.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notice.description,
                style: TextStyle(
                  color: kTextSecondaryColor,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreview(String description) {
    if (description.length <= 30) return description;
    return description.substring(0, 27) + "...";
  }
}
