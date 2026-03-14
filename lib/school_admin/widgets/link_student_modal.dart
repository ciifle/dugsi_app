import 'package:flutter/material.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/parents_service.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);

/// Modal to pick a student and link to parent. Uses GET /api/school-admin/students.
/// [alreadyLinkedIds] are excluded from the list.
class LinkStudentModal extends StatefulWidget {
  final int parentId;
  final Set<int> alreadyLinkedIds;
  final VoidCallback? onLinked;

  const LinkStudentModal({
    Key? key,
    required this.parentId,
    required this.alreadyLinkedIds,
    this.onLinked,
  }) : super(key: key);

  @override
  State<LinkStudentModal> createState() => _LinkStudentModalState();
}

class _LinkStudentModalState extends State<LinkStudentModal> {
  List<StudentModel> _allStudents = [];
  List<StudentModel> _filtered = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  bool _submitting = false;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await StudentsService().listStudents();
    if (!mounted) return;
    if (result is StudentError) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    final list = (result as StudentSuccess<List<StudentModel>>).data;
    final available = list.where((s) => !widget.alreadyLinkedIds.contains(s.id)).toList();
    setState(() {
      _allStudents = available;
      _filtered = _applyFilter(available, _searchQuery);
      _loading = false;
    });
  }

  List<StudentModel> _applyFilter(List<StudentModel> list, String q) {
    if (q.isEmpty) return list;
    final lower = q.toLowerCase();
    return list.where((s) {
      return s.studentName.toLowerCase().contains(lower) ||
          s.emisNumber.toLowerCase().contains(lower) ||
          (s.telephone?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _filtered = _applyFilter(_allStudents, value);
    });
  }

  Future<void> _link() async {
    if (_selectedId == null || _submitting) return;
    setState(() => _submitting = true);
    final result = await ParentsService().linkStudent(parentId: widget.parentId, studentId: _selectedId!);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result is ParentSuccess) {
      widget.onLinked?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Linked successfully'), backgroundColor: kPrimaryGreen),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as ParentError).message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Link Student',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name or EMIS...',
                  prefixIcon: const Icon(Icons.search, color: kPrimaryBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryGreen))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _loadStudents,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _filtered.isEmpty
                          ? Center(
                              child: Text(
                                widget.alreadyLinkedIds.isEmpty
                                    ? 'No students available'
                                    : _searchQuery.isEmpty
                                        ? 'All students are already linked'
                                        : 'No students match your search',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final s = _filtered[index];
                                final selected = _selectedId == s.id;
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedId = s.id),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: selected ? kPrimaryBlue.withOpacity(0.08) : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: selected ? Border.all(color: kPrimaryBlue, width: 1.5) : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                            color: selected ? kPrimaryBlue : Colors.grey,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s.studentName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: selected ? kPrimaryBlue : Colors.grey[800],
                                                  ),
                                                ),
                                                Text(
                                                  '${s.emisNumber.trim().isEmpty ? '—' : s.emisNumber} • ${s.classDisplayName}',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_selectedId != null && !_submitting) ? _link : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Link', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
