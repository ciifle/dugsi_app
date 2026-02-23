import 'package:flutter/material.dart';

// Color constants
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE6F0FF);
const Color kSoftPurple = Color(0xFFA29BFE);
const Color kSoftOrange = Color(0xFFF59E0B);
const Color kBackgroundEnd = Color(0xFFF5F0FF);
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF636E72);
const Color kSuccessColor = Color(0xFF059669);
const Color kErrorColor = Color(0xFFEF4444);
const Color kSecondaryColor = Color(0xFF6C5CE7);
const Color kAccentColor = Color(0xFF00B894);
const Color kSoftPink = Color(0xFFFF7675);
const Color kDarkBlue = Color(0xFF01255C);

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<ParentNotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<ParentNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'type': 'fee',
      'title': 'Fee Payment Reminder',
      'message':
          'Tuition fee for Ava Carter (Grade 6-A) is due on June 15, 2024. Late fee of \$50 will apply after due date.',
      'date': '2024-06-10T09:30:00',
      'isRead': false,
      'priority': 'high',
      'childName': 'Ava Carter',
    },
    {
      'id': '2',
      'type': 'event',
      'title': 'Parent-Teacher Meeting',
      'message':
          'Parent-Teacher meeting for Grade 8-B will be held on June 20, 2024 at 2:00 PM in the school auditorium.',
      'date': '2024-06-09T14:15:00',
      'isRead': false,
      'priority': 'medium',
      'childName': 'Liam Carter',
    },
    {
      'id': '3',
      'type': 'result',
      'title': 'Term Results Published',
      'message':
          'Term 1 results for Emma Carter (Grade 4-C) have been published. Check the results section for details.',
      'date': '2024-06-08T11:45:00',
      'isRead': true,
      'priority': 'medium',
      'childName': 'Emma Carter',
    },
    {
      'id': '4',
      'type': 'attendance',
      'title': 'Attendance Alert',
      'message':
          'Liam Carter was marked absent on June 8, 2024. Please provide a reason if this was an excused absence.',
      'date': '2024-06-08T08:20:00',
      'isRead': true,
      'priority': 'high',
      'childName': 'Liam Carter',
    },
    {
      'id': '5',
      'type': 'holiday',
      'title': 'School Holiday Announcement',
      'message':
          'School will remain closed on June 17, 2024 on account of Eid-ul-Adha.',
      'date': '2024-06-07T16:30:00',
      'isRead': true,
      'priority': 'low',
      'childName': 'All Children',
    },
    {
      'id': '6',
      'type': 'event',
      'title': 'Sports Day Registration',
      'message':
          'Annual Sports Day registration is open until June 25, 2024. Please register your child for events.',
      'date': '2024-06-06T10:00:00',
      'isRead': false,
      'priority': 'medium',
      'childName': 'All Children',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get unreadCount => notifications.where((n) => !n['isRead']).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundEnd,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryBlue, kSecondaryColor, kPrimaryGreen],
              stops: const [0.2, 0.5, 0.9],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: kPrimaryBlue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: kPrimaryBlue,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'NOTIFICATIONS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kErrorColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Notification Center',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        toolbarHeight: 90,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
                size: 22,
              ),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              offset: const Offset(0, 40),
              onSelected: (value) {
                if (value == 'mark_read') {
                  _markAllAsRead();
                } else if (value == 'filter') {
                  _showFilterDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_read',
                  child: Row(
                    children: [
                      Icon(
                        Icons.done_all_rounded,
                        color: kSuccessColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text('Mark all as read'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'filter',
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        color: kSoftPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text('Filter'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white,
              ),
              labelColor: kPrimaryBlue,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                const Tab(text: 'All'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Unread'),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: kPrimaryBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Important'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(notifications),
          _buildNotificationsList(
            notifications.where((n) => !n['isRead']).toList(),
          ),
          _buildNotificationsList(
            notifications.where((n) => n['priority'] == 'high').toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<Map<String, dynamic>> notificationsList) {
    if (notificationsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                size: 50,
                color: kTextSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 16,
                color: kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notificationsList.length,
      itemBuilder: (context, index) {
        final notification = notificationsList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _NotificationCard(
            notification: notification,
            onTap: () => _markAsRead(notification['id']),
          ),
        );
      },
    );
  }

  void _markAsRead(String id) {
    setState(() {
      final index = notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        notifications[index]['isRead'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification['isRead'] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: kSuccessColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildFilterOption('All', Icons.notifications_rounded, true),
              _buildFilterOption('Fee Related', Icons.payment_rounded, false),
              _buildFilterOption('Events', Icons.event_rounded, false),
              _buildFilterOption('Results', Icons.assignment_rounded, false),
              _buildFilterOption(
                'Attendance',
                Icons.event_available_rounded,
                false,
              ),
              _buildFilterOption('Holidays', Icons.beach_access_rounded, false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, IconData icon, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? kPrimaryBlue : kTextSecondary),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? kPrimaryBlue : kTextPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: kPrimaryBlue)
          : null,
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  Color _getTypeColor() {
    switch (notification['type']) {
      case 'fee':
        return kAccentColor;
      case 'event':
        return kSoftPurple;
      case 'result':
        return kSoftBlue;
      case 'attendance':
        return kSoftOrange;
      case 'holiday':
        return kSoftPink;
      default:
        return kSecondaryColor;
    }
  }

  IconData _getTypeIcon() {
    switch (notification['type']) {
      case 'fee':
        return Icons.payment_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'result':
        return Icons.assignment_rounded;
      case 'attendance':
        return Icons.event_available_rounded;
      case 'holiday':
        return Icons.beach_access_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor();
    final isHighPriority = notification['priority'] == 'high';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: notification['isRead']
              ? Colors.white
              : typeColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighPriority && !notification['isRead']
                ? kErrorColor.withOpacity(0.3)
                : Colors.grey.shade200,
            width: isHighPriority && !notification['isRead'] ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getTypeIcon(), color: typeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontWeight: notification['isRead']
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: notification['isRead']
                                  ? kTextSecondary
                                  : kTextPrimary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!notification['isRead'])
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: kErrorColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kSoftBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            notification['childName'],
                            style: TextStyle(
                              color: kSoftBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: kTextSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeAgo(notification['date']),
                          style: TextStyle(
                            color: kTextSecondary.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isHighPriority)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.priority_high_rounded,
                    color: kErrorColor,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
