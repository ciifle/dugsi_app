import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:kobac/school_admin/pages/student_promotion_history_page.dart';
import 'package:kobac/services/promotions_service.dart';
import 'package:kobac/widgets/form_3d/form_theme_3d.dart';

class PromotionHistoryGroup {
  final String key;
  final List<PromotionHistoryItem> records;

  const PromotionHistoryGroup({required this.key, required this.records});

  PromotionHistoryItem get first => records.first;
  int get studentCount => records.length;
}

List<PromotionHistoryGroup> groupPromotionHistory(
  List<PromotionHistoryItem> records,
) {
  final groups = <String, List<PromotionHistoryItem>>{};
  for (final record in records) {
    final key = record.batchId?.isNotEmpty == true
        ? 'batch:${record.batchId}'
        : [
            record.fromAcademicYearId ?? record.fromYear,
            record.toAcademicYearId ?? record.toYear,
            record.fromClassId ?? record.fromClass,
            record.toClassId ?? record.toClass,
            record.decision,
            record.date,
          ].join('|');
    groups.putIfAbsent(key, () => []).add(record);
  }
  final result = groups.entries
      .map(
        (entry) => PromotionHistoryGroup(
          key: entry.key,
          records: List.unmodifiable(entry.value),
        ),
      )
      .toList();
  result.sort((a, b) => _date(b.first.date).compareTo(_date(a.first.date)));
  return result;
}

DateTime _date(String raw) =>
    DateTime.tryParse(raw)?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);

String formatPromotionDate(String raw, {bool includeTime = false}) {
  final parsed = DateTime.tryParse(raw)?.toLocal();
  if (parsed == null) return '—';
  return DateFormat(
    includeTime ? 'dd MMM yyyy, h:mm a' : 'dd MMM yyyy',
  ).format(parsed);
}

class PromotionBatchDetailsPage extends StatelessWidget {
  final PromotionHistoryGroup group;

  const PromotionBatchDetailsPage({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final item = group.first;
    return Scaffold(
      backgroundColor: FormTheme3D.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: FormTheme3D.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Promotion Batch Details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: FormTheme3D.primaryBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  _Surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DecisionBadge(decision: item.decision),
                        const SizedBox(height: 18),
                        _RouteRow(
                          from: item.fromClass,
                          to: item.toClass,
                          icon: Icons.school_rounded,
                        ),
                        const SizedBox(height: 12),
                        _RouteRow(
                          from: item.fromYear,
                          to: item.toYear,
                          icon: Icons.calendar_month_rounded,
                        ),
                        const Divider(height: 28),
                        _InfoRow(
                          icon: Icons.people_alt_outlined,
                          label: 'Students',
                          value: '${group.studentCount}',
                        ),
                        _InfoRow(
                          icon: Icons.schedule_rounded,
                          label: 'Processed',
                          value: formatPromotionDate(
                            item.date,
                            includeTime: true,
                          ),
                        ),
                        if (item.notes != '—' && item.notes.trim().isNotEmpty)
                          _InfoRow(
                            icon: Icons.notes_rounded,
                            label: 'Notes',
                            value: item.notes,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Students',
                    style: TextStyle(
                      color: FormTheme3D.primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...group.records.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StudentCard(record: record),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final PromotionHistoryItem record;
  const _StudentCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final student = record.student;
    return _Surface(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(FormTheme3D.radiusCard),
        onTap: student.id <= 0
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentPromotionHistoryPage(
                    studentId: student.id,
                    studentName: student.name,
                  ),
                ),
              ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: FormTheme3D.primaryBlue.withValues(alpha: 0.1),
              foregroundColor: FormTheme3D.primaryBlue,
              child: Text(
                student.name.trim().isEmpty
                    ? '?'
                    : student.name.trim()[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
                      color: FormTheme3D.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${student.emis} • ${record.fromClass} → ${record.toClass}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: FormTheme3D.textHint),
                  ),
                ],
              ),
            ),
            if (student.id > 0)
              const Icon(
                Icons.chevron_right_rounded,
                color: FormTheme3D.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: FormTheme3D.cardBg,
      borderRadius: BorderRadius.circular(FormTheme3D.radiusCard),
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: FormTheme3D.cardShadow,
    ),
    child: child,
  );
}

class _RouteRow extends StatelessWidget {
  final String from;
  final String to;
  final IconData icon;
  const _RouteRow({required this.from, required this.to, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: FormTheme3D.primaryBlue, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          from,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Icon(
          Icons.arrow_forward_rounded,
          color: FormTheme3D.primaryBlue,
        ),
      ),
      Expanded(
        child: Text(
          to,
          maxLines: 2,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: FormTheme3D.primaryBlue, size: 18),
        const SizedBox(width: 9),
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: const TextStyle(color: FormTheme3D.textHint),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _DecisionBadge extends StatelessWidget {
  final String decision;
  const _DecisionBadge({required this.decision});

  @override
  Widget build(BuildContext context) {
    final color = promotionDecisionColor(decision);
    return Chip(
      avatar: Icon(promotionDecisionIcon(decision), color: color, size: 18),
      label: Text(_title(decision)),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      side: BorderSide.none,
    );
  }
}

Color promotionDecisionColor(String decision) => switch (decision) {
  'promoted' => FormTheme3D.primaryGreen,
  'repeated' => Colors.orange,
  'graduated' => FormTheme3D.primaryBlue,
  'transferred' => Colors.blue,
  'left' => FormTheme3D.errorRed,
  _ => Colors.blueGrey,
};

IconData promotionDecisionIcon(String decision) => switch (decision) {
  'promoted' => Icons.trending_up_rounded,
  'repeated' => Icons.replay_rounded,
  'graduated' => Icons.school_rounded,
  'transferred' => Icons.swap_horiz_rounded,
  'left' => Icons.logout_rounded,
  _ => Icons.history_rounded,
};

String _title(String value) => value.isEmpty
    ? 'Unknown'
    : '${value[0].toUpperCase()}${value.substring(1)}';
