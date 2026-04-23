import 'package:flutter/material.dart';
import 'package:kobac/services/student_service.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE0E9F5);
const Color kSoftGreen = Color(0xFFE4F1E2);
const Color kTextPrimary = Color(0xFF1A1E1F);
const Color kTextSecondary = Color(0xFF4F5A5E);

class StudentResultReportScreen extends StatefulWidget {
  final int examId;

  const StudentResultReportScreen({Key? key, required this.examId}) : super(key: key);

  @override
  State<StudentResultReportScreen> createState() => _StudentResultReportScreenState();
}

class _StudentResultReportScreenState extends State<StudentResultReportScreen> {
  late Future<StudentResult<StudentResultReportModel>> _future;

  @override
  void initState() {
    super.initState();
    print('DEBUG: StudentResultReportScreen calling getResultReport for examId: ${widget.examId}');
    _future = StudentService().getResultReport(widget.examId);
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Result Report',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<StudentResult<StudentResultReportModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
                    }
                    if (snapshot.data is StudentError) {
                      final err = snapshot.data as StudentError;
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                              const SizedBox(height: 12),
                              Text(
                                err.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: kTextPrimary, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final report = (snapshot.data as StudentSuccess<StudentResultReportModel>).data;
                    final results = report.results;
                    final summary = report.summary;
                    final examName = report.exam['name']?.toString() ?? 'Exam';
                    
                    print('DEBUG: Parsed response - examName: $examName');
                    print('DEBUG: Parsed response - summary keys: ${summary?.keys.toList()}');
                    print('DEBUG: Parsed response - summary position: ${summary?['position']}');
                    print('DEBUG: Parsed response - results count: ${results.length}');

                    if (results.isEmpty && (summary == null || (summary['total'] == 0 && summary['total_max'] == 0))) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_rounded, size: 56, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('No marks yet for this exam', style: TextStyle(fontSize: 16, color: kTextSecondary)),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 6))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(examName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                                if (summary != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _summaryChip('Total', '${summary['total'] ?? summary['total_marks_obtained'] ?? 0}/${summary['total_max'] ?? summary['total_max_marks'] ?? 0}'),
                                      _summaryChip('Average', '${summary['average'] ?? summary['overall_percentage'] ?? 0}%'),
                                      _summaryChip('Status', '${summary['status'] ?? '—'}'),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...results.map((r) {
                            final subj = r['subject'] is Map ? r['subject'] as Map : <String, dynamic>{};
                            final name = subj['name']?.toString() ?? '—';
                            final obtained = r['marks_obtained'] ?? r['marksObtained'] ?? 0;
                            final max = r['max_marks'] ?? r['maxMarks'] ?? 100;
                            final pct = r['percentage'];
                            final grade = r['grade']?.toString() ?? '—';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kPrimaryBlue))),
                                  Text('$obtained/$max', style: const TextStyle(fontSize: 14, color: kTextSecondary)),
                                  if (pct != null) ...[const SizedBox(width: 8), Text('${pct}%', style: TextStyle(fontSize: 13, color: kTextSecondary))],
                                  const SizedBox(width: 8),
                                  Text(grade, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryGreen)),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 40),
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

  Widget _summaryChip(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: kTextSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
      ],
    );
  }
}
