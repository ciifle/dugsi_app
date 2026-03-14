import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/dummy_school_service.dart';
import 'package:kobac/printing/student_letter_pdf.dart';
import 'package:kobac/school_admin/pages/edit_student_screen.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';

const Color kDarkBlue = Color(0xFF023471);
const Color kOrange = Color(0xFF5AB04B);
const Color kBackground = Color(0xFFF6F8FA);

class StudentDetailPage extends StatelessWidget {
  final int studentId;

  const StudentDetailPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2F5F9), Color(0xFFE8ECF2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    _BackButton(onPressed: () => Navigator.of(context).maybePop()),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Student Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kDarkBlue),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
              child: FutureBuilder<_StudentDetailData>(
                future: _loadStudentDetailData(studentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kOrange));
                  }
                  if (snapshot.hasError) {
                    final userMsg = userFriendlyMessage(snapshot.error!, null, 'StudentDetailPage');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 12),
                            Text(userMsg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final data = snapshot.data;
                  if (data == null) return const Center(child: Text('No data'));
                  if (data.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 12),
                            Text(data.error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return _StudentDetailBody(
                    student: data.student!,
                    classesById: data.classesById,
                    fallbackSchoolNameFuture: (data.student!.schoolName == null || data.student!.schoolName!.isEmpty)
                        ? _getAdminSchoolName(context)
                        : null,
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

  /// Load student + classes list for class name fallback.
  static Future<_StudentDetailData> _loadStudentDetailData(int studentId) async {
    final studentResult = await StudentsService().getStudent(studentId);
    if (studentResult is StudentError) {
      return _StudentDetailData(error: studentResult.message);
    }
    final student = (studentResult as StudentSuccess<StudentModel>).data;
    final classesResult = await ClassesService().listClasses();
    final classesById = <int, String>{};
    if (classesResult is ClassSuccess<List<ClassModel>>) {
      for (final c in classesResult.data) {
        classesById[c.id] = c.name;
      }
    }
    return _StudentDetailData(student: student, classesById: classesById);
  }

  /// Fallback school name when API does not return it (e.g. from admin's school).
  static Future<String?> _getAdminSchoolName(BuildContext context) async {
    try {
      final auth = context.read<AuthProvider>();
      final schoolId = auth.user?.schoolId ?? auth.schoolAdminProfile?.schoolId;
      if (schoolId == null) return null;
      final school = await DummySchoolService().getSchoolById(schoolId.toString());
      return school?.name;
    } catch (_) {
      return null;
    }
  }
}

class _StudentDetailData {
  final StudentModel? student;
  final Map<int, String> classesById;
  final String? error;
  _StudentDetailData({this.student, Map<int, String>? classesById, this.error})
      : classesById = classesById ?? {};
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
          boxShadow: [BoxShadow(color: kDarkBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.arrow_back_rounded, color: kDarkBlue, size: 24),
      ),
    );
  }
}

class _StudentDetailBody extends StatelessWidget {
  final StudentModel student;
  final Map<int, String> classesById;
  final Future<String?>? fallbackSchoolNameFuture;

  const _StudentDetailBody({
    required this.student,
    required this.classesById,
    this.fallbackSchoolNameFuture,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileCard(student: student, classesById: classesById),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Personal',
            children: [
              _InfoRow(label: 'EMIS Number', value: student.emisNumber.trim().isEmpty ? '—' : student.emisNumber),
              _InfoRow(label: 'Student Name', value: student.studentName),
              _InfoRow(label: 'Sex', value: student.sex ?? '—'),
              _InfoRow(label: 'Birth Date', value: student.birthDate ?? '—'),
              _InfoRow(label: 'Age', value: student.age?.toString() ?? '—'),
              _InfoRow(label: 'Nationality', value: student.nationality ?? '—'),
              _InfoRow(label: 'Birth Place', value: student.birthPlace ?? '—'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Family',
            children: [
              _InfoRow(label: "Mother's name", value: student.motherName ?? '—'),
              _InfoRow(label: 'Guardian', value: student.guardianName ?? '—'),
              _InfoRow(label: 'Refugee Status', value: student.refugeeStatus ?? '—'),
              _InfoRow(label: 'Orphan Status', value: student.orphanStatus ?? '—'),
              _InfoRow(label: 'Disability', value: student.disabilityStatus ?? '—'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Contact & Location',
            children: [
              _InfoRow(label: 'Telephone', value: student.telephone ?? '—'),
              _InfoRow(label: 'State', value: student.studentState ?? '—'),
              _InfoRow(label: 'District', value: student.studentDistrict ?? '—'),
              _InfoRow(label: 'Village', value: student.studentVillage ?? '—'),
            ],
          ),
          const SizedBox(height: 16),
          _SchoolSection(
            student: student,
            classesById: classesById,
            fallbackSchoolNameFuture: fallbackSchoolNameFuture,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _printStudentLetter(context, student),
                  icon: const Icon(Icons.print_rounded, size: 20),
                  label: const Text('Print Letter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kDarkBlue,
                    side: const BorderSide(color: kDarkBlue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => EditStudentScreen(studentId: student.id),
                      ),
                    );
                    if (result == true && context.mounted) Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, student),
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[700]),
                  label: Text('Delete', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _printStudentLetter(BuildContext context, StudentModel student) async {
    try {
      final pdfBytes = await buildStudentLetterPdf(
        student: student,
        classModel: null,
        schoolName: student.schoolName,
      );
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, StudentModel student) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete student?',
      message: 'Delete student ${student.studentName}? This will also delete the linked user.',
    );
    if (confirmed != true) return;
    final result = await StudentsService().deleteStudent(student.id);
    if (!context.mounted) return;
    if (result is StudentSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${student.studentName} deleted'), backgroundColor: kOrange),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as StudentError).message), backgroundColor: Colors.red),
      );
    }
  }
}

/// School section: School name (API, "School #id", or auth fallback) and Class name (Class.name or classesById lookup).
class _SchoolSection extends StatelessWidget {
  final StudentModel student;
  final Map<int, String> classesById;
  final Future<String?>? fallbackSchoolNameFuture;

  const _SchoolSection({
    required this.student,
    required this.classesById,
    this.fallbackSchoolNameFuture,
  });

  String get _className {
    final fromClass = student.classDisplayName;
    if (fromClass.isNotEmpty && fromClass != '—') return fromClass;
    if (student.classId != null && classesById.containsKey(student.classId)) {
      return classesById[student.classId]!;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final schoolLabel = student.schoolName != null && student.schoolName!.isNotEmpty
        ? student.schoolName!
        : (student.schoolId != null ? 'School #${student.schoolId}' : '—');
    if (fallbackSchoolNameFuture == null) {
      return _SectionCard(
        title: 'School',
        children: [
          _InfoRow(label: 'School', value: schoolLabel),
          _InfoRow(label: 'Class', value: _className),
          _InfoRow(label: 'Absenteeism', value: student.absenteeismStatus ?? '—'),
        ],
      );
    }
    return FutureBuilder<String?>(
      future: fallbackSchoolNameFuture,
      builder: (context, snapshot) {
        final schoolName = schoolLabel != '—'
            ? schoolLabel
            : (snapshot.data ?? '—');
        return _SectionCard(
          title: 'School',
          children: [
            _InfoRow(label: 'School', value: schoolName),
            _InfoRow(label: 'Class', value: _className),
            _InfoRow(label: 'Absenteeism', value: student.absenteeismStatus ?? '—'),
          ],
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final StudentModel student;
  final Map<int, String> classesById;

  const _ProfileCard({required this.student, required this.classesById});

  String get _className {
    final fromClass = student.classDisplayName;
    if (fromClass.isNotEmpty && fromClass != '—') return fromClass;
    if (student.classId != null && classesById.containsKey(student.classId)) {
      return classesById[student.classId]!;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: kOrange.withOpacity(0.1),
              child: Text(
                student.studentName.isNotEmpty ? student.studentName.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kDarkBlue),
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kDarkBlue,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    student.emisNumber.trim().isEmpty ? 'EMIS: —' : 'EMIS: ${student.emisNumber}',
                    style: TextStyle(
                      color: kDarkBlue.withOpacity(0.92),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_className.isNotEmpty)
                    Text(
                      _className,
                      style: TextStyle(
                        color: kDarkBlue.withOpacity(0.8),
                        fontSize: 14,
                      ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kDarkBlue,
              ),
            ),
            const SizedBox(height: 12),
            ...children.asMap().entries.map((e) {
              return Column(
                children: [
                  if (e.key > 0) const Divider(height: 20, color: Colors.grey),
                  e.value,
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: kDarkBlue.withOpacity(0.92),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: kDarkBlue, fontSize: 15),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
