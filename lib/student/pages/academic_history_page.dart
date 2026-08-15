import 'package:flutter/material.dart';

import 'package:kobac/services/academic_performance_service.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/student/widgets/student_learning_ui.dart';
import 'package:kobac/student/widgets/student_web_ui.dart';

/// Student-facing academic history: browse previous academic years and see
/// that year's exams, results, attendance, and academic performance.
/// Uses GET /api/student/academic-years (student-scoped — never the
/// school-admin academic-years endpoint).
class StudentAcademicHistoryPage extends StatefulWidget {
  final bool embedBodyOnly;
  const StudentAcademicHistoryPage({super.key, this.embedBodyOnly = false});

  @override
  State<StudentAcademicHistoryPage> createState() =>
      _StudentAcademicHistoryPageState();
}

class _StudentAcademicHistoryPageState
    extends State<StudentAcademicHistoryPage> {
  bool _yearsLoading = true;
  String? _yearsError;
  List<StudentAcademicYearOption> _years = const [];
  int? _selectedYearId;

  bool _examsLoading = false;
  String? _examsError;
  List<StudentExamModel> _exams = const [];

  bool _marksLoading = false;
  String? _marksError;
  List<StudentMarkModel> _marks = const [];

  int? _expandedExamId;
  bool _resultLoading = false;
  String? _resultError;
  StudentResultReportModel? _result;

  bool _attendanceLoading = false;
  String? _attendanceError;
  List<StudentAttendanceRecordModel> _attendance = const [];

  bool _performanceLoading = false;
  String? _performanceError;
  StudentAcademicPerformance? _performance;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    setState(() {
      _yearsLoading = true;
      _yearsError = null;
    });
    final result = await StudentService().listAcademicYears();
    if (!mounted) return;
    if (result is StudentSuccess<List<StudentAcademicYearOption>>) {
      setState(() {
        _years = result.data;
        _yearsLoading = false;
        if (_years.isNotEmpty) {
          StudentAcademicYearOption current = _years.first;
          for (final year in _years) {
            if (year.isCurrent) {
              current = year;
              break;
            }
          }
          _selectedYearId = current.id;
        }
      });
      if (_selectedYearId != null) await _loadYearData();
    } else {
      setState(() {
        _yearsLoading = false;
        _yearsError = (result as StudentError).message;
      });
    }
  }

  Future<void> _onYearChanged(int? yearId) async {
    if (yearId == null || yearId == _selectedYearId) return;
    setState(() {
      _selectedYearId = yearId;
      _exams = const [];
      _examsError = null;
      _marks = const [];
      _marksError = null;
      _expandedExamId = null;
      _result = null;
      _resultError = null;
      _attendance = const [];
      _attendanceError = null;
      _performance = null;
      _performanceError = null;
    });
    await _loadYearData();
  }

  Future<void> _loadYearData() async {
    final yearId = _selectedYearId;
    if (yearId == null) return;
    await Future.wait([
      _loadExams(yearId),
      _loadMarks(yearId),
      _loadAttendance(yearId),
      _loadPerformance(yearId),
    ]);
  }

  Future<void> _loadMarks(int yearId) async {
    setState(() {
      _marksLoading = true;
      _marksError = null;
    });
    final result = await StudentService().listMarks(academicYearId: yearId);
    if (!mounted || yearId != _selectedYearId) return;
    setState(() {
      _marksLoading = false;
      if (result is StudentSuccess<List<StudentMarkModel>>) {
        _marks = result.data;
      } else {
        _marksError = (result as StudentError).message;
      }
    });
  }

  Future<void> _loadExams(int yearId) async {
    setState(() {
      _examsLoading = true;
      _examsError = null;
    });
    final result = await StudentService().listExams(academicYearId: yearId);
    if (!mounted || yearId != _selectedYearId) return;
    setState(() {
      _examsLoading = false;
      if (result is StudentSuccess<List<StudentExamModel>>) {
        _exams = result.data;
      } else {
        _examsError = (result as StudentError).message;
      }
    });
  }

  Future<void> _loadAttendance(int yearId) async {
    setState(() {
      _attendanceLoading = true;
      _attendanceError = null;
    });
    final result = await StudentService().listAttendance(
      academicYearId: yearId,
    );
    if (!mounted || yearId != _selectedYearId) return;
    setState(() {
      _attendanceLoading = false;
      if (result is StudentSuccess<List<StudentAttendanceRecordModel>>) {
        _attendance = result.data;
      } else {
        _attendanceError = (result as StudentError).message;
      }
    });
  }

  Future<void> _loadPerformance(int yearId) async {
    setState(() {
      _performanceLoading = true;
      _performanceError = null;
    });
    final result = await AcademicPerformanceService().performance(
      academicYearId: yearId,
    );
    if (!mounted || yearId != _selectedYearId) return;
    setState(() {
      _performanceLoading = false;
      if (result is PerformanceSuccess<StudentAcademicPerformance>) {
        _performance = result.data;
      } else {
        _performanceError = (result as PerformanceError).message;
      }
    });
  }

  Future<void> _toggleExam(StudentExamModel exam) async {
    if (_expandedExamId == exam.id) {
      setState(() => _expandedExamId = null);
      return;
    }
    setState(() {
      _expandedExamId = exam.id;
      _resultLoading = true;
      _resultError = null;
      _result = null;
    });
    final result = await StudentService().getResultReport(
      exam.id,
      academicYearId: _selectedYearId,
    );
    if (!mounted || _expandedExamId != exam.id) return;
    setState(() {
      _resultLoading = false;
      if (result is StudentSuccess<StudentResultReportModel>) {
        _result = result.data;
      } else {
        _resultError = (result as StudentError).message;
      }
    });
  }

  StudentAcademicYearOption? get _selectedYear {
    for (final year in _years) {
      if (year.id == _selectedYearId) return year;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isStudentDesktopWeb(context);
    final Widget body;
    if (_yearsLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_yearsError != null) {
      body = Center(
        child: StudentErrorState(message: _yearsError!, onRetry: _loadYears),
      );
    } else if (_years.isEmpty) {
      body = const Center(
        child: StudentEmptyState(
          icon: Icons.history_edu_rounded,
          title: 'No academic years available',
          message: 'Your academic history will appear here once available.',
        ),
      );
    } else {
      body = desktop ? _desktopContent() : _mobileContent();
    }

    if (widget.embedBodyOnly) {
      return desktop ? StudentWebSurface(child: body) : body;
    }
    return Scaffold(
      backgroundColor: studentCanvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudentPageHeader(
                title: 'Academic History',
                subtitle: 'View your current and previous academic years.',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 16),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileContent() => RefreshIndicator(
    onRefresh: _loadYears,
    child: ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: _sections(),
    ),
  );

  Widget _desktopContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Academic History',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: studentWebBlue,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'View your current and previous academic years.',
        style: TextStyle(color: studentWebTextSecondary),
      ),
      const SizedBox(height: 20),
      ..._sections(),
    ],
  );

  List<Widget> _sections() => [
    _yearSelector(),
    const SizedBox(height: 16),
    _yearInfoCard(),
    const SizedBox(height: 20),
    const StudentSectionHeader(title: 'Exams'),
    const SizedBox(height: 10),
    _examsSection(),
    const SizedBox(height: 20),
    const StudentSectionHeader(title: 'Marks'),
    const SizedBox(height: 10),
    _marksSection(),
    const SizedBox(height: 20),
    const StudentSectionHeader(title: 'Attendance'),
    const SizedBox(height: 10),
    _attendanceSection(),
    const SizedBox(height: 20),
    const StudentSectionHeader(title: 'Academic Performance'),
    const SizedBox(height: 10),
    _performanceSection(),
  ];

  String _markNumber(num value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();

  Widget _marksSection() {
    if (_marksLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Loading marks...'),
          ],
        ),
      );
    }
    if (_marksError != null) {
      return StudentErrorState(
        message: _marksError!,
        onRetry: () => _loadMarks(_selectedYearId!),
      );
    }
    if (_marks.isEmpty) {
      return StudentEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No marks available',
        message:
            'Released marks for ${_selectedYear?.name ?? 'this academic year'} will appear here.',
      );
    }
    final grouped = <String, List<StudentMarkModel>>{};
    for (final mark in _marks) {
      final exam = mark.exam['name']?.toString().trim();
      grouped
          .putIfAbsent(exam == null || exam.isEmpty ? 'Exam' : exam, () => [])
          .add(mark);
    }
    return Column(
      children: grouped.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StudentWebCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: studentWebBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedYear?.name ?? ''}${_selectedYear?.historicalClassName == null ? '' : ' • ${_selectedYear!.historicalClassName}'}',
                      style: const TextStyle(color: studentWebTextSecondary),
                    ),
                    const Divider(height: 22),
                    ...entry.value.map(
                      (mark) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                mark.subject['name']?.toString() ?? 'Subject',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${_markNumber(mark.marksObtained)} / ${_markNumber(mark.maxMarks)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: studentWebGreen,
                              ),
                            ),
                            if (mark.grade?.isNotEmpty == true) ...[
                              const SizedBox(width: 12),
                              Text(mark.grade!),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _yearSelector() => StudentWebDropdown<int>(
    value: _years.any((y) => y.id == _selectedYearId) ? _selectedYearId : null,
    items: _years
        .map(
          (year) => DropdownMenuItem(
            value: year.id,
            child: Text(year.isCurrent ? '${year.name} (Current)' : year.name),
          ),
        )
        .toList(),
    onChanged: _onYearChanged,
  );

  Widget _yearInfoCard() {
    final year = _selectedYear;
    if (year == null) return const SizedBox.shrink();
    return StudentWebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  year.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: studentWebBlue,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      (year.isCurrent
                              ? studentWebGreen
                              : studentWebTextSecondary)
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  year.isCurrent ? 'Current' : 'Previous',
                  style: TextStyle(
                    color: year.isCurrent
                        ? studentWebGreen
                        : studentWebTextSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (year.historicalClassName != null) ...[
            const SizedBox(height: 8),
            StudentWebInfoRow(label: 'Class', value: year.historicalClassName!),
          ],
          if (year.enrollmentStatus != null)
            StudentWebInfoRow(
              label: 'Enrollment status',
              value: year.enrollmentStatus!,
            ),
          if (year.resultsReleased != null)
            StudentWebInfoRow(
              label: 'Results',
              value: year.resultsReleased! ? 'Released' : 'Not released',
            ),
        ],
      ),
    );
  }

  Widget _examsSection() {
    if (_examsLoading) return const Center(child: CircularProgressIndicator());
    if (_examsError != null) {
      return StudentErrorState(
        message: _examsError!,
        onRetry: () => _loadExams(_selectedYearId!),
      );
    }
    if (_exams.isEmpty) {
      return const StudentEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No exams for this academic year',
      );
    }
    return Column(
      children: _exams
          .map(
            (exam) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExamCard(
                exam: exam,
                expanded: _expandedExamId == exam.id,
                onTap: () => _toggleExam(exam),
                resultLoading: _resultLoading,
                resultError: _resultError,
                result: _result,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _attendanceSection() {
    if (_attendanceLoading)
      return const Center(child: CircularProgressIndicator());
    if (_attendanceError != null) {
      return StudentErrorState(
        message: _attendanceError!,
        onRetry: () => _loadAttendance(_selectedYearId!),
      );
    }
    if (_attendance.isEmpty) {
      return const StudentEmptyState(
        icon: Icons.event_available_rounded,
        title: 'No attendance records for this academic year',
      );
    }
    final present = _attendance
        .where((a) => (a.status ?? '').toLowerCase() == 'present')
        .length;
    final absent = _attendance
        .where((a) => (a.status ?? '').toLowerCase() == 'absent')
        .length;
    final late = _attendance
        .where((a) => (a.status ?? '').toLowerCase() == 'late')
        .length;
    final leave = _attendance
        .where(
          (a) => const [
            'leave',
            'holiday',
          ].contains((a.status ?? '').toLowerCase()),
        )
        .length;
    final total = _attendance.length;
    final percentage = total == 0 ? 0.0 : (present / total) * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            StudentMetricCard(
              label: 'Present',
              value: '$present',
              icon: Icons.check_circle_rounded,
              color: studentGreen,
            ),
            StudentMetricCard(
              label: 'Absent',
              value: '$absent',
              icon: Icons.cancel_rounded,
              color: Colors.red,
            ),
            if (late > 0)
              StudentMetricCard(
                label: 'Late',
                value: '$late',
                icon: Icons.schedule_rounded,
                color: Colors.orange,
              ),
            if (leave > 0)
              StudentMetricCard(
                label: 'Leave / Holiday',
                value: '$leave',
                icon: Icons.beach_access_rounded,
                color: studentBlue,
              ),
            StudentMetricCard(
              label: 'Attendance %',
              value: '${percentage.toStringAsFixed(1)}%',
              icon: Icons.percent_rounded,
              color: studentBlue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _performanceSection() {
    if (_performanceLoading)
      return const Center(child: CircularProgressIndicator());
    if (_performanceError != null) {
      return StudentErrorState(
        message: _performanceError!,
        onRetry: () => _loadPerformance(_selectedYearId!),
      );
    }
    final data = _performance;
    if (data == null) {
      return const StudentEmptyState(
        icon: Icons.insights_rounded,
        title: 'No academic performance available for this year',
      );
    }
    return StudentWebCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.percentage}%',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: studentWebBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.grade} • ${data.status.isEmpty ? 'Unavailable' : data.status}',
                  style: const TextStyle(color: studentWebTextSecondary),
                ),
              ],
            ),
          ),
          if (data.position != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Position ${data.position}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: studentWebBlue,
                  ),
                ),
                Text(
                  'of ${data.totalStudents} students',
                  style: const TextStyle(
                    fontSize: 12,
                    color: studentWebTextSecondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final StudentExamModel exam;
  final bool expanded;
  final VoidCallback onTap;
  final bool resultLoading;
  final String? resultError;
  final StudentResultReportModel? result;

  const _ExamCard({
    required this.exam,
    required this.expanded,
    required this.onTap,
    required this.resultLoading,
    required this.resultError,
    required this.result,
  });

  @override
  Widget build(BuildContext context) => StudentWebCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: studentBlueTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: studentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exam.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: studentInk,
                  ),
                ),
              ),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: studentMuted,
              ),
            ],
          ),
        ),
        if (expanded) ...[
          const Divider(height: 24),
          if (resultLoading)
            const Center(child: CircularProgressIndicator())
          else if (resultError != null)
            Text(resultError!, style: const TextStyle(color: Colors.red))
          else if (result != null)
            _resultSummary(result!)
          else
            const Text('No result available.'),
        ],
      ],
    ),
  );

  Widget _resultSummary(StudentResultReportModel report) {
    final summary = report.summary ?? const {};
    final percentage = summary['percentage'] ?? summary['average'];
    final grade = (summary['grade'] ?? '—').toString();
    final status = (summary['status'] ?? '').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _stat('Percentage', percentage == null ? '—' : '$percentage%'),
            _stat('Grade', grade),
            _stat('Status', status.isEmpty ? 'Unavailable' : status),
          ],
        ),
        if (report.results.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...report.results.map((subject) {
            final name =
                (subject['subject_name'] ??
                        subject['name'] ??
                        (subject['subject'] is Map
                            ? subject['subject']['name']
                            : null) ??
                        'Subject')
                    .toString();
            final obtained =
                subject['marks_obtained'] ?? subject['obtained_marks'];
            final max = subject['max_marks'] ?? subject['maximum_marks'];
            final subjectStatus =
                (subject['status'] ?? subject['result_status'] ?? '')
                    .toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(color: studentInk),
                    ),
                  ),
                  Text(
                    obtained != null && max != null ? '$obtained/$max' : '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: studentBlue,
                    ),
                  ),
                  if (subjectStatus.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      subjectStatus,
                      style: TextStyle(
                        color: subjectStatus.toLowerCase() == 'fail'
                            ? Colors.red
                            : studentGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: studentMuted, fontSize: 11)),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, color: studentBlue),
      ),
    ],
  );
}
