import 'package:flutter/material.dart';
import 'package:kobac/services/academic_performance_service.dart';
import 'package:kobac/services/students_service.dart';

Future<bool?> showResetStudentPasswordDialog(
  BuildContext context,
  StudentModel student,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ResetStudentPasswordDialog(student: student),
  );
}

class _ResetStudentPasswordDialog extends StatefulWidget {
  final StudentModel student;
  const _ResetStudentPasswordDialog({required this.student});

  @override
  State<_ResetStudentPasswordDialog> createState() =>
      _ResetStudentPasswordDialogState();
}

class _ResetStudentPasswordDialogState
    extends State<_ResetStudentPasswordDialog> {
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _visible = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_newPassword.text.trim().isEmpty ||
        _confirmPassword.text.trim().isEmpty) {
      setState(() => _error = 'Both password fields are required.');
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await AcademicPerformanceService().resetStudentPassword(
      studentId: widget.student.id,
      newPassword: _newPassword.text,
      confirmPassword: _confirmPassword.text,
    );
    if (!mounted) return;
    if (result is PerformanceError) {
      setState(() {
        _submitting = false;
        _error = result.message;
      });
      return;
    }
    _newPassword.clear();
    _confirmPassword.clear();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Reset Student Password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF023471),
              ),
            ),
            const SizedBox(height: 10),
            Text(widget.student.studentName),
            if (widget.student.emisNumber.isNotEmpty)
              Text('EMIS ${widget.student.emisNumber}'),
            const SizedBox(height: 18),
            TextField(
              controller: _newPassword,
              obscureText: !_visible,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _visible = !_visible),
                  icon: Icon(
                    _visible ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPassword,
              obscureText: !_visible,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            const Text(
              'The student will use the new password on their next login.',
              style: TextStyle(color: Colors.amber),
            ),
            const SizedBox(height: 18),
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
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5AB04B),
                      foregroundColor: Colors.white,
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
                        : const Text('Reset Password'),
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
