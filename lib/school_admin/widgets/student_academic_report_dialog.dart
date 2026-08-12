import 'package:flutter/material.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/exams_service.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/utils/student_pdf_handler.dart';
import 'package:kobac/utils/pdf_save_feedback.dart';
import 'package:kobac/school_admin/widgets/mobile_pdf_actions.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF023471);
const _green = Color(0xFF5AB04B);

Future<void> showStudentAcademicReportDialog(
  BuildContext context, {
  required StudentModel student,
  int? initialAcademicYearId,
}) async {
  if (MediaQuery.sizeOf(context).width < 700) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AcademicReportForm(
        student: student,
        initialYearId: initialAcademicYearId,
      ),
    );
  } else {
    final yearsProvider = context.read<AcademicYearsProvider>();
    await showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider<AcademicYearsProvider>.value(
        value: yearsProvider,
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _AcademicReportForm(
              student: student,
              initialYearId: initialAcademicYearId,
              isPwaDialog: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _AcademicReportForm extends StatefulWidget {
  final StudentModel student;
  final int? initialYearId;
  final bool isPwaDialog;
  const _AcademicReportForm({
    required this.student,
    this.initialYearId,
    this.isPwaDialog = false,
  });
  @override
  State<_AcademicReportForm> createState() => _AcademicReportFormState();
}

class _AcademicReportFormState extends State<_AcademicReportForm> {
  int? _yearId;
  int? _examId;
  String _examScope = 'single';
  List<ExamModel> _exams = const [];
  bool _includeAttendance = true;
  bool _loadingExams = false;
  bool _generating = false;
  String? _examError;
  int _examLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _yearId = widget.initialYearId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final years = context.read<AcademicYearsProvider>();
    await years.ensureLoaded();
    if (!mounted) return;
    setState(() => _yearId ??= years.activeYear?.id);
    if (_examScope == 'single') await _loadExams();
  }

  Future<void> _changeYear(int? value) async {
    if (value == null || value == _yearId || _generating) return;
    setState(() {
      _yearId = value;
      _examId = null;
      _exams = const [];
      _examError = null;
    });
    if (_examScope == 'single') await _loadExams();
  }

  Future<void> _changeScope(String scope) async {
    if (_generating || scope == _examScope) return;
    setState(() {
      _examScope = scope;
      _examId = null;
      _examError = null;
      _loadingExams = false;
      _examLoadGeneration++;
      if (scope == 'all') _exams = const [];
    });
    if (scope == 'single' && _yearId != null) await _loadExams();
  }

  Future<void> _loadExams() async {
    final yearId = _yearId;
    if (yearId == null || _examScope != 'single') return;
    final generation = ++_examLoadGeneration;
    setState(() {
      _loadingExams = true;
      _examError = null;
      _examId = null;
    });
    final result = await ExamsService().listExams(academicYearId: yearId);
    if (!mounted ||
        yearId != _yearId ||
        _examScope != 'single' ||
        generation != _examLoadGeneration)
      return;
    if (result is ExamError) {
      setState(() {
        _loadingExams = false;
        _examError = result.message;
        _exams = const [];
      });
      return;
    }
    final values = (result as ExamSuccess<List<ExamModel>>).data
        .where(
          (exam) =>
              exam.academicYearId == null || exam.academicYearId == yearId,
        )
        .toList();
    setState(() {
      _loadingExams = false;
      _exams = values;
    });
  }

  String _safe(String value) =>
      value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');

  Future<void> _generate(bool download) async {
    if (_generating ||
        _yearId == null ||
        (_examScope == 'single' && _examId == null))
      return;
    final year = context
        .read<AcademicYearsProvider>()
        .years
        .where((y) => y.id == _yearId)
        .firstOrNull;
    final exam = _examScope == 'single'
        ? _exams.where((e) => e.id == _examId).firstOrNull
        : null;
    if (year == null || (_examScope == 'single' && exam == null)) return;
    setState(() => _generating = true);
    final result = await StudentsService().getStudentAcademicReportPdf(
      studentId: widget.student.id,
      academicYearId: year.id,
      examScope: _examScope,
      examId: exam?.id,
      includeAttendance: _includeAttendance,
      download: download,
    );
    if (!mounted) return;
    if (result is StudentError) {
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
      return;
    }
    final document = (result as StudentSuccess<StudentPdfDocument>).data;
    final emis = _safe(
      widget.student.emisNumber.isEmpty ? 'student' : widget.student.emisNumber,
    );
    final filename =
        document.filename ??
        (_examScope == 'single'
            ? 'report-card-$emis-${_safe(year.name)}-${_safe(exam!.name)}.pdf'
            : 'academic-report-$emis-${_safe(year.name)}-all-exams.pdf');
    try {
      if (download) {
        await savePdfWithFeedback(
          context,
          bytes: document.bytes,
          filename: filename,
        );
      } else {
        final opened = await previewStudentPdf(document.bytes, filename);
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The browser blocked the report preview. Allow pop-ups and try again.',
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The academic report could not be opened. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
    }
    if (mounted) setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    final yearsProvider = context.watch<AcademicYearsProvider>();
    final years = yearsProvider.years;
    final validYear = years.any((year) => year.id == _yearId);
    final canGenerate =
        !_generating &&
        validYear &&
        (_examScope == 'all' || (!_loadingExams && _examId != null));
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE8F0FA),
                  child: Icon(Icons.assessment_rounded, color: _blue),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Print Academic Report',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _blue,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Generate the student's marks, performance, position, and attendance report for the selected exam.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _generating ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _green.withValues(alpha: .14),
                    child: Text(
                      widget.student.studentName.isEmpty
                          ? '?'
                          : widget.student.studentName[0].toUpperCase(),
                      style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.studentName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'EMIS: ${widget.student.emisNumber.isEmpty ? '-' : widget.student.emisNumber}  |  ${widget.student.classDisplayName}',
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.isPwaDialog && yearsProvider.loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('Loading academic years...'),
                  ],
                ),
              ),
            if (widget.isPwaDialog &&
                !yearsProvider.loading &&
                yearsProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Failed to load academic years.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: yearsProvider.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            if (widget.isPwaDialog &&
                !yearsProvider.loading &&
                yearsProvider.error == null &&
                years.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'No academic years available.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            DropdownButtonFormField<int>(
              key: ValueKey('academic-report-year-$_yearId-${years.length}'),
              value: validYear ? _yearId : null,
              decoration: const InputDecoration(
                labelText: 'Academic Year *',
                prefixIcon: Icon(Icons.calendar_month_rounded),
                border: OutlineInputBorder(),
              ),
              items: years
                  .map(
                    (year) => DropdownMenuItem(
                      value: year.id,
                      child: Text(year.name),
                    ),
                  )
                  .toList(),
              onChanged:
                  _generating || (widget.isPwaDialog && yearsProvider.loading)
                  ? null
                  : _changeYear,
            ),
            const SizedBox(height: 14),
            const Text(
              'Report Scope *',
              style: TextStyle(fontWeight: FontWeight.w700, color: _blue),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ScopeOption(
                    label: 'One Exam',
                    value: 'single',
                    selectedValue: _examScope,
                    enabled: !_generating,
                    onSelected: _changeScope,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScopeOption(
                    label: 'All Exams',
                    value: 'all',
                    selectedValue: _examScope,
                    enabled: !_generating,
                    onSelected: _changeScope,
                  ),
                ),
              ],
            ),
            if (_examScope == 'single') ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                key: ValueKey(
                  'academic-report-exam-$_yearId-$_examId-${_exams.length}',
                ),
                value: _exams.any((exam) => exam.id == _examId)
                    ? _examId
                    : null,
                decoration: InputDecoration(
                  labelText: 'Exam *',
                  prefixIcon: _loadingExams
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.quiz_rounded),
                  border: const OutlineInputBorder(),
                ),
                items: _exams
                    .map(
                      (exam) => DropdownMenuItem(
                        value: exam.id,
                        child: Text(
                          [
                            exam.name,
                            exam.examType,
                          ].where((v) => v != null && v.isNotEmpty).join(' - '),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged:
                    _loadingExams ||
                        _generating ||
                        (widget.isPwaDialog && (!validYear || _exams.isEmpty))
                    ? null
                    : (value) => setState(() {
                        _examId = value;
                        _examError = null;
                      }),
              ),
              if (_examError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _examError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadingExams ? null : _loadExams,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              if ((!widget.isPwaDialog || validYear) &&
                  !_loadingExams &&
                  _examError == null &&
                  _exams.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'No exams found for this academic year.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: _green,
              title: const Text(
                'Include Attendance',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: _includeAttendance,
              onChanged: _generating
                  ? null
                  : (value) => setState(() => _includeAttendance = value),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDCE3EC)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This report includes',
                    style: TextStyle(fontWeight: FontWeight.w700, color: _blue),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _examScope == 'single'
                        ? "This report includes the selected exam's subject marks, totals, percentage, grade, result, position, and attendance."
                        : 'This report includes student and guardian details, all released exams combined by subject, a Grand Overall Summary, and a detailed attendance summary.',
                  ),
                ],
              ),
            ),
            if (_generating) ...[
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _green,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Generating academic report...'),
                ],
              ),
            ],
            const SizedBox(height: 18),
            if (!widget.isPwaDialog)
              MobilePdfActions(
                enabled: canGenerate,
                busy: _generating,
                previewLabel: 'Preview Report',
                saveLabel: 'Save Report',
                onPreview: () => _generate(false),
                onSave: () => _generate(true),
                onCancel: () => Navigator.pop(context),
              )
            else
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  TextButton(
                    onPressed: _generating
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  OutlinedButton.icon(
                    onPressed: canGenerate ? () => _generate(false) : null,
                    icon: const Icon(Icons.preview_rounded),
                    label: const Text('Preview Report'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: canGenerate ? () => _generate(true) : null,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download Report'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final bool enabled;
  final ValueChanged<String> onSelected;

  const _ScopeOption({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: enabled ? () => onSelected(value) : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F0FA) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _blue : const Color(0xFFDCE3EC),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x18023471),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? _blue : const Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? _blue : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
