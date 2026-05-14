import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/student_service.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kPrimaryGreen = Color(0xFF5AB04B);
const Color _kTextPrimary = Color(0xFF2D3436);
const Color _kTextSecondary = Color(0xFF636E72);

class StudentWebDashboard extends StatefulWidget {
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const StudentWebDashboard({super.key, this.onNavigateToPage});

  @override
  State<StudentWebDashboard> createState() => _StudentWebDashboardState();
}

class _StudentWebDashboardState extends State<StudentWebDashboard> {
  static const List<String> _kDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  late Future<StudentResult<List<StudentTimetableSlotModel>>> _timetableTodayFuture;
  late Future<StudentResult<List<StudentNoticeModel>>> _noticesFuture;
  late Future<StudentResult<List<StudentFeeModel>>> _feesFuture;
  late Future<StudentResult<List<StudentAttendanceRecordModel>>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  void _reloadData() {
    final wd = DateTime.now().weekday;
    final todayIndex = (wd == DateTime.sunday ? 7 : wd) - 1;
    final todayDay = _kDays[todayIndex.clamp(0, 6)];
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    _timetableTodayFuture = StudentService().getTimetable(day: todayDay);
    _noticesFuture = StudentService().listNotices();
    _feesFuture = StudentService().listFees();
    _attendanceFuture = StudentService().listAttendance(
      from: '${monthStart.year.toString().padLeft(4, '0')}-${monthStart.month.toString().padLeft(2, '0')}-${monthStart.day.toString().padLeft(2, '0')}',
      to: '${monthEnd.year.toString().padLeft(4, '0')}-${monthEnd.month.toString().padLeft(2, '0')}-${monthEnd.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _refresh() async {
    await context.read<AuthProvider>().refreshMe();
    if (!mounted) return;
    setState(_reloadData);
  }

  void _navigate(String pageKey) {
    widget.onNavigateToPage?.call(pageKey);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final prof = auth.studentProfile;
    final name = prof?.studentName?.trim().isNotEmpty == true
        ? prof!.studentName!.trim()
        : (user?.name?.trim().isNotEmpty == true ? user!.name.trim() : 'Student');
    final className = prof?.className?.trim().isNotEmpty == true ? prof!.className!.trim() : '—';
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'S';

    return Container(
      color: const Color(0xFFF0F3F7),
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: _kPrimaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(name, initials, className),
              const SizedBox(height: 24),
              _buildStatsGrid(auth.feesEnabled),
              const SizedBox(height: 24),
              _buildQuickActions(auth.feesEnabled),
              const SizedBox(height: 24),
              _buildTodayClasses(),
              const SizedBox(height: 24),
              _buildLatestNotices(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(String name, String initials, String className) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimaryBlue, _kPrimaryBlue, _kPrimaryGreen],
          stops: [0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPrimaryBlue.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _heroChip('STUDENT'),
                    _heroChip(className),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Text(
              initials,
              style: const TextStyle(
                color: _kPrimaryBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  int _statColumns(double width) {
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  int _quickActionColumns(double width) {
    if (width >= 1100) return 4;
    if (width >= 850) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  Widget _buildStatsGrid(bool feesEnabled) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _statColumns(constraints.maxWidth);
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _timetableTodayFuture,
            _noticesFuture,
            if (feesEnabled) _feesFuture else Future.value(StudentSuccess<List<StudentFeeModel>>([])),
            _attendanceFuture,
          ]),
          builder: (context, snap) {
            final loading = snap.connectionState != ConnectionState.done;
            final todayClasses = _countTodayClasses(snap.data);
            final noticeCount = _countNotices(snap.data);
            final unpaidFees = _countUnpaidFees(snap.data, feesEnabled);
            final attendanceRate = _attendanceRate(snap.data);

            final stats = <({IconData icon, String label, String value, Color color, String pageKey})>[
              (
                icon: Icons.schedule_rounded,
                label: "Today's classes",
                value: loading ? '—' : '$todayClasses',
                color: _kPrimaryBlue,
                pageKey: 'timetable',
              ),
              (
                icon: Icons.campaign_rounded,
                label: 'Notices',
                value: loading ? '—' : '$noticeCount',
                color: _kPrimaryGreen,
                pageKey: 'notices',
              ),
              (
                icon: Icons.calendar_month_rounded,
                label: 'Attendance',
                value: loading ? '—' : attendanceRate,
                color: const Color(0xFFF59E0B),
                pageKey: 'attendance',
              ),
              if (feesEnabled)
                (
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Unpaid fees',
                  value: loading ? '—' : '$unpaidFees',
                  color: _kPrimaryBlue,
                  pageKey: 'fees',
                ),
            ];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 130,
              ),
              itemBuilder: (context, index) {
                final stat = stats[index];
                return _StatCard(
                  icon: stat.icon,
                  label: stat.label,
                  value: stat.value,
                  color: stat.color,
                  onTap: () => _navigate(stat.pageKey),
                );
              },
            );
          },
        );
      },
    );
  }

  int _countTodayClasses(List<dynamic>? data) {
    if (data == null || data.isEmpty) return 0;
    final result = data[0];
    if (result is StudentSuccess<List<StudentTimetableSlotModel>>) {
      return result.data.length;
    }
    return 0;
  }

  int _countNotices(List<dynamic>? data) {
    if (data == null || data.length < 2) return 0;
    final result = data[1];
    if (result is StudentSuccess<List<StudentNoticeModel>>) {
      return result.data.length;
    }
    return 0;
  }

  int _countUnpaidFees(List<dynamic>? data, bool feesEnabled) {
    if (!feesEnabled || data == null || data.length < 3) return 0;
    final result = data[2];
    if (result is StudentSuccess<List<StudentFeeModel>>) {
      return result.data.where((f) => f.status?.toUpperCase() == 'UNPAID').length;
    }
    return 0;
  }

  String _attendanceRate(List<dynamic>? data) {
    if (data == null) return '—';
    final index = data.length >= 4 ? 3 : data.length - 1;
    final result = data[index];
    if (result is StudentSuccess<List<StudentAttendanceRecordModel>>) {
      final records = result.data;
      if (records.isEmpty) return '0%';
      final present = records.where((r) => r.status?.toUpperCase() == 'PRESENT').length;
      final rate = ((present / records.length) * 100).round();
      return '$rate%';
    }
    return '—';
  }

  Widget _buildQuickActions(bool feesEnabled) {
    final actions = <({String key, IconData icon, Color color, String title, String subtitle})>[
      (key: 'attendance', icon: Icons.calendar_month_rounded, color: _kPrimaryBlue, title: 'Attendance', subtitle: 'View your records'),
      (key: 'timetable', icon: Icons.schedule_rounded, color: _kPrimaryGreen, title: 'Timetable', subtitle: "Today's schedule"),
      (key: 'marks', icon: Icons.grade_rounded, color: _kPrimaryBlue, title: 'Marks', subtitle: 'Grades by exam'),
      (key: 'results', icon: Icons.stars_rounded, color: _kPrimaryGreen, title: 'Results', subtitle: 'Exam reports'),
      if (feesEnabled) (key: 'fees', icon: Icons.account_balance_wallet_rounded, color: _kPrimaryBlue, title: 'Fees', subtitle: 'Payment status'),
      if (feesEnabled) (key: 'payFee', icon: Icons.payment_rounded, color: _kPrimaryGreen, title: 'Pay Fee', subtitle: 'Make a payment'),
      (key: 'notices', icon: Icons.campaign_rounded, color: _kPrimaryBlue, title: 'Notices', subtitle: 'Announcements'),
      (key: 'messages', icon: Icons.message_rounded, color: _kPrimaryGreen, title: 'Messages', subtitle: 'Conversations'),
      (key: 'profile', icon: Icons.person_rounded, color: _kPrimaryBlue, title: 'Profile', subtitle: 'Your account'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _quickActionColumns(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 90,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _QuickActionTile(
              icon: action.icon,
              iconColor: action.color,
              title: action.title,
              subtitle: action.subtitle,
              onTap: () => _navigate(action.key),
            );
          },
        );
      },
    );
  }

  Widget _buildTodayClasses() {
    return FutureBuilder<StudentResult<List<StudentTimetableSlotModel>>>(
      future: _timetableTodayFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: _kPrimaryBlue),
            ),
          );
        }
        final list = snap.data is StudentSuccess<List<StudentTimetableSlotModel>>
            ? (snap.data as StudentSuccess<List<StudentTimetableSlotModel>>).data
            : <StudentTimetableSlotModel>[];
        list.sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
        final showList = list.take(4).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8ECF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Today's classes",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimaryBlue,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _navigate('timetable'),
                    child: const Text('View timetable'),
                  ),
                ],
              ),
              if (showList.isEmpty)
                Text('No classes today', style: TextStyle(color: _kTextSecondary.withValues(alpha: 0.9)))
              else
                ...showList.map((slot) {
                  final subject = slot.subject?['name']?.toString() ?? '—';
                  final teacher = slot.teacher?['fullName']?.toString() ??
                      slot.teacher?['name']?.toString() ??
                      '—';
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _kPrimaryBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            slot.startTime ?? '—',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kPrimaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextPrimary,
                                ),
                              ),
                              Text(
                                teacher,
                                style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLatestNotices() {
    return FutureBuilder<StudentResult<List<StudentNoticeModel>>>(
      future: _noticesFuture,
      builder: (context, snap) {
        final list = snap.data is StudentSuccess<List<StudentNoticeModel>>
            ? (snap.data as StudentSuccess<List<StudentNoticeModel>>).data
            : <StudentNoticeModel>[];
        final showList = list.take(3).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8ECF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Latest notices',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimaryBlue,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _navigate('notices'),
                    child: const Text('View all'),
                  ),
                ],
              ),
              if (showList.isEmpty)
                Text('No notices yet', style: TextStyle(color: _kTextSecondary.withValues(alpha: 0.9)))
              else
                ...showList.map((notice) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notice.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary,
                          ),
                        ),
                        if ((notice.content ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            notice.content!.length > 120
                                ? '${notice.content!.substring(0, 120).trim()}…'
                                : notice.content!,
                            style: const TextStyle(fontSize: 13, color: _kTextSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _kTextPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _kTextSecondary,
                          height: 1.15,
                        ),
                      ),
                    ],
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

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimaryBlue,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextSecondary,
                          height: 1.15,
                        ),
                      ),
                    ],
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
