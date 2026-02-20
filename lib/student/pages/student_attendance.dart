import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------- WONDERFUL COLOR PALETTE (Matching Dashboard) ----------
const Color kPrimaryColor = Color(0xFF1E3A8A); // Deep indigo
const Color kSecondaryColor = Color(0xFF3B82F6); // Bright blue
const Color kAccentColor = Color(0xFF10B981); // Emerald green
const Color kSoftPurple = Color(0xFF8B5CF6); // Light purple
const Color kSoftPink = Color(0xFFEC4899); // Pink
const Color kSoftOrange = Color(0xFFF59E0B); // Amber
const Color kSoftBlue = Color(0xFF3B82F6); // Sky blue
const Color kSuccessColor = Color(0xFF059669); // Dark green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kBackgroundColor = Color(0xFFF8FAFC); // Light background
const Color kSurfaceColor = Colors.white;
const Color kTextPrimaryColor = Color(0xFF1E293B); // Dark slate
const Color kTextSecondaryColor = Color(0xFF64748B); // Medium slate

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [Color(0xFF1E3A8A), Color(0xFF3B82F6)];
const List<Color> kSuccessGradient = [Color(0xFF10B981), Color(0xFF34D399)];
const List<Color> kWarningGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];

// Attendance status enum and model
enum AttendanceStatus { present, absent, holiday }

class AttendanceRecord {
  final DateTime date;
  final AttendanceStatus status;
  final String? remarks;

  AttendanceRecord({required this.date, required this.status, this.remarks});
}

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedMonth;
  late List<AttendanceRecord> _attendanceRecords;
  late List<DateTime> _availableMonths;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Only allow months including and prior to current month (up to 12 months back)
    DateTime now = DateTime.now();

    // Calculate available months
    _availableMonths = [];
    for (int i = 0; i < 13; i++) {
      int year = now.year;
      int month = now.month - i;
      while (month <= 0) {
        year -= 1;
        month += 12;
      }
      _availableMonths.add(DateTime(year, month, 1));
    }

    _selectedMonth = _availableMonths.first;
    _attendanceRecords = _generateDummyAttendance(_selectedMonth);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<AttendanceRecord> _generateDummyAttendance(DateTime month) {
    final List<AttendanceRecord> list = [];
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      if (date.weekday == DateTime.sunday) {
        list.add(
          AttendanceRecord(date: date, status: AttendanceStatus.holiday),
        );
      } else if (d % 5 == 0) {
        list.add(
          AttendanceRecord(
            date: date,
            status: AttendanceStatus.absent,
            remarks: d == 10 ? "Medical leave" : null,
          ),
        );
      } else {
        list.add(
          AttendanceRecord(date: date, status: AttendanceStatus.present),
        );
      }
    }
    return list;
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      _selectedMonth = DateTime(newMonth.year, newMonth.month, 1);
      _attendanceRecords = _generateDummyAttendance(_selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Compute summary
    final totalDays = _attendanceRecords
        .where((r) => r.status != AttendanceStatus.holiday)
        .length;
    final presentDays = _attendanceRecords
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    final absentDays = _attendanceRecords
        .where((r) => r.status == AttendanceStatus.absent)
        .length;
    final attendancePct = totalDays == 0
        ? 0
        : ((presentDays / totalDays) * 100).round();

    int selectedIdx = _availableMonths.indexWhere(
      (dt) =>
          dt.year == _selectedMonth.year && dt.month == _selectedMonth.month,
    );

    return Scaffold(
      backgroundColor: kBackgroundColor, // Matching dashboard background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- ENHANCED APP BAR WITH BACK ARROW ----------------
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Attendance",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryColor, kSecondaryColor],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {},
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------------- SUMMARY CARD ----------------
                      _buildSummaryCard(
                        totalDays,
                        presentDays,
                        absentDays,
                        attendancePct,
                      ),

                      const SizedBox(height: 20),

                      // ---------------- MONTH SELECTOR ----------------
                      _buildMonthSelector(selectedIdx),

                      const SizedBox(height: 20),

                      // ---------------- ATTENDANCE CALENDAR ----------------
                      _AttendanceCalendarGrid(
                        records: _attendanceRecords,
                        month: _selectedMonth,
                      ),

                      const SizedBox(height: 20),

                      // ---------------- LEGEND ----------------
                      _AttendanceLegend(),

                      const SizedBox(height: 24),

                      // ---------------- DETAILED RECORDS HEADER ----------------
                      _buildDetailedRecordsHeader(),

                      const SizedBox(height: 12),

                      // ---------------- DETAILED RECORDS ----------------
                      _buildDetailedRecords(),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    int totalDays,
    int presentDays,
    int absentDays,
    int attendancePct,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSoftPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: kSoftPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Attendance Summary',
                style: TextStyle(
                  color: kTextPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total\nDays', '$totalDays', kSoftBlue),
              _buildSummaryItem('Present', '$presentDays', kSuccessColor),
              _buildSummaryItem('Absent', '$absentDays', kWarningColor),
              _buildSummaryItem('Percent', '$attendancePct%', kSoftPurple),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: attendancePct / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              attendancePct >= 75
                  ? kSuccessColor
                  : attendancePct >= 50
                  ? kWarningColor
                  : kErrorColor,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kTextSecondaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector(int selectedIdx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: kSecondaryColor,
              size: 28,
            ),
            onPressed: (selectedIdx < _availableMonths.length - 1)
                ? () {
                    final prev = _availableMonths[selectedIdx + 1];
                    _onMonthChanged(prev);
                  }
                : null,
          ),
          Expanded(
            child: Center(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DateTime>(
                  value:
                      _availableMonths.any(
                        (dt) =>
                            dt.year == _selectedMonth.year &&
                            dt.month == _selectedMonth.month,
                      )
                      ? _availableMonths.firstWhere(
                          (dt) =>
                              dt.year == _selectedMonth.year &&
                              dt.month == _selectedMonth.month,
                        )
                      : _availableMonths.first,
                  menuMaxHeight: 260,
                  isDense: true,
                  style: const TextStyle(
                    color: kTextPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  items: _availableMonths.map((date) {
                    return DropdownMenuItem<DateTime>(
                      value: date,
                      child: Text(
                        DateFormat('MMMM yyyy').format(date),
                        style: const TextStyle(
                          color: kTextPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _onMonthChanged(val);
                  },
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: kSecondaryColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: kSecondaryColor,
              size: 28,
            ),
            onPressed: (selectedIdx > 0)
                ? () {
                    final next = _availableMonths[selectedIdx - 1];
                    _onMonthChanged(next);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRecordsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kSoftOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.list_alt_rounded,
            color: kSoftOrange,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Detailed Records',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: kTextPrimaryColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedRecords() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, idx) {
        final record = _attendanceRecords[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: kAccentColor.withOpacity(0.07),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: record.status == AttendanceStatus.present
                      ? kSuccessColor.withOpacity(0.1)
                      : record.status == AttendanceStatus.absent
                      ? kWarningColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  record.status == AttendanceStatus.present
                      ? Icons.check_circle_rounded
                      : record.status == AttendanceStatus.absent
                      ? Icons.cancel_rounded
                      : Icons.celebration_rounded,
                  color: record.status == AttendanceStatus.present
                      ? kSuccessColor
                      : record.status == AttendanceStatus.absent
                      ? kWarningColor
                      : Colors.grey.shade400,
                  size: 18,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(record.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kTextPrimaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(record.status),
                ],
              ),
              trailing: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: kSecondaryColor,
                size: 22,
              ),
              children: [
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 8),
                _buildDetailRow('Status', _statusText(record.status)),
                if (record.remarks != null) ...[
                  const SizedBox(height: 6),
                  _buildDetailRow('Remarks', record.remarks!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: kTextSecondaryColor,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: kTextPrimaryColor, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ---------------- ATTENDANCE CALENDAR GRID ----------------
class _AttendanceCalendarGrid extends StatelessWidget {
  final List<AttendanceRecord> records;
  final DateTime month;

  const _AttendanceCalendarGrid({
    Key? key,
    required this.records,
    required this.month,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    final startWeekday = firstDayOfMonth.weekday % 7; // Sun=0, Mon=1,...
    final totalCells = daysInMonth + startWeekday;
    final rows = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        children: [
          // Days of the week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
              return Expanded(
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: i == 0 || i == 6
                          ? kSecondaryColor
                          : kTextPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: rows * 7,
            itemBuilder: (context, idx) {
              final dayNum = idx - startWeekday + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox();
              }
              final AttendanceRecord record = records[dayNum - 1];
              return _CalendarDayCell(dayNum: dayNum, record: record);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------- CALENDAR DAY CELL ----------------
class _CalendarDayCell extends StatelessWidget {
  final int dayNum;
  final AttendanceRecord record;

  const _CalendarDayCell({Key? key, required this.dayNum, required this.record})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color getStatusColor() {
      switch (record.status) {
        case AttendanceStatus.present:
          return kSuccessColor;
        case AttendanceStatus.absent:
          return kWarningColor;
        case AttendanceStatus.holiday:
          return Colors.grey.shade400;
      }
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: record.status == AttendanceStatus.present
              ? kSuccessColor.withOpacity(0.1)
              : record.status == AttendanceStatus.absent
              ? kWarningColor.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: record.status == AttendanceStatus.absent
                ? kWarningColor.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNum.toString(),
              style: TextStyle(
                color: getStatusColor(),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            _buildStatusIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (record.status) {
      case AttendanceStatus.present:
        return Icon(Icons.check_circle, color: kSuccessColor, size: 10);
      case AttendanceStatus.absent:
        return Icon(Icons.cancel, color: kWarningColor, size: 10);
      case AttendanceStatus.holiday:
        return Icon(Icons.star, color: Colors.grey.shade400, size: 10);
    }
  }
}

// ---------------- ATTENDANCE LEGEND ----------------
class _AttendanceLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(
            icon: Icons.check_circle,
            color: kSuccessColor,
            label: 'Present',
          ),
          _legendItem(
            icon: Icons.cancel,
            color: kWarningColor,
            label: 'Absent',
          ),
          _legendItem(
            icon: Icons.star,
            color: Colors.grey.shade400,
            label: 'Holiday',
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: kTextSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------- STATUS CHIP ----------------
Widget _statusChip(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: kSuccessColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Present',
          style: TextStyle(
            fontSize: 10,
            color: kSuccessColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    case AttendanceStatus.absent:
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: kWarningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Absent',
          style: TextStyle(
            fontSize: 10,
            color: kWarningColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    case AttendanceStatus.holiday:
    default:
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Holiday',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
  }
}

String _statusText(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return "Present";
    case AttendanceStatus.absent:
      return "Absent";
    case AttendanceStatus.holiday:
      return "Holiday";
  }
}
