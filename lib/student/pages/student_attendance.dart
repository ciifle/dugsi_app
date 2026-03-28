import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kobac/services/student_service.dart';

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
  const StudentAttendanceScreen({Key? key}) : super(key: key);

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
    return Scaffold(
      backgroundColor: kSoftBlue,
      body: Container(
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
              // ---------- HEADER ----------
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
      ),
    );
  }
}

class _AttendanceCalendarGrid extends StatelessWidget {
  final List<StudentAttendanceRecordModel> records;
  final DateTime selectedMonth;

  const _AttendanceCalendarGrid({
    required this.records,
    required this.selectedMonth,
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
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttendanceSummary(records: records),
          const SizedBox(height: 20),
          Text(
            'Calendar View',
            style: const TextStyle(
              fontSize: 18,
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
