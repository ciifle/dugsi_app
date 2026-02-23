import 'package:flutter/material.dart';
import 'package:kobac/services/local_auth_service.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFE8ECF2);
const double kCardRadius = 20.0;

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final ok = await LocalAuthService().changePassword(
      _currentController.text.trim(),
      _newController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password changed successfully'),
          backgroundColor: kPrimaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Current password is incorrect'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: kPrimaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: kPrimaryBlue, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kPrimaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.white, blurRadius: 6, offset: const Offset(-2, -2)),
                              BoxShadow(color: kPrimaryBlue.withOpacity(0.15), blurRadius: 10, offset: const Offset(2, 2)),
                            ],
                          ),
                          child: const Icon(Icons.lock_rounded, color: kPrimaryBlue, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Update your password',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Current password'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _currentController,
                      hint: 'Enter current password',
                      obscure: _obscureCurrent,
                      prefixIcon: Icons.lock_outline_rounded,
                      onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('New password'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _newController,
                      hint: 'Enter new password',
                      obscure: _obscureNew,
                      prefixIcon: Icons.lock_reset_rounded,
                      onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Confirm new password'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _confirmController,
                      hint: 'Confirm new password',
                      obscure: _obscureConfirm,
                      prefixIcon: Icons.lock_reset_rounded,
                      onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v != _newController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    _buildSubmitButton(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.white, blurRadius: 18, offset: const Offset(-6, -6), spreadRadius: 0.5),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 28, offset: const Offset(10, 12)),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(5, 8)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required IconData prefixIcon,
    required VoidCallback onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        prefixIcon: Icon(prefixIcon, color: kPrimaryBlue, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey.shade600,
            size: 22,
          ),
          onPressed: onToggleObscure,
        ),
        filled: true,
        fillColor: kBgColor.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : _submit,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A4A8C), kPrimaryBlue],
            ),
            borderRadius: BorderRadius.circular(kCardRadius),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.white.withOpacity(0.25), blurRadius: 8, offset: const Offset(-2, -2)),
              BoxShadow(color: kPrimaryBlue.withOpacity(0.4), blurRadius: 16, offset: const Offset(4, 6)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else ...[
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  _loading ? 'Updating...' : 'Change Password',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
