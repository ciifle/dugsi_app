import 'package:flutter/material.dart';
import 'package:kobac/services/timetables_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/api_error_helpers.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

String _timeDisplay(String t) {
  final parts = t.split(':');
  if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
  return t;
}

/// Timetable slot detail page — loads slot by id and shows class, subject, teacher, day, times.
class TimetableDetailPage extends StatefulWidget {
  final int slotId;

  const TimetableDetailPage({Key? key, required this.slotId}) : super(key: key);

  @override
  State<TimetableDetailPage> createState() => _TimetableDetailPageState();
}

class _TimetableDetailPageState extends State<TimetableDetailPage> {
  late Future<TimetableResult<TimetableSlotModel>> _slotFuture;
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<TeacherModel> _teachers = [];

  @override
  void initState() {
    super.initState();
    _slotFuture = TimetablesService().getTimetable(widget.slotId);
    _loadRefData();
  }

  Future<void> _loadRefData() async {
    final classesR = await ClassesService().listClasses();
    final subjectsR = await SubjectsService().listSubjects();
    final teachersR = await TeachersService().listTeachers();
    if (!mounted) return;
    setState(() {
      if (classesR is ClassSuccess<List<ClassModel>>) _classes = classesR.data;
      if (subjectsR is SubjectSuccess<List<SubjectModel>>) _subjects = subjectsR.data;
      if (teachersR is TeacherSuccess<List<TeacherModel>>) _teachers = teachersR.data;
    });
  }

  String _className(int id) {
    for (final c in _classes) { if (c.id == id) return c.name; }
    return '—';
  }

  String _subjectName(int id) {
    for (final s in _subjects) { if (s.id == id) return s.name; }
    return '—';
  }

  String _teacherName(int id) {
    for (final t in _teachers) { if (t.id == id) return t.fullName; }
    return '—';
  }

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
                        'Timetable Slot',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<TimetableResult<TimetableSlotModel>>(
                  future: _slotFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                    }
                    if (snapshot.hasError) {
                      final msg = userFriendlyMessage(snapshot.error!, null, 'TimetableDetailPage');
                      return _ErrorState(
                        message: msg,
                        onRetry: () => setState(() => _slotFuture = TimetablesService().getTimetable(widget.slotId)),
                      );
                    }
                    final result = snapshot.data;
                    if (result == null) return const Center(child: Text('No data'));
                    if (result is TimetableError) {
                      return _ErrorState(
                        message: result.message,
                        onRetry: () => setState(() => _slotFuture = TimetablesService().getTimetable(widget.slotId)),
                      );
                    }
                    final slot = (result as TimetableSuccess<TimetableSlotModel>).data;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _OverviewCard(
                            slot: slot,
                            className: _className(slot.classId),
                            subjectName: _subjectName(slot.subjectId),
                            teacherName: _teacherName(slot.teacherId),
                          ),
                          const SizedBox(height: 24),
                        ],
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

class _OverviewCard extends StatelessWidget {
  final TimetableSlotModel slot;
  final String className;
  final String subjectName;
  final String teacherName;

  const _OverviewCard({
    required this.slot,
    required this.className,
    required this.subjectName,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = '${_timeDisplay(slot.startTime)} - ${_timeDisplay(slot.endTime)}';
    return Container(
      padding: const EdgeInsets.all(20),
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
          if (slot.period != null) ...[
            Text(
              slot.period!.name.isNotEmpty ? slot.period!.name : 'Period ${slot.period!.periodNumber}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            timeStr,
            style: TextStyle(
              fontSize: slot.period != null ? 16 : 20, 
              fontWeight: slot.period != null ? FontWeight.normal : FontWeight.bold, 
              color: slot.period != null ? Colors.grey[700] : kPrimaryBlue
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.menu_book_rounded, label: 'Subject', value: subjectName),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.class_rounded, label: 'Class', value: className),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.person_rounded, label: 'Teacher', value: teacherName),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.calendar_view_week_rounded, label: 'Day', value: slot.day),
          if (slot.period?.shift != null && slot.period!.shift.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: slot.period!.shift.toLowerCase() == 'afternoon' ? Icons.wb_twilight_rounded : Icons.wb_sunny_rounded, 
              label: 'Shift', 
              value: slot.period!.shift.toLowerCase() == 'afternoon' ? 'Afternoon' : 'Morning'
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kPrimaryGreen, size: 22),
        const SizedBox(width: 12),
        Text('$label: ', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 14)),
        Expanded(
          child: Text(value, style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w500, fontSize: 15)),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
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
