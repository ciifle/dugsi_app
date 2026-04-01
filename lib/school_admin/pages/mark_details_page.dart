import 'package:flutter/material.dart';
import 'package:kobac/services/marks_service.dart';
import 'package:kobac/services/exams_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/api_error_helpers.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

/// Mark detail page — loads mark by id and shows student, exam, subject, marks, grade.
class MarkDetailsPage extends StatefulWidget {
  final int markId;

  const MarkDetailsPage({Key? key, required this.markId}) : super(key: key);

  @override
  State<MarkDetailsPage> createState() => _MarkDetailsPageState();
}

class _MarkDetailsPageState extends State<MarkDetailsPage> {
  late Future<MarkResult<MarkModel>> _markFuture;
  List<ExamModel> _exams = [];
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<StudentModel> _students = [];
  List<TeacherModel> _teachers = [];

  @override
  void initState() {
    super.initState();
    print('[AdminMarksDetail] received mark id: ${widget.markId}');
    _markFuture = MarksService().getMark(widget.markId);
    _loadRefData();
  }

  Future<void> _loadRefData() async {
    final examsR = await ExamsService().listExams();
    final classesR = await ClassesService().listClasses();
    final subjectsR = await SubjectsService().listSubjects();
    final studentsR = await StudentsService().listStudents();
    final teachersR = await TeachersService().listTeachers();
    if (!mounted) return;
    setState(() {
      if (examsR is ExamSuccess<List<ExamModel>>) _exams = examsR.data;
      if (classesR is ClassSuccess<List<ClassModel>>) _classes = classesR.data;
      if (subjectsR is SubjectSuccess<List<SubjectModel>>) _subjects = subjectsR.data;
      if (studentsR is StudentSuccess<List<StudentModel>>) _students = studentsR.data;
      if (teachersR is TeacherSuccess<List<TeacherModel>>) _teachers = teachersR.data;
    });
  }

  String _examName(int id) {
    for (final e in _exams) { if (e.id == id) return e.name; }
    return '—';
  }

  String _subjectName(int id) {
    for (final s in _subjects) { if (s.id == id) return s.name; }
    return '—';
  }

  String _studentName(int id) {
    for (final s in _students) { if (s.id == id) return s.studentName; }
    return '—';
  }

  String _teacherName(int? id) {
    if (id == null || id <= 0) return '—';
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
                        'Mark Details',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<MarkResult<MarkModel>>(
                  future: _markFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                    }
                    if (snapshot.hasError) {
                      final msg = userFriendlyMessage(snapshot.error!, null, 'MarkDetailsPage');
                      return _ErrorState(
                        message: msg,
                        onRetry: () => setState(() => _markFuture = MarksService().getMark(widget.markId)),
                      );
                    }
                    final result = snapshot.data;
                    if (result == null) return const Center(child: Text('No data'));
                    if (result is MarkError) {
                      return _ErrorState(
                        message: result.message,
                        onRetry: () => setState(() => _markFuture = MarksService().getMark(widget.markId)),
                      );
                    }
                    final mark = (result as MarkSuccess<MarkModel>).data;
                    print('[AdminMarksDetail] received examName: ${mark.examName}');
                    print('[AdminMarksDetail] received exam object: ${mark.exam}');
                    final pct = mark.maxMarks > 0
                        ? (mark.marksObtained / mark.maxMarks * 100).toStringAsFixed(1)
                        : '—';
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _OverviewCard(
                            mark: mark,
                            studentName: mark.studentName ?? _studentName(mark.studentId),
                            examName: mark.examName ?? _examName(mark.examId),
                            subjectName: mark.subjectName ?? _subjectName(mark.subjectId),
                            teacherName: mark.teacherName ?? _teacherName(mark.teacherId),
                            percentage: pct,
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
  final MarkModel mark;
  final String studentName;
  final String examName;
  final String subjectName;
  final String teacherName;
  final String percentage;

  const _OverviewCard({
    required this.mark,
    required this.studentName,
    required this.examName,
    required this.subjectName,
    required this.teacherName,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            studentName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.quiz_rounded, label: 'Exam', value: examName),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.menu_book_rounded, label: 'Subject', value: subjectName),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.grade_rounded,
            label: 'Marks',
            value: '${mark.marksObtained} / ${mark.maxMarks} ($percentage%)',
          ),
          if (mark.grade != null && mark.grade!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.star_rounded, label: 'Grade', value: mark.grade!),
          ],
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.person_rounded, label: 'Teacher', value: teacherName),
          if (mark.createdAt != null && mark.createdAt!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.calendar_today_rounded, label: 'Recorded', value: mark.createdAt!),
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
