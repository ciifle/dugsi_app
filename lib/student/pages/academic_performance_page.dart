import 'package:flutter/material.dart';
import 'package:kobac/services/academic_performance_service.dart';
import 'package:kobac/student/widgets/student_web_ui.dart';
import 'package:kobac/student/widgets/student_learning_ui.dart';

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
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 16,
                20,
                24,
              ),
              children: [
                StudentPageHeader(
                  title: 'Academic Performance',
                  subtitle: 'Your released academic progress',
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                _PerformanceSummaryCard(data: data),
                if (false)
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
                _PositionCard(data: data),
                if (false)
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
                            Container(
                              width: 42,
                              height: 42,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: studentWebBlue,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 21,
                              ),
                            ),
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
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: (subject.percentage / 100)
                                          .clamp(0.0, 1.0),
                                      minHeight: 7,
                                      backgroundColor: studentWebBorder,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        subject.status.toLowerCase() ==
                                                'fail'
                                            ? Colors.red
                                            : studentWebGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: subject.status
                                                    .toLowerCase() ==
                                                'fail'
                                            ? Colors.red
                                            : studentWebGreen,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        subject.grade,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
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

class _PerformanceSummaryCard extends StatelessWidget {
  final StudentAcademicPerformance data;

  const _PerformanceSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final failed = data.status.toLowerCase() == 'fail';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: studentWebBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22023471),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: studentWebBlue,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: studentWebBlue,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.studentName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${data.yearName} • ${data.className}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        '${data.percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: studentWebBlue,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: failed ? Colors.red : studentWebGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        data.status.isEmpty ? 'Unavailable' : data.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryValue(
                        label: 'Grade',
                        value: data.grade,
                      ),
                    ),
                    Container(width: 1, height: 38, color: studentWebBorder),
                    Expanded(
                      child: _SummaryValue(
                        label: 'Marks',
                        value:
                            '${data.totalMarks}/${data.maximumMarks}',
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
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: studentWebTextSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: studentWebTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}

class _PositionCard extends StatelessWidget {
  final StudentAcademicPerformance data;

  const _PositionCard({required this.data});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: studentWebBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18023471),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: studentWebGreen,
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x285AB04B),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 29,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.position == null
                        ? 'Position unavailable'
                        : 'Position ${data.position}',
                    style: const TextStyle(
                      color: studentWebBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.position == null
                        ? 'Ranking will appear after results are released'
                        : 'Out of ${data.totalStudents} students in class',
                    style: const TextStyle(
                      color: studentWebTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
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
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: studentWebBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18023471),
          blurRadius: 20,
          offset: Offset(0, 8),
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
