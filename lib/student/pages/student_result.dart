import 'package:flutter/material.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/student/widgets/student_web_ui.dart';

// --- Color Palette (Matching Student Dashboard) ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE6F0FF);
const Color kSoftGreen = Color(0xFFEDF7EB);
const Color kDarkGreen = Color(0xFF3A7A30);
const Color kDarkBlue = Color(0xFF01255C);
const Color kTextPrimaryColor = Color(0xFF2D3436);
const Color kTextSecondaryColor = Color(0xFF636E72);
const Color kErrorColor = Color(0xFFEF4444);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kCardColor = Colors.white;
const Color kBackgroundColor = Color(0xFFF0F3F7);

// ====================
//   MAIN SCREEN WIDGET
// ====================
class StudentResultsScreen extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const StudentResultsScreen({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen>
    with SingleTickerProviderStateMixin {
  late Future<StudentResult<List<StudentExamModel>>> _examsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  StudentExamModel? _selectedExam;
  Future<StudentResult<StudentResultReportModel>>? _selectedExamResult;

  // Exam weights for 4-exam system
  static const Map<String, int> _examWeights = {
    'M1': 10,
    'Monthly 1': 10,
    'M2': 10,
    'Monthly 2': 10,
    'Midterm': 30,
    'Final': 50,
  };

  // Get exam weight by name
  int _getExamWeight(String examName) {
    final examNameLower = examName.toLowerCase();
    
    for (final entry in _examWeights.entries) {
      if (examNameLower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // Additional pattern matching
    if (examNameLower.contains('monthly 1') || examNameLower.contains('m1')) {
      return 10;
    }
    if (examNameLower.contains('monthly 2') || examNameLower.contains('m2')) {
      return 10;
    }
    if (examNameLower.contains('midterm') || examNameLower.contains('mid')) {
      return 30;
    }
    if (examNameLower.contains('final') || examNameLower.contains('end')) {
      return 50;
    }
    
    return 10; // Default
  }

  // Calculate correct PASS/FAIL status
  String _calculateCorrectStatus(StudentResultReportModel result) {
    // Get exam type and weight
    final examName = result.exam['name']?.toString() ?? '';
    final examWeight = _getExamWeight(examName);
    
    // Get subject count from results
    final subjectCount = result.results.length;
    
    // Calculate total exam max and pass mark
    final totalExamMax = subjectCount * examWeight;
    final passMark = totalExamMax / 2;
    
    // Get student's total obtained marks
    final studentTotal = result.summary?['total_marks_obtained'] ?? 
                        result.summary?['total_obtained'] ?? 
                        result.summary?['total'] ?? 0;
    
    // Determine status
    return studentTotal >= passMark ? 'PASS' : 'FAIL';
  }

  @override
  void initState() {
    super.initState();
    _examsFuture = StudentService().listExams();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _selectExam(StudentExamModel exam) async {
    setState(() {
      _selectedExam = exam;
      _selectedExamResult = StudentService().getResultReport(exam.id);
    });
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
        child: _buildDesktopResultsBody(context),
      );
    }

    return _buildMobileResultsBody(context);
  }

  Widget _buildDesktopResultsBody(BuildContext context) {
    return FutureBuilder<StudentResult<List<StudentExamModel>>>(
      future: _examsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
        }

        if (snapshot.data is StudentError) {
          final err = snapshot.data as StudentError;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: StudentWebCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    err.statusCode == 403 ? Icons.info_outline_rounded : Icons.error_outline_rounded,
                    size: 40,
                    color: err.statusCode == 403 ? kWarningColor : kErrorColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    err.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kTextPrimaryColor, fontSize: 14),
                  ),
                  if (err.statusCode != 403) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _examsFuture = StudentService().listExams()),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        final exams = snapshot.data is StudentSuccess<List<StudentExamModel>>
            ? (snapshot.data as StudentSuccess<List<StudentExamModel>>).data
            : <StudentExamModel>[];

        if (exams.isEmpty) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: StudentWebCard(
              child: SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(fontSize: 14, color: kTextSecondaryColor),
                  ),
                ),
              ),
            ),
          );
        }

        if (_selectedExam == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedExam == null) {
              _selectExam(exams.first);
            }
          });
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedExam != null && _selectedExamResult != null)
                FutureBuilder<StudentResult<StudentResultReportModel>>(
                  future: _selectedExamResult,
                  builder: (context, reportSnapshot) {
                    if (reportSnapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (reportSnapshot.data is StudentSuccess<StudentResultReportModel>) {
                      final report = (reportSnapshot.data as StudentSuccess<StudentResultReportModel>).data;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDesktopSummaryCards(report),
                          const SizedBox(height: 18),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              _buildDesktopExamFilter(exams),
              const SizedBox(height: 18),
              _buildDesktopResultsReportCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopSummaryCards(StudentResultReportModel report) {
    final summary = report.summary;
    final status = _calculateCorrectStatus(report);
    final bestGrade = _bestGradeFromResults(report.results);
    final average = summary?['average'] ?? summary?['overall_percentage'] ?? summary?['percentage'];
    final rank = summary?['position'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1200;
        final cards = <Widget>[];

        if (average != null) {
          cards.add(_DesktopSummaryCard(
            icon: Icons.percent_rounded,
            label: 'Average Score',
            value: '$average%',
            color: kPrimaryGreen,
            compact: compact,
          ));
        }

        if (report.results.isNotEmpty) {
          cards.add(_DesktopSummaryCard(
            icon: Icons.menu_book_rounded,
            label: 'Total Subjects',
            value: '${report.results.length}',
            color: kPrimaryBlue,
            compact: compact,
          ));
        }

        cards.add(_DesktopSummaryCard(
          icon: Icons.verified_rounded,
          label: 'Status',
          value: status,
          color: status == 'PASS' ? kPrimaryGreen : kErrorColor,
          compact: compact,
        ));

        if (bestGrade != null) {
          cards.add(_DesktopSummaryCard(
            icon: Icons.grade_rounded,
            label: 'Best Grade',
            value: bestGrade,
            color: kPrimaryBlue,
            compact: compact,
          ));
        }

        if (rank != null && rank.toString().trim().isNotEmpty) {
          cards.add(_DesktopSummaryCard(
            icon: Icons.leaderboard_rounded,
            label: 'Rank',
            value: rank.toString(),
            color: kPrimaryBlue,
            compact: compact,
          ));
        }

        if (cards.isEmpty) {
          return const SizedBox.shrink();
        }

        if (constraints.maxWidth >= 1024) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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

  String? _bestGradeFromResults(List<Map<String, dynamic>> results) {
    String? best;
    for (final row in results) {
      final grade = row['grade']?.toString().trim();
      if (grade == null || grade.isEmpty || grade == 'N/A' || grade == '—') continue;
      if (best == null || grade.compareTo(best) < 0) {
        best = grade;
      }
    }
    return best;
  }

  Widget _buildDesktopExamFilter(List<StudentExamModel> exams) {
    return StudentWebCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Exam',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextSecondaryColor,
            ),
          ),
          SizedBox(
            width: 280,
            child: StudentWebDropdown<int>(
              value: _selectedExam?.id,
              items: exams
                  .map(
                    (exam) => DropdownMenuItem<int>(
                      value: exam.id,
                      child: Text(
                        exam.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (examId) {
                if (examId == null) return;
                final exam = exams.firstWhere((e) => e.id == examId);
                _selectExam(exam);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopResultsReportCard() {
    if (_selectedExam == null || _selectedExamResult == null) {
      return const StudentWebCard(
        child: SizedBox(
          height: 220,
          child: Center(
            child: Text(
              'Select an exam to view results',
              style: TextStyle(fontSize: 14, color: kTextSecondaryColor),
            ),
          ),
        ),
      );
    }

    return FutureBuilder<StudentResult<StudentResultReportModel>>(
      future: _selectedExamResult,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const StudentWebCard(
            child: SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
            ),
          );
        }

        if (snapshot.data is StudentError) {
          final err = snapshot.data as StudentError;
          return StudentWebCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 40, color: kErrorColor.withValues(alpha: 0.85)),
                const SizedBox(height: 12),
                Text(err.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _selectExam(_selectedExam!),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
          );
        }

        final report = snapshot.data is StudentSuccess<StudentResultReportModel>
            ? (snapshot.data as StudentSuccess<StudentResultReportModel>).data
            : null;
        if (report == null) {
          return const StudentWebCard(
            child: SizedBox(
              height: 220,
              child: Center(child: Text('No results found', style: TextStyle(color: kTextSecondaryColor))),
            ),
          );
        }

        final examName = report.exam['name']?.toString() ?? 'Exam';
        final examType = report.exam['exam_type']?.toString();
        final examDate = report.exam['date']?.toString();

        return StudentWebCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      examName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kPrimaryBlue,
                      ),
                    ),
                    if (examType != null || examDate != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (examType != null)
                            _DesktopInfoChip(label: examType),
                          if (examDate != null)
                            _DesktopInfoChip(label: 'Date: $examDate'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (report.results.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SizedBox(
                    height: 180,
                    child: Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(fontSize: 14, color: kTextSecondaryColor),
                      ),
                    ),
                  ),
                )
              else ...[
                const StudentWebTableHeader(
                  columns: ['Subject', 'Score', 'Total', 'Percentage', 'Grade', 'Status'],
                  flex: [3, 1, 1, 2, 1, 2],
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: report.results.length,
                  itemBuilder: (context, index) {
                    return _DesktopResultsRow(
                      row: report.results[index],
                      showDivider: index < report.results.length - 1,
                    );
                  },
                ),
              ],
              if (report.summary != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (report.summary!['total'] != null || report.summary!['total_marks_obtained'] != null)
                        Text(
                          'Total: ${report.summary!['total'] ?? report.summary!['total_marks_obtained']}'
                          '${report.summary!['total_max'] != null ? ' / ${report.summary!['total_max']}' : ''}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimaryColor),
                        ),
                      if (report.summary!['average'] != null || report.summary!['overall_percentage'] != null)
                        Text(
                          'Average: ${report.summary!['average'] ?? report.summary!['overall_percentage']}%',
                          style: const TextStyle(fontSize: 13, color: kTextSecondaryColor),
                        ),
                      Text(
                        'Status: ${_calculateCorrectStatus(report)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _calculateCorrectStatus(report) == 'PASS' ? kPrimaryGreen : kErrorColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileResultsBody(BuildContext context) {
    final shell = Container(
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
        body: FutureBuilder<StudentResult<List<StudentExamModel>>>(
          future: _examsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
            }
            if (snapshot.data is StudentError) {
              final err = snapshot.data as StudentError;
              if (err.statusCode == 403) {
                return CustomScrollView(
                  slivers: [
                    _buildResultsAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 28),
                              const SizedBox(width: 12),
                              Expanded(child: Text(err.message, style: TextStyle(fontSize: 14, color: Colors.orange.shade900))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return CustomScrollView(
                slivers: [
                  _buildResultsAppBar(),
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: kErrorColor),
                            const SizedBox(height: 12),
                            Text(err.message, textAlign: TextAlign.center, style: const TextStyle(color: kTextPrimaryColor)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            final exams = snapshot.data is StudentSuccess<List<StudentExamModel>>
                ? (snapshot.data as StudentSuccess<List<StudentExamModel>>).data
                : <StudentExamModel>[];
            if (exams.isEmpty) {
              return CustomScrollView(
                slivers: [
                  _buildResultsAppBar(),
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.quiz_rounded, size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('No exams yet', style: TextStyle(fontSize: 16, color: kTextSecondaryColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildResultsAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final exam = exams[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectExam(exam),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 6))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: kPrimaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.assignment_rounded, color: kPrimaryBlue, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        exam.name,
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kTextSecondaryColor),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: exams.length,
                    ),
                  ),
                ),
                // Show selected exam results
                if (_selectedExam != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: FutureBuilder<StudentResult<StudentResultReportModel>>(
                        future: _selectedExamResult!,
                        builder: (context, resultSnapshot) {
                          if (resultSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
                          }
                          if (resultSnapshot.data is StudentError) {
                            final err = resultSnapshot.data as StudentError;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade800, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(err.message, style: TextStyle(fontSize: 14, color: Colors.red.shade900))),
                                ],
                              ),
                            );
                          }
                          final report = resultSnapshot.data as StudentSuccess<StudentResultReportModel>?;
                          if (report == null) {
                            return const Center(child: Text('No result data available'));
                          }
                          final result = report.data;
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Exam Header
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: kPrimaryBlue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        result.exam['name'] ?? 'Exam',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (result.exam['exam_type'] != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: kPrimaryBlue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                result.exam['exam_type'],
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimaryBlue),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Expanded(
                                            child: Text(
                                              'Date: ${result.exam['date'] ?? 'N/A'}',
                                              style: TextStyle(fontSize: 14, color: kTextSecondaryColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Subject-by-Subject Results
                                if (result.results.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6))],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: kPrimaryBlue.withOpacity(0.05),
                                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                                          ),
                                          child: const Text(
                                            'Subject Results',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: kPrimaryBlue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Subject List
                                        ...result.results.map((r) => Container(
                                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Subject Name
                                              Text(
                                                r['subject']?['name'] ?? r['subject_name'] ?? 'Subject',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: kPrimaryBlue,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              
                                              // Marks and Percentage Row
                                              Row(
                                                children: [
                                                  // Marks
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          'Marks',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: kTextSecondaryColor,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          '${r['marks_obtained'] ?? 0} / ${r['max_marks'] ?? 100}',
                                                          style: const TextStyle(
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                            color: kPrimaryGreen,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  
                                                  // Percentage
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          'Percentage',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: kTextSecondaryColor,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          '${r['percentage'] ?? 0}%',
                                                          style: const TextStyle(
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                            color: kPrimaryBlue,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              
                                              // Grade
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: kPrimaryGreen.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  'Grade: ${r['grade'] ?? 'N/A'}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: kPrimaryGreen,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )).toList(),
                                      ],
                                    ),
                                  ),
                                if (result.results.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: kSoftBlue.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.info_outline_rounded, size: 48, color: kPrimaryBlue),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No subject results available',
                                          style: TextStyle(fontSize: 16, color: kPrimaryBlue, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'The exam results for individual subjects are not yet available.',
                                          style: TextStyle(fontSize: 14, color: kTextSecondaryColor),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                // Summary Section
                                if (result.summary != null)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))],
                                    ),
                                    child: Column(
                                      children: [
                                        // Header
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: kPrimaryBlue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.assessment_rounded, color: kPrimaryBlue, size: 24),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Results Summary',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: kPrimaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        // Results Grid
                                        Column(
                                          children: [
                                            // TOTAL - Full width card
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: kSoftBlue,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'TOTAL',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: kTextSecondaryColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                                    textBaseline: TextBaseline.alphabetic,
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          '${result.summary!['total'] ?? result.summary!['total_marks_obtained'] ?? 0}',
                                                          style: const TextStyle(
                                                            fontSize: 24,
                                                            fontWeight: FontWeight.bold,
                                                            color: kPrimaryBlue,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (result.summary!['total_max'] != null) ...[
                                                        const SizedBox(width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            '/ ${result.summary!['total_max']}',
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w500,
                                                              color: kTextSecondaryColor,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            
                                            // Second row: AVERAGE and STATUS side by side
                                            Row(
                                              children: [
                                                // AVERAGE
                                                Expanded(
                                                  child: Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: kSoftGreen,
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          'AVERAGE',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: kTextSecondaryColor,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          '${result.summary!['average'] ?? result.summary!['overall_percentage'] ?? 0}%',
                                                          style: const TextStyle(
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                            color: kPrimaryGreen,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                               
                                                // STATUS
                                                Expanded(
                                                  child: Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: (_calculateCorrectStatus(result) == 'PASS' ? kPrimaryGreen.withOpacity(0.1) : kErrorColor.withOpacity(0.1)),
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(color: (_calculateCorrectStatus(result) == 'PASS' ? kPrimaryGreen : kErrorColor).withOpacity(0.3)),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        const Text(
                                                          'STATUS',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: kTextSecondaryColor,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          _calculateCorrectStatus(result),
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                            color: _calculateCorrectStatus(result) == 'PASS' ? kPrimaryGreen : kErrorColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );

    return shell;
  }

  Widget _buildResultsAppBar() {
    return SliverToBoxAdapter(
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Academic Results",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Exam Results",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  const _DesktopSummaryCard({
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
                    color: kTextSecondaryColor,
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

class _DesktopInfoChip extends StatelessWidget {
  final String label;

  const _DesktopInfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kPrimaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimaryBlue),
      ),
    );
  }
}

class _DesktopResultsRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool showDivider;

  const _DesktopResultsRow({
    required this.row,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final subject = row['subject']?['name']?.toString() ?? row['subject_name']?.toString() ?? 'Subject';
    final obtained = row['marks_obtained'] ?? row['marksObtained'] ?? 0;
    final maxMarks = row['max_marks'] ?? row['maxMarks'] ?? '—';
    final percentage = row['percentage'];
    final grade = row['grade']?.toString() ?? '—';
    final status = row['status']?.toString();

    return Container(
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: studentWebBorder)) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$obtained',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryGreen),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$maxMarks',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: kTextSecondaryColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              percentage != null ? '$percentage%' : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: kTextSecondaryColor),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _GradeBadge(grade: grade),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: status != null && status.trim().isNotEmpty
                  ? _StatusBadge(status: status)
                  : const Text(
                      '—',
                      style: TextStyle(fontSize: 12, color: kTextSecondaryColor),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  final String grade;

  const _GradeBadge({required this.grade});

  @override
  Widget build(BuildContext context) {
    final normalized = grade.trim().toUpperCase();
    Color color = kPrimaryBlue;
    if (normalized.startsWith('A')) {
      color = kPrimaryGreen;
    } else if (normalized.startsWith('B')) {
      color = kPrimaryBlue;
    } else if (normalized.startsWith('C')) {
      color = kWarningColor;
    } else if (normalized.startsWith('D') || normalized.startsWith('F')) {
      color = kErrorColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        grade,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    final isPass = normalized.contains('PASS');
    final color = isPass ? kPrimaryGreen : kErrorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
