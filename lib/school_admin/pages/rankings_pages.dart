import 'package:flutter/material.dart';
import 'package:kobac/services/academic_performance_service.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF023471);
const _green = Color(0xFF5AB04B);
const _bg = Color(0xFFF0F3F7);

class ClassRankingsPage extends StatefulWidget {
  final int classId;
  final String className;
  final int academicYearId;

  const ClassRankingsPage({
    super.key,
    required this.classId,
    required this.className,
    required this.academicYearId,
  });

  @override
  State<ClassRankingsPage> createState() => _ClassRankingsPageState();
}

class _ClassRankingsPageState extends State<ClassRankingsPage> {
  late Future<PerformanceResult<ClassRankingResponse>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = AcademicPerformanceService().classRankings(
        classId: widget.classId,
        academicYearId: widget.academicYearId,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(
      backgroundColor: _bg,
      foregroundColor: _blue,
      elevation: 0,
      title: const Text('Class Rankings'),
    ),
    body: FutureBuilder<PerformanceResult<ClassRankingResponse>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _green));
        }
        final result = snapshot.data!;
        if (result is PerformanceError) {
          return _RankingState(message: result.message, retry: _load);
        }
        final data =
            (result as PerformanceSuccess<ClassRankingResponse>).data;
        if (data.students.isEmpty) {
          return _RankingState(
            message: 'No released rankings available for this class.',
            retry: _load,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Summary(
                title: data.className.isEmpty
                    ? widget.className
                    : data.className,
                subtitle: data.yearName,
                values: [
                  '${data.total} students',
                  '${data.passed} passed',
                  '${data.failed} failed',
                ],
              ),
              const SizedBox(height: 16),
              ...data.students.map((student) => _RankCard(student: student)),
            ],
          ),
        );
      },
    ),
  );
}

class TopStudentsPage extends StatefulWidget {
  const TopStudentsPage({super.key});

  @override
  State<TopStudentsPage> createState() => _TopStudentsPageState();
}

class _TopStudentsPageState extends State<TopStudentsPage> {
  int? _yearId;
  Future<PerformanceResult<TopStudentsResponse>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final provider = context.read<AcademicYearsProvider>();
    await provider.ensureLoaded();
    if (!mounted) return;
    _yearId = provider.activeYear?.id;
    _load();
  }

  void _load() {
    setState(() {
      _future = AcademicPerformanceService().topStudents(
        academicYearId: _yearId,
        limit: 10,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final years = context.watch<AcademicYearsProvider>().years;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _blue,
        elevation: 0,
        title: const Text('Top Students'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: DropdownButtonFormField<int>(
              initialValue: _yearId,
              decoration: const InputDecoration(
                labelText: 'Academic Year',
                prefixIcon: Icon(Icons.calendar_month_rounded),
              ),
              items: years
                  .map(
                    (year) => DropdownMenuItem(
                      value: year.id,
                      child: Text(year.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null || value == _yearId) return;
                _yearId = value;
                _load();
              },
            ),
          ),
          Expanded(
            child: _future == null
                ? const Center(child: CircularProgressIndicator(color: _green))
                : FutureBuilder<PerformanceResult<TopStudentsResponse>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: _green),
                        );
                      }
                      final result = snapshot.data!;
                      if (result is PerformanceError) {
                        return _RankingState(
                          message: result.message,
                          retry: _load,
                        );
                      }
                      final data =
                          (result
                                  as PerformanceSuccess<TopStudentsResponse>)
                              .data;
                      if (data.students.isEmpty) {
                        return _RankingState(
                          message: 'No released school rankings available.',
                          retry: _load,
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async => _load(),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          children: [
                            _Summary(
                              title: 'School ranking',
                              subtitle: data.yearName,
                              values: ['${data.students.length} ranked'],
                            ),
                            const SizedBox(height: 16),
                            ...data.students.map(
                              (student) => _RankCard(student: student),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> values;
  const _Summary({
    required this.title,
    required this.subtitle,
    required this.values,
  });

  @override
  Widget build(BuildContext context) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _blue,
          ),
        ),
        if (subtitle.isNotEmpty) Text(subtitle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: values
              .map(
                (value) => Chip(
                  label: Text(value),
                  backgroundColor: _blue.withOpacity(0.08),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _RankCard extends StatelessWidget {
  final RankedStudent student;
  const _RankCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final pass = student.status.toLowerCase() == 'pass';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        Row(
          children: [
            CircleAvatar(
              backgroundColor: student.position <= 3
                  ? _green
                  : _blue.withOpacity(0.1),
              foregroundColor: student.position <= 3 ? Colors.white : _blue,
              child: Text('#${student.position}'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _blue,
                    ),
                  ),
                  Text(
                    [
                      if (student.emis.isNotEmpty) 'EMIS ${student.emis}',
                      if (student.className.isNotEmpty) student.className,
                    ].join(' • '),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${student.percentage}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _blue,
                  ),
                ),
                Text(
                  student.grade,
                  style: TextStyle(
                    color: pass ? _green : Colors.red,
                    fontWeight: FontWeight.w700,
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

Widget _card(Widget child) => Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: _blue.withOpacity(0.07),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  ),
  child: child,
);

class _RankingState extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _RankingState({required this.message, required this.retry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 54, color: Colors.amber),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
