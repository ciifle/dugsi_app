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
const Color kTextSecondary = Color(0xFF64748B); // Medium slate

enum NotificationType { system, classes, exams }

class TeacherNotificationsScreen extends StatefulWidget {
  const TeacherNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends State<TeacherNotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: "System Update",
      message: "The school portal will undergo maintenance on Friday night.",
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.system,
      read: false,
      icon: Icons.settings_rounded,
    ),
    NotificationItem(
      title: "Class 9A Exam Scheduled",
      message: "Maths exam rescheduled to 20th June at 10:00 AM.",
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.exams,
      read: true,
      icon: Icons.assignment_rounded,
    ),
    NotificationItem(
      title: "New Message from Admin",
      message: "Please submit the grade sheets by tomorrow.",
      dateTime: DateTime.now().subtract(const Duration(hours: 8)),
      type: NotificationType.system,
      read: false,
      icon: Icons.message_rounded,
    ),
    NotificationItem(
      title: "Class Attendance",
      message: "Attendance for class 10B submitted successfully.",
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.classes,
      read: true,
      icon: Icons.checklist_rounded,
    ),
    NotificationItem(
      title: "Exam Reminder",
      message: "Physics practical exam for 11C tomorrow.",
      dateTime: DateTime.now().subtract(const Duration(hours: 23)),
      type: NotificationType.exams,
      read: false,
      icon: Icons.event_available_rounded,
    ),
    NotificationItem(
      title: "New Assignment Uploaded",
      message: "Upload the assignment for class 7A by Friday.",
      dateTime: DateTime.now().subtract(const Duration(hours: 19)),
      type: NotificationType.classes,
      read: false,
      icon: Icons.assignment_rounded,
    ),
  ];

  String _selectedFilter = 'All';
  final List<String> filters = ['All', 'Classes', 'Exams', 'System'];

  List<NotificationItem> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'Classes':
        return _notifications
            .where((n) => n.type == NotificationType.classes)
            .toList();
      case 'Exams':
        return _notifications
            .where((n) => n.type == NotificationType.exams)
            .toList();
      case 'System':
        return _notifications
            .where((n) => n.type == NotificationType.system)
            .toList();
      default:
        return _notifications;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.read).length;

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'All':
        return kSoftPurple;
      case 'Classes':
        return kSoftBlue;
      case 'Exams':
        return kAccentColor;
      case 'System':
        return kSoftOrange;
      default:
        return kSecondaryColor;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt).inDays;

    if (difference == 0) {
      final hourDiff = now.difference(dt).inHours;
      if (hourDiff == 0) {
        final minDiff = now.difference(dt).inMinutes;
        return '$minDiff min ago';
      }
      return '$hourDiff hours ago';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundEnd,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR (SMALLER SIZE) ----------------
          SliverAppBar(
            expandedHeight: 80, // REDUCED from 100
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 14,
                bottom: 8,
              ), // REDUCED padding
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4), // REDUCED padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6), // REDUCED radius
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 14, // REDUCED icon size
                    ),
                  ),
                  const SizedBox(width: 4), // REDUCED spacing
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // REDUCED font size
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
                size: 18,
              ), // REDUCED size
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(8), // REDUCED padding
              constraints: const BoxConstraints(),
            ),
            actions: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8), // REDUCED margin
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.done_all_rounded,
                        color: Colors.white,
                        size: 16,
                      ), // REDUCED size
                      onPressed: () {
                        setState(() {
                          for (var n in _notifications) {
                            n.read = true;
                          }
                        });
                      },
                      padding: const EdgeInsets.all(6), // REDUCED padding
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(1.5), // REDUCED padding
                        decoration: BoxDecoration(
                          color: kSoftPink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Center(
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7, // REDUCED font size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(12), // REDUCED from 16
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- SUMMARY CARD ----------------
                _NotificationSummaryCard(
                  total: _notifications.length,
                  unread: _unreadCount,
                ),

                const SizedBox(height: 16), // REDUCED from 20
                // ---------------- FILTER SECTION ----------------
                _buildFilterSection(),

                const SizedBox(height: 16), // REDUCED from 20
                // ---------------- NOTIFICATIONS HEADER ----------------
                _buildNotificationsHeader(_filteredNotifications.length),

                const SizedBox(height: 12), // REDUCED from 16
                // ---------------- NOTIFICATION CARDS ----------------
                if (_filteredNotifications.isNotEmpty)
                  ...List.generate(
                    _filteredNotifications.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ), // REDUCED from 12
                      child: _NotificationCard(
                        notification: _filteredNotifications[index],
                        onMarkAsRead: () {
                          setState(() {
                            _filteredNotifications[index].read = true;
                          });
                        },
                        onDelete: () {
                          setState(() {
                            _notifications.remove(
                              _filteredNotifications[index],
                            );
                          });
                        },
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
              padding: const EdgeInsets.all(3), // REDUCED padding
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4), // REDUCED radius
              ),
              child: const Icon(
                Icons.filter_list_rounded,
                color: kSoftPurple,
                size: 12, // REDUCED icon size
              ),
            ),
            const SizedBox(width: 4), // REDUCED spacing
            const Text(
              "Filter by Type",
              style: TextStyle(
                fontSize: 12, // REDUCED font size
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6), // REDUCED from 8
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              final bool isSelected = _selectedFilter == filter;
              final Color filterColor = _getFilterColor(filter);

              return Padding(
                padding: const EdgeInsets.only(right: 4), // REDUCED spacing
                child: FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10, // REDUCED font size
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
                    borderRadius: BorderRadius.circular(12), // REDUCED radius
                  ),
                  side: BorderSide(
                    color: isSelected ? filterColor : Colors.grey.shade300,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
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

  Widget _buildNotificationsHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3), // REDUCED padding
              decoration: BoxDecoration(
                color: kSoftOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4), // REDUCED radius
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: kSoftOrange,
                size: 12, // REDUCED icon size
              ),
            ),
            const SizedBox(width: 4), // REDUCED spacing
            const Text(
              "Notification List",
              style: TextStyle(
                fontSize: 12, // REDUCED font size
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ), // REDUCED padding
          decoration: BoxDecoration(
            color: kSoftPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12), // REDUCED radius
          ),
          child: Text(
            '$count items',
            style: TextStyle(
              color: kSoftPurple,
              fontWeight: FontWeight.w600,
              fontSize: 9, // REDUCED font size
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20), // REDUCED from 30
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10), // REDUCED from 12
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                color: kSoftPurple,
                size: 28, // REDUCED from 36
              ),
            ),
            const SizedBox(height: 8), // REDUCED from 12
            const Text(
              'No notifications',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 12, // REDUCED from 14
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2), // REDUCED from 4
            const Text(
              'You\'re all caught up!',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 10, // REDUCED from 12
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- SUMMARY CARD ----------------
class _NotificationSummaryCard extends StatelessWidget {
  final int total;
  final int unread;

  const _NotificationSummaryCard({required this.total, required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // REDUCED from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // REDUCED from 20
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, // REDUCED from 15
            offset: const Offset(0, 3), // REDUCED from 5
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ), // REDUCED border width
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // REDUCED from 8
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kSoftPurple, kSoftBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10), // REDUCED from 12
              boxShadow: [
                BoxShadow(
                  color: kSoftPurple.withOpacity(0.3),
                  blurRadius: 4, // REDUCED from 6
                  offset: const Offset(0, 1), // REDUCED from 2
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 16, // REDUCED from 20
            ),
          ),
          const SizedBox(width: 8), // REDUCED from 12
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.list_alt_rounded,
                  label: "Total",
                  value: "$total",
                  color: kSoftPurple,
                ),
                _buildStatItem(
                  icon: Icons.circle_rounded,
                  label: "Unread",
                  value: "$unread",
                  color: kSoftPink,
                ),
              ],
            ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3), // REDUCED from 4
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 10), // REDUCED from 12
          ),
          const SizedBox(width: 3), // REDUCED from 4
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12, // REDUCED from 14
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 8, // REDUCED from 9
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- NOTIFICATION CARD ----------------
class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return kSoftPurple;
      case NotificationType.classes:
        return kSoftBlue;
      case NotificationType.exams:
        return kAccentColor;
    }
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return "System";
      case NotificationType.classes:
        return "Class";
      case NotificationType.exams:
        return "Exam";
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt).inDays;

    if (difference == 0) {
      final hourDiff = now.difference(dt).inHours;
      if (hourDiff == 0) {
        final minDiff = now.difference(dt).inMinutes;
        return '$minDiff min ago';
      }
      return '$hourDiff hours ago';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(notification.type);
    final typeLabel = _getTypeLabel(notification.type);

    return Container(
      decoration: BoxDecoration(
        color: notification.read
            ? Colors.white
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14), // REDUCED from 16
        border: Border.all(
          color: notification.read
              ? Colors.grey.shade200
              : typeColor.withOpacity(0.3),
          width: notification.read ? 1 : 1.5, // REDUCED border width
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5, // REDUCED from 8
            offset: const Offset(0, 1), // REDUCED from 2
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(10), // REDUCED from 12
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with gradient background
                  Container(
                    width: 34, // REDUCED from 40
                    height: 34, // REDUCED from 40
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [typeColor, typeColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // REDUCED from 12
                      boxShadow: [
                        BoxShadow(
                          color: typeColor.withOpacity(0.3),
                          blurRadius: 3, // REDUCED from 4
                          offset: const Offset(0, 1), // REDUCED from 2
                        ),
                      ],
                    ),
                    child: Icon(
                      notification.icon,
                      color: Colors.white,
                      size: 16, // REDUCED from 20
                    ),
                  ),
                  const SizedBox(width: 8), // REDUCED from 12
                  // Title and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimary,
                                  fontSize: 12, // REDUCED from 14
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.read)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ), // REDUCED padding
                                decoration: BoxDecoration(
                                  color: kSoftPink,
                                  borderRadius: BorderRadius.circular(
                                    8,
                                  ), // REDUCED from 10
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7, // REDUCED from 8
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2), // REDUCED from 2
                        Text(
                          _formatDate(notification.dateTime),
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 10, // REDUCED from 11
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6), // REDUCED from 10
              // Message
              Text(
                notification.message,
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 11, // REDUCED from 13
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6), // REDUCED from 8
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ), // REDUCED padding
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8), // REDUCED from 10
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 8, // REDUCED from 9
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 6), // REDUCED from 8
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!notification.read)
                    _buildActionButton(
                      icon: Icons.check_circle_rounded,
                      label: "Mark Read",
                      color: kSoftPurple,
                      onTap: onMarkAsRead,
                    ),
                  const SizedBox(width: 6), // REDUCED from 8
                  _buildActionButton(
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
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10), // REDUCED from 12
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 3,
          ), // REDUCED from 8,4
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10), // REDUCED from 12
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 2, // REDUCED from 2
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 10), // REDUCED from 12
              const SizedBox(width: 3), // REDUCED from 4
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8, // REDUCED from 10
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

// ---------------- DATA MODEL ----------------
class NotificationItem {
  final String title;
  final String message;
  final DateTime dateTime;
  final NotificationType type;
  final IconData icon;
  bool read;

  NotificationItem({
    required this.title,
    required this.message,
    required this.dateTime,
    required this.type,
    required this.icon,
    this.read = false,
  });
}
