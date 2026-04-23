import 'package:flutter/material.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/student/widgets/student_drawer.dart';

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
  const StudentResultsScreen({Key? key}) : super(key: key);

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
                                            // First row: TOTAL and AVERAGE
                                            Row(
                                              children: [
                                                // TOTAL
                                                Expanded(
                                                  child: Container(
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
                                                            Text(
                                                              '${result.summary!['total'] ?? result.summary!['total_marks_obtained'] ?? 0}',
                                                              style: const TextStyle(
                                                                fontSize: 24,
                                                                fontWeight: FontWeight.bold,
                                                                color: kPrimaryBlue,
                                                              ),
                                                            ),
                                                            if (result.summary!['total_max'] != null) ...[
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                '/ ${result.summary!['total_max']}',
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w500,
                                                                  color: kTextSecondaryColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                               
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
                                                          '${result.summary!['average'] ?? result.summary!['percentage'] ?? 0}%',
                                                          style: const TextStyle(
                                                            fontSize: 24,
                                                            fontWeight: FontWeight.bold,
                                                            color: kPrimaryGreen,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            
                                            // STATUS - Single centered card
                                            Center(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                                decoration: BoxDecoration(
                                                  color: (result.summary!['status'] == 'PASS' ? kPrimaryGreen : kErrorColor).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: (result.summary!['status'] == 'PASS' ? kPrimaryGreen : kErrorColor).withOpacity(0.3)),
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
                                                      result.summary!['status'] ?? 'N/A',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: result.summary!['status'] == 'PASS' ? kPrimaryGreen : kErrorColor,
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
