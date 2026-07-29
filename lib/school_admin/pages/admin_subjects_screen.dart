import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

// --- Premium 3D Design Constants (match admin_classes) ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const Color kTextSecondaryColor = Color(0xFF636E72);
const double kCardRadius = 28.0;

class AdminSubjectsScreen extends StatefulWidget {
  /// When true, opens "Add Subject" dialog after first frame.
  final bool openCreateOnLoad;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AdminSubjectsScreen({
    Key? key,
    this.openCreateOnLoad = false,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends State<AdminSubjectsScreen> {
  late Future<SubjectResult<List<SubjectModel>>> _subjectsFuture;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreateSubject());
    }
  }

  void _loadSubjects() {
    setState(() {
      _subjectsFuture = SubjectsService().listSubjects();
    });
  }

  List<SubjectModel> _filter(List<SubjectModel> list) {
    if (searchQuery.isEmpty) return list;
    final q = searchQuery.toLowerCase();
    return list.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _openCreateSubject() async {
    final isDesktop = isDesktopWebAdminLayout(context);
    if (isDesktop && widget.onNavigateToPage != null) {
      widget.onNavigateToPage!('addSubject');
      return;
    }

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SubjectFormDialog(
        title: 'Add Subject',
        submitLabel: 'Create',
        onSave: (data) async {
          final result = await SubjectsService().createSubject(data);
          if (result is SubjectSuccess) return true;
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text((result as SubjectError).message),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        },
      ),
    );
    if (created == true) {
      _loadSubjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject created'),
            backgroundColor: kPrimaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _openEditSubject(SubjectModel subject) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SubjectFormDialog(
        title: 'Edit Subject',
        initialName: subject.name,
        submitLabel: 'Save',
        onSave: (data) async {
          final result = await SubjectsService().updateSubject(
            subject.id,
            data,
          );
          if (result is SubjectSuccess) return true;
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text((result as SubjectError).message),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        },
      ),
    );
    if (updated == true) {
      _loadSubjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject updated'),
            backgroundColor: kPrimaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _deleteSubject(SubjectModel subject) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete subject?',
      message: 'Remove ${subject.name}?',
    );
    if (confirmed != true) return;
    final result = await SubjectsService().deleteSubject(subject.id);
    if (!mounted) return;
    if (result is SubjectSuccess) {
      _loadSubjects();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${subject.name} removed'),
          backgroundColor: kPrimaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as SubjectError).message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)
        ? _buildDesktopPageBody(context)
        : _buildMobilePageBody(context);

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) return body;
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(child: body),
    );
  }

  Widget _buildMobilePageBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBgColor, kPrimaryBlue.withValues(alpha: 0.02)],
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Subjects",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue,
                        ),
                      ),
                      Text(
                        'Manage school subjects',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openCreateSubject,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('Add Subject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
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
                    color: kPrimaryBlue.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: kPrimaryBlue.withValues(alpha: 0.03),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search subjects...",
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
              onRefresh: () async => _loadSubjects(),
              color: kPrimaryGreen,
              child: FutureBuilder<SubjectResult<List<SubjectModel>>>(
                future: _subjectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _SubjectSkeletonList();
                  }
                  if (snapshot.hasError) {
                    final userMsg = userFriendlyMessage(
                      snapshot.error!,
                      null,
                      'AdminSubjectsScreen',
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
                              onPressed: _loadSubjects,
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
                  if (result is SubjectError) {
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
                              onPressed: _loadSubjects,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final subjects = _filter(
                    (result as SubjectSuccess<List<SubjectModel>>).data,
                  );
                  if (subjects.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                        ),
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(kCardRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimaryBlue.withValues(alpha: 0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 60,
                                  color: kPrimaryBlue.withValues(alpha: 0.25),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'No subjects created'
                                      : 'No subjects match your search',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: kPrimaryBlue,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (searchQuery.isEmpty) ...[
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    onPressed: _openCreateSubject,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Create Subject'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryGreen,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return _SubjectCard(
                        index: index,
                        subject: subject,
                        onEdit: () => _openEditSubject(subject),
                        onDelete: () => _deleteSubject(subject),
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

  Widget _buildDesktopPageBody(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE8ECF2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search subjects...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade500,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Subject Name',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 80),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<SubjectResult<List<SubjectModel>>>(
              future: _subjectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryBlue),
                  );
                }
                if (snapshot.hasError) {
                  final userMsg = userFriendlyMessage(
                    snapshot.error!,
                    null,
                    'AdminSubjectsScreen',
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
                          onPressed: _loadSubjects,
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
                if (result == null) return const Center(child: Text('No data'));
                if (result is SubjectError) {
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
                          onPressed: _loadSubjects,
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
                final subjects = _filter(
                  (result as SubjectSuccess<List<SubjectModel>>).data,
                );
                if (subjects.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                      ),
                      Center(
                        child: Text(
                          searchQuery.isEmpty
                              ? 'No subjects found. Add subjects to get started.'
                              : 'No subjects match your search',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return _SubjectRow(
                      subject: subject,
                      onEdit: () => _openEditSubject(subject),
                      onDelete: () => _deleteSubject(subject),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddSubjectScreen extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AddSubjectScreen({
    super.key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final result = await SubjectsService().createSubject({'name': name});
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result is SubjectSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject created'),
          backgroundColor: kPrimaryGreen,
        ),
      );
      if (widget.onNavigateToPage != null) {
        widget.onNavigateToPage!('subjects');
      } else {
        Navigator.of(context).pop(true);
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text((result as SubjectError).message),
        backgroundColor: Colors.red,
      ),
    );
  }

  InputDecoration _desktopInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: kPrimaryBlue, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5),
      ),
    );
  }

  void _cancel() {
    if (widget.onNavigateToPage != null) {
      widget.onNavigateToPage!('subjects');
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildEmbeddedBody(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8ECF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final fieldWidth = isWide
                    ? (constraints.maxWidth - 24) / 2
                    : constraints.maxWidth;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _desktopInputDecoration('Subject name'),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isWide)
                      Row(
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _submitting ? null : _cancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: fieldWidth,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Add Subject'),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _submitting ? null : _cancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: fieldWidth,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Add Subject'),
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) {
      return _buildEmbeddedBody(context);
    }

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _cancel,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryBlue.withValues(alpha: 0.08),
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
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Add Subject',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(child: _buildEmbeddedBody(context)),
          ],
        ),
      ),
    );
  }
}

/// Dialog for Create/Edit subject: single "name" field, Save/Create button.
class _SubjectFormDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final String submitLabel;
  final Future<bool> Function(Map<String, dynamic> data) onSave;

  const _SubjectFormDialog({
    required this.title,
    this.initialName,
    required this.submitLabel,
    required this.onSave,
  });

  @override
  State<_SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<_SubjectFormDialog> {
  late TextEditingController _nameController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);

    final data = <String, dynamic>{'name': name};
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
              label: 'Subject name',
              hint: 'e.g. Mathematics',
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submit(),
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
              color: kPrimaryBlue.withValues(alpha: 0.08),
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

// ignore: unused_element
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
          color: kPrimaryGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: kPrimaryGreen.withValues(alpha: 0.2),
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

class _SubjectRow extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectRow({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: kPrimaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subject.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kPrimaryBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: kPrimaryGreen,
                  ),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red[400],
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final int index;
  final SubjectModel subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    this.index = 0,
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 240 + (index.clamp(0, 5).toInt() * 40)),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kCardRadius),
            boxShadow: [
              BoxShadow(
                color: kPrimaryBlue.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: kPrimaryBlue.withValues(alpha: 0.03),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: kPrimaryBlue.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: kPrimaryBlue,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: kPrimaryBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: const Color(0xFFE8ECF2)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimaryGreen,
                        minimumSize: const Size(0, 46),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFE8ECF2),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size(0, 46),
                      ),
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

class _SubjectSkeletonList extends StatelessWidget {
  const _SubjectSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        height: 156,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12023471),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8ECF2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8ECF2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(height: 1, color: const Color(0xFFE8ECF2)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
