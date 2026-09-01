import 'package:flutter/material.dart';
import 'package:kobac/services/class_subjects_service.dart';
import 'package:kobac/school_admin/widgets/exam_subject_controls.dart';

const _blue = Color(0xFF023471);
const _green = Color(0xFF5AB04B);
const _subtleText = Color(0xFF64748B);

/// Opens the centered "Update Subject Type" dialog for one already-assigned
/// class subject. Updates `is_exam_subject` in place via the existing
/// backend update endpoint — never deletes/recreates the class-subject
/// relationship. Returns the updated exam-subject flag on success, or null
/// if cancelled/unchanged.
Future<bool?> showEditSubjectTypeDialog(
  BuildContext context, {
  required int classId,
  required int subjectId,
  required String subjectName,
  required String className,
  required bool currentIsExamSubject,
}) async {
  final width = MediaQuery.sizeOf(context).width;
  final maxWidth = width < 700 ? width - 32 : 520.0;
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black38,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _EditSubjectTypeForm(
          classId: classId,
          subjectId: subjectId,
          subjectName: subjectName,
          className: className,
          currentIsExamSubject: currentIsExamSubject,
        ),
      ),
    ),
  );
}

class _EditSubjectTypeForm extends StatefulWidget {
  final int classId;
  final int subjectId;
  final String subjectName;
  final String className;
  final bool currentIsExamSubject;

  const _EditSubjectTypeForm({
    required this.classId,
    required this.subjectId,
    required this.subjectName,
    required this.className,
    required this.currentIsExamSubject,
  });

  @override
  State<_EditSubjectTypeForm> createState() => _EditSubjectTypeFormState();
}

class _EditSubjectTypeFormState extends State<_EditSubjectTypeForm> {
  late bool _isExamSubject;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isExamSubject = widget.currentIsExamSubject;
    print(
      'UPDATE SUBJECT TYPE DIALOG OPENED\n'
      '  DIALOG CLASS ID: ${widget.classId}\n'
      '  DIALOG SUBJECT ID: ${widget.subjectId}\n'
      '  subjectName: ${widget.subjectName}\n'
      '  className: ${widget.className}\n'
      '  currentIsExamSubject: ${widget.currentIsExamSubject}',
    );
  }

  bool get _changingToNonExam =>
      widget.currentIsExamSubject && !_isExamSubject;

  Future<void> _save() async {
    if (_saving) return;
    if (_isExamSubject == widget.currentIsExamSubject) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    final result = await ClassSubjectsService().updateExamSubjectStatus(
      classId: widget.classId,
      subjectId: widget.subjectId,
      isExamSubject: _isExamSubject,
    );
    if (!mounted) return;
    if (result is ClassSubjectSuccess<ClassSubjectModel>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isExamSubject
                ? '${widget.subjectName} is now an Exam Subject.'
                : '${widget.subjectName} is now Non-Exam.',
          ),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, _isExamSubject);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as ClassSubjectError).message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          22,
          20,
          22,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.tune_rounded, color: _blue),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Subject Type',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: _blue,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Classify this subject for exams and grading.',
                        style: TextStyle(color: _subtleText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _InfoRow(label: 'Subject', value: widget.subjectName),
            const SizedBox(height: 10),
            _InfoRow(label: 'Class', value: widget.className),
            const SizedBox(height: 18),
            const Text(
              'Subject Type',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _subtleText,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            ExamSubjectToggle(
              isExamSubject: _isExamSubject,
              enabled: !_saving,
              onChanged: (value) => setState(() => _isExamSubject = value),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _changingToNonExam
                    ? const Color(0xFFFFF6E9)
                    : const Color(0xFFF6F8FA),
                border: Border.all(
                  color: _changingToNonExam
                      ? const Color(0xFFF0D9A8)
                      : const Color(0xFFDCE3EC),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _changingToNonExam
                    ? 'This subject will remain assigned to the class, but '
                          'it will no longer be included in examination '
                          'grading.'
                    : examSubjectExplanation(_isExamSubject) +
                          (_isExamSubject
                              ? ' Grand Total and academic reports will '
                                    'include it.'
                              : ''),
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563)),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _green.withOpacity(0.5),
                  ),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 64,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: _subtleText),
        ),
      ),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _blue,
          ),
        ),
      ),
    ],
  );
}
