import 'package:flutter/material.dart';
import 'package:kobac/services/academic_performance_service.dart';
import 'package:kobac/student/widgets/student_web_ui.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _currentVisible = false;
  bool _nextVisible = false;
  bool _confirmVisible = false;
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (_next.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await AcademicPerformanceService().changePassword(
      currentPassword: _current.text,
      newPassword: _next.text,
      confirmPassword: _confirm.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result is PerformanceError) {
      final incorrect = result.message.toLowerCase().contains('incorrect');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            incorrect
                ? 'Current password is incorrect. Please contact your principal if you need help resetting your password.'
                : result.message,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _current.clear();
    _next.clear();
    _confirm.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password changed successfully.'),
        backgroundColor: studentWebGreen,
      ),
    );
    Navigator.of(context).pop();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  Widget _field(
    TextEditingController controller,
    String label,
    bool visible,
    VoidCallback toggle,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: _required,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studentWebBg,
      appBar: AppBar(
        backgroundColor: studentWebBg,
        foregroundColor: studentWebBlue,
        elevation: 0,
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Use a strong password that you do not use elsewhere.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: studentWebBlue.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _field(
                          _current,
                          'Current Password',
                          _currentVisible,
                          () => setState(
                            () => _currentVisible = !_currentVisible,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _field(
                          _next,
                          'New Password',
                          _nextVisible,
                          () => setState(() => _nextVisible = !_nextVisible),
                        ),
                        const SizedBox(height: 14),
                        _field(
                          _confirm,
                          'Confirm New Password',
                          _confirmVisible,
                          () => setState(
                            () => _confirmVisible = !_confirmVisible,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: studentWebBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 50),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Change Password'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.help_outline_rounded, color: Colors.amber),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Forgot your current password? Ask your principal to reset it for you.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
