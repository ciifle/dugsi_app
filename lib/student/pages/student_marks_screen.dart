import 'package:flutter/material.dart';
import 'package:kobac/services/student_service.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE0E9F5);
const Color kSoftGreen = Color(0xFFE4F1E2);
const Color kErrorColor = Color(0xFFEF4444);
const Color kTextPrimary = Color(0xFF1A1E1F);
const Color kTextSecondary = Color(0xFF4F5A5E);

class StudentMarksScreen extends StatefulWidget {
  const StudentMarksScreen({Key? key}) : super(key: key);

  @override
  State<StudentMarksScreen> createState() => _StudentMarksScreenState();
}

class _StudentMarksScreenState extends State<StudentMarksScreen> {
  late Future<StudentResult<List<StudentExamModel>>> _examsFuture;
  late Future<StudentResult<List<StudentMarkModel>>> _marksFuture;
  int? _examId;

  @override
  void initState() {
    super.initState();
    _examsFuture = StudentService().listExams();
    _loadMarks();
  }

  void _loadMarks() {
    setState(() {
      _marksFuture = StudentService().listMarks(examId: _examId);
    });
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
                              BoxShadow(color: kPrimaryBlue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
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
              SliverToBoxAdapter(
                child: FutureBuilder<StudentResult<List<StudentExamModel>>>(
                  future: _examsFuture,
                  builder: (context, examSnap) {
                    if (examSnap.data is StudentError && (examSnap.data as StudentError).statusCode == 403) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ModuleDisabledBanner(message: (examSnap.data as StudentError).message),
                      );
                    }
                    final exams = examSnap.data is StudentSuccess<List<StudentExamModel>>
                        ? (examSnap.data as StudentSuccess<List<StudentExamModel>>).data
                        : <StudentExamModel>[];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: _examId,
                                  isExpanded: true,
                                  hint: const Text('All exams'),
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text('All exams')),
                                    ...exams.map((e) => DropdownMenuItem<int?>(value: e.id, child: Text(e.name))),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _examId = v;
                                      _loadMarks();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _examsFuture = StudentService().listExams(forceRefresh: true);
                      _loadMarks();
                    });
                  },
                  color: kPrimaryGreen,
                  child: FutureBuilder<StudentResult<List<StudentMarkModel>>>(
                    future: _marksFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
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
                                Icon(Icons.error_outline, size: 48, color: kErrorColor.withOpacity(0.8)),
                                const SizedBox(height: 12),
                                Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: kTextPrimary, fontSize: 15)),
                              ],
                            ),
                          ),
                        );
                      }
                      final list = (snapshot.data as StudentSuccess<List<StudentMarkModel>>).data;
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.assignment_rounded, size: 56, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text('No marks yet', style: TextStyle(fontSize: 16, color: kTextSecondary)),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final m = list[index];
                          final examName = m.exam['name']?.toString() ?? '—';
                          final subjectName = m.subject['name']?.toString() ?? '—';
                          final teacherName = m.teacher?['fullName']?.toString() ?? m.teacher?['name']?.toString() ?? '—';
                          final className = m.class_?['name']?.toString() ?? '—';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6)),
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
                                      child: const Icon(Icons.grade_rounded, color: kPrimaryBlue, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(subjectName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                                          Text('$examName ${className != '—' ? '· $className' : ''}', style: TextStyle(fontSize: 13, color: kTextSecondary)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${m.marksObtained}/${m.maxMarks}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                                    ),
                                    if (m.percentage != null) ...[
                                      const SizedBox(width: 8),
                                      Text('${m.percentage!.toStringAsFixed(0)}%', style: TextStyle(fontSize: 14, color: kTextSecondary)),
                                    ],
                                  ],
                                ),
                                if (m.grade != null && m.grade!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text('Grade: ${m.grade}', style: TextStyle(fontSize: 13, color: kTextSecondary)),
                                  ),
                                if (teacherName != '—')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Teacher: $teacherName', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
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
          Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 28),
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
