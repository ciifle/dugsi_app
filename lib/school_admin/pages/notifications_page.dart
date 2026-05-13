import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';

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

enum _NotificationFilter {
  all,
  unread,
  read,
}

// Main Notifications Page
class NotificationsPage extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const NotificationsPage({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
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
      description: 'Tomorrow is a holiday due to severe weather conditions. Stay safe!',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      isRead: true,
    ),
    NotificationItemData(
      id: '5',
      type: 'registration',
      title: 'New Student Registered',
      description: 'Aarav Sharma has joined Class 7-C. Please update attendance.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: false,
    ),
    NotificationItemData(
      id: '6',
      type: 'exam',
      title: 'Exam Created',
      description: 'Mock Test for Mathematics scheduled for Class 12-A this Friday.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  _NotificationFilter _filter = _NotificationFilter.all;

  static const Color _kPrimaryBlue = Color(0xFF023471);
  static const Color _kPrimaryGreen = Color(0xFF5AB04B);
  static const Color _kBgColor = Color(0xFFF4F6F8);
  static const double _kPadding = 20.0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index].isRead = true;
    });
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  List<NotificationItemData> get _filteredNotifications {
    return _notifications.where((notification) {
      final matchesFilter = switch (_filter) {
        _NotificationFilter.all => true,
        _NotificationFilter.unread => !notification.isRead,
        _NotificationFilter.read => notification.isRead,
      };
      if (!matchesFilter) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.trim().toLowerCase();
      return notification.title.toLowerCase().contains(query) ||
          notification.description.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _confirmClearAll() async {
    if (_notifications.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to remove all notifications?'),
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
  }

  @override
  Widget build(BuildContext context) {
    final body = isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)
        ? _buildDesktopPageBody(context)
        : _buildMobilePageBody(context);

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) {
      return body;
    }

    return Scaffold(
      backgroundColor: _kBgColor,
      body: SafeArea(child: body),
    );
  }

  Widget _buildMobilePageBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                  child: const Icon(Icons.arrow_back_rounded, color: _kPrimaryBlue, size: 24),
                ),
              ),
              const Spacer(),
              const Text(
                'Notifications',
                style: TextStyle(
                  color: _kPrimaryBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _notifications.isEmpty ? null : _confirmClearAll,
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
                    child: const Icon(Icons.clear_all_rounded, color: _kPrimaryBlue, size: 24),
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
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: _kPadding),
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
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopPageBody(BuildContext context) {
    final filtered = _filteredNotifications;

    return Container(
      color: const Color(0xFFF8F9FC),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8ECF2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final searchField = Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search notifications...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      );
                      final clearButton = OutlinedButton.icon(
                        onPressed: _notifications.isEmpty ? null : _confirmClearAll,
                        icon: const Icon(Icons.clear_all_rounded, size: 18),
                        label: const Text('Clear All'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimaryBlue,
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: 16),
                            clearButton,
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          searchField,
                          const SizedBox(height: 12),
                          Align(alignment: Alignment.centerRight, child: clearButton),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filter == _NotificationFilter.all,
                        onTap: () => setState(() => _filter = _NotificationFilter.all),
                      ),
                      _FilterChip(
                        label: 'Unread',
                        selected: _filter == _NotificationFilter.unread,
                        onTap: () => setState(() => _filter = _NotificationFilter.unread),
                      ),
                      _FilterChip(
                        label: 'Read',
                        selected: _filter == _NotificationFilter.read,
                        onTap: () => setState(() => _filter = _NotificationFilter.read),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8ECF2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: List.generate(filtered.length, (index) {
                            final notification = filtered[index];
                            final sourceIndex = _notifications.indexOf(notification);
                            return _DesktopNotificationRow(
                              notification: notification,
                              onTap: () {
                                if (!notification.isRead && sourceIndex >= 0) {
                                  _markAsRead(sourceIndex);
                                }
                              },
                              onDelete: sourceIndex >= 0 ? () => _deleteNotification(sourceIndex) : null,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: _kPrimaryBlue.withOpacity(0.13),
          ),
          const SizedBox(height: 18),
          const Text(
            "You're all caught up!",
            style: TextStyle(
              color: _kPrimaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isEmpty ? 'No notifications found.' : 'No notifications match your search.',
            style: TextStyle(
              color: _kPrimaryBlue.withOpacity(0.70),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF023471) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF023471) : const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF023471),
          ),
        ),
      ),
    );
  }
}

class _DesktopNotificationRow extends StatelessWidget {
  final NotificationItemData notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _DesktopNotificationRow({
    required this.notification,
    required this.onTap,
    this.onDelete,
  });

  IconData _typeIcon(String type) {
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

  String _timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead ? Colors.white : const Color(0xFFF5F8FF),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF023471).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(_typeIcon(notification.type), color: const Color(0xFF023471), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF023471),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _timeAgo(notification.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF023471),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
            ],
          ),
        ),
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

  String getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF023471);
    const orange = Color(0xFF5AB04B);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFF1F4FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead ? Colors.transparent : orange.withOpacity(0.07),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    getTimeAgo(notification.timestamp),
                    style: TextStyle(
                      color: const Color(0xFF023471).withOpacity(0.54),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
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
