import 'package:flutter/material.dart';
import 'package:kobac/services/academic_performance_service.dart';
import 'package:kobac/student/widgets/student_web_ui.dart';

class AcademicPerformancePage extends StatefulWidget {
  const AcademicPerformancePage({super.key});

  @override
  State<AcademicPerformancePage> createState() =>
      _AcademicPerformancePageState();
}

class _AcademicPerformancePageState extends State<AcademicPerformancePage> {
  late Future<PerformanceResult<StudentAcademicPerformance>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = AcademicPerformanceService().performance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studentWebBg,
      appBar: AppBar(
        backgroundColor: studentWebBg,
        foregroundColor: studentWebBlue,
        elevation: 0,
        title: const Text('My Academic Performance'),
      ),
      body: FutureBuilder<PerformanceResult<StudentAcademicPerformance>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!;
          if (result is PerformanceError) {
            return _PerformanceState(
              message: result.message,
              onRetry: _load,
            );
          }
          final data =
              (result as PerformanceSuccess<StudentAcademicPerformance>).data;
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _PerformanceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.studentName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: studentWebBlue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('${data.yearName} • ${data.className}'),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 20,
                        runSpacing: 12,
                        children: [
                          _metric('Percentage', '${data.percentage}%'),
                          _metric('Grade', data.grade),
                          _metric(
                            'Result',
                            data.status.isEmpty ? 'Unavailable' : data.status,
                          ),
                          _metric(
                            'Marks',
                            '${data.totalMarks}/${data.maximumMarks}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PerformanceCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: studentWebGreen,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          data.position == null
                              ? 'Class position unavailable'
                              : 'Position ${data.position} of ${data.totalStudents}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: studentWebBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Subject Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: studentWebBlue,
                  ),
                ),
                const SizedBox(height: 10),
                if (data.subjects.isEmpty)
                  const _PerformanceCard(
                    child: Text('No released subject results available.'),
                  )
                else
                  ...data.subjects.map(
                    (subject) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PerformanceCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: studentWebBlue,
                                    ),
                                  ),
                                  Text(
                                    '${subject.marks}/${subject.maximum}',
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${subject.percentage}% • ${subject.grade}',
                              style: TextStyle(
                                color: subject.status.toLowerCase() == 'fail'
                                    ? Colors.red
                                    : studentWebGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metric(String label, String value) => SizedBox(
    width: 125,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: studentWebBlue,
          ),
        ),
      ],
    ),
  );
}

class _PerformanceCard extends StatelessWidget {
  final Widget child;
  const _PerformanceCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: studentWebBlue.withOpacity(0.07),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _PerformanceState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PerformanceState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insights_rounded, size: 54, color: Colors.amber),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
