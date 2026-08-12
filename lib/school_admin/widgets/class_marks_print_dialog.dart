import 'package:flutter/material.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/exams_service.dart';
import 'package:kobac/services/pdf_file_result.dart';
import 'package:kobac/utils/student_pdf_handler.dart';
import 'package:kobac/utils/pdf_save_feedback.dart';
import 'package:kobac/school_admin/widgets/mobile_pdf_actions.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF023471);
const _green = Color(0xFF5AB04B);
const _orders = <String, String>{
  'alphabetical_asc': 'Alphabetical A-Z',
  'alphabetical_desc': 'Alphabetical Z-A',
  'marks_high_to_low': 'Highest Marks First',
  'marks_low_to_high': 'Lowest Marks First',
  'position_asc': 'Position',
  'emis_asc': 'EMIS Number',
};

Future<void> showClassMarksPrintDialog(
  BuildContext context, {
  required int classId,
  required String className,
  required int studentCount,
  int? initialAcademicYearId,
  int? initialExamId,
}) async {
  Widget form(bool pwa) => _ClassMarksPrintForm(
    classId: classId,
    className: className,
    studentCount: studentCount,
    initialYearId: initialAcademicYearId,
    initialExamId: initialExamId,
    isPwaDialog: pwa,
  );
  if (MediaQuery.sizeOf(context).width < 700) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => form(false),
    );
  } else {
    final provider = context.read<AcademicYearsProvider>();
    await showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider<AcademicYearsProvider>.value(
        value: provider,
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: form(true),
          ),
        ),
      ),
    );
  }
}

class _ClassMarksPrintForm extends StatefulWidget {
  final int classId;
  final String className;
  final int studentCount;
  final int? initialYearId;
  final int? initialExamId;
  final bool isPwaDialog;

  const _ClassMarksPrintForm({
    required this.classId,
    required this.className,
    required this.studentCount,
    this.initialYearId,
    this.initialExamId,
    this.isPwaDialog = false,
  });

  @override
  State<_ClassMarksPrintForm> createState() => _ClassMarksPrintFormState();
}

class _ClassMarksPrintFormState extends State<_ClassMarksPrintForm> {
  int? _yearId;
  String _examScope = 'single';
  int? _examId;
  String _orderBy = 'alphabetical_asc';
  List<ExamModel> _exams = const [];
  bool _loadingExams = false;
  bool _generating = false;
  String? _examError;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _yearId = widget.initialYearId;
    _examId = widget.initialExamId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final provider = context.read<AcademicYearsProvider>();
    await provider.ensureLoaded();
    if (!mounted) return;
    setState(() => _yearId ??= provider.activeYear?.id);
    await _loadExams(preserveInitialExam: true);
  }

  Future<void> _changeYear(int? value) async {
    if (value == null || value == _yearId || _generating) return;
    setState(() {
      _yearId = value;
      _examId = null;
      _examError = null;
      _exams = const [];
      _loadGeneration++;
    });
    if (_examScope == 'single') await _loadExams();
  }

  Future<void> _changeScope(String scope) async {
    if (scope == _examScope || _generating) return;
    setState(() {
      _examScope = scope;
      _examId = null;
      _examError = null;
      _exams = const [];
      _loadingExams = false;
      _loadGeneration++;
    });
    if (scope == 'single') await _loadExams();
  }

  Future<void> _loadExams({bool preserveInitialExam = false}) async {
    final yearId = _yearId;
    if (yearId == null || _examScope != 'single') return;
    final generation = ++_loadGeneration;
    setState(() {
      _loadingExams = true;
      _examError = null;
      if (!preserveInitialExam) _examId = null;
    });
    final result = await ExamsService().listExams(academicYearId: yearId);
    if (!mounted ||
        generation != _loadGeneration ||
        yearId != _yearId ||
        _examScope != 'single') {
      return;
    }
    if (result is ExamError) {
      setState(() {
        _loadingExams = false;
        _examError = result.message;
        _exams = const [];
        _examId = null;
      });
      return;
    }
    final exams = (result as ExamSuccess<List<ExamModel>>).data
        .where(
          (exam) =>
              exam.academicYearId == null || exam.academicYearId == yearId,
        )
        .toList();
    setState(() {
      _loadingExams = false;
      _exams = exams;
      if (!exams.any((exam) => exam.id == _examId)) _examId = null;
    });
  }

  String _safe(String value) =>
      value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');

  String get _yearName {
    for (final year in context.read<AcademicYearsProvider>().years) {
      if (year.id == _yearId) return year.name;
    }
    return 'academic-year';
  }

  Future<void> _generate(bool download) async {
    if (_generating ||
        _yearId == null ||
        (_examScope == 'single' && _examId == null)) {
      return;
    }
    setState(() => _generating = true);
    final result = await ClassesService().getClassMarksReportPdf(
      classId: widget.classId,
      academicYearId: _yearId!,
      examScope: _examScope,
      examId: _examScope == 'single' ? _examId : null,
      orderBy: _orderBy,
      download: download,
    );
    if (!mounted) return;
    if (result is ClassError) {
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
      return;
    }
    final document = (result as ClassSuccess<PdfFileResult>).data;
    final filename =
        document.filename ??
        'class-marks-${_safe(widget.className)}-${_safe(_yearName)}.pdf';
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
            const SnackBar(content: Text('Allow pop-ups to preview the PDF.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The PDF could not be generated. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicYearsProvider>();
    final validYear = provider.years.any((year) => year.id == _yearId);
    final canSubmit =
        validYear && !_generating && (_examScope == 'all' || _examId != null);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        'Print Class Marks',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _blue,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Generate a class marks and performance report using released results.',
                        style: TextStyle(color: Color(0xFF64748B)),
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
                  const Icon(Icons.school_rounded, color: _blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.className,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('${widget.studentCount} students'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: validYear ? _yearId : null,
              decoration: const InputDecoration(
                labelText: 'Academic Year *',
                border: OutlineInputBorder(),
              ),
              items: provider.years
                  .map(
                    (year) => DropdownMenuItem(
                      value: year.id,
                      child: Text(year.name),
                    ),
                  )
                  .toList(),
              onChanged: _generating || provider.loading ? null : _changeYear,
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'single', label: Text('One Exam')),
                ButtonSegment(value: 'all', label: Text('All Exams')),
              ],
              selected: {_examScope},
              onSelectionChanged: _generating
                  ? null
                  : (values) => _changeScope(values.first),
            ),
            if (_examScope == 'single') ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _exams.any((exam) => exam.id == _examId)
                    ? _examId
                    : null,
                decoration: InputDecoration(
                  labelText: 'Exam *',
                  border: const OutlineInputBorder(),
                  suffixIcon: _loadingExams
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                items: _exams
                    .map(
                      (exam) => DropdownMenuItem(
                        value: exam.id,
                        child: Text(exam.name),
                      ),
                    )
                    .toList(),
                onChanged: _loadingExams || _generating
                    ? null
                    : (value) => setState(() => _examId = value),
              ),
              if (_examError != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _examError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadExams,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _orderBy,
              decoration: const InputDecoration(
                labelText: 'Student Order',
                border: OutlineInputBorder(),
              ),
              items: _orders.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: _generating
                  ? null
                  : (value) => setState(() => _orderBy = value!),
            ),
            if (_generating)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Row(
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
                    Text('Generating document...'),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            if (!widget.isPwaDialog)
              MobilePdfActions(
                enabled: canSubmit,
                busy: _generating,
                previewLabel: 'Preview Marks Report',
                saveLabel: 'Save Marks Report',
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
                    onPressed: canSubmit ? () => _generate(false) : null,
                    icon: const Icon(Icons.preview_rounded),
                    label: const Text('Preview Marks Report'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: canSubmit ? () => _generate(true) : null,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download Marks Report'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
