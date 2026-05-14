import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/student/widgets/student_web_ui.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE0E9F5);
const Color kSoftGreen = Color(0xFFE4F1E2);
const Color kErrorColor = Color(0xFFEF4444);
const Color kTextPrimary = Color(0xFF1A1E1F);
const Color kTextSecondary = Color(0xFF4F5A5E);
const Color kSuccessColor = Color(0xFF3D8C30);
const Color kWarningColor = Color(0xFFF59E0B);

class StudentAttendanceScreen extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const StudentAttendanceScreen({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedMonth;
  late Future<StudentResult<List<StudentAttendanceRecordModel>>> _attendanceFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadAttendanceData();
    _animationController.forward();
  }

  void _loadAttendanceData() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    
    setState(() {
      _attendanceFuture = StudentService().listAttendance(
        from: DateFormat('yyyy-MM-dd').format(firstDay),
        to: DateFormat('yyyy-MM-dd').format(lastDay),
      );
    });
  }

  void _changeMonth(int direction) {
    setState(() {
      if (direction > 0) {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
      }
    });
    _loadAttendanceData();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedBodyOnly && isStudentDesktopWeb(context)) {
      return ColoredBox(
        color: studentWebBg,
        child: _buildDesktopAttendanceBody(context),
      );
    }

    return Scaffold(
      backgroundColor: kSoftBlue,
      body: _buildMobileAttendanceBody(context),
    );
  }

  Widget _buildDesktopAttendanceBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDesktopMonthToolbar(),
          const SizedBox(height: 18),
          FutureBuilder<StudentResult<List<StudentAttendanceRecordModel>>>(
            future: _attendanceFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const StudentWebCard(
                  child: SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
                  ),
                );
              }

              if (snapshot.hasError || snapshot.data is StudentError) {
                final msg = snapshot.data is StudentError
                    ? (snapshot.data as StudentError).message
                    : 'Could not load attendance.';
                return StudentWebCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 40, color: kErrorColor.withValues(alpha: 0.85)),
                      const SizedBox(height: 12),
                      Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _loadAttendanceData,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final records = (snapshot.data as StudentSuccess<List<StudentAttendanceRecordModel>>).data;
              final sortedRecords = List<StudentAttendanceRecordModel>.from(records)
                ..sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDesktopSummaryRow(records),
                  const SizedBox(height: 18),
                  _buildDesktopRecordsCard(sortedRecords),
                  const SizedBox(height: 18),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: _AttendanceCalendarGrid(
                        records: records,
                        selectedMonth: _selectedMonth,
                        showSummary: false,
                        compact: true,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMonthToolbar() {
    return StudentWebCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded, color: kPrimaryBlue),
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kPrimaryBlue,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded, color: kPrimaryBlue),
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSummaryRow(List<StudentAttendanceRecordModel> records) {
    int present = 0;
    int absent = 0;
    int late = 0;
    for (final record in records) {
      switch (record.status?.toUpperCase()) {
        case 'PRESENT':
          present++;
          break;
        case 'ABSENT':
          absent++;
          break;
        case 'LATE':
          late++;
          break;
      }
    }

    final total = records.length;
    final attendanceRate = total > 0 ? ((present / total) * 100).round() : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1200;
        final cards = <Widget>[
          _DesktopAttendanceSummaryCard(
            icon: Icons.percent_rounded,
            label: 'Attendance',
            value: '$attendanceRate%',
            color: kPrimaryGreen,
            compact: compact,
          ),
          _DesktopAttendanceSummaryCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Present Days',
            value: '$present',
            color: kSuccessColor,
            compact: compact,
          ),
          _DesktopAttendanceSummaryCard(
            icon: Icons.cancel_outlined,
            label: 'Absent Days',
            value: '$absent',
            color: kErrorColor,
            compact: compact,
          ),
          if (late > 0)
            _DesktopAttendanceSummaryCard(
              icon: Icons.schedule_rounded,
              label: 'Late Days',
              value: '$late',
              color: kWarningColor,
              compact: compact,
            ),
          _DesktopAttendanceSummaryCard(
            icon: Icons.event_note_rounded,
            label: 'Total Records',
            value: '$total',
            color: kPrimaryBlue,
            compact: compact,
          ),
        ];

        if (constraints.maxWidth >= 1024) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(
                  width: constraints.maxWidth >= 720
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildDesktopRecordsCard(List<StudentAttendanceRecordModel> records) {
    if (records.isEmpty) {
      return const StudentWebCard(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'No attendance records found for this month',
              style: TextStyle(fontSize: 14, color: kTextSecondary),
            ),
          ),
        ),
      );
    }

    return StudentWebCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StudentWebTableHeader(
            columns: ['Date', 'Status', 'Period', 'Class', 'Time'],
            flex: [2, 2, 2, 2, 2],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return StudentWebTableRow(
                flex: const [2, 2, 2, 2, 2],
                cells: [
                  Text(
                    record.date ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary),
                  ),
                  _AttendanceStatusChip(status: record.status),
                  Text(
                    record.period ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                  Text(
                    record.className ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                  Text(
                    record.time ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAttendanceBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kSoftBlue, kSoftGreen],
          stops: [0.0, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 48),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Attendance",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMMM yyyy').format(_selectedMonth),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ---------- MONTH NAVIGATOR ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryBlue.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _changeMonth(-1),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kSoftBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              color: kPrimaryBlue,
                              size: 24,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            DateFormat('MMMM yyyy').format(_selectedMonth),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryBlue,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _changeMonth(1),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kSoftBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: kPrimaryBlue,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ---------- ATTENDANCE CONTENT ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: FutureBuilder<StudentResult<List<StudentAttendanceRecordModel>>>(
                    future: _attendanceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: kPrimaryBlue),
                        );
                      }
                      if (snapshot.hasError || snapshot.data is StudentError) {
                        final msg = snapshot.data is StudentError
                            ? (snapshot.data as StudentError).message
                            : 'Could not load attendance.';
                        return Container(
                          padding: const EdgeInsets.all(32),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryBlue.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 56, color: kErrorColor.withOpacity(0.8)),
                              const SizedBox(height: 16),
                              Text(
                                msg,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: kTextPrimary, fontSize: 15),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadAttendanceData,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final records = (snapshot.data as StudentSuccess<List<StudentAttendanceRecordModel>>).data;
                      return _AttendanceCalendarGrid(
                        records: records,
                        selectedMonth: _selectedMonth,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
    );
  }
}

class _AttendanceCalendarGrid extends StatelessWidget {
  final List<StudentAttendanceRecordModel> records;
  final DateTime selectedMonth;
  final bool showSummary;
  final bool compact;

  const _AttendanceCalendarGrid({
    required this.records,
    required this.selectedMonth,
    this.showSummary = true,
    this.compact = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingWeekday = firstDay.weekday;
    
    final attendanceMap = <String, StudentAttendanceRecordModel>{};
    for (final record in records) {
      if (record.date != null) {
        attendanceMap[record.date!] = record;
      }
    }

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: compact ? const Border.fromBorderSide(BorderSide(color: studentWebBorder)) : null,
        boxShadow: compact
            ? const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSummary) ...[
            _AttendanceSummary(records: records),
            const SizedBox(height: 20),
          ],
          Text(
            'Calendar View',
            style: TextStyle(
              fontSize: compact ? 15 : 18,
              fontWeight: FontWeight.bold,
              color: kPrimaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kTextSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(((daysInMonth + startingWeekday - 1) / 7).ceil(), (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - startingWeekday + 2;
                  final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
                  final dateStr = isCurrentMonth
                      ? DateFormat('yyyy-MM-dd').format(
                          DateTime(selectedMonth.year, selectedMonth.month, dayNumber))
                      : '';
                  final attendance = attendanceMap[dateStr];
                  
                  return Expanded(
                    child: _CalendarDayCell(
                      dayNumber: isCurrentMonth ? dayNumber : null,
                      attendance: attendance,
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  final List<StudentAttendanceRecordModel> records;

  const _AttendanceSummary({required this.records, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int present = 0;
    int absent = 0;
    int holiday = 0;
    int total = records.length;

    for (final record in records) {
      switch (record.status?.toUpperCase()) {
        case 'PRESENT':
          present++;
          break;
        case 'ABSENT':
          absent++;
          break;
        case 'HOLIDAY':
        case 'LEAVE':
          holiday++;
          break;
      }
    }

    double presentPercentage = total > 0 ? (present / total * 100) : 0;
    double absentPercentage = total > 0 ? (absent / total * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryBlue.withOpacity(0.05), kPrimaryGreen.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Present',
                  count: present,
                  percentage: presentPercentage,
                  color: kSuccessColor,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Absent',
                  count: absent,
                  percentage: absentPercentage,
                  color: kErrorColor,
                  icon: Icons.cancel_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Holiday/Leave',
                  count: holiday,
                  percentage: total > 0 ? (holiday / total * 100) : 0,
                  color: kWarningColor,
                  icon: Icons.beach_access_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
    required this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopAttendanceSummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  const _DesktopAttendanceSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBox = compact ? 38.0 : 40.0;
    final iconSize = compact ? 18.0 : 20.0;
    final valueSize = compact ? 20.0 : 22.0;
    final labelSize = compact ? 11.5 : 12.0;

    return Container(
      constraints: const BoxConstraints(maxHeight: 104),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: studentWebBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: labelSize,
                    color: kTextSecondary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceStatusChip extends StatelessWidget {
  final String? status;

  const _AttendanceStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status?.trim();
    final label = normalized == null || normalized.isEmpty ? '—' : normalized;
    final upper = normalized?.toUpperCase() ?? '';

    Color background;
    Color foreground;
    switch (upper) {
      case 'PRESENT':
        background = kSuccessColor.withValues(alpha: 0.12);
        foreground = kSuccessColor;
        break;
      case 'ABSENT':
        background = kErrorColor.withValues(alpha: 0.12);
        foreground = kErrorColor;
        break;
      case 'LATE':
        background = kWarningColor.withValues(alpha: 0.14);
        foreground = kWarningColor;
        break;
      default:
        background = kSoftBlue;
        foreground = kTextSecondary;
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int? dayNumber;
  final StudentAttendanceRecordModel? attendance;

  const _CalendarDayCell({
    required this.dayNumber,
    this.attendance,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dayNumber == null) {
      return const SizedBox(height: 40);
    }

    Color cellColor = kSoftBlue;
    Color textColor = kTextSecondary;
    String? tooltip;
    IconData? statusIcon;

    if (attendance != null) {
      switch (attendance?.status?.toUpperCase()) {
        case 'PRESENT':
          cellColor = kSuccessColor.withOpacity(0.1);
          textColor = kSuccessColor;
          tooltip = 'Present';
          statusIcon = Icons.check_circle_rounded;
          break;
        case 'ABSENT':
          cellColor = kErrorColor.withOpacity(0.1);
          textColor = kErrorColor;
          tooltip = 'Absent';
          statusIcon = Icons.cancel_rounded;
          break;
        case 'HOLIDAY':
        case 'LEAVE':
          cellColor = kWarningColor.withOpacity(0.1);
          textColor = kWarningColor;
          tooltip = attendance?.status?.toLowerCase() ?? 'Holiday';
          statusIcon = Icons.beach_access_rounded;
          break;
        default:
          cellColor = kSoftBlue;
          textColor = kTextSecondary;
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: attendance != null 
                  ? textColor.withOpacity(0.3) 
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (statusIcon != null)
                Icon(statusIcon, size: 12, color: textColor)
              else
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              if (attendance?.time != null) ...[
                const SizedBox(height: 2),
                Text(
                  attendance!.time!,
                  style: TextStyle(
                    fontSize: 8,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
