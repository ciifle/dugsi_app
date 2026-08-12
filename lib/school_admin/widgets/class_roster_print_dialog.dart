import 'package:flutter/material.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/pdf_file_result.dart';
import 'package:kobac/utils/student_pdf_handler.dart';
import 'package:kobac/utils/pdf_save_feedback.dart';
import 'package:kobac/school_admin/widgets/mobile_pdf_actions.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF023471);
const _green = Color(0xFF5AB04B);

Future<void> showClassRosterPrintDialog(
  BuildContext context, {
  required int classId,
  required String className,
  required int studentCount,
  int? initialAcademicYearId,
}) async {
  Widget form(bool pwa) => _ClassRosterPrintForm(
    classId: classId,
    className: className,
    studentCount: studentCount,
    initialYearId: initialAcademicYearId,
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
            constraints: const BoxConstraints(maxWidth: 640),
            child: form(true),
          ),
        ),
      ),
    );
  }
}

class _ClassRosterPrintForm extends StatefulWidget {
  final int classId;
  final String className;
  final int studentCount;
  final int? initialYearId;
  final bool isPwaDialog;

  const _ClassRosterPrintForm({
    required this.classId,
    required this.className,
    required this.studentCount,
    this.initialYearId,
    this.isPwaDialog = false,
  });

  @override
  State<_ClassRosterPrintForm> createState() => _ClassRosterPrintFormState();
}

class _ClassRosterPrintFormState extends State<_ClassRosterPrintForm> {
  int? _yearId;
  bool _includeContact = true;
  bool _includeAddress = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _yearId = widget.initialYearId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final provider = context.read<AcademicYearsProvider>();
    await provider.ensureLoaded();
    if (!mounted) return;
    setState(() => _yearId ??= provider.activeYear?.id);
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
    if (_generating || _yearId == null) return;
    setState(() => _generating = true);
    final result = await ClassesService().getClassStudentListPdf(
      classId: widget.classId,
      academicYearId: _yearId!,
      includeContact: _includeContact,
      includeAddress: _includeAddress,
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
        'class-list-${_safe(widget.className)}-${_safe(_yearName)}.pdf';
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
    final canSubmit = validYear && !_generating;
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
            _DialogHeader(
              title: 'Print Class List',
              subtitle:
                  'Generate an alphabetical class student list for school records.',
              busy: _generating,
            ),
            const SizedBox(height: 16),
            _ClassSummary(
              className: widget.className,
              studentCount: widget.studentCount,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: validYear ? _yearId : null,
              decoration: const InputDecoration(
                labelText: 'Academic Year *',
                prefixIcon: Icon(Icons.calendar_month_rounded),
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
              onChanged: _generating || provider.loading
                  ? null
                  : (value) => setState(() => _yearId = value),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: _green,
              title: const Text('Include Phone Number'),
              value: _includeContact,
              onChanged: _generating
                  ? null
                  : (value) => setState(() => _includeContact = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: _green,
              title: const Text('Include Address'),
              value: _includeAddress,
              onChanged: _generating
                  ? null
                  : (value) => setState(() => _includeAddress = value ?? false),
            ),
            const _InfoPanel(
              text:
                  'This document contains the class students in alphabetical A-Z order with name, EMIS, class, enrollment information, and any selected contact details.',
            ),
            if (_generating) const _GeneratingIndicator(),
            const SizedBox(height: 18),
            _DialogActions(
              canSubmit: canSubmit,
              busy: _generating,
              isPwaDialog: widget.isPwaDialog,
              previewLabel: 'Preview Class List',
              downloadLabel: 'Download Class List',
              onPreview: () => _generate(false),
              onDownload: () => _generate(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool busy;

  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CircleAvatar(
        backgroundColor: Color(0xFFE8F0FA),
        child: Icon(Icons.format_list_numbered_rounded, color: _blue),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _blue,
              ),
            ),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Close',
        onPressed: busy ? null : () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
    ],
  );
}

class _ClassSummary extends StatelessWidget {
  final String className;
  final int studentCount;

  const _ClassSummary({required this.className, required this.studentCount});

  @override
  Widget build(BuildContext context) => Container(
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
            className,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text('$studentCount students'),
      ],
    ),
  );
}

class _InfoPanel extends StatelessWidget {
  final String text;
  const _InfoPanel({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F8FA),
      border: Border.all(color: const Color(0xFFDCE3EC)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text),
  );
}

class _GeneratingIndicator extends StatelessWidget {
  const _GeneratingIndicator();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _green),
        ),
        SizedBox(width: 10),
        Text('Generating document...'),
      ],
    ),
  );
}

class _DialogActions extends StatelessWidget {
  final bool canSubmit;
  final bool busy;
  final bool isPwaDialog;
  final String previewLabel;
  final String downloadLabel;
  final VoidCallback onPreview;
  final VoidCallback onDownload;

  const _DialogActions({
    required this.canSubmit,
    required this.busy,
    required this.isPwaDialog,
    required this.previewLabel,
    required this.downloadLabel,
    required this.onPreview,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) => isPwaDialog
      ? Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            OutlinedButton.icon(
              onPressed: canSubmit ? onPreview : null,
              icon: const Icon(Icons.preview_rounded),
              label: Text(previewLabel),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
              onPressed: canSubmit ? onDownload : null,
              icon: const Icon(Icons.download_rounded),
              label: Text(downloadLabel),
            ),
          ],
        )
      : MobilePdfActions(
          enabled: canSubmit,
          busy: busy,
          previewLabel: previewLabel,
          saveLabel: 'Save Class List',
          onPreview: onPreview,
          onSave: onDownload,
          onCancel: () => Navigator.pop(context),
        );
}
