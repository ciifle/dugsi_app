import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kobac/services/student_service.dart';

// ---------- WONDERFUL COLOR PALETTE (Matching Dashboard) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE0E9F5); // Light tint of blue
const Color kSoftGreen = Color(0xFFE4F1E2); // Light tint of green
const Color kDarkGreen = Color(0xFF3D8C30); // Darker shade of green
const Color kDarkBlue = Color(0xFF011A3D); // Darker shade of blue
const Color kSoftPurple = Color(0xFF4A6FA5); // Soft blue-purple
const Color kSoftPink = Color(0xFF7CB86E); // Soft green-pink
const Color kSoftOrange = Color(0xFFF59E0B); // Amber for warning
const Color kSuccessColor = Color(0xFF3D8C30); // Darker green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kBackgroundColor = Color(0xFFF5F8FC); // Light background
const Color kSurfaceColor = Colors.white;
const Color kTextPrimaryColor = Color(0xFF1A1E1F); // Dark slate
const Color kTextSecondaryColor = Color(0xFF4F5A5E); // Medium slate

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [kPrimaryBlue, kPrimaryGreen];
const List<Color> kSuccessGradient = [kPrimaryGreen, kDarkGreen];
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
  late Future<StudentResult<List<StudentAttendanceRecordModel>>> _attendanceFuture;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static String _dateStr(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    _attendanceFuture = StudentService().listAttendance(
      from: _dateStr(from),
      to: _dateStr(now),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Only allow months including and prior to current month (up to 12 months back)
    // (reuse 'now' from above)

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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kSoftBlue, kSoftGreen],
          stops: [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ---------------- REDESIGNED APP BAR (Matching Dashboard) ----------------
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 40),
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
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title
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
                        const SizedBox(width: 16),
                        // Calendar Icon
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
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- MAIN CONTENT ----------------
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------------- ATTENDANCE FROM API (last 30 days) ----------------
                        FutureBuilder<StudentResult<List<StudentAttendanceRecordModel>>>(
                          future: _attendanceFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryBlue))),
                              );
                            }
                            if (snapshot.data is! StudentSuccess<List<StudentAttendanceRecordModel>>) {
                              return const SizedBox.shrink();
                            }
                            final list = (snapshot.data as StudentSuccess<List<StudentAttendanceRecordModel>>).data;
                            if (list.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                                  ),
                                  child: const Text('No attendance records', style: TextStyle(color: kTextSecondaryColor)),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Recent attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                                  const SizedBox(height: 10),
                                  ...list.take(14).map((r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(r.date ?? '—', style: const TextStyle(fontSize: 14, color: kTextPrimaryColor)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (r.status?.toUpperCase() == 'PRESENT' ? kPrimaryGreen : Colors.orange).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(r.status ?? '—', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: r.status?.toUpperCase() == 'PRESENT' ? kDarkGreen : Colors.orange.shade800)),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            );
                          },
                        ),
                        // ---------------- REDESIGNED SUMMARY CARD ----------------
                        _buildSummaryCard(
                          totalDays,
                          presentDays,
                          absentDays,
                          attendancePct,
                        ),

                        const SizedBox(height: 20),

                        // ---------------- REDESIGNED MONTH SELECTOR ----------------
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
      ),
    );
  }

  // REDESIGNED SUMMARY CARD
  Widget _buildSummaryCard(
    int totalDays,
    int presentDays,
    int absentDays,
    int attendancePct,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, kSoftGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryBlue, kPrimaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Attendance Summary',
                style: TextStyle(
                  color: kTextPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _buildEnhancedSummaryItem(
                label: 'Total Days',
                value: '$totalDays',
                icon: Icons.calendar_today_rounded,
                color: kPrimaryBlue,
                bgColor: kSoftBlue,
              ),
              const SizedBox(width: 12),
              _buildEnhancedSummaryItem(
                label: 'Present',
                value: '$presentDays',
                icon: Icons.check_circle_rounded,
                color: kPrimaryGreen,
                bgColor: kSoftGreen,
              ),
              const SizedBox(width: 12),
              _buildEnhancedSummaryItem(
                label: 'Absent',
                value: '$absentDays',
                icon: Icons.cancel_rounded,
                color: kWarningColor,
                bgColor: kWarningColor.withOpacity(0.1),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Percentage Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance Rate',
                      style: TextStyle(
                        color: kTextSecondaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: attendancePct >= 75
                            ? kPrimaryGreen.withOpacity(0.1)
                            : attendancePct >= 50
                            ? kWarningColor.withOpacity(0.1)
                            : kErrorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$attendancePct%',
                        style: TextStyle(
                          color: attendancePct >= 75
                              ? kPrimaryGreen
                              : attendancePct >= 50
                              ? kWarningColor
                              : kErrorColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: attendancePct / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    attendancePct >= 75
                        ? kPrimaryGreen
                        : attendancePct >= 50
                        ? kWarningColor
                        : kErrorColor,
                  ),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Summary Item
  Widget _buildEnhancedSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: kTextSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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

  // REDESIGNED MONTH SELECTOR
  Widget _buildMonthSelector(int selectedIdx) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          // Previous Month Button
          Container(
            decoration: BoxDecoration(
              color: selectedIdx < _availableMonths.length - 1
                  ? kPrimaryBlue.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: Icon(
                Icons.chevron_left_rounded,
                color: selectedIdx < _availableMonths.length - 1
                    ? kPrimaryBlue
                    : Colors.grey.shade400,
                size: 28,
              ),
              onPressed: (selectedIdx < _availableMonths.length - 1)
                  ? () {
                      final prev = _availableMonths[selectedIdx + 1];
                      _onMonthChanged(prev);
                    }
                  : null,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
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
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  items: _availableMonths.map((date) {
                    return DropdownMenuItem<DateTime>(
                      value: date,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          DateFormat('MMMM yyyy').format(date),
                          style: TextStyle(
                            color: kTextPrimaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _onMonthChanged(val);
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kPrimaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_drop_down,
                      color: kPrimaryGreen,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Next Month Button
          Container(
            decoration: BoxDecoration(
              color: selectedIdx > 0
                  ? kPrimaryBlue.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: Icon(
                Icons.chevron_right_rounded,
                color: selectedIdx > 0 ? kPrimaryBlue : Colors.grey.shade400,
                size: 28,
              ),
              onPressed: (selectedIdx > 0)
                  ? () {
                      final next = _availableMonths[selectedIdx - 1];
                      _onMonthChanged(next);
                    }
                  : null,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  // REDESIGNED DETAILED RECORDS HEADER
  Widget _buildDetailedRecordsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryBlue, kPrimaryGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.list_alt_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Detailed Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextPrimaryColor,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  // REDESIGNED DETAILED RECORDS
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: record.status == AttendanceStatus.present
                  ? kPrimaryGreen.withOpacity(0.2)
                  : record.status == AttendanceStatus.absent
                  ? kWarningColor.withOpacity(0.2)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: kPrimaryGreen.withOpacity(0.07),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: record.status == AttendanceStatus.present
                        ? [kPrimaryGreen, kDarkGreen]
                        : record.status == AttendanceStatus.absent
                        ? [kWarningColor, kSoftOrange]
                        : [Colors.grey.shade400, Colors.grey.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  record.status == AttendanceStatus.present
                      ? Icons.check_circle_rounded
                      : record.status == AttendanceStatus.absent
                      ? Icons.cancel_rounded
                      : Icons.celebration_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(record.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTextPrimaryColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(record.status),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: kPrimaryGreen,
                  size: 20,
                ),
              ),
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Status',
                        _statusText(record.status),
                        _getStatusColor(record.status),
                      ),
                      if (record.remarks != null) ...[
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          'Remarks',
                          record.remarks!,
                          kTextSecondaryColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return kPrimaryGreen;
      case AttendanceStatus.absent:
        return kWarningColor;
      case AttendanceStatus.holiday:
        return Colors.grey.shade600;
    }
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: kTextSecondaryColor,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, kSoftBlue.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: i == 0 || i == 6
                          ? kPrimaryBlue.withOpacity(0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: i == 0 || i == 6
                            ? kPrimaryBlue
                            : kTextPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
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
          return kPrimaryGreen;
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
          gradient: LinearGradient(
            colors: [
              getStatusColor().withOpacity(0.1),
              getStatusColor().withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: getStatusColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayNum.toString(),
                style: TextStyle(
                  color: getStatusColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: _buildStatusIcon(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (record.status) {
      case AttendanceStatus.present:
        return Icon(Icons.check_circle, color: kPrimaryGreen, size: 10);
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(
            icon: Icons.check_circle,
            color: kPrimaryGreen,
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
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: kTextSecondaryColor,
            fontSize: 13,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: kPrimaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Present',
          style: TextStyle(
            fontSize: 11,
            color: kPrimaryGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    case AttendanceStatus.absent:
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: kWarningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Absent',
          style: TextStyle(
            fontSize: 11,
            color: kWarningColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    case AttendanceStatus.holiday:
    default:
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Holiday',
          style: TextStyle(
            fontSize: 11,
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
