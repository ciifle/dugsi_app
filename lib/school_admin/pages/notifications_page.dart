import 'package:flutter/material.dart';

// Notification Data Model
class NotificationItemData {
  final String id;
  final String type; // e.g. 'registration', 'exam', 'marks', 'notice'
  final String title;
  final String description;
  final DateTime timestamp;
  bool isRead;

  NotificationItemData({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
  });
}

// Main Notifications Page
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Dummy data
  final List<NotificationItemData> _notifications = [
    NotificationItemData(
      id: '1',
      type: 'registration',
      title: 'New Student Registered',
      description: 'Michael Smith has joined Class 10-B.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      isRead: false,
    ),
    NotificationItemData(
      id: '2',
      type: 'exam',
      title: 'Exam Created',
      description: 'Mid Term English Exam has been scheduled.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    NotificationItemData(
      id: '3',
      type: 'marks',
      title: 'Marks Submitted',
      description: 'Science marks for Class 9-A have been submitted.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      isRead: true,
    ),
    NotificationItemData(
      id: '4',
      type: 'notice',
      title: 'Notice Published',
      description:
          'Tomorrow is a holiday due to severe weather conditions. Stay safe!',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      isRead: true,
    ),
    NotificationItemData(
      id: '5',
      type: 'registration',
      title: 'New Student Registered',
      description:
          'Aarav Sharma has joined Class 7-C. Please update attendance.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: false,
    ),
    NotificationItemData(
      id: '6',
      type: 'exam',
      title: 'Exam Created',
      description:
          'Mock Test for Mathematics scheduled for Class 12-A this Friday.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
    // Add more dummy data as needed
  ];

  // Mark specific notification as read
  void _markAsRead(int index) {
    setState(() {
      _notifications[index].isRead = true;
    });
  }

  // Delete notification
  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  // Clear all notifications
  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  // Design constants to match admin dashboard (no colored top bar, 3D style)
  static const Color _kPrimaryBlue = Color(0xFF023471);
  static const Color _kPrimaryGreen = Color(0xFF5AB04B);
  static const Color _kBgColor = Color(0xFFF4F6F8);
  static const double _kPadding = 20.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar: no color, same style as dashboard (3D icon containers)
            Padding(
              padding: const EdgeInsets.fromLTRB(_kPadding, _kPadding, _kPadding, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimaryBlue.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: _kPrimaryBlue, size: 24),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Notifications',
                    style: const TextStyle(
                      color: _kPrimaryBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _notifications.isEmpty
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear All Notifications'),
                                content: const Text(
                                    'Are you sure you want to remove all notifications?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text(
                                      'Clear All',
                                      style: TextStyle(color: _kPrimaryGreen),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) _clearAll();
                          },
                    child: Opacity(
                      opacity: _notifications.isEmpty ? 0.4 : 1,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimaryBlue.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.clear_all_rounded, color: _kPrimaryBlue, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: _kPadding),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: NotificationItem(
                      notification: notification,
                      onTap: () {
                        if (!notification.isRead) {
                          _markAsRead(index);
                        }
                      },
                      onDelete: () => _deleteNotification(index),
                    ),
                  );
                },
                reverse: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for empty notifications state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: const Color(0xFF023471).withOpacity(0.13),
          ),
          const SizedBox(height: 18),
          const Text(
            "You're all caught up!",
            style: TextStyle(
              color: Color(0xFF023471),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No new notifications.',
            style: TextStyle(
              color: const Color(0xFF023471).withOpacity(0.70),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable notification item widget
class NotificationItem extends StatelessWidget {
  final NotificationItemData notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  // Map notification type to specific orange icon
  IconData getTypeIcon(String type) {
    switch (type) {
      case 'registration':
        return Icons.person_add_alt_1_rounded;
      case 'exam':
        return Icons.event_note_rounded;
      case 'marks':
        return Icons.assignment_turned_in_rounded;
      case 'notice':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  // Format date/time display (e.g. "2h ago", "Yesterday", etc.)
  String getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    // Fallback for older
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Color palette
    const darkBlue = Color(0xFF023471);
    const orange = Color(0xFF5AB04B);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : const Color(0xFFF1F4FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : orange.withOpacity(0.07),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: darkBlue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: darkBlue.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // spacing
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Orange Icon
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: orange.withOpacity(0.09),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  getTypeIcon(notification.type),
                  color: orange,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Center: Notification details (title, description)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      notification.title,
                      style: const TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                        letterSpacing: 0.05,
                        height: 1.21,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      notification.description,
                      style: TextStyle(
                        color: darkBlue.withOpacity(0.82),
                        fontSize: 14,
                        height: 1.34,
                        fontWeight: FontWeight.normal,
                        letterSpacing: 0.003,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Right: Time/date + unread dot
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Time/Date
                  Text(
                    getTimeAgo(notification.timestamp),
                    style: TextStyle(
                      color: const Color(0xFF023471).withOpacity(0.54),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Orange dot indicator for unread
                  if (!notification.isRead)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
