import 'package:flutter/material.dart';
import 'package:kobac/services/student_service.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE0E9F5);
const Color kSoftGreen = Color(0xFFE4F1E2);
const Color kErrorColor = Color(0xFFEF4444);
const Color kTextPrimary = Color(0xFF1A1E1F);
const Color kTextSecondary = Color(0xFF4F5A5E);

const List<String> kDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const List<String> kDayFullNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Subject accent colors for left bar (same palette, consistent)
final List<Color> kSlotAccentColors = [
  kPrimaryBlue,
  kPrimaryGreen,
  const Color(0xFFF59E0B), // amber
  const Color(0xFF4A6FA5), // soft purple
  const Color(0xFF3D8C30), // dark green
  const Color(0xFF0EA5E9), // sky
];

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({Key? key}) : super(key: key);

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen> {
  late int _dayIndex;
  late Future<StudentResult<List<StudentTimetableSlotModel>>> _timetableFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    int wd = now.weekday;
    if (wd == DateTime.sunday) wd = 7;
    _dayIndex = (wd - 1).clamp(0, 6);
    _loadTimetable();
  }

  void _loadTimetable() {
    setState(() {
      _timetableFuture = StudentService().getTimetable(day: kDays[_dayIndex]);
    });
  }

  bool get _isToday {
    final now = DateTime.now();
    int wd = now.weekday;
    if (wd == DateTime.sunday) wd = 7;
    return (wd - 1).clamp(0, 6) == _dayIndex;
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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------- 1) HEADER ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Timetable',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${kDayFullNames[_dayIndex]}',
                            style: TextStyle(fontSize: 14, color: kTextSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- 2) DAY SELECTOR ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: kDays.length,
                    itemBuilder: (context, i) {
                      final isSelected = _dayIndex == i;
                      final isToday = _isTodayDay(i);
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _dayIndex = i;
                                  _loadTimetable();
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? kPrimaryBlue : Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? kPrimaryBlue : kPrimaryBlue.withOpacity(0.2),
                                    width: isSelected ? 0 : 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: kPrimaryBlue.withOpacity(0.25),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: kPrimaryBlue.withOpacity(0.06),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      kDays[i],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : kTextPrimary,
                                      ),
                                    ),
                                    if (isToday) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isSelected ? Colors.white : kPrimaryGreen).withOpacity(isSelected ? 0.25 : 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Today',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? Colors.white : kPrimaryGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ---------- 3) MAIN TIMETABLE (time-based layout) ----------
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadTimetable(),
                  color: kPrimaryGreen,
                  child: FutureBuilder<StudentResult<List<StudentTimetableSlotModel>>>(
                    future: _timetableFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: kPrimaryBlue),
                              SizedBox(height: 16),
                              Text('Loading timetable…', style: TextStyle(color: kTextSecondary, fontSize: 14)),
                            ],
                          ),
                        );
                      }
                      if (snapshot.hasError || snapshot.data is StudentError) {
                        final msg = snapshot.data is StudentError
                            ? (snapshot.data as StudentError).message
                            : 'Could not load timetable.';
                        return _ErrorState(message: msg);
                      }
                      final list = (snapshot.data as StudentSuccess<List<StudentTimetableSlotModel>>).data;
                      list.sort((a, b) {
                        final t1 = a.startTime ?? '';
                        final t2 = b.startTime ?? '';
                        return t1.compareTo(t2);
                      });
                      if (list.isEmpty) {
                        return _EmptyState(dayName: kDayFullNames[_dayIndex]);
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final s = list[index];
                          final accentColor = kSlotAccentColors[index % kSlotAccentColors.length];
                          return _TimetableSlotCard(
                            slot: s,
                            accentColor: accentColor,
                            isToday: _isToday,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isTodayDay(int i) {
    final now = DateTime.now();
    int wd = now.weekday;
    if (wd == DateTime.sunday) wd = 7;
    return (wd - 1).clamp(0, 6) == i;
  }
}

// ---------- SLOT CARD (time bar left, subject + teacher right) ----------
class _TimetableSlotCard extends StatelessWidget {
  final StudentTimetableSlotModel slot;
  final Color accentColor;
  final bool isToday;

  const _TimetableSlotCard({
    required this.slot,
    required this.accentColor,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final subjectName = slot.subject?['name']?.toString() ?? '—';
    final teacherName = slot.teacher?['fullName']?.toString() ?? slot.teacher?['name']?.toString() ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                if (isToday)
                  BoxShadow(
                    color: kPrimaryGreen.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  accentColor.withOpacity(0.04),
                ],
              ),
              border: isToday ? Border.all(color: kPrimaryGreen.withOpacity(0.3), width: 1) : null,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: vertical time bar + time block
                  Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (slot.period != null) ...[
                          Text(
                            slot.period!.name.isNotEmpty ? slot.period!.name : 'P${slot.period!.periodNumber}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          slot.startTime ?? '—',
                          style: TextStyle(
                            fontSize: slot.period != null ? 12 : 13,
                            fontWeight: FontWeight.bold,
                            color: slot.period != null ? kTextSecondary : accentColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            width: 16,
                            height: 1,
                            color: accentColor.withOpacity(0.4),
                          ),
                        ),
                        Text(
                          slot.endTime ?? '—',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 6px colored strip
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        bottomLeft: Radius.circular(3),
                      ),
                    ),
                  ),
                  // Right: subject + teacher
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.menu_book_rounded, size: 22, color: accentColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  subjectName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: kTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  teacherName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: kTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- EMPTY STATE ----------
class _EmptyState extends StatelessWidget {
  final String dayName;

  const _EmptyState({required this.dayName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.schedule_rounded, size: 64, color: kPrimaryBlue.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              'No classes scheduled for $dayName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your schedule is clear for this day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- ERROR STATE ----------
class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: kErrorColor.withOpacity(0.8)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextPrimary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
