import 'package:flutter/material.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/student/pages/student_total_page.dart';
import 'package:kobac/student/widgets/student_web_ui.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE0E9F5);
const Color kSoftGreen = Color(0xFFE4F1E2);
const Color kErrorColor = Color(0xFFEF4444);
const Color kTextPrimary = Color(0xFF1A1E1F);
const Color kTextSecondary = Color(0xFF4F5A5E);

class StudentMarksScreen extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const StudentMarksScreen({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<StudentMarksScreen> createState() => _StudentMarksScreenState();
}

class _StudentMarksScreenState extends State<StudentMarksScreen> {
  late Future<StudentResult<List<StudentAcademicYearOption>>> _yearsFuture;
  late Future<StudentResult<List<StudentExamModel>>> _examsFuture;
  late Future<StudentResult<List<StudentMarkModel>>> _marksFuture;
  StudentAcademicYearOption? _selectedYear;
  int? _examId;

  @override
  void initState() {
    super.initState();
    _yearsFuture = StudentService().listAcademicYears();
    _examsFuture = StudentService().listExams();
    _loadMarks();
    _yearsFuture.then((result) {
      if (!mounted ||
          result is! StudentSuccess<List<StudentAcademicYearOption>>)
        return;
      final years = result.data;
      if (years.isEmpty) return;
      var year = years.first;
      for (final item in years) {
        if (item.isCurrent || item.isActive) {
          year = item;
          break;
        }
      }
      setState(() => _selectedYear = year);
      _loadYear(year.id);
    });
  }

  void _loadMarks() {
    setState(() {
      _marksFuture = StudentService().listMarks(
        academicYearId: _selectedYear?.id,
        examId: _examId,
      );
    });
  }

  void _loadYear(int yearId) {
    setState(() {
      _examId = null;
      _examsFuture = StudentService().listExams(academicYearId: yearId);
      _marksFuture = StudentService().listMarks(academicYearId: yearId);
    });
  }

  String _number(num value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();

  void _openTotalPage(List<StudentMarkModel> list) {
    if (widget.embedBodyOnly &&
        isStudentDesktopWeb(context) &&
        widget.onNavigateToPage != null) {
      widget.onNavigateToPage!(
        'marksTotal',
        arguments: StudentMarksTotalArguments(
          marks: list,
          academicYearId: _selectedYear?.id,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StudentTotalPage(marks: list, academicYearId: _selectedYear?.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedBodyOnly && isStudentDesktopWeb(context)) {
      return Container(
        color: studentWebBg,
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _examsFuture = StudentService().listExams(forceRefresh: true);
              _loadMarks();
            });
          },
          color: kPrimaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildYearFilter(),
                const SizedBox(height: 16),
                _buildExamFilter(),
                const SizedBox(height: 16),
                _buildMarksBody(compact: true),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kSoftBlue,
      body: Container(
        decoration: const BoxDecoration(color: studentWebBg),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryBlue.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: kPrimaryBlue,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'My Marks',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildYearFilter()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(child: _buildExamFilter()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(child: _buildMarksBody()),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearFilter() {
    return FutureBuilder<StudentResult<List<StudentAcademicYearOption>>>(
      future: _yearsFuture,
      builder: (context, snapshot) {
        final years =
            snapshot.data is StudentSuccess<List<StudentAcademicYearOption>>
            ? (snapshot.data as StudentSuccess<List<StudentAcademicYearOption>>)
                  .data
            : <StudentAcademicYearOption>[];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StudentWebCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: StudentWebDropdown<int>(
              value: _selectedYear?.id,
              hint: Text(
                snapshot.connectionState == ConnectionState.waiting
                    ? 'Loading academic years...'
                    : 'Academic year',
              ),
              items: years
                  .map(
                    (year) => DropdownMenuItem<int>(
                      value: year.id,
                      child: Text(
                        year.historicalClassName == null
                            ? year.name
                            : '${year.name} - ${year.historicalClassName}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                final year = years.firstWhere((item) => item.id == id);
                setState(() => _selectedYear = year);
                _loadYear(id);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildExamFilter() {
    return FutureBuilder<StudentResult<List<StudentExamModel>>>(
      future: _examsFuture,
      builder: (context, examSnap) {
        if (examSnap.data is StudentError &&
            (examSnap.data as StudentError).statusCode == 403) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ModuleDisabledBanner(
              message: (examSnap.data as StudentError).message,
            ),
          );
        }
        final exams = examSnap.data is StudentSuccess<List<StudentExamModel>>
            ? (examSnap.data as StudentSuccess<List<StudentExamModel>>).data
            : <StudentExamModel>[];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StudentWebCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: StudentWebDropdown<int?>(
              value: _examId,
              hint: const Text('All exams'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All exams'),
                ),
                ...exams.map(
                  (e) =>
                      DropdownMenuItem<int?>(value: e.id, child: Text(e.name)),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  _examId = v;
                  _loadMarks();
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarksBody({bool compact = false}) {
    return FutureBuilder<StudentResult<List<StudentMarkModel>>>(
      future: _marksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: kPrimaryBlue),
                  SizedBox(height: 14),
                  Text(
                    'Loading marks...',
                    style: TextStyle(color: kTextSecondary),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data is StudentError) {
          final msg = snapshot.data is StudentError
              ? (snapshot.data as StudentError).message
              : 'Could not load marks.';
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: kErrorColor.withOpacity(0.8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kTextPrimary, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _loadMarks,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final list =
            (snapshot.data as StudentSuccess<List<StudentMarkModel>>).data;
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    size: 56,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No marks available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Released marks for ${_selectedYear?.name ?? 'this academic year'} will appear here.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kTextSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        if (compact) {
          return StudentWebCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudentWebTableHeader(
                  columns: const ['Subject', 'Exam', 'Score', 'Grade'],
                ),
                ...list.map((m) {
                  final examName = m.exam['name']?.toString() ?? '—';
                  final subjectName = m.subject['name']?.toString() ?? '—';
                  return StudentWebTableRow(
                    cells: [
                      Text(
                        subjectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                      Text(
                        examName,
                        style: const TextStyle(color: kTextSecondary),
                      ),
                      Text(
                        '${_number(m.marksObtained)}/${_number(m.maxMarks)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kPrimaryGreen,
                        ),
                      ),
                      Text(
                        m.grade ?? '—',
                        style: const TextStyle(color: kTextSecondary),
                      ),
                    ],
                  );
                }),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _openTotalPage(list),
                    child: const Text('See total'),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GestureDetector(
                onTap: () => _openTotalPage(list),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assessment_rounded,
                          color: kPrimaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'See Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: kPrimaryBlue.withOpacity(0.7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final m = list[index];
                final examName = m.exam['name']?.toString() ?? '—';
                final subjectName = m.subject['name']?.toString() ?? '—';
                final teacherName =
                    m.teacher?['fullName']?.toString() ??
                    m.teacher?['name']?.toString() ??
                    '—';
                final className = m.class_?['name']?.toString() ?? '—';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kPrimaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.grade_rounded,
                              color: kPrimaryBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subjectName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryBlue,
                                  ),
                                ),
                                Text(
                                  '$examName ${className != '—' ? '· $className' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${_number(m.marksObtained)}/${_number(m.maxMarks)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryGreen,
                            ),
                          ),
                          if (m.percentage != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${_number(m.percentage!)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (m.grade != null && m.grade!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Grade: ${m.grade}',
                            style: TextStyle(
                              fontSize: 13,
                              color: kTextSecondary,
                            ),
                          ),
                        ),
                      if (teacherName != '—')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Teacher: $teacherName',
                            style: TextStyle(
                              fontSize: 12,
                              color: kTextSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ModuleDisabledBanner extends StatelessWidget {
  final String message;

  const _ModuleDisabledBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.orange.shade800,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
