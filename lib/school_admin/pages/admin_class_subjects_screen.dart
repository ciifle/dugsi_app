import 'package:flutter/material.dart';
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
  const AdminClassSubjectsScreen({Key? key}) : super(key: key);

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
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
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
              // Header
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
              
              // Content
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
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
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(20),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                // Class Selector
                                Text(
                                  'Select Class:',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kPrimaryBlue),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
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
                                
                                const SizedBox(height: 24),
                                
                                // Subject Management
                                if (_selectedClass != null) ...[
                                  Text(
                                    'Manage Subjects for ${_selectedClass!.name}:',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kPrimaryBlue),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  if (_loadingClassSubjects)
                                    const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
                                  else ...[
                                    // Currently Assigned Subjects
                                    if (_selectedSubjectIds.isNotEmpty) ...[
                                      Text(
                                        'Currently Assigned (${_selectedSubjectIds.length}):',
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
                                    
                                    // Available Subjects
                                    Text(
                                      'Available Subjects:',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextSecondaryColor),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      constraints: const BoxConstraints(maxHeight: 300),
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
                                    
                                    // Save Button
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
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
                                          backgroundColor: kPrimaryGreen,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                                ],
                              ),
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
