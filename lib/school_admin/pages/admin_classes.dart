import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/pages/admin_class_details_screen.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

// --- Premium 3D Design Constants ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class AdminClassesPage extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AdminClassesPage({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends State<AdminClassesPage> {
  late Future<ClassResult<List<ClassModel>>> _classesFuture;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _loadClasses() {
    setState(() {
      _classesFuture = ClassesService().listClasses();
    });
  }

  List<ClassModel> _filter(List<ClassModel> list) {
    if (searchQuery.isEmpty) return list;
    final q = searchQuery.toLowerCase();
    return list.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _openCreateClass() async {
    final isDesktop = isDesktopWebAdminLayout(context);
    if (isDesktop && widget.onNavigateToPage != null) {
      widget.onNavigateToPage!('addClass');
      return;
    }

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ClassFormDialog(
        title: 'Add Class',
        initialName: '',
        submitLabel: 'Create',
        onSave: (name) async {
          final result = await ClassesService().createClass({'name': name});
          if (result is ClassSuccess) return true;
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text((result as ClassError).message), backgroundColor: Colors.red),
            );
          }
          return false;
        },
      ),
    );
    if (created == true) {
      _loadClasses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class created'), backgroundColor: kPrimaryGreen),
        );
      }
    }
  }

  Future<void> _openEditClass(ClassModel classModel) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ClassFormDialog(
        title: 'Edit Class',
        initialName: classModel.name,
        submitLabel: 'Save',
        onSave: (name) async {
          final result = await ClassesService().updateClass(classModel.id, {'name': name});
          if (result is ClassSuccess) return true;
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text((result as ClassError).message), backgroundColor: Colors.red),
            );
          }
          return false;
        },
      ),
    );
    if (updated == true) {
      _loadClasses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated'), backgroundColor: kPrimaryGreen),
        );
      }
    }
  }

  Future<void> _deleteClass(ClassModel classModel) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete class?',
      message: 'Delete class ${classModel.name}?',
    );
    if (confirmed != true) return;
    final result = await ClassesService().deleteClass(classModel.id);
    if (!mounted) return;
    if (result is ClassSuccess) {
      _loadClasses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${classModel.name} deleted'), backgroundColor: kPrimaryGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as ClassError).message), backgroundColor: Colors.red),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Classes",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryBlue,
                            ),
                          ),
                          Text(
                            'Manage school classes',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openCreateClass,
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text('Add Class'),
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
                      BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
                      BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 40, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search classes...",
                      prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryBlue),
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
                  onRefresh: () async => _loadClasses(),
                  color: kPrimaryGreen,
                  child: FutureBuilder<ClassResult<List<ClassModel>>>(
                    future: _classesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _MinimalClassSkeletonList();
                      }
                      if (snapshot.hasError) {
                        final userMsg = userFriendlyMessage(snapshot.error!, null, 'AdminClassesPage');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                const SizedBox(height: 12),
                                Text(userMsg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _loadClasses,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final result = snapshot.data;
                      if (result == null) return const Center(child: Text('No data'));
                      if (result is ClassError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                const SizedBox(height: 12),
                                Text(result.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _loadClasses,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final classes = _filter((result as ClassSuccess<List<ClassModel>>).data);
                      if (classes.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(kCardRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kPrimaryBlue.withOpacity(0.06),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                children: [
                                    Icon(
                                      Icons.school_rounded,
                                      size: 60,
                                      color: kPrimaryBlue.withOpacity(0.25),
                                    ),
                                  const SizedBox(height: 12),
                                  Text(
                                    searchQuery.isEmpty ? 'No classes created' : 'No classes match your search',
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
                                        onPressed: _openCreateClass,
                                        icon: const Icon(Icons.add_rounded),
                                        label: const Text('Create Class'),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          final classModel = classes[index];
                          return _MinimalClassCard(
                            index: index,
                            classModel: classModel,
                            onTap: () {
                              final isDesktop = isDesktopWebAdminLayout(context);
                              if (isDesktop && widget.onNavigateToPage != null) {
                                widget.onNavigateToPage!('classDetail', arguments: {
                                  'classId': classModel.id,
                                  'className': classModel.name,
                                  'academicYearId':
                                      classModel.academicYear?.id,
                                });
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AdminClassDetailsScreen(
                                      classId: classModel.id,
                                      className: classModel.name,
                                      initialAcademicYearId:
                                          classModel.academicYear?.id,
                                    ),
                                  ),
                                );
                              }
                            },
                            onEdit: () => _openEditClass(classModel),
                            onDelete: () => _deleteClass(classModel),
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
                      border: Border.all(color: const Color(0xFFE8ECF2), width: 1),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search classes...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<ClassResult<List<ClassModel>>>(
              future: _classesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _MinimalClassSkeletonList();
                }
                if (snapshot.hasError) {
                  final userMsg = userFriendlyMessage(snapshot.error!, null, 'AdminClassesPage');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 12),
                        Text(userMsg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _loadClasses,
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
                if (result is ClassError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 12),
                        Text(result.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _loadClasses,
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
                final classes = _filter((result as ClassSuccess<List<ClassModel>>).data);
                if (classes.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 60,
                              color: kPrimaryBlue.withOpacity(0.25),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No classes created'
                                  : 'No classes match your search',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            if (searchQuery.isEmpty) ...[
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _openCreateClass,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create Class'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryGreen,
                                  foregroundColor: Colors.white,
                                ),
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
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final classModel = classes[index];
                    return _MinimalClassCard(
                      index: index,
                      classModel: classModel,
                      onTap: () {
                        if (widget.onNavigateToPage != null) {
                          widget.onNavigateToPage!('classDetail', arguments: {
                            'classId': classModel.id,
                            'className': classModel.name,
                            'academicYearId': classModel.academicYear?.id,
                          });
                        }
                      },
                      onEdit: () => _openEditClass(classModel),
                      onDelete: () => _deleteClass(classModel),
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

class _ClassRow extends StatelessWidget {
  final ClassModel classModel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassRow({
    required this.classModel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
                      color: kPrimaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.class_rounded, color: kPrimaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      classModel.name,
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
                    icon: const Icon(Icons.edit_outlined, size: 20, color: kPrimaryGreen),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
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

class AddClassScreen extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AddClassScreen({
    super.key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
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
        const SnackBar(content: Text('Class name is required'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final result = await ClassesService().createClass({'name': name});
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result is ClassSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class created'), backgroundColor: kPrimaryGreen),
      );
      if (widget.onNavigateToPage != null) {
        widget.onNavigateToPage!('classes');
      } else {
        Navigator.of(context).pop(true);
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text((result as ClassError).message), backgroundColor: Colors.red),
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
      widget.onNavigateToPage!('classes');
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
                color: Colors.black.withOpacity(0.04),
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
                final fieldWidth = isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _desktopInputDecoration('Class name'),
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
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Add Class'),
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
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Add Class'),
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
                        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Add Class',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
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

/// Dialog for Create/Edit class: single "name" field, Save/Create button.
class _ClassFormDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final String submitLabel;
  final Future<bool> Function(String name) onSave;

  const _ClassFormDialog({
    required this.title,
    required this.initialName,
    required this.submitLabel,
    required this.onSave,
  });

  @override
  State<_ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<_ClassFormDialog> {
  late TextEditingController _nameController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
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
        const SnackBar(content: Text('Class name is required'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await widget.onSave(name);
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
            ),
            const SizedBox(height: 20),
            Input3D(
              controller: _nameController,
              label: 'Class name',
              hint: 'e.g. Grade 7 - A',
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
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
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
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
          boxShadow: [BoxShadow(color: kPrimaryGreen.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add_rounded, color: kPrimaryGreen, size: 24),
      ),
    );
  }
}

class _MinimalClassCard extends StatelessWidget {
  final int index;
  final ClassModel classModel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MinimalClassCard({
    required this.index,
    required this.classModel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final countText = classModel.studentCount == 0
        ? 'No students'
        : '${classModel.studentCount} '
              'Student${classModel.studentCount == 1 ? '' : 's'}';
    return TweenAnimationBuilder<double>(
      duration: Duration(
        milliseconds: 240 + (index.clamp(0, 5).toInt() * 40),
      ),
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kCardRadius),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kCardRadius),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.03),
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
                      backgroundColor: kPrimaryBlue.withOpacity(0.1),
                      child: const Icon(
                        Icons.school_rounded,
                        color: kPrimaryBlue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classModel.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: kPrimaryBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.groups_rounded,
                                size: 18,
                                color: kPrimaryGreen,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  countText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: kPrimaryBlue,
                      size: 26,
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
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
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
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final int index;
  final ClassModel classModel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassCard({
    this.index = 0,
    required this.classModel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(
        milliseconds: 260 + (index.clamp(0, 5).toInt() * 45),
      ),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kCardRadius),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kCardRadius),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.03),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                  decoration: BoxDecoration(
                        color: kPrimaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: kPrimaryBlue,
                        size: 30,
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    classModel.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue,
                        ),
                        maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: kPrimaryBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ClassInfo(
                        icon: Icons.groups_rounded,
                        label: 'Students',
                        value: classModel.studentCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: _ClassInfo(
                        icon: Icons.menu_book_rounded,
                        label: 'Subjects',
                        value: '—',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: _ClassInfo(
                        icon: Icons.person_rounded,
                        label: 'Class Teacher',
                        value: 'Not assigned',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ClassInfo(
                        icon: Icons.calendar_month_rounded,
                        label: 'Academic Year',
                        value: classModel.academicYear?.name ?? '—',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: const Color(0xFFE8ECF2)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                        label: const Text('Manage'),
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryBlue,
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryGreen,
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                        ),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ClassInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: kPrimaryGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClassSummary extends StatelessWidget {
  final List<ClassModel> classes;

  const _ClassSummary({required this.classes});

  @override
  Widget build(BuildContext context) {
    final students = classes.fold<int>(
      0,
      (total, item) => total + item.studentCount,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.school_rounded,
              value: '${classes.length}',
              label: classes.length == 1 ? 'Class' : 'Classes',
              color: kPrimaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              icon: Icons.groups_rounded,
              value: '$students',
              label: students == 1 ? 'Student' : 'Students',
              color: kPrimaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalClassSkeletonList extends StatelessWidget {
  const _MinimalClassSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        height: 174,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Column(
          children: [
            Row(
              children: [
                _ClassSkeletonBlock(width: 56, height: 56),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ClassSkeletonBlock(width: 150, height: 16),
                      SizedBox(height: 10),
                      _ClassSkeletonBlock(width: 105, height: 13),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 22),
            _ClassSkeletonBlock(height: 46),
          ],
        ),
      ),
    );
  }
}

class _ClassSkeletonList extends StatelessWidget {
  const _ClassSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        height: 286,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ClassSkeletonBlock(width: 54, height: 54),
                SizedBox(width: 16),
                _ClassSkeletonBlock(width: 150, height: 16),
              ],
            ),
            SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: _ClassSkeletonBlock(height: 42)),
                SizedBox(width: 14),
                Expanded(child: _ClassSkeletonBlock(height: 42)),
              ],
            ),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _ClassSkeletonBlock(height: 42)),
                SizedBox(width: 14),
                Expanded(child: _ClassSkeletonBlock(height: 42)),
              ],
            ),
            SizedBox(height: 24),
            _ClassSkeletonBlock(height: 42),
          ],
        ),
      ),
    );
  }
}

class _ClassSkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;

  const _ClassSkeletonBlock({this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
