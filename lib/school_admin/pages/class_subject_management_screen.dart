import 'package:flutter/material.dart';
import 'package:kobac/services/class_subjects_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const Color kTextSecondaryColor = Color(0xFF636E72);
const double kCardRadius = 28.0;

class ClassSubjectManagementScreen extends StatefulWidget {
  final int classId;
  final String className;

  const ClassSubjectManagementScreen({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  State<ClassSubjectManagementScreen> createState() => _ClassSubjectManagementScreenState();
}

class _ClassSubjectManagementScreenState extends State<ClassSubjectManagementScreen> {
  late Future<ClassSubjectResult<List<ClassSubjectModel>>> _classSubjectsFuture;
  late Future<SubjectResult<List<SubjectModel>>> _allSubjectsFuture;
  Set<int> _selectedSubjectIds = {};
  bool _loading = false;
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
      final classSubjectsResult = await ClassSubjectsService().listClassSubjects(classId: widget.classId);
      final allSubjectsResult = await SubjectsService().listSubjects();
      
      if (!mounted) return;
      
      if (classSubjectsResult is ClassSubjectError) {
        setState(() {
          _loading = false;
          _error = (classSubjectsResult as ClassSubjectError).message;
        });
        return;
      }
      
      if (allSubjectsResult is SubjectError) {
        setState(() {
          _loading = false;
          _error = (allSubjectsResult as SubjectError).message;
        });
        return;
      }
      
      final classSubjects = (classSubjectsResult as ClassSubjectSuccess<List<ClassSubjectModel>>).data;
      final allSubjects = (allSubjectsResult as SubjectSuccess<List<SubjectModel>>).data;
      
      // Pre-select currently assigned subjects
      _selectedSubjectIds = classSubjects.map((cs) => cs.subjectId).toSet();
      
      setState(() {
        _classSubjectsFuture = Future.value(ClassSubjectSuccess(classSubjects));
        _allSubjectsFuture = Future.value(SubjectSuccess(allSubjects));
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = userFriendlyMessage(e, st, 'ClassSubjectManagementScreen');
      });
    }
  }

  Future<void> _saveClassSubjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final data = {
        'subject_ids': _selectedSubjectIds.toList(),
      };
      
      final result = await ClassSubjectsService().createClassSubject(data);
      
      if (!mounted) return;
      
      if (result is ClassSubjectError) {
        setState(() {
          _loading = false;
          _error = (result as ClassSubjectError).message;
        });
        return;
      }
      
      setState(() {
        _loading = false;
        _error = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class subjects updated successfully'), backgroundColor: kPrimaryGreen),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = userFriendlyMessage(e, st, 'ClassSubjectManagementScreen');
      });
    }
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manage Subjects',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.className,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryBlue,
                            ),
                          ),
                        ],
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
                        : FutureBuilder(
                            future: Future.wait([_classSubjectsFuture, _allSubjectsFuture]),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select subjects for this class:',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kPrimaryBlue),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Available Subjects
                                    FutureBuilder<SubjectResult<List<SubjectModel>>>(
                                      future: _allSubjectsFuture,
                                      builder: (context, subjectsSnapshot) {
                                        if (subjectsSnapshot.data is SubjectSuccess<List<SubjectModel>>) {
                                          final subjects = (subjectsSnapshot.data as SubjectSuccess<List<SubjectModel>>).data;
                                          return Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: subjects.map((subject) {
                                              final isSelected = _selectedSubjectIds.contains(subject.id);
                                              return FilterChip(
                                                label: Text(subject.name),
                                                selected: isSelected,
                                                onSelected: (selected) {
                                                  setState(() {
                                                    if (selected) {
                                                      _selectedSubjectIds.add(subject.id);
                                                    } else {
                                                      _selectedSubjectIds.remove(subject.id);
                                                    }
                                                  });
                                                },
                                                backgroundColor: isSelected ? kPrimaryGreen : Colors.grey[200],
                                                labelStyle: TextStyle(
                                                  color: isSelected ? Colors.white : kTextSecondaryColor,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Save Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _selectedSubjectIds.isEmpty ? null : _saveClassSubjects,
                                        icon: _loading ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ) : const Icon(Icons.save_rounded),
                                        label: Text(_loading ? 'Saving...' : 'Save Subjects'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _selectedSubjectIds.isEmpty ? Colors.grey : kPrimaryGreen,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
