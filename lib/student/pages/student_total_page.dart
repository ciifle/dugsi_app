import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/services/academic_performance_service.dart';
import 'package:kobac/student/widgets/student_web_ui.dart';
import 'package:kobac/utils/number_format.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kPrimaryGreenOpacity = Color(0x1A5AB04B);
const Color kSoftBlue = Color(0xFFE0E9F5);
const Color kSoftGreen = Color(0xFFE4F1E2);
const Color kSoftRed = Color(0xFFFFEBEE);
const Color kErrorColor = Color(0xFFEF4444);
const Color kTextPrimary = Color(0xFF1A1E1F);
const Color kTextSecondary = Color(0xFF4F5A5E);

class StudentMarksTotalArguments {
  final List<StudentMarkModel> marks;
  final int? academicYearId;
  const StudentMarksTotalArguments({required this.marks, this.academicYearId});
}

String formatOrdinalPosition(int value) {
  final mod100 = value % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${value}th';
  return switch (value % 10) {
    1 => '${value}st',
    2 => '${value}nd',
    3 => '${value}rd',
    _ => '${value}th',
  };
}

class StudentTotalPage extends StatefulWidget {
  final List<StudentMarkModel> marks;
  final bool embedBodyOnly;
  final int? academicYearId;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  StudentTotalPage({
    Key? key,
    required this.marks,
    this.academicYearId,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<StudentTotalPage> createState() => _StudentTotalPageState();
}

class _StudentTotalPageState extends State<StudentTotalPage> {
  String _selectedExam = 'Total'; // 'Total', 'M1', 'M2', 'Midterm', 'Final'
  StudentAcademicPerformance? _canonicalResult;
  bool _loadingCanonical = true;

  @override
  void initState() {
    super.initState();
    _loadCanonicalResult();
  }

  Future<void> _loadCanonicalResult() async {
    final result = await AcademicPerformanceService().performance(
      academicYearId: widget.academicYearId,
    );
    if (!mounted) return;
    setState(() {
      _loadingCanonical = false;
      if (result is PerformanceSuccess<StudentAcademicPerformance>) {
        _canonicalResult = result.data;
      }
    });
  }

  bool? _isPassedStatus(String? status) {
    final normalized = status?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized == 'pass' || normalized == 'passed') return true;
    if (normalized == 'fail' || normalized == 'failed') return false;
    return null;
  }

  bool? _isPassedFromExistingStatus() {
    final matchingMarks = widget.marks.where((mark) {
      if (_selectedExam == 'Total') return true;
      return _getExamType(mark.exam['name']?.toString() ?? '') == _selectedExam;
    });

    bool? isPassed;
    for (final mark in matchingMarks) {
      final markPassed = _isPassedStatus(mark.status);
      if (markPassed == null) continue;
      isPassed ??= markPassed;
      if (isPassed != markPassed) return null;
    }

    return isPassed;
  }

  // Get exam type for display
  String _getExamType(String examName) {
    final examNameLower = examName.toLowerCase();

    if (examNameLower.contains('monthly 1') || examNameLower.contains('m1')) {
      return 'M1';
    }
    if (examNameLower.contains('monthly 2') || examNameLower.contains('m2')) {
      return 'M2';
    }
    if (examNameLower.contains('midterm') || examNameLower.contains('mid')) {
      return 'Midterm';
    }
    if (examNameLower.contains('final') || examNameLower.contains('end')) {
      return 'Final';
    }

    return 'Unknown';
  }

  // Group each mark's obtained/max by subject and exam — real backend
  // per-mark maxima, never a hardcoded weight.
  Map<String, Map<String, (num obtained, num max)>>
  _groupMarksBySubjectAndExam() {
    final subjectMarks = <String, Map<String, (num obtained, num max)>>{};

    for (final mark in widget.marks) {
      final subjectName = mark.subject['name']?.toString() ?? 'Unknown Subject';
      final examType = _getExamType(mark.exam['name']?.toString() ?? '');

      subjectMarks.putIfAbsent(subjectName, () => {});
      subjectMarks[subjectName]![examType] = (
        mark.marksObtained,
        mark.maxMarks,
      );
    }

    return subjectMarks;
  }

  // Calculate totals based on selected exam. The "Total" tab never sums
  // local exam records — it is backend-canonical via `_canonicalResult`.
  Map<String, dynamic> _calculateTotals() {
    if (_selectedExam == 'Total') {
      final subjects = _canonicalResult?.subjects ?? const [];
      final subjectTotals = <String, Map<String, num>>{
        for (final subject in subjects)
          subject.name: {'obtained': subject.marks, 'max': subject.maximum},
      };
      return {'subjectTotals': subjectTotals};
    }

    final subjectMarks = _groupMarksBySubjectAndExam();
    final subjectTotals = <String, Map<String, num>>{};
    num totalObtained = 0;
    num totalMax = 0;

    for (final entry in subjectMarks.entries) {
      final examMark = entry.value[_selectedExam];
      if (examMark == null) continue; // no real max for this subject/exam
      final (obtained, max) = examMark;
      subjectTotals[entry.key] = {'obtained': obtained, 'max': max};
      totalObtained += obtained;
      totalMax += max;
    }

    return {
      'subjectTotals': subjectTotals,
      'totalObtained': totalObtained,
      'totalMax': totalMax,
    };
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();
    final subjectTotals =
        totals['subjectTotals'] as Map<String, Map<String, num>>;
    final isGrandTotal = _selectedExam == 'Total';
    final num? calculatedObtained = totals['totalObtained'] as num?;
    final num? calculatedMax = totals['totalMax'] as num?;
    // Total tab: backend-canonical grand total, never locally summed.
    final num? totalObtained = isGrandTotal
        ? _canonicalResult?.grandTotalMarks
        : calculatedObtained;
    final num? totalMax = isGrandTotal
        ? _canonicalResult?.grandMaximumMarks
        : calculatedMax;
    final num? overallPercentage = isGrandTotal
        ? _canonicalResult?.percentage
        : ((calculatedMax != null && calculatedMax > 0)
              ? (calculatedObtained! / calculatedMax) * 100
              : null);
    final backendPassed = _isPassedStatus(_canonicalResult?.status);
    final isPassed = isGrandTotal
        ? backendPassed
        : _isPassedFromExistingStatus();
    final percentageBg = isPassed == false ? kSoftRed : kPrimaryGreenOpacity;
    final percentageColor = isPassed == false
        ? const Color(0xFFD32F2F)
        : kPrimaryGreen;
    final statusText = isPassed == null ? 'N/A' : (isPassed ? 'PASS' : 'FAIL');

    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = kIsWeb || screenWidth > 600;
    final embedded = widget.embedBodyOnly && isStudentDesktopWeb(context);
    final maxContentWidth = isWeb ? 1000.0 : double.infinity;

    final body = Container(
      decoration: embedded
          ? const BoxDecoration(color: studentWebBg)
          : const BoxDecoration(color: studentWebBg),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (!embedded)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isWeb ? 32 : 24,
                        16,
                        isWeb ? 32 : 24,
                        24,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (embedded && widget.onNavigateToPage != null) {
                                widget.onNavigateToPage!('marks');
                                return;
                              }
                              Navigator.pop(context);
                            },
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
                              'Total',
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

                // Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWeb ? 32 : 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                      child: Column(
                        children: [
                          Row(
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedExam == 'Total'
                                          ? 'Grand Total'
                                          : '$_selectedExam Total',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryBlue,
                                      ),
                                    ),
                                    if (isGrandTotal &&
                                        _canonicalResult?.subjectsIncluded !=
                                            null)
                                      Text(
                                        '${_canonicalResult!.subjectsIncluded} subjects included',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: kTextSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 28,
                                  ),
                                  color: kSoftBlue,
                                  child: isGrandTotal && _loadingCanonical
                                      ? const Center(
                                          child: SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: kPrimaryBlue,
                                            ),
                                          ),
                                        )
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.baseline,
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                formatDecimal(totalObtained),
                                                style: const TextStyle(
                                                  fontSize: 42,
                                                  fontWeight: FontWeight.w800,
                                                  color: kPrimaryBlue,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Text(
                                                '/ ${formatDecimal(totalMax)}',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w700,
                                                  color: kTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                                if (isGrandTotal) ...[
                                  Container(height: 2, color: Colors.white),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    color: kSoftBlue,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Overall Percentage',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: kTextSecondary,
                                          ),
                                        ),
                                        Text(
                                          _loadingCanonical ||
                                                  overallPercentage == null
                                              ? '—'
                                              : '${formatDecimal(overallPercentage)}%',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: kPrimaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 22,
                                        ),
                                        color: percentageBg,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            isGrandTotal
                                                ? 'Grade: ${_canonicalResult?.grade.isNotEmpty == true ? _canonicalResult!.grade : '—'}'
                                                : (overallPercentage == null
                                                      ? '—'
                                                      : '${formatDecimal(overallPercentage)}%'),
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                              color: percentageColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 2,
                                      height: 80,
                                      color: Colors.white,
                                    ),
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 22,
                                        ),
                                        color: isPassed == false
                                            ? kSoftRed
                                            : kPrimaryGreenOpacity,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Status: $statusText',
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                              color: isPassed == false
                                                  ? const Color(0xFFD32F2F)
                                                  : kPrimaryGreen,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isGrandTotal) ...[
                                  Container(height: 2, color: Colors.white),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                    color: kSoftBlue,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Position',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: kTextSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          _canonicalResult?.position == null
                                              ? '—'
                                              : _canonicalResult!
                                                        .totalStudents >
                                                    0
                                              ? '${formatOrdinalPosition(_canonicalResult!.position!)} of ${_canonicalResult!.totalStudents}'
                                              : formatOrdinalPosition(
                                                  _canonicalResult!.position!,
                                                ),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: kPrimaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Exam Selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWeb ? 32 : 20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryBlue.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: ['Total', 'M1', 'M2', 'Midterm', 'Final'].map(
                          (exam) {
                            final isSelected = _selectedExam == exam;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedExam = exam),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kPrimaryBlue
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    exam,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : kTextSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Table Section
                if (isGrandTotal && _loadingCanonical)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: kPrimaryBlue),
                      ),
                    ),
                  )
                else if (subjectTotals.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
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
                            Text(
                              'No marks available',
                              style: TextStyle(
                                fontSize: 16,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 32 : 20,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryBlue.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: kPrimaryBlue.withOpacity(0.05),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Subject',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryBlue,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Marks Obtained',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryBlue,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Max Marks',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Table Rows
                            ...subjectTotals.entries.map((entry) {
                              final subjectName = entry.key;
                              final data = entry.value;
                              final obtained = data['obtained'] ?? 0;
                              final max = data['max'] ?? 0;
                              final percentage = max > 0
                                  ? (obtained / max) * 100
                                  : 0;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: kTextSecondary.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        subjectName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: kTextPrimary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        formatDecimal(obtained),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: percentage >= 50
                                              ? kPrimaryGreen
                                              : kErrorColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        formatDecimal(max),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: kTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(backgroundColor: kSoftBlue, body: body);
  }
}
