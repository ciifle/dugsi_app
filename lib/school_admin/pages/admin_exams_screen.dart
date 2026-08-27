import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/exams_service.dart';
import 'package:kobac/services/school_admin_assignments_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/school_admin/pages/exam_details_page.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:provider/provider.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class AdminExamsScreen extends StatefulWidget {
  final bool openCreateOnLoad;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AdminExamsScreen({
    Key? key,
    this.openCreateOnLoad = false,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<AdminExamsScreen> createState() => _AdminExamsScreenState();
}

class _AdminExamsScreenState extends State<AdminExamsScreen> {
  late Future<ExamResult<List<ExamModel>>> _examsFuture;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int? _academicYearId;

  @override
  void initState() {
    super.initState();
    _examsFuture = ExamsService().listExams();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final years = context.read<AcademicYearsProvider>();
      await years.ensureLoaded();
      if (!mounted) return;
      setState(() => _academicYearId ??= years.activeYear?.id);
      _loadExams();
    });
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreateExam());
    }
  }

  void _loadExams() {
    setState(() {
      _examsFuture = ExamsService().listExams(academicYearId: _academicYearId);
    });
  }

  List<ExamModel> _filter(List<ExamModel> list) {
    if (searchQuery.isEmpty) return list;
    final q = searchQuery.toLowerCase();
    return list.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _openCreateExam() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ExamFormDialog(
        title: 'Add Exam',
        initialName: '',
        submitLabel: 'Create',
        isCreate: true,
        initialAcademicYearId: _academicYearId,
        onSave: (data) async {
          final result = await ExamsService().createExam(data);
          if (result is ExamSuccess) return true;
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text((result as ExamError).message),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        },
      ),
    );
    if (created == true) {
      _loadExams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam created'),
            backgroundColor: kPrimaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _openEditExam(ExamModel exam) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ExamFormDialog(
        title: 'Edit Exam',
        initialName: exam.name,
        initialDate: exam.date,
        initialExamType: exam.examType,
        initialWeight: exam.weight,
        initialAcademicYearId: exam.academicYearId ?? _academicYearId,
        submitLabel: 'Save',
        isCreate: false,
        examId: exam.id,
        onSave: (data) async {
          final result = await ExamsService().updateExam(exam.id, data);
          if (result is ExamSuccess) return true;
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text((result as ExamError).message),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        },
      ),
    );
    if (updated == true) {
      _loadExams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam updated'),
            backgroundColor: kPrimaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _deleteExam(ExamModel exam) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete exam?',
      message: 'Delete exam ${exam.name}?',
    );
    if (confirmed != true) return;
    final result = await ExamsService().deleteExam(exam.id);
    if (!mounted) return;
    if (result is ExamSuccess) {
      _loadExams();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${exam.name} deleted'),
          backgroundColor: kPrimaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as ExamError).message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = context.watch<AcademicYearsProvider>().years;
    final body = isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)
        ? _buildDesktopPageBody(context, years)
        : Column(
            children: [
              _yearFilter(years),
              Expanded(child: _buildMobilePageBody(context)),
            ],
          );

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) {
      return body;
    }

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(child: body),
    );
  }

  Widget _yearFilter(List<AcademicYear> years) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: DropdownButtonFormField<int>(
      value: years.any((e) => e.id == _academicYearId) ? _academicYearId : null,
      decoration: const InputDecoration(
        labelText: 'Academic Year',
        filled: true,
        fillColor: Colors.white,
      ),
      items: years
          .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
          .toList(),
      onChanged: (value) {
        setState(() => _academicYearId = value);
        _loadExams();
      },
    ),
  );

  Widget _buildMobilePageBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBgColor, kPrimaryBlue.withOpacity(0.02)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                _BackButton(onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Exams',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ),
                _AddButton(onPressed: _openCreateExam),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: kPrimaryBlue.withOpacity(0.03),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search exams...",
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: kPrimaryBlue,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadExams(),
              color: kPrimaryGreen,
              child: FutureBuilder<ExamResult<List<ExamModel>>>(
                future: _examsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kPrimaryGreen),
                    );
                  }
                  if (snapshot.hasError) {
                    final userMsg = userFriendlyMessage(
                      snapshot.error!,
                      null,
                      'AdminExamsScreen',
                    );
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              userMsg,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _loadExams,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final result = snapshot.data;
                  if (result == null)
                    return const Center(child: Text('No data'));
                  if (result is ExamError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              result.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _loadExams,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final exams = _filter(
                    (result as ExamSuccess<List<ExamModel>>).data,
                  );
                  if (exams.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                        ),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.quiz_rounded,
                                size: 60,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                searchQuery.isEmpty
                                    ? 'No exams yet'
                                    : 'No exams match your search',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              if (searchQuery.isEmpty) ...[
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _openCreateExam,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Exam'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: exams.length,
                    itemBuilder: (context, index) {
                      final exam = exams[index];
                      return _ExamCard(
                        exam: exam,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExamDetailsPage(examId: exam.id),
                          ),
                        ),
                        onEdit: () => _openEditExam(exam),
                        onDelete: () => _deleteExam(exam),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPageBody(BuildContext context, List<AcademicYear> years) {
    return Container(
      color: kAdminBg,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            title: 'Exams',
            subtitle: 'Manage examinations and assessment periods',
            primaryAction: AdminPrimaryButton(
              label: '+ Add Exam',
              onPressed: _openCreateExam,
            ),
          ),
          const SizedBox(height: 20),
          AdminFilterBar(
            filters: [
              AdminFilterDropdown<int>(
                label: 'Academic Year',
                value: years.any((e) => e.id == _academicYearId)
                    ? _academicYearId
                    : null,
                items: years
                    .map(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _academicYearId = value);
                  _loadExams();
                },
              ),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search exams...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kAdminBorder),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kAdminBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const AdminTableHeader(
                    columns: [
                      AdminTableColumn('Exam Name', flex: 3),
                      AdminTableColumn('Type', flex: 2),
                      AdminTableColumn('Class', flex: 2),
                      AdminTableColumn('Date', flex: 2),
                      AdminTableColumn('Weight', flex: 1),
                      AdminTableColumn(
                        'Actions',
                        flex: 2,
                        align: TextAlign.right,
                      ),
                    ],
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => _loadExams(),
                      color: kPrimaryGreen,
                      child: FutureBuilder<ExamResult<List<ExamModel>>>(
                        future: _examsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: kPrimaryBlue,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            final userMsg = userFriendlyMessage(
                              snapshot.error!,
                              null,
                              'AdminExamsScreen',
                            );
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    userMsg,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _loadExams,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                    style: TextButton.styleFrom(
                                      backgroundColor: kPrimaryBlue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final result = snapshot.data;
                          if (result == null)
                            return const Center(child: Text('No data'));
                          if (result is ExamError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    result.message,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _loadExams,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                    style: TextButton.styleFrom(
                                      backgroundColor: kPrimaryBlue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final exams = _filter(
                            (result as ExamSuccess<List<ExamModel>>).data,
                          );
                          if (exams.isEmpty) {
                            return AdminEmptyState(
                              icon: Icons.quiz_outlined,
                              title: 'No exams yet',
                              message: searchQuery.isEmpty
                                  ? 'Create an exam to get started.'
                                  : 'No exams match your search.',
                              action: searchQuery.isEmpty
                                  ? AdminPrimaryButton(
                                      label: '+ Add First Exam',
                                      onPressed: _openCreateExam,
                                    )
                                  : null,
                            );
                          }
                          return ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: exams.length,
                            itemBuilder: (context, index) {
                              final exam = exams[index];
                              return _ExamRow(
                                exam: exam,
                                onEdit: () => _openEditExam(exam),
                                onDelete: () => _deleteExam(exam),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamRow extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExamRow({
    required this.exam,
    required this.onEdit,
    required this.onDelete,
  });

  String _displayValue(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return AdminTableRow(
      flexes: const [3, 2, 2, 2, 1, 2],
      cells: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: kPrimaryBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                exam.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Text(
          _displayValue(exam.examType),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _displayValue(exam.className),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _displayValue(exam.date),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          exam.weight != null ? exam.weight!.toString() : '-',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Tooltip(
              message: 'Edit Exam',
              child: IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: kPrimaryGreen,
                ),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Tooltip(
              message: 'Delete Exam',
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red[400],
                ),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExamFormDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final String? initialDate;
  final String? initialExamType;
  final double? initialWeight;
  final String submitLabel;
  final bool isCreate;
  final int? examId;
  final int? initialAcademicYearId;
  final Future<bool> Function(Map<String, dynamic> data) onSave;

  const _ExamFormDialog({
    required this.title,
    required this.initialName,
    this.initialDate,
    this.initialExamType,
    this.initialWeight,
    required this.submitLabel,
    required this.isCreate,
    this.examId,
    this.initialAcademicYearId,
    required this.onSave,
  });

  @override
  State<_ExamFormDialog> createState() => _ExamFormDialogState();
}

class _ExamFormDialogState extends State<_ExamFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _examTypeController;
  late TextEditingController _weightController;
  late TextEditingController _dateController;
  bool _submitting = false;
  int? _academicYearId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _examTypeController = TextEditingController(
      text: widget.initialExamType ?? '',
    );
    _weightController = TextEditingController(
      text: widget.initialWeight?.toString() ?? '',
    );
    _dateController = TextEditingController(
      text: widget.initialDate?.isNotEmpty == true
          ? widget.initialDate!
          : _formatDate(DateTime.now()),
    );
    _academicYearId = widget.initialAcademicYearId;
  }

  String _formatDate(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _examTypeController.dispose();
    _weightController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final examType = _examTypeController.text.trim();
    final weightText = _weightController.text.trim();
    final weight = weightText.isNotEmpty ? double.tryParse(weightText) : null;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (weight == null || weight! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid exam weight (maximum marks) greater than 0.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_academicYearId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Academic year is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);

    final data = <String, dynamic>{
      'name': name,
      'date': _dateController.text,
      'exam_type': examType.isNotEmpty ? examType : null,
      'weight': weight,
      'academic_year_id': _academicYearId,
    };
    final ok = await widget.onSave(data);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: FormCard(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              Input3D(
                controller: _nameController,
                label: 'Exam name',
                hint: 'e.g. Mid-term 2024',
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Input3D(
                controller: _examTypeController,
                label: 'Exam type (optional)',
                hint: 'e.g. Mid-term, Final, Quiz',
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Input3D(
                controller: _weightController,
                label: 'Exam Weight / Maximum Marks',
                hint: 'e.g. 10, 30, 50',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Maximum mark allowed for each subject in this exam.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<AcademicYearsProvider>(
                builder: (_, provider, __) => DropdownButtonFormField<int>(
                  value: provider.years.any((e) => e.id == _academicYearId)
                      ? _academicYearId
                      : null,
                  decoration: const InputDecoration(labelText: 'Academic Year'),
                  items: provider.years
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _academicYearId = value),
                ),
              ),
              const SizedBox(height: 16),
              DatePicker3D(
                label: 'Date',
                value: _dateController.text,
                initialDate:
                    DateTime.tryParse(_dateController.text) ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDatePicked: (d) =>
                    setState(() => _dateController.text = _formatDate(d)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton3D(
                      label: widget.submitLabel,
                      onPressed: _submit,
                      loading: _submitting,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: kPrimaryBlue,
          size: 24,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kPrimaryGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: kPrimaryGreen.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: kPrimaryGreen, size: 24),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExamCard({
    required this.exam,
    this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kCardRadius),
            boxShadow: [
              BoxShadow(
                color: kPrimaryBlue.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: kPrimaryBlue.withOpacity(0.03),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: kPrimaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  exam.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 22,
                  color: kPrimaryGreen,
                ),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 22,
                  color: Colors.red[400],
                ),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
