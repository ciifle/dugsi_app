import 'package:flutter/material.dart';

// ==================== COLOR CONSTANTS (DEFINED HERE) ====================
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
const Color kSuccessColor = Color(0xFF059669); // Dark green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red

class ParentNotificationsScreen extends StatelessWidget {
  const ParentNotificationsScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> notifications = const [
    {
      'title': 'Fee Payment Reminder',
      'message': 'Fee payment for Ava Carter is due on 15th June.',
      'time': '2 hours ago',
      'type': 'fee',
      'read': false,
    },
    {
      'title': 'Parent-Teacher Meeting',
      'message': 'PTM scheduled for 20th June at 10:00 AM.',
      'time': '1 day ago',
      'type': 'event',
      'read': true,
    },
    {
      'title': 'Exam Results',
      'message': 'Results for Grade 6 - A are now available.',
      'time': '2 days ago',
      'type': 'exam',
      'read': false,
    },
    {
      'title': 'School Holiday',
      'message': 'School will remain closed on 25th June.',
      'time': '3 days ago',
      'type': 'holiday',
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundEnd,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...List.generate(
                  notifications.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(
                      notification: notifications[index],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotificationCard({required this.notification});

  Color _getTypeColor(String type) {
    switch (type) {
      case 'fee':
        return kWarningColor;
      case 'event':
        return kSoftPurple;
      case 'exam':
        return kAccentColor;
      case 'holiday':
        return kSoftOrange;
      default:
        return kSoftBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(notification['type']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification['read']
              ? Colors.transparent
              : color.withOpacity(0.3),
          width: 2,
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
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification['type'] == 'fee'
                    ? Icons.payment_rounded
                    : notification['type'] == 'event'
                    ? Icons.event_rounded
                    : notification['type'] == 'exam'
                    ? Icons.assignment_rounded
                    : Icons.celebration_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
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
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (!notification['read'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification['time'],
                    style: TextStyle(
                      color: kTextSecondary.withOpacity(0.6),
                      fontSize: 11,
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
}
