import 'package:flutter/material.dart';
import 'package:kobac/services/parents_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/pages/edit_parent_screen.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/school_admin/widgets/link_student_modal.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);

class ParentDetailScreen extends StatefulWidget {
  final int parentId;

  const ParentDetailScreen({Key? key, required this.parentId}) : super(key: key);

  @override
  State<ParentDetailScreen> createState() => _ParentDetailScreenState();
}

class _ParentDetailScreenState extends State<ParentDetailScreen> {
  late Future<ParentResult<ParentModel>> _parentFuture;

  @override
  void initState() {
    super.initState();
    _loadParent();
  }

  void _loadParent() {
    setState(() {
      _parentFuture = ParentsService().getParent(widget.parentId);
    });
  }

  Future<void> _openLinkStudent(ParentModel parent) async {
    final linked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LinkStudentModal(
        parentId: parent.id,
        alreadyLinkedIds: parent.linkedStudents.map((s) => s.id).toSet(),
        onLinked: () {
          Navigator.of(ctx).pop(true);
        },
      ),
    );
    if (linked == true) _loadParent();
  }

  Future<void> _unlinkStudent(ParentModel parent, int studentId, String studentName) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Unlink student?',
      message: 'Unlink $studentName from ${parent.name}?',
    );
    if (confirmed != true) return;
    final result = await ParentsService().unlinkStudent(parentId: parent.id, studentId: studentId);
    if (!mounted) return;
    if (result is ParentSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlinked'), backgroundColor: kPrimaryGreen),
      );
      _loadParent();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as ParentError).message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteParent(ParentModel parent) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete parent?',
      message: 'Delete parent ${parent.name}? This will delete the user and unlink from all students.',
    );
    if (confirmed != true) return;
    final result = await ParentsService().deleteParent(parent.id);
    if (!mounted) return;
    if (result is ParentSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${parent.name} deleted'), backgroundColor: kPrimaryGreen),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as ParentError).message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
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
                        'Parent Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<ParentResult<ParentModel>>(
                  future: _parentFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                    }
                    if (snapshot.hasError) {
                      final userMsg = userFriendlyMessage(snapshot.error!, null, 'ParentDetailScreen');
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
                    if (result == null) return const Center(child: Text('No data'));
                    if (result is ParentError) {
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
                    final parent = (result as ParentSuccess<ParentModel>).data;
                    return _ParentDetailBody(
                      parent: parent,
                      onEdit: () async {
                        final ok = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => EditParentScreen(parentId: parent.id),
                          ),
                        );
                        if (ok == true) _loadParent();
                      },
                      onDelete: () => _deleteParent(parent),
                      onLinkStudent: () => _openLinkStudent(parent),
                      onUnlinkStudent: (studentId, studentName) => _unlinkStudent(parent, studentId, studentName),
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

class _ParentDetailBody extends StatelessWidget {
  final ParentModel parent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLinkStudent;
  final void Function(int studentId, String studentName) onUnlinkStudent;

  const _ParentDetailBody({
    required this.parent,
    required this.onEdit,
    required this.onDelete,
    required this.onLinkStudent,
    required this.onUnlinkStudent,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileCard(parent: parent),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Info',
            children: [
              _InfoRow(label: 'Name', value: parent.name),
              _InfoRow(label: 'Email', value: parent.email),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Linked Students',
            trailing: TextButton.icon(
              onPressed: onLinkStudent,
              icon: const Icon(Icons.person_add_rounded, size: 20, color: kPrimaryGreen),
              label: const Text('Link Student', style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.w600)),
            ),
            children: [
              if (parent.linkedStudents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No students linked. Tap "Link Student" to add.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                )
              else
                ...parent.linkedStudents.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.studentName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kPrimaryBlue),
                              ),
                              if (s.emisNumber != null && s.emisNumber!.isNotEmpty)
                                Text('EMIS: ${s.emisNumber}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              if (s.className != null && s.className!.isNotEmpty)
                                Text('Class: ${s.className}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => onUnlinkStudent(s.id, s.studentName),
                          child: Text('Unlink', style: TextStyle(fontSize: 13, color: Colors.red[700], fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
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
}

class _ProfileCard extends StatelessWidget {
  final ParentModel parent;

  const _ProfileCard({required this.parent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: kPrimaryGreen.withOpacity(0.1),
            child: Text(
              parent.name.isNotEmpty ? parent.name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kPrimaryBlue),
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parent.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kPrimaryBlue, letterSpacing: 0.2),
                ),
                const SizedBox(height: 7),
                Text(
                  parent.email,
                  style: TextStyle(color: kPrimaryBlue.withOpacity(0.92), fontSize: 16, fontWeight: FontWeight.w500),
                ),
                if (parent.linkedStudents.isNotEmpty)
                  Text(
                    '${parent.linkedStudents.length} student${parent.linkedStudents.length == 1 ? '' : 's'} linked',
                    style: TextStyle(color: kPrimaryBlue.withOpacity(0.8), fontSize: 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: kPrimaryBlue, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
