import 'package:flutter/material.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/utils/student_pdf_handler.dart';
import 'package:kobac/utils/pdf_save_feedback.dart';
import 'package:kobac/school_admin/widgets/mobile_pdf_actions.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF023471);
const _green = Color(0xFF5AB04B);

Future<void> showStudentPrintDialog(
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
      builder: (_) => _StudentPrintForm(
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
          child: SizedBox(
            width: 620,
            child: _StudentPrintForm(
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

class _StudentPrintForm extends StatefulWidget {
  final StudentModel student;
  final int? initialYearId;
  final bool isPwaDialog;
  const _StudentPrintForm({
    required this.student,
    this.initialYearId,
    this.isPwaDialog = false,
  });
  @override
  State<_StudentPrintForm> createState() => _StudentPrintFormState();
}

class _StudentPrintFormState extends State<_StudentPrintForm> {
  int? _yearId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _yearId = widget.initialYearId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AcademicYearsProvider>();
      await provider.ensureLoaded();
      if (mounted) setState(() => _yearId ??= provider.activeYear?.id);
    });
  }

  String _filename(AcademicYear year) {
    String safe(String value) =>
        value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
    final emis = safe(
      widget.student.emisNumber.isEmpty ? 'student' : widget.student.emisNumber,
    );
    return 'student-information-$emis-${safe(year.name)}.pdf';
  }

  Future<void> _generate(bool download) async {
    if (_busy || _yearId == null) return;
    final provider = context.read<AcademicYearsProvider>();
    final matchingYears = provider.years.where((year) => year.id == _yearId);
    if (matchingYears.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a valid academic year.')),
      );
      return;
    }
    setState(() => _busy = true);
    final result = await StudentsService().getStudentPrintPdf(
      studentId: widget.student.id,
      academicYearId: _yearId!,
      download: download,
    );
    if (!mounted) return;
    if (result is StudentError) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
      return;
    }
    final document = (result as StudentSuccess<StudentPdfDocument>).data;
    final year = matchingYears.first;
    final filename = document.filename ?? _filename(year);
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
                'The browser blocked the PDF preview. Allow pop-ups and try again.',
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
              'The student document could not be opened. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicYearsProvider>();
    final years = provider.years;
    final validYear = years.any((year) => year.id == _yearId);
    final canSubmit =
        !_busy && (widget.isPwaDialog ? validYear : _yearId != null);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 22, 24, 22 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE8F0FA),
                  child: Icon(Icons.description_rounded, color: _blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isPwaDialog
                            ? 'Print Student Record'
                            : 'Print Student Information',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _blue,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.isPwaDialog
                            ? 'Generate a professional student information document for the parent or school records.'
                            : 'Choose a year, then preview or save the PDF.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 18),
            if (widget.isPwaDialog && provider.loading)
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
                !provider.loading &&
                provider.error != null)
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
                      onPressed: provider.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            if (widget.isPwaDialog &&
                !provider.loading &&
                provider.error == null &&
                years.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'No academic years available.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            DropdownButtonFormField<int>(
              key: ValueKey(
                'student-information-year-$_yearId-${years.length}',
              ),
              value: validYear ? _yearId : null,
              decoration: const InputDecoration(
                labelText: 'Academic Year *',
                prefixIcon: Icon(Icons.calendar_month_rounded),
                border: OutlineInputBorder(),
              ),
              items: years
                  .map(
                    (y) => DropdownMenuItem(value: y.id, child: Text(y.name)),
                  )
                  .toList(),
              onChanged: _busy || (widget.isPwaDialog && provider.loading)
                  ? null
                  : (value) => setState(() => _yearId = value),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDCE3EC)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The PDF contains',
                    style: TextStyle(fontWeight: FontWeight.w700, color: _blue),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'School branding, student information, selected academic year and class, guardian information, signature areas, and school stamp area.',
                  ),
                ],
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
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
                  Text('Generating student document...'),
                ],
              ),
            ],
            const SizedBox(height: 20),
            if (!widget.isPwaDialog)
              MobilePdfActions(
                enabled: canSubmit,
                busy: _busy,
                previewLabel: 'Preview PDF',
                saveLabel: 'Save PDF',
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
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  OutlinedButton.icon(
                    onPressed: canSubmit ? () => _generate(false) : null,
                    icon: const Icon(Icons.preview_rounded),
                    label: const Text('Preview PDF'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: canSubmit ? () => _generate(true) : null,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download PDF'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
