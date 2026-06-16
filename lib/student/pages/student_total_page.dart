import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/student/widgets/student_web_ui.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kPrimaryGreenOpacity = Color(0x1A5AB04B);
const Color kSoftBlue = Color(0xFFE0E9F5);
const Color kSoftGreen = Color(0xFFE4F1E2);
const Color kSoftRed = Color(0xFFFFEBEE);
const Color kErrorColor = Color(0xFFEF4444);
const Color kTextPrimary = Color(0xFF1A1E1F);
const Color kTextSecondary = Color(0xFF4F5A5E);

class StudentTotalPage extends StatefulWidget {
  final List<StudentMarkModel> marks;
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  StudentTotalPage({
    Key? key,
    required this.marks,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<StudentTotalPage> createState() => _StudentTotalPageState();
}

class _StudentTotalPageState extends State<StudentTotalPage> {
  String _selectedExam = 'Total'; // 'Total', 'M1', 'M2', 'Midterm', 'Final'

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

  // Group marks by subject and exam
  Map<String, Map<String, num>> _groupMarksBySubjectAndExam() {
    Map<String, Map<String, num>> subjectMarks = {};
    
    for (final mark in widget.marks) {
      final subjectName = mark.subject['name']?.toString() ?? 'Unknown Subject';
      final examType = _getExamType(mark.exam['name']?.toString() ?? '');
      
      if (!subjectMarks.containsKey(subjectName)) {
        subjectMarks[subjectName] = {};
      }
      
      subjectMarks[subjectName]![examType] = mark.marksObtained;
    }
    
    return subjectMarks;
  }

  // Calculate totals based on selected exam
  Map<String, dynamic> _calculateTotals() {
    final subjectMarks = _groupMarksBySubjectAndExam();
    final subjectTotals = <String, Map<String, num>>{};
    
    num totalObtained = 0;
    num totalMax = 0;
    
    for (final subjectName in subjectMarks.keys) {
      final marks = subjectMarks[subjectName]!;
      num subjectObtained = 0;
      num subjectMax = 0;
      
      if (_selectedExam == 'Total') {
        // TOTAL view: sum all available exams, but max is always 100
        for (final examType in marks.keys) {
          subjectObtained += marks[examType]!;
          subjectMax += _getExamWeight(examType);
        }
        // For TOTAL view, max is always 100 per subject
        subjectMax = 100;
      } else {
        // Exam-specific view
        subjectObtained = marks[_selectedExam] ?? 0;
        subjectMax = _getExamWeight(_selectedExam);
      }
      
      subjectTotals[subjectName] = {
        'obtained': subjectObtained,
        'max': subjectMax,
      };
      
      totalObtained += subjectObtained;
      totalMax += subjectMax;
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
    final subjectTotals = totals['subjectTotals'] as Map<String, Map<String, num>>;
    final totalObtained = totals['totalObtained'] as num;
    final totalMax = totals['totalMax'] as num;
    final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : null;
    final isPassed = percentage == null
        ? null
        : _isPassedFromExistingStatus() ?? percentage >= 50;
    final percentageBg = isPassed == false
        ? kSoftRed
        : kPrimaryGreenOpacity;
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
          : const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kSoftBlue, kSoftGreen],
                stops: [0.0, 1.0],
              ),
            ),
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
                                  BoxShadow(color: kPrimaryBlue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
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
                                  child: const Icon(Icons.assessment_rounded, color: kPrimaryBlue, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedExam == 'Total' ? 'Grand Total' : '$_selectedExam Total',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryBlue,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                                    color: kSoftBlue,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            totalObtained.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 42,
                                              fontWeight: FontWeight.w800,
                                              color: kPrimaryBlue,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            '/ ${totalMax.toStringAsFixed(0)}',
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
                                          color: percentageBg,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              percentage == null ? '-' : '${percentage.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800,
                                                color: percentageColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(width: 2, height: 80, color: Colors.white),
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
                                          color: isPassed == false ? kSoftRed : kPrimaryGreenOpacity,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              statusText,
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
                            BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: ['Total', 'M1', 'M2', 'Midterm', 'Final'].map((exam) {
                            final isSelected = _selectedExam == exam;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedExam = exam),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? kPrimaryBlue : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    exam,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : kTextSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Table Section
                  if (subjectTotals.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment_rounded, size: 56, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text('No marks available', style: TextStyle(fontSize: 16, color: kTextSecondary)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isWeb ? 32 : 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6)),
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
                                final percentage = max > 0 ? (obtained / max) * 100 : 0;
                                
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
                                          obtained.toStringAsFixed(1),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: percentage >= 50 ? kPrimaryGreen : kErrorColor,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          max.toStringAsFixed(0),
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

    return Scaffold(
      backgroundColor: kSoftBlue,
      body: body,
    );
  }
}
