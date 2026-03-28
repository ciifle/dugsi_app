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

/// Subject accent colors for better visual hierarchy
final List<Color> kSlotAccentColors = [
  kPrimaryBlue,
  kPrimaryGreen,
  const Color(0xFFF59E0B), // amber
  const Color(0xFF4A6FA5), // soft purple
  const Color(0xFF3D8C30), // dark green
  const Color(0xFF0EA5E9), // sky
  const Color(0xFFE91E63), // pink
  const Color(0xFF9C27B0), // purple
];

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({Key? key}) : super(key: key);

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen>
    with TickerProviderStateMixin {
  late int _dayIndex;
  late Future<StudentResult<List<StudentTimetableSlotModel>>> _timetableFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    final now = DateTime.now();
    int wd = now.weekday;
    if (wd == DateTime.sunday) wd = 7;
    _dayIndex = (wd - 1).clamp(0, 6);
    _loadTimetable();
    _animationController.forward();
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

  String _getShiftDisplay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '🌅 Morning Shift';
    } else if (hour < 17) {
      return '☀️ Afternoon Shift';
    } else {
      return '🌆 Evening Shift';
    }
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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------- 1) HEADER ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryBlue.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
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
                            '${kDayFullNames[_dayIndex]} • ${_getShiftDisplay()}',
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(kDays.length, (i) {
                      final isToday = _isToday && i == _dayIndex;
                      final isSelected = i == _dayIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _dayIndex = i;
                            _loadTimetable();
                            _animationController.reset();
                            _animationController.forward();
                          },
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? kPrimaryBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: kPrimaryBlue.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  kDays[i],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : kTextSecondary,
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: kPrimaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // ---------- 3) TIMETABLE LIST ----------
              Expanded(
                child: FutureBuilder<StudentResult<List<StudentTimetableSlotModel>>>(
                  future: _timetableFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: kPrimaryBlue),
                      );
                    }
                    if (snapshot.hasError || snapshot.data is StudentError) {
                      final msg = snapshot.data is StudentError
                          ? (snapshot.data as StudentError).message
                          : 'Could not load timetable.';
                      return Center(
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
                              onPressed: _loadTimetable,
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
                    final slots = (snapshot.data as StudentSuccess<List<StudentTimetableSlotModel>>).data;
                    if (slots.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded, size: 56, color: kTextSecondary.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No classes on ${kDayFullNames[_dayIndex]}',
                              style: TextStyle(fontSize: 16, color: kTextSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enjoy your day!',
                              style: TextStyle(fontSize: 14, color: kTextSecondary.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      );
                    }
                    slots.sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final slot = slots[index];
                          final accentColor = kSlotAccentColors[index % kSlotAccentColors.length];
                          return _TimetableSlotCard(
                            slot: slot,
                            accentColor: accentColor,
                            index: index,
                          );
                        },
                      ),
                    );
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

// ---------- TIMETABLE SLOT CARD ----------
class _TimetableSlotCard extends StatelessWidget {
  final StudentTimetableSlotModel slot;
  final Color accentColor;
  final int index;

  const _TimetableSlotCard({
    required this.slot,
    required this.accentColor,
    required this.index,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subjectName = slot.subject?['name']?.toString() ?? '—';
    final teacherName = slot.teacher?['fullName']?.toString() ?? slot.teacher?['name']?.toString() ?? '—';
    final startTime = slot.startTime ?? '—';
    final endTime = slot.endTime ?? '—';
    
    // Extract period information
    final periodName = slot.period?.name ?? 
                      (slot.period?.periodNumber != null ? 'Period ${slot.period?.periodNumber}' : 
                      '—');
    final periodNumber = slot.period?.periodNumber ?? 0;
    final periodShift = slot.period?.shift ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left accent bar with period info
          Container(
            width: 60,
            height: 100,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  periodNumber > 0 ? '$periodNumber' : '—',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  periodName.length > 8 ? periodName.substring(0, 8) + '...' : periodName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: accentColor),
                            const SizedBox(width: 4),
                            Text(
                              '$startTime - $endTime',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Shift indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getShiftColor(startTime).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getShiftLabel(startTime),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getShiftColor(startTime),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Subject name
                  Text(
                    subjectName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Teacher name
                  Row(
                    children: [
                      Icon(Icons.person_rounded, size: 16, color: kTextSecondary.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          teacherName,
                          style: TextStyle(
                            fontSize: 14,
                            color: kTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Additional info row
                  Row(
                    children: [
                      Icon(Icons.class_rounded, size: 16, color: kTextSecondary.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '$periodName • $periodShift',
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextSecondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getShiftColor(String? startTime) {
    if (startTime == null) return kPrimaryBlue;
    
    final hour = int.tryParse(startTime.split(':')[0]) ?? 0;
    if (hour < 12) {
      return const Color(0xFFF59E0B); // Morning - amber
    } else if (hour < 17) {
      return kPrimaryBlue; // Afternoon - blue
    } else {
      return const Color(0xFF9C27B0); // Evening - purple
    }
  }

  String _getShiftLabel(String? startTime) {
    if (startTime == null) return '—';
    
    final hour = int.tryParse(startTime.split(':')[0]) ?? 0;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }
}
