import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kobac/models/exam_hall_models.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/exam_hall_service.dart';
import 'package:kobac/services/excel_file_result.dart';
import 'package:kobac/services/pdf_file_result.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/timetables_service.dart';
import 'package:kobac/utils/excel_save_feedback.dart';
import 'package:kobac/utils/pdf_save_feedback.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';
import 'package:provider/provider.dart';

const _blue = FormTheme3D.primaryBlue;
const _green = FormTheme3D.primaryGreen;
const _borderGray = Color(0xFFE2E7ED);
const _subtleText = Color(0xFF64748B);
const _errorRed = FormTheme3D.errorRed;

/// Sentinel dropdown value for "All Levels" (a Class Excel export may cover
/// every level; the dropdown itself needs a non-null value so its label floats).
const _allLevelsValue = 0;

/// Separator row between "All Levels" and the real levels.
const _dividerValue = -1;

enum _ExportType { classTimetable, teacherTimetable }

enum _ExportFormat { pdf, excel }

/// The single School Admin timetable export flow: Class or Teacher timetable,
/// as PDF or editable Excel.
Future<void> showExportTimetableDialog(
  BuildContext context, {
  int? initialAcademicYearId,
}) async {
  final provider = context.read<AcademicYearsProvider>();
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black38,
    barrierDismissible: false,
    builder: (_) => ChangeNotifierProvider<AcademicYearsProvider>.value(
      value: provider,
      child: ExportTimetableDialog(initialAcademicYearId: initialAcademicYearId),
    ),
  );
}

/// File name used when the server sends no `Content-Disposition` name, e.g.
/// `Dugsi_Teacher_Timetable_Ahmed_Ali_2026-2027.xlsx`.
@visibleForTesting
String timetableExportFallbackName({
  required bool teacher,
  required String yearName,
  required String extension,
  String? subject,
}) {
  String safe(String v) => v
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '')
      .replaceAll(RegExp(r'\s+'), '_');
  final parts = [
    'Dugsi',
    teacher ? 'Teacher' : 'Class',
    'Timetable',
    if (subject != null && safe(subject).isNotEmpty) safe(subject),
    safe(yearName),
  ];
  return '${parts.join('_')}.$extension';
}

class ExportTimetableDialog extends StatefulWidget {
  final int? initialAcademicYearId;

  const ExportTimetableDialog({super.key, this.initialAcademicYearId});

  @override
  State<ExportTimetableDialog> createState() => _ExportTimetableDialogState();
}

class _ExportTimetableDialogState extends State<ExportTimetableDialog> {
  _ExportType _type = _ExportType.classTimetable;
  _ExportFormat _format = _ExportFormat.pdf;

  // Kept across type/format switches so switching back restores the choice.
  int? _yearId;
  int? _levelId; // null = none chosen yet (PDF) / all levels (Excel)
  int? _teacherId;

  List<TeacherModel> _teachers = const [];
  List<SchoolLevel> _levels = const [];
  bool _teachersLoading = true;
  bool _levelsLoading = true;
  String? _teachersError;
  String? _levelsError;

  bool _busy = false;
  String? _error;

  bool get _isClass => _type == _ExportType.classTimetable;
  bool get _isExcel => _format == _ExportFormat.excel;

  @override
  void initState() {
    super.initState();
    _yearId = widget.initialAcademicYearId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final provider = context.read<AcademicYearsProvider>();
    await Future.wait([
      provider.ensureLoaded(),
      _loadTeachers(),
      _loadLevels(),
    ]);
    if (!mounted) return;
    setState(() => _yearId ??= provider.activeYear?.id);
  }

  Future<void> _loadTeachers() async {
    if (mounted) {
      setState(() {
        _teachersLoading = true;
        _teachersError = null;
      });
    }
    final result = await TeachersService().listTeachers();
    if (!mounted) return;
    setState(() {
      _teachersLoading = false;
      if (result is TeacherSuccess<List<TeacherModel>>) {
        _teachers = result.data;
      } else if (result is TeacherError) {
        _teachersError = result.message;
      }
    });
  }

  Future<void> _loadLevels() async {
    if (mounted) {
      setState(() {
        _levelsLoading = true;
        _levelsError = null;
      });
    }
    final result = await ExamHallService().levels();
    if (!mounted) return;
    setState(() {
      _levelsLoading = false;
      if (result is HallSuccess<List<SchoolLevel>>) {
        _levels = result.data;
      } else if (result is HallError) {
        _levelsError = result.message;
      }
    });
  }

  AcademicYear? _yearById(AcademicYearsProvider provider, int? id) {
    for (final year in provider.years) {
      if (year.id == id) return year;
    }
    return null;
  }

  SchoolLevel? get _selectedLevel {
    for (final level in _levels) {
      if (level.id == _levelId) return level;
    }
    return null;
  }

  TeacherModel? get _selectedTeacher {
    for (final teacher in _teachers) {
      if (teacher.id == _teacherId) return teacher;
    }
    return null;
  }

  bool _canSubmit(AcademicYearsProvider provider) {
    if (_busy || _yearById(provider, _yearId) == null) return false;
    if (_isClass) return _isExcel || _selectedLevel != null;
    return _selectedTeacher != null;
  }

  void _update(VoidCallback change) {
    if (_busy) return;
    setState(() {
      change();
      _error = null;
    });
  }

  Future<void> _download() async {
    final provider = context.read<AcademicYearsProvider>();
    if (!_canSubmit(provider)) return; // also blocks a second click
    final year = _yearById(provider, _yearId)!;
    final level = _selectedLevel;
    final teacher = _selectedTeacher;
    final isClass = _isClass;
    final isExcel = _isExcel;
    setState(() {
      _busy = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = TimetablesService();
      final TimetableResult<dynamic> result;
      if (isClass) {
        result = isExcel
            ? await service.getClassesTimetableExcel(
                academicYearId: year.id,
                levelId: level?.id,
                levelLabel: level?.name,
              )
            : await service.getClassesTimetablePrintPdf(
                academicYearId: year.id,
                levelId: level!.id,
                levelLabel: level.name,
              );
      } else {
        result = isExcel
            ? await service.getTeacherTimetableExcel(
                teacherId: teacher!.id,
                academicYearId: year.id,
              )
            : await service.getTeacherTimetablePrintPdf(
                teacherId: teacher!.id,
                academicYearId: year.id,
              );
      }
      if (!mounted) return;
      if (result is TimetableError) {
        final message = result.message;
        setState(() => _error = message);
        return;
      }
      final fallback = timetableExportFallbackName(
        teacher: !isClass,
        subject: isClass ? level?.name : teacher?.fullName,
        yearName: year.name,
        extension: isExcel ? 'xlsx' : 'pdf',
      );
      final bool saved;
      if (isExcel) {
        final file = (result as TimetableSuccess<ExcelFileResult>).data;
        saved = await saveExcelWithFeedback(
          context,
          bytes: file.bytes,
          filename: file.filename ?? fallback,
        );
      } else {
        final file = (result as TimetableSuccess<PdfFileResult>).data;
        saved = await savePdfWithFeedback(
          context,
          bytes: file.bytes,
          filename: file.filename ?? fallback,
        );
      }
      if (!mounted || !saved) return; // cancelled/failed: stay open, retryable
      if (kIsWeb) {
        // The browser has been handed the file; mobile already showed its own
        // "saved" confirmation with the file name.
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Timetable downloaded successfully.'),
            backgroundColor: _green,
          ),
        );
      }
      navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not export the timetable. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTeacher() async {
    final picked = await showDialog<int>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) =>
          _TeacherPickerDialog(teachers: _teachers, selectedId: _teacherId),
    );
    if (picked != null && mounted) _update(() => _teacherId = picked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicYearsProvider>();
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width < 600 ? media.size.width - 32 : 520.0;
    final canSubmit = _canSubmit(provider);

    return PopScope(
      canPop: !_busy,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                  child: _Header(busy: _busy),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionLabel('Timetable Type'),
                        Row(
                          children: [
                            Expanded(
                              child: _ChoiceCard(
                                icon: Icons.school_outlined,
                                label: 'Class Timetable',
                                selected: _isClass,
                                onTap: () => _update(
                                  () => _type = _ExportType.classTimetable,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ChoiceCard(
                                icon: Icons.person_outline_rounded,
                                label: 'Teacher Timetable',
                                selected: !_isClass,
                                onTap: () => _update(
                                  () => _type = _ExportType.teacherTimetable,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _SectionLabel('File Format'),
                        Row(
                          children: [
                            Expanded(
                              child: _ChoiceCard(
                                icon: Icons.picture_as_pdf_outlined,
                                label: 'PDF',
                                selected: !_isExcel,
                                onTap: () =>
                                    _update(() => _format = _ExportFormat.pdf),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ChoiceCard(
                                icon: Icons.table_chart_outlined,
                                label: 'Excel',
                                selected: _isExcel,
                                onTap: () => _update(
                                  () => _format = _ExportFormat.excel,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isExcel
                              ? 'Editable spreadsheet. You can make changes in Excel before printing.'
                              : 'Ready-to-print timetable document.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _subtleText,
                          ),
                        ),
                        if (_isExcel) ...[
                          const SizedBox(height: 8),
                          const _InfoNote(
                            'Changes made in the downloaded Excel file will not update the timetable in Dugsi.',
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildYearField(provider),
                        const SizedBox(height: 14),
                        if (_isClass) _buildLevelField() else _buildTeacherField(),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          _ErrorBanner(_error!),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: _Actions(
                    canSubmit: canSubmit,
                    busy: _busy,
                    onDownload: _download,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearField(AcademicYearsProvider provider) {
    final valid = _yearById(provider, _yearId) != null;
    return Select3D<int?>(
      value: valid ? _yearId : null,
      label: provider.loading ? 'Loading academic years...' : 'Academic Year *',
      items: provider.years
          .map(
            (year) => DropdownMenuItem<int?>(
              value: year.id,
              child: Text(
                year.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _busy || provider.loading
          ? null
          : (value) => _update(() => _yearId = value),
    );
  }

  Widget _buildLevelField() {
    if (_levelsError != null) {
      return _LoadError(message: _levelsError!, onRetry: _loadLevels);
    }
    final level = _selectedLevel;
    final String label;
    if (_levelsLoading) {
      label = 'Loading levels...';
    } else if (_isExcel) {
      label = 'Level';
    } else {
      label = level == null ? 'Select Level *' : 'Level *';
    }
    return Select3D<int?>(
      value: level != null ? level.id : (_isExcel ? _allLevelsValue : null),
      label: label,
      items: [
        if (_isExcel) ...[
          const DropdownMenuItem<int?>(
            value: _allLevelsValue,
            child: Text('All Levels'),
          ),
          if (_levels.isNotEmpty)
            const DropdownMenuItem<int?>(
              value: _dividerValue,
              enabled: false,
              child: Divider(height: 1),
            ),
        ],
        ..._levels.map(
          (item) => DropdownMenuItem<int?>(
            value: item.id,
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: _busy || _levelsLoading
          ? null
          : (value) => _update(
              () => _levelId = value == _allLevelsValue ? null : value,
            ),
    );
  }

  Widget _buildTeacherField() {
    if (_teachersError != null) {
      return _LoadError(message: _teachersError!, onRetry: _loadTeachers);
    }
    final teacher = _selectedTeacher;
    final String? placeholder;
    if (_teachersLoading) {
      placeholder = 'Loading teachers...';
    } else if (_teachers.isEmpty) {
      placeholder = 'No teachers found';
    } else {
      placeholder = null;
    }
    return _PickerField(
      label: 'Teacher *',
      value: teacher?.fullName,
      placeholder: placeholder ?? 'Search and select a teacher',
      loading: _teachersLoading,
      enabled: !_busy && !_teachersLoading && _teachers.isNotEmpty,
      onTap: _pickTeacher,
    );
  }
}

class _Header extends StatelessWidget {
  final bool busy;
  const _Header({required this.busy});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.file_download_outlined, color: _blue),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Padding(
          padding: EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Timetable',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _blue,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Choose what you want to export',
                style: TextStyle(color: _subtleText, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      IconButton(
        tooltip: 'Close',
        onPressed: busy ? null : () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
      ),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: Color(0xFF1A1A2E),
      ),
    ),
  );
}

/// Selectable card. Selection is conveyed by border, tint, bold text and a
/// check mark - never by color alone.
class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _blue.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _blue : _borderGray,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? _blue : _subtleText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _blue : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: selected ? _green : const Color(0xFFCBD2DA),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Neutral, informational note (not a warning).
class _InfoNote extends StatelessWidget {
  final String text;
  const _InfoNote(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F6F9),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: _subtleText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: _subtleText),
          ),
        ),
      ],
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _errorRed.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _errorRed.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: _errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: _errorRed),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.error_outline_rounded, size: 18, color: _errorRed),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, color: _errorRed),
        ),
      ),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ],
  );
}

/// Select-style field that opens the searchable teacher list.
class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: '$label ${value ?? placeholder}',
    excludeSemantics: true,
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(FormTheme3D.radiusInput),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: FormTheme3D.inputBg,
          borderRadius: BorderRadius.circular(FormTheme3D.radiusInput),
          boxShadow: FormTheme3D.inputShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: FormTheme3D.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: value != null
                          ? FormTheme3D.textPrimary
                          : FormTheme3D.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded, color: _blue),
          ],
        ),
      ),
    ),
  );
}

class _TeacherPickerDialog extends StatefulWidget {
  final List<TeacherModel> teachers;
  final int? selectedId;
  const _TeacherPickerDialog({required this.teachers, this.selectedId});

  @override
  State<_TeacherPickerDialog> createState() => _TeacherPickerDialogState();
}

class _TeacherPickerDialogState extends State<_TeacherPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final matches = q.isEmpty
        ? widget.teachers
        : widget.teachers
              .where(
                (t) =>
                    t.fullName.toLowerCase().contains(q) ||
                    t.email.toLowerCase().contains(q),
              )
              .toList();
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width < 600 ? media.size.width - 32 : 460.0;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Teacher',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _blue,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search teachers',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Flexible(
              child: matches.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No teachers match your search.',
                          style: TextStyle(color: _subtleText),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: matches.length,
                      itemBuilder: (_, i) {
                        final teacher = matches[i];
                        final selected = teacher.id == widget.selectedId;
                        return ListTile(
                          title: Text(
                            teacher.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: teacher.email.isEmpty
                              ? null
                              : Text(
                                  teacher.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: _green,
                                )
                              : null,
                          selected: selected,
                          onTap: () => Navigator.pop(context, teacher.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final bool canSubmit;
  final bool busy;
  final VoidCallback onDownload;

  const _Actions({
    required this.canSubmit,
    required this.busy,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(72, 46)),
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _green.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(140, 46),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: canSubmit ? onDownload : null,
        icon: busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.download_rounded, size: 18),
        label: Text(busy ? 'Downloading...' : 'Download'),
      ),
    ],
  );
}
