import 'package:flutter/material.dart';
import 'package:kobac/services/promotions_service.dart';

class StudentPromotionHistoryPage extends StatefulWidget {
  final int studentId;
  final String studentName;
  const StudentPromotionHistoryPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });
  @override
  State<StudentPromotionHistoryPage> createState() =>
      _StudentPromotionHistoryPageState();
}

class _StudentPromotionHistoryPageState
    extends State<StudentPromotionHistoryPage> {
  late Future<PromotionResult<List<PromotionHistoryItem>>> _future;
  @override
  void initState() {
    super.initState();
    _future = PromotionsService().studentHistory(widget.studentId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF0F3F7),
    appBar: AppBar(
      title: Text('${widget.studentName} — Academic History'),
      backgroundColor: Colors.white,
    ),
    body: FutureBuilder<PromotionResult<List<PromotionHistoryItem>>>(
      future: _future,
      builder: (_, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final result = snapshot.data!;
        if (result is PromotionError)
          return Center(child: Text(result.message));
        final items =
            (result as PromotionSuccess<List<PromotionHistoryItem>>).data;
        if (items.isEmpty)
          return const Center(child: Text('No academic history found'));
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final item = items[i];
            return Card(
              child: ListTile(
                leading: const Icon(
                  Icons.history_edu_rounded,
                  color: Color(0xFF023471),
                ),
                title: Text(item.decision.toUpperCase()),
                subtitle: Text(
                  '${item.fromYear} • ${item.fromClass}\n'
                  '${item.toYear} • ${item.toClass}\n${item.date}\nNotes: ${item.notes}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    ),
  );
}
