import 'package:flutter/material.dart';

const Color _examGreen = Color(0xFF5AB04B);
const Color _nonExamAmber = Color(0xFFB07A1E);
const Color _navy = Color(0xFF023471);

/// Restrained status badge distinguishing an exam subject from a non-exam
/// (still-taught, still-timetabled) subject. Never shows raw booleans.
class ExamSubjectBadge extends StatelessWidget {
  final bool isExamSubject;
  final bool compact;

  const ExamSubjectBadge({
    super.key,
    required this.isExamSubject,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExamSubject ? _examGreen : _nonExamAmber;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        isExamSubject ? 'Exam Subject' : 'Non-Exam',
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Compact two-way segmented control for picking Exam Subject vs Non-Exam
/// Subject. Used both inline (assignment rows) and inside the Update
/// Subject Type dialog.
class ExamSubjectToggle extends StatelessWidget {
  final bool isExamSubject;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const ExamSubjectToggle({
    super.key,
    required this.isExamSubject,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E7ED)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'Exam Subject',
            selected: isExamSubject,
            color: _examGreen,
            enabled: enabled,
            onTap: () => onChanged(true),
          ),
          _Segment(
            label: 'Non-Exam',
            selected: !isExamSubject,
            color: _nonExamAmber,
            enabled: enabled,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? (enabled ? color : Colors.grey)
                : (enabled ? _navy.withOpacity(0.45) : Colors.grey.shade400),
          ),
        ),
      ),
    ),
  );
}

/// Explanatory helper text shown beneath the exam-subject toggle, matching
/// the exact copy the product spec requires.
String examSubjectExplanation(bool isExamSubject) => isExamSubject
    ? 'Included in examinations and grading.'
    : 'Taught by the class but excluded from examination grading.';
