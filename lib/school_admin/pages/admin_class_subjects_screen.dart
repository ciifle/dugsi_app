import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/class_subjects_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const Color kTextSecondaryColor = Color(0xFF636E72);
const double kCardRadius = 28.0;

class AdminClassSubjectsScreen extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AdminClassSubjectsScreen({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<AdminClassSubjectsScreen> createState() => _AdminClassSubjectsScreenState();
}

class _AdminClassSubjectsScreenState extends State<AdminClassSubjectsScreen> {
  List<ClassModel> _classes = [];
  List<SubjectModel> _allSubjects = [];
  ClassModel? _selectedClass;
  List<ClassSubjectModel> _classSubjects = [];
  Set<int> _selectedSubjectIds = {};
  bool _loading = false;
  bool _loadingClassSubjects = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final classesResult = await ClassesService().listClasses();
      final subjectsResult = await SubjectsService().listSubjects();
      
      if (!mounted) return;
      
      setState(() {
        _loading = false;
        if (classesResult is ClassSuccess<List<ClassModel>>) {
          _classes = classesResult.data;
        }
        if (subjectsResult is SubjectSuccess<List<SubjectModel>>) {
          _allSubjects = subjectsResult.data;
        }
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = userFriendlyMessage(e, st, 'AdminClassSubjectsScreen');
      });
    }
  }

  Future<void> _loadClassSubjects(int classId) async {
    setState(() {
      _loadingClassSubjects = true;
    });
    
    try {
      final result = await ClassSubjectsService().listClassSubjects(classId: classId);
      if (!mounted) return;
      
      setState(() {
        _loadingClassSubjects = false;
        if (result is ClassSubjectSuccess<List<ClassSubjectModel>>) {
          _classSubjects = result.data;
          _selectedSubjectIds = _classSubjects.map((cs) => cs.subjectId).toSet();
        } else {
          _classSubjects = [];
          _selectedSubjectIds = {};
        }
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loadingClassSubjects = false;
        _classSubjects = [];
        _selectedSubjectIds = {};
      });
    }
  }

  Future<void> _saveClassSubjects() async {
    if (_selectedClass == null) return;
    
    setState(() {
      _saving = true;
    });
    
    try {
      final data = {
        'class_id': _selectedClass!.id,
        'subject_ids': _selectedSubjectIds.toList(),
      };
      
      final result = await ClassSubjectsService().createClassSubject(data);
      
      if (!mounted) return;
      
      setState(() {
        _saving = false;
      });
      
      if (result is ClassSubjectSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class subjects updated successfully'),
            backgroundColor: kPrimaryGreen,
          ),
        );
        // Reload to show updated state
        _loadClassSubjects(_selectedClass!.id);
      } else {
        final error = result as ClassSubjectError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyMessage(e, st, 'AdminClassSubjectsScreen')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getClassName(int classId) {
    final classModel = _classes.firstWhere(
      (c) => c.id == classId,
      orElse: () => ClassModel(id: classId, name: 'Class $classId'),
    );
    return classModel.name;
  }

  String _getSubjectName(int subjectId) {
    final subject = _allSubjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => SubjectModel(id: subjectId, name: 'Subject $subjectId'),
    );
    return subject.name;
  }

  @override
  Widget build(BuildContext context) {
    final body = isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)
        ? _buildDesktopPageBody(context)
        : _buildMobilePageBody(context);

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) {
      return body;
    }

    return Scaffold(
      backgroundColor: kBgColor,
      body: body,
    );
  }

  Widget _buildMobilePageBody(BuildContext context) {
    return SafeArea(
      child: Container(
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Class Subjects',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildManagementContent(compact: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPageBody(BuildContext context) {
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
          child: _buildManagementContent(compact: false),
        ),
      ),
    );
  }

  Widget _buildManagementContent({required bool compact}) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: kTextSecondaryColor)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Class',
          style: TextStyle(
            fontSize: compact ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: compact ? kPrimaryBlue : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ClassModel?>(
              value: _selectedClass,
              hint: const Text('Choose a class'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<ClassModel?>(
                  value: null,
                  child: Text('Select a class'),
                ),
                ..._classes.map((classModel) => DropdownMenuItem<ClassModel?>(
                  value: classModel,
                  child: Text(classModel.name),
                )),
              ],
              onChanged: (ClassModel? value) {
                setState(() {
                  _selectedClass = value;
                  _classSubjects = [];
                  _selectedSubjectIds = {};
                });
                if (value != null) {
                  _loadClassSubjects(value.id);
                }
              },
            ),
          ),
        ),
        if (_selectedClass != null) ...[
          const SizedBox(height: 24),
          Text(
            'Manage Subjects for ${_selectedClass!.name}',
            style: TextStyle(
              fontSize: compact ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: compact ? kPrimaryBlue : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingClassSubjects)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
            )
          else ...[
            if (_selectedSubjectIds.isNotEmpty) ...[
              Text(
                'Currently Assigned (${_selectedSubjectIds.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextSecondaryColor),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedSubjectIds.map((subjectId) {
                  return Chip(
                    label: Text(_getSubjectName(subjectId)),
                    backgroundColor: kPrimaryGreen.withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedSubjectIds.remove(subjectId);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Available Subjects',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextSecondaryColor),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8ECF2)),
              ),
              child: ListView(
                shrinkWrap: true,
                children: _allSubjects.map((subject) {
                  final isSelected = _selectedSubjectIds.contains(subject.id);
                  return CheckboxListTile(
                    title: Text(subject.name),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedSubjectIds.add(subject.id);
                        } else {
                          _selectedSubjectIds.remove(subject.id);
                        }
                      });
                    },
                    activeColor: kPrimaryGreen,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveClassSubjects,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving...' : 'Save Subjects'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
