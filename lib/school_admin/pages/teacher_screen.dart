import 'package:flutter/material.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/pages/edit_teacher_screen.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';

// Project color constants (match teachers list / school admin style)
const Color kDarkBlue = Color(0xFF023471);
const Color kOrange = Color(0xFF5AB04B);
const Color kBackground = Color(0xFFF6F8FA);

class TeacherDetailsPage extends StatelessWidget {
  final int teacherId;

  const TeacherDetailsPage({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
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
                      'Teacher Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kDarkBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<TeacherResult<TeacherModel>>(
        future: TeachersService().getTeacher(teacherId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kOrange));
          }
          if (snapshot.hasError) {
            final userMsg = userFriendlyMessage(snapshot.error!, null, 'TeacherDetailsPage');
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
          final result = snapshot.data;
          if (result == null) {
            return const Center(child: Text('No data'));
          }
          if (result is TeacherError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 12),
                    Text(result.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
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
          final teacher = (result as TeacherSuccess<TeacherModel>).data;
          return _TeacherDetailBody(teacher: teacher);
        },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same style as teachers list: no colored bar, white rounded back button.
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

class _TeacherDetailBody extends StatelessWidget {
  final TeacherModel teacher;

  const _TeacherDetailBody({required this.teacher});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileCard(teacher: teacher),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: EdgeInsets.zero,
            color: Colors.white,
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(icon: Icons.email_outlined, label: 'Email', value: teacher.email),
                  const Divider(height: 24, color: Colors.grey),
                  InfoRow(icon: Icons.phone, label: 'Phone', value: teacher.phone ?? '—'),
                  const Divider(height: 24, color: Colors.grey),
                  InfoRow(icon: Icons.person_outline, label: "Mother's name", value: teacher.motherName ?? '—'),
                  const Divider(height: 24, color: Colors.grey),
                  InfoRow(icon: Icons.school_outlined, label: 'Graduated university', value: teacher.graduatedUniversity ?? '—'),
                  const Divider(height: 24, color: Colors.grey),
                  InfoRow(icon: Icons.wc, label: 'Gender', value: teacher.gender ?? '—'),
                  const Divider(height: 24, color: Colors.grey),
                  InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: teacher.address ?? '—'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => EditTeacherScreen(teacherId: teacher.id),
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
                  onPressed: () => _confirmDelete(context, teacher),
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

  Future<void> _confirmDelete(BuildContext context, TeacherModel teacher) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete teacher?',
      message: 'Delete teacher ${teacher.fullName}? This will also delete the linked user.',
    );
    if (confirmed != true) return;
    final result = await TeachersService().deleteTeacher(teacher.id);
    if (!context.mounted) return;
    if (result is TeacherSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${teacher.fullName} deleted'), backgroundColor: kOrange),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as TeacherError).message), backgroundColor: Colors.red),
      );
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final TeacherModel teacher;

  const _ProfileCard({required this.teacher});

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
                teacher.fullName.isNotEmpty ? teacher.fullName.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kDarkBlue),
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kDarkBlue,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (teacher.gender != null)
                    Text(
                      teacher.gender!,
                      style: TextStyle(
                        color: kDarkBlue.withOpacity(0.92),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: kOrange, size: 22),
        const SizedBox(width: 13),
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              color: kDarkBlue.withOpacity(0.92),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kDarkBlue,
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
