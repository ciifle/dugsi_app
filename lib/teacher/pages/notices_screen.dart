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

enum NoticeStatus { active, draft, expired }

class Notice {
  final String id;
  String title;
  String description;
  String fullContent;
  String targetAudience;
  String createdDate;
  NoticeStatus status;
  String type;
  IconData icon;
  String? attachedInfo;
  String? notes;

  Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.fullContent,
    required this.targetAudience,
    required this.createdDate,
    required this.status,
    required this.type,
    required this.icon,
    this.attachedInfo,
    this.notes,
  });
}

final List<Notice> dummyNotices = [
  Notice(
    id: 'n1',
    title: 'PTM Announcement',
    description: 'Parent Teacher Meeting scheduled for 5th Jun.',
    fullContent:
        'Dear Parents, You are requested to attend the PTM on June 5th at 10AM in the school auditorium.',
    targetAudience: 'All Students',
    createdDate: '2024-05-22',
    status: NoticeStatus.active,
    type: 'general',
    attachedInfo: 'PTM Agenda: Curriculum updates, feedback, Q&A.',
    notes: null,
    icon: Icons.campaign_rounded,
  ),
  Notice(
    id: 'n2',
    title: 'Test Reminder',
    description: 'Class 8B Math test on Thursday.',
    fullContent:
        'This is to remind all students of Class 8B about the Math test scheduled for Thursday.',
    targetAudience: 'Class 8B',
    createdDate: '2024-05-20',
    status: NoticeStatus.draft,
    type: 'class',
    attachedInfo: null,
    notes: 'Draft. Edit before sending.',
    icon: Icons.class_rounded,
  ),
  Notice(
    id: 'n3',
    title: 'Science Exam Guidelines',
    description: 'Important rules for mid-term Science exams.',
    fullContent:
        'Students must carry their own stationery. No electronic devices allowed.',
    targetAudience: 'All Students',
    createdDate: '2024-05-15',
    status: NoticeStatus.expired,
    type: 'exam',
    attachedInfo: null,
    notes: null,
    icon: Icons.science_rounded,
  ),
  Notice(
    id: 'n4',
    title: 'Assembly Timing Change',
    description: 'Morning assembly to start 15min early.',
    fullContent:
        'Assembly will begin at 8:15AM, effective next week, for all classes.',
    targetAudience: 'All Students',
    createdDate: '2024-05-17',
    status: NoticeStatus.active,
    type: 'general',
    attachedInfo: 'Be present on time. Latecomers will be noted.',
    notes: null,
    icon: Icons.access_time_rounded,
  ),
];

const List<_NoticeFilter> _filters = [
  _NoticeFilter(label: "All", value: "all"),
  _NoticeFilter(label: "Class", value: "class"),
  _NoticeFilter(label: "Exam", value: "exam"),
  _NoticeFilter(label: "General", value: "general"),
];

class TeacherNoticesScreen extends StatefulWidget {
  const TeacherNoticesScreen({Key? key}) : super(key: key);

  @override
  State<TeacherNoticesScreen> createState() => _TeacherNoticesScreenState();
}

class _TeacherNoticesScreenState extends State<TeacherNoticesScreen> {
  String _selectedFilter = "all";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Notice> _notices = List.from(dummyNotices);

  List<Notice> get _filteredNotices {
    List<Notice> searchFiltered = _notices;
    if (_searchQuery.isNotEmpty) {
      searchFiltered = _notices.where((n) {
        final query = _searchQuery.toLowerCase();
        return n.title.toLowerCase().contains(query) ||
            n.description.toLowerCase().contains(query) ||
            n.targetAudience.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedFilter == "all") {
      return searchFiltered;
    } else {
      return searchFiltered.where((n) => n.type == _selectedFilter).toList();
    }
  }

  int get _totalCount => _notices.length;
  int get _activeCount =>
      _notices.where((n) => n.status == NoticeStatus.active).length;
  int get _draftCount =>
      _notices.where((n) => n.status == NoticeStatus.draft).length;

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

  void _deleteNotice(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildDeleteDialog(id);
      },
    );
  }

  Widget _buildDeleteDialog(String id) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: kErrorColor.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kErrorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: kErrorColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Delete Notice",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Are you sure you want to delete this notice? This action cannot be undone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kTextSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kErrorColor, kErrorColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kErrorColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _notices.removeWhere((notice) => notice.id == id);
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              _buildSuccessSnackBar(
                                "Notice deleted successfully",
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: const Center(
                              child: Text(
                                "Delete",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editNotice(Notice notice) {
    TextEditingController titleController = TextEditingController(
      text: notice.title,
    );
    TextEditingController descController = TextEditingController(
      text: notice.description,
    );
    TextEditingController contentController = TextEditingController(
      text: notice.fullContent,
    );
    TextEditingController audienceController = TextEditingController(
      text: notice.targetAudience,
    );
    TextEditingController attachedInfoController = TextEditingController(
      text: notice.attachedInfo ?? '',
    );
    TextEditingController notesController = TextEditingController(
      text: notice.notes ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, kSoftBlue],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fixed Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
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
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          "Edit Notice",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildDialogField(
                          controller: titleController,
                          label: "Title",
                          icon: Icons.title_rounded,
                          color: kPrimaryBlue,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          controller: descController,
                          label: "Description",
                          icon: Icons.description_rounded,
                          color: kPrimaryGreen,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          controller: contentController,
                          label: "Full Content",
                          icon: Icons.note_alt_rounded,
                          color: kSoftOrange,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          controller: audienceController,
                          label: "Target Audience",
                          icon: Icons.person_rounded,
                          color: kDarkBlue,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          controller: attachedInfoController,
                          label: "Attached Info",
                          icon: Icons.attach_file_rounded,
                          color: kPrimaryGreen,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          controller: notesController,
                          label: "Notes",
                          icon: Icons.note_rounded,
                          color: kSoftOrange,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Fixed Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: kTextSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kPrimaryBlue, kPrimaryGreen],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  notice.title = titleController.text;
                                  notice.description = descController.text;
                                  notice.fullContent = contentController.text;
                                  notice.targetAudience =
                                      audienceController.text;
                                  notice.attachedInfo =
                                      attachedInfoController.text.isNotEmpty
                                      ? attachedInfoController.text
                                      : null;
                                  notice.notes = notesController.text.isNotEmpty
                                      ? notesController.text
                                      : null;
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  _buildSuccessSnackBar(
                                    "Notice updated successfully",
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: const Center(
                                  child: Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    int maxLines = 1,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: 1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          floatingLabelStyle: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 18),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          isDense: true,
        ),
        style: const TextStyle(color: kTextPrimary, fontSize: 14),
      ),
    );
  }

  void _togglePublishStatus(Notice notice) {
    setState(() {
      if (notice.status == NoticeStatus.active) {
        notice.status = NoticeStatus.draft;
      } else {
        notice.status = NoticeStatus.active;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSuccessSnackBar(
        notice.status == NoticeStatus.active
            ? "Notice published successfully"
            : "Notice unpublished successfully",
      ),
    );
  }

  void _viewNotice(Notice notice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildViewDialog(notice);
      },
    );
  }

  Widget _buildViewDialog(Notice notice) {
    final statusColor = _getStatusColor(notice.status);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, kSoftBlue],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
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
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(notice.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notice.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(notice.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildViewInfoRow(
                      "Description",
                      notice.description,
                      kPrimaryBlue,
                    ),
                    const SizedBox(height: 12),
                    _buildViewInfoRow(
                      "Full Content",
                      notice.fullContent,
                      kPrimaryGreen,
                    ),
                    const SizedBox(height: 12),
                    _buildViewInfoRow(
                      "Target Audience",
                      notice.targetAudience,
                      kSoftOrange,
                    ),
                    const SizedBox(height: 12),
                    _buildViewInfoRow("Date", notice.createdDate, kDarkBlue),
                    if (notice.attachedInfo != null) ...[
                      const SizedBox(height: 12),
                      _buildViewInfoRow(
                        "Attached Info",
                        notice.attachedInfo!,
                        kPrimaryBlue,
                      ),
                    ],
                    if (notice.notes != null) ...[
                      const SizedBox(height: 12),
                      _buildViewInfoRow("Notes", notice.notes!, kSoftOrange),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Close Button
            Container(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryBlue, kPrimaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Text(
                        "Close",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewInfoRow(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: kTextPrimary),
          ),
        ],
      ),
    );
  }

  SnackBar _buildSuccessSnackBar(String message) {
    return SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: kPrimaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      duration: const Duration(seconds: 2),
    );
  }

  Color _getStatusColor(NoticeStatus status) {
    switch (status) {
      case NoticeStatus.active:
        return kPrimaryGreen;
      case NoticeStatus.draft:
        return kSoftOrange;
      case NoticeStatus.expired:
        return kErrorColor;
    }
  }

  String _getStatusText(NoticeStatus status) {
    switch (status) {
      case NoticeStatus.active:
        return 'Active';
      case NoticeStatus.draft:
        return 'Draft';
      case NoticeStatus.expired:
        return 'Expired';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotices;

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
                        "Notices",
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
                            hintText: 'Search notices...',
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
                _NoticeSummaryCard(
                  total: _totalCount,
                  active: _activeCount,
                  draft: _draftCount,
                ),
                const SizedBox(height: 20),
                _buildFilterSection(),
                const SizedBox(height: 16),

                // ---------------- SEARCH RESULT COUNT ----------------
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Found ${filtered.length} notice${filtered.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---------------- NOTICES HEADER ----------------
                if (_searchQuery.isEmpty) _buildNoticesHeader(filtered.length),

                const SizedBox(height: 12),

                // ---------------- NOTICE CARDS ----------------
                if (filtered.isNotEmpty)
                  ...List.generate(
                    filtered.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NoticeCard(
                        notice: filtered[index],
                        onView: () => _viewNotice(filtered[index]),
                        onEdit: () => _editNotice(filtered[index]),
                        onTogglePublish: () =>
                            _togglePublishStatus(filtered[index]),
                        onDelete: () => _deleteNotice(filtered[index].id),
                      ),
                    ),
                  )
                else
                  _buildEmptyState(),

                const SizedBox(height: 20),

                // ---------------- CREATE BUTTON ----------------
                _CreateNoticeCTAButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      _buildSuccessSnackBar("Create Notice - Coming Soon!"),
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
    final filters = _filters;

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
              "Filter by Type",
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
              final bool isSelected = _selectedFilter == filter.value;
              final Color filterColor = _getFilterColor(filter.value);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    filter.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = filter.value;
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

  Widget _buildNoticesHeader(int count) {
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
                Icons.campaign_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Notice List",
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
                    : Icons.campaign_rounded,
                color: kPrimaryBlue,
                size: 56,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'No notices found' : 'No notices',
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
                  : 'Create your first notice',
              style: TextStyle(color: kTextSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'all':
        return kPrimaryBlue;
      case 'class':
        return kPrimaryBlue;
      case 'exam':
        return kPrimaryGreen;
      case 'general':
        return kSoftOrange;
      default:
        return kPrimaryBlue;
    }
  }
}

// ---------------- SUMMARY CARD ----------------
class _NoticeSummaryCard extends StatelessWidget {
  final int total;
  final int active;
  final int draft;

  const _NoticeSummaryCard({
    required this.total,
    required this.active,
    required this.draft,
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
                'Notice Overview',
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
                icon: Icons.campaign_rounded,
                label: "Active",
                value: "$active",
                color: kPrimaryGreen,
              ),
              _buildStatItem(
                icon: Icons.edit_note_rounded,
                label: "Draft",
                value: "$draft",
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

// ---------------- NOTICE CARD ----------------
class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublish;
  final VoidCallback onDelete;

  const _NoticeCard({
    required this.notice,
    required this.onView,
    required this.onEdit,
    required this.onTogglePublish,
    required this.onDelete,
  });

  Color _getStatusColor(NoticeStatus status) {
    switch (status) {
      case NoticeStatus.active:
        return kPrimaryGreen;
      case NoticeStatus.draft:
        return kSoftOrange;
      case NoticeStatus.expired:
        return kErrorColor;
    }
  }

  String _getStatusText(NoticeStatus status) {
    switch (status) {
      case NoticeStatus.active:
        return 'Active';
      case NoticeStatus.draft:
        return 'Draft';
      case NoticeStatus.expired:
        return 'Expired';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(notice.status);
    final statusText = _getStatusText(notice.status);

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
        border: Border.all(
          color: notice.status == NoticeStatus.active
              ? statusColor.withOpacity(0.3)
              : Colors.grey.shade100,
          width: 1.5,
        ),
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
            child: Icon(notice.icon, color: Colors.white, size: 24),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notice.title,
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
                notice.description,
                style: TextStyle(color: kTextSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.person_rounded,
                    value: notice.targetAudience,
                    color: kPrimaryBlue,
                  ),
                  _buildInfoChip(
                    icon: Icons.calendar_today_rounded,
                    value: notice.createdDate,
                    color: kSoftOrange,
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: statusColor,
            size: 24,
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.info_rounded,
              label: "Full Notice",
              value: notice.fullContent,
              color: kPrimaryBlue,
            ),
            if (notice.attachedInfo != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.attach_file_rounded,
                label: "Attachment",
                value: notice.attachedInfo!,
                color: kPrimaryGreen,
              ),
            ],
            if (notice.notes != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.note_alt_rounded,
                label: "Notes",
                value: notice.notes!,
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
                  label: "View",
                  color: kPrimaryBlue,
                  onTap: onView,
                ),
                _buildActionChip(
                  icon: Icons.edit_rounded,
                  label: "Edit",
                  color: kPrimaryGreen,
                  onTap: onEdit,
                ),
                _buildActionChip(
                  icon: notice.status == NoticeStatus.active
                      ? Icons.visibility_off_rounded
                      : Icons.publish_rounded,
                  label: notice.status == NoticeStatus.active
                      ? "Unpublish"
                      : "Publish",
                  color: kSoftOrange,
                  onTap: onTogglePublish,
                ),
                _buildActionChip(
                  icon: Icons.delete_rounded,
                  label: "Delete",
                  color: kErrorColor,
                  onTap: onDelete,
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
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
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

// ---------------- CREATE BUTTON ----------------
class _CreateNoticeCTAButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateNoticeCTAButton({required this.onPressed});

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
                  "Create New Notice",
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

class _NoticeFilter {
  final String label;
  final String value;
  const _NoticeFilter({required this.label, required this.value});
}
