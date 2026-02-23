import 'package:flutter/material.dart';

// --- Premium 3D Design Constants ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class NoticesPage extends StatelessWidget {
  NoticesPage({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> notices = [
    {
      'title': 'School Closed on Friday',
      'content': 'Due to weather conditions, the school will remain closed this Friday. Please inform your respective departments.',
      'audience': 'All',
      'date': '2024-06-15',
    },
    {
      'title': 'Staff Meeting',
      'content': 'A mandatory staff meeting will be held in the auditorium at 2pm. Attendance is required for all staff members.',
      'audience': 'Teachers',
      'date': '2024-06-12',
    },
    {
      'title': 'Sports Day Registrations',
      'content': 'Students can register for Sports Day events at the admin office. Registrations close on June 18th.',
      'audience': 'Students',
      'date': '2024-06-10',
    },
     {
      'title': 'Bus Route Change',
      'content': 'Bus routes 4 and 5 are changed starting next week. Kindly check the updated schedule on the school portal.',
      'audience': 'All',
      'date': '2024-06-11',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kBgColor, kPrimaryBlue.withOpacity(0.02)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    _BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Notices",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                    _AddButton(onPressed: () {}),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: notices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    return _NoticeCard(notice: notice);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kPrimaryGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryGreen.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add_rounded, color: kPrimaryGreen, size: 24),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Map<String, dynamic> notice;

  const _NoticeCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notice['audience'] as String,
                  style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Text(
                notice['date'] as String,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notice['title'] as String,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue),
          ),
          const SizedBox(height: 8),
          Text(
            notice['content'] as String,
            style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }
}
