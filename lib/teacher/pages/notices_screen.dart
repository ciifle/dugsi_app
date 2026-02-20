import 'package:flutter/material.dart';

// ---------- WONDERFUL COLOR PALETTE ----------
const Color kPrimaryColor = Color(0xFF2A2E45);
const Color kSecondaryColor = Color(0xFF6C5CE7);
const Color kAccentColor = Color(0xFF00B894);
const Color kSoftPurple = Color(0xFFA29BFE);
const Color kSoftPink = Color(0xFFFF7675);
const Color kSoftOrange = Color(0xFFFDCB6E);
const Color kSoftBlue = Color(0xFF74B9FF);
const Color kBackgroundEnd = Color(0xFFF5F0FF);
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF64748B);

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
  List<Notice> _notices = List.from(dummyNotices);

  List<Notice> get _filteredNotices {
    if (_selectedFilter == "all") {
      return _notices;
    } else {
      return _notices.where((n) => n.type == _selectedFilter).toList();
    }
  }

  int get _totalCount => _notices.length;
  int get _activeCount =>
      _notices.where((n) => n.status == NoticeStatus.active).length;
  int get _draftCount =>
      _notices.where((n) => n.status == NoticeStatus.draft).length;

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
              color: kSoftPink.withOpacity(0.2),
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
                      color: kSoftPink.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: kSoftPink,
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
                          colors: [kSoftPink, kSoftPink.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kSoftPink.withOpacity(0.3),
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
                colors: [Colors.white, kBackgroundEnd],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: kSoftPurple.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 0,
                  offset: const Offset(-2, -2),
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
                            colors: [kSoftPurple, kSoftBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: kSoftPurple.withOpacity(0.3),
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
                          color: kSoftPurple,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          controller: descController,
                          label: "Description",
                          icon: Icons.description_rounded,
                          color: kSoftBlue,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          controller: contentController,
                          label: "Full Content",
                          icon: Icons.note_alt_rounded,
                          color: kAccentColor,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          controller: audienceController,
                          label: "Target Audience",
                          icon: Icons.person_rounded,
                          color: kSoftOrange,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          controller: attachedInfoController,
                          label: "Attached Info",
                          icon: Icons.attach_file_rounded,
                          color: kSoftPink,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          controller: notesController,
                          label: "Notes",
                          icon: Icons.note_rounded,
                          color: kSoftPurple,
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
                              colors: [
                                kAccentColor,
                                kAccentColor.withOpacity(0.8),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kAccentColor.withOpacity(0.3),
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
            colors: [Colors.white, kBackgroundEnd],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: kSoftPurple.withOpacity(0.2),
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
                        colors: [kSoftPurple, kSoftBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kSoftPurple.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(notice.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      notice.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                      kSoftPurple,
                    ),
                    const SizedBox(height: 12),
                    _buildViewInfoRow(
                      "Full Content",
                      notice.fullContent,
                      kSoftBlue,
                    ),
                    const SizedBox(height: 12),
                    _buildViewInfoRow(
                      "Target Audience",
                      notice.targetAudience,
                      kSoftOrange,
                    ),
                    const SizedBox(height: 12),
                    _buildViewInfoRow("Date", notice.createdDate, kAccentColor),
                    if (notice.attachedInfo != null) ...[
                      const SizedBox(height: 12),
                      _buildViewInfoRow(
                        "Attached Info",
                        notice.attachedInfo!,
                        kSoftPink,
                      ),
                    ],
                    if (notice.notes != null) ...[
                      const SizedBox(height: 12),
                      _buildViewInfoRow("Notes", notice.notes!, kSoftPurple),
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
                  gradient: LinearGradient(colors: [kSoftPurple, kSoftBlue]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kSoftPurple.withOpacity(0.3),
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
      backgroundColor: kAccentColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      duration: const Duration(seconds: 2),
    );
  }

  Color _getStatusColor(NoticeStatus status) {
    switch (status) {
      case NoticeStatus.active:
        return kAccentColor;
      case NoticeStatus.draft:
        return kSoftOrange;
      case NoticeStatus.expired:
        return kSoftPink;
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
      backgroundColor: kBackgroundEnd,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 90,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 10),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Notices",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

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
                _buildNoticesHeader(filtered.length),
                const SizedBox(height: 12),
                if (filtered.isNotEmpty)
                  ...List.generate(
                    filtered.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.filter_list_rounded,
                color: kSoftPurple,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "Filter by Type",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              final bool isSelected = _selectedFilter == filter.value;
              final Color filterColor = _getFilterColor(filter.value);

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(
                    filter.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: isSelected ? filterColor : Colors.grey.shade300,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kSoftOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: kSoftOrange,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "Notice List",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: kSoftPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$count items',
            style: TextStyle(
              color: kSoftPurple,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: kSoftPurple,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No notices',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create your first notice',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'all':
        return kSoftPurple;
      case 'class':
        return kSoftBlue;
      case 'exam':
        return kAccentColor;
      case 'general':
        return kSoftOrange;
      default:
        return kSecondaryColor;
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kSoftPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: kSoftPurple,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Notice Overview',
                style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                icon: Icons.campaign_rounded,
                label: "Active",
                value: "$active",
                color: kAccentColor,
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
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(label, style: TextStyle(color: kTextSecondary, fontSize: 9)),
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
        return kAccentColor;
      case NoticeStatus.draft:
        return kSoftOrange;
      case NoticeStatus.expired:
        return kSoftPink;
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
          tilePadding: const EdgeInsets.all(12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(notice.icon, color: Colors.white, size: 22),
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
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                notice.description,
                style: TextStyle(color: kTextSecondary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildInfoChip(
                    icon: Icons.person_rounded,
                    value: notice.targetAudience,
                    color: kSoftPurple,
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
            size: 20,
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.info_rounded,
              label: "Full Notice",
              value: notice.fullContent,
              color: kSoftPurple,
            ),
            if (notice.attachedInfo != null) ...[
              const SizedBox(height: 6),
              _buildDetailRow(
                icon: Icons.attach_file_rounded,
                label: "Attachment",
                value: notice.attachedInfo!,
                color: kSoftBlue,
              ),
            ],
            if (notice.notes != null) ...[
              const SizedBox(height: 6),
              _buildDetailRow(
                icon: Icons.note_alt_rounded,
                label: "Notes",
                value: notice.notes!,
                color: kSoftOrange,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildActionChip(
                  icon: Icons.visibility_rounded,
                  label: "View",
                  color: kSoftPurple,
                  onTap: onView,
                ),
                _buildActionChip(
                  icon: Icons.edit_rounded,
                  label: "Edit",
                  color: kSoftBlue,
                  onTap: onEdit,
                ),
                _buildActionChip(
                  icon: notice.status == NoticeStatus.active
                      ? Icons.visibility_off_rounded
                      : Icons.publish_rounded,
                  label: notice.status == NoticeStatus.active
                      ? "Unpublish"
                      : "Publish",
                  color: kAccentColor,
                  onTap: onTogglePublish,
                ),
                _buildActionChip(
                  icon: Icons.delete_rounded,
                  label: "Delete",
                  color: kSoftPink,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
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
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(color: kTextPrimary, fontSize: 11),
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 11),
              const SizedBox(width: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
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
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccentColor, kAccentColor.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: kAccentColor.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  "Create New Notice",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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
