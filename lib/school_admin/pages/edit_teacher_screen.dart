import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);

class EditTeacherScreen extends StatefulWidget {
  final int teacherId;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const EditTeacherScreen({
    super.key, 
    required this.teacherId,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<EditTeacherScreen> createState() => _EditTeacherScreenState();
}

class _EditTeacherScreenState extends State<EditTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _motherName = TextEditingController();
  final _graduatedUniversity = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  String _gender = 'Male';
  bool _loading = true;
  bool _submitting = false;
  bool _obscureDesktopPassword = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
  }

  Future<void> _loadTeacher() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await TeachersService().getTeacher(widget.teacherId);
    if (!mounted) return;
    if (result is TeacherError) {
      setState(() {
        _loading = false;
        _loadError = result.message;
      });
      return;
    }
    final t = (result as TeacherSuccess<TeacherModel>).data;
    _fullName.text = t.fullName;
    _email.text = t.email;
    _phone.text = t.phone ?? '';
    _motherName.text = t.motherName ?? '';
    _graduatedUniversity.text = t.graduatedUniversity ?? '';
    _address.text = t.address ?? '';
    _gender = t.gender == 'Female' ? 'Female' : 'Male';
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _motherName.dispose();
    _graduatedUniversity.dispose();
    _address.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _emailFormat(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v)) return 'Invalid email';
    return null;
  }
  String? _passwordOptional(String? v) {
    if (v != null && v.isNotEmpty && v.length < 8) return 'At least 8 characters';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    final payload = updateTeacherPayload(
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      motherName: _motherName.text.trim(),
      graduatedUniversity: _graduatedUniversity.text.trim(),
      gender: _gender,
      address: _address.text.trim(),
      password: _password.text.isEmpty ? null : _password.text,
    );
    final result = await TeachersService().updateTeacher(widget.teacherId, payload);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result is TeacherSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher updated'), backgroundColor: kPrimaryGreen),
      );
      final isDesktop = isDesktopWebAdminLayout(context);
      if (isDesktop && widget.onNavigateToPage != null) {
        widget.onNavigateToPage!('teachers');
      } else {
        Navigator.of(context).pop(true);
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text((result as TeacherError).message), backgroundColor: Colors.red),
    );
  }

  Widget _buildTopBar(String title) {
    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          if (!isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) {
      return _buildEditTeacherBody(context);
    }

    final body = Container(
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
            _buildTopBar('Edit Teacher'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryGreen))
                  : _loadError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_loadError!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                                const SizedBox(height: 16),
                                TextButton.icon(onPressed: _loadTeacher, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                              ],
                            ),
                          ),
                        )
                      : Form(
                          key: _formKey,
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              FormCard(
                                child: FormSection(
                                  title: 'Personal Info',
                                  children: [
                                    Input3D(controller: _fullName, label: 'Full name', validator: _required, textCapitalization: TextCapitalization.words),
                                    const SizedBox(height: 18),
                                    Input3D(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress, validator: _emailFormat),
                                    const SizedBox(height: 18),
                                    Input3D(controller: _phone, label: 'Phone', keyboardType: TextInputType.phone, validator: _required),
                                    const SizedBox(height: 18),
                                    Input3D(controller: _motherName, label: "Mother's name", validator: _required, textCapitalization: TextCapitalization.words),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              FormCard(
                                child: FormSection(
                                  title: 'Professional & Contact',
                                  children: [
                                    Input3D(controller: _graduatedUniversity, label: 'Graduated university', validator: _required, textCapitalization: TextCapitalization.words),
                                    const SizedBox(height: 18),
                                    Select3D<String>(
                                      value: _gender,
                                      label: 'Gender',
                                      items: const [
                                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                                      ],
                                      onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                                    ),
                                    const SizedBox(height: 18),
                                    Input3D(controller: _address, label: 'Address', validator: _required),
                                    const SizedBox(height: 18),
                                    PasswordInput3D(
                                      controller: _password,
                                      label: 'New password (leave blank to keep current)',
                                      validator: _passwordOptional,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              PrimaryButton3D(label: 'Save', onPressed: _submit, loading: _submitting),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
    return Scaffold(body: body);
  }

  Widget _buildEditTeacherBody(BuildContext context) {
    if (_loading) {
      return Container(
        color: kBgColor,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: kPrimaryBlue),
      );
    }
    if (_loadError != null) {
      return Container(
        color: kBgColor,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_loadError!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              const SizedBox(height: 16),
              TextButton.icon(onPressed: _loadTeacher, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Container(
      color: kBgColor,
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
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final fieldWidth = isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;

                Widget field(Widget child) {
                  return SizedBox(width: fieldWidth, child: child);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 24,
                      runSpacing: 20,
                      children: [
                        field(_desktopTextField(controller: _fullName, label: 'Full name', validator: _required, textCapitalization: TextCapitalization.words)),
                        field(_desktopTextField(controller: _email, label: 'Email', validator: _emailFormat, keyboardType: TextInputType.emailAddress)),
                        field(_desktopTextField(controller: _phone, label: 'Phone', validator: _required, keyboardType: TextInputType.phone)),
                        field(_desktopTextField(controller: _motherName, label: "Mother's name", validator: _required, textCapitalization: TextCapitalization.words)),
                        field(_desktopTextField(controller: _graduatedUniversity, label: 'Graduated university', validator: _required, textCapitalization: TextCapitalization.words)),
                        field(_desktopSelectField<String>(
                          value: _gender,
                          label: 'Gender',
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                          ],
                          onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                        )),
                        field(_desktopTextField(controller: _address, label: 'Address', validator: _required)),
                        field(_desktopPasswordField()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isWide)
                      Row(
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () {
                                      if (widget.onNavigateToPage != null) {
                                        widget.onNavigateToPage!('teachers');
                                      } else {
                                        Navigator.of(context).pop();
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: fieldWidth,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Save'),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () {
                                      if (widget.onNavigateToPage != null) {
                                        widget.onNavigateToPage!('teachers');
                                      } else {
                                        Navigator.of(context).pop();
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: fieldWidth,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _desktopInputDecoration(String label) {
    const borderGray = Color(0xFFE5E7EB);

    OutlineInputBorder outline(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: outline(borderGray),
      enabledBorder: outline(borderGray),
      focusedBorder: outline(kPrimaryBlue, width: 2),
      errorBorder: outline(Colors.red),
      focusedErrorBorder: outline(Colors.red, width: 2),
    );
  }

  Widget _desktopTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: _desktopInputDecoration(label),
    );
  }

  Widget _desktopSelectField<T>({
    required T? value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      decoration: _desktopInputDecoration(label),
    );
  }

  Widget _desktopPasswordField() {
    return TextFormField(
      controller: _password,
      validator: _passwordOptional,
      obscureText: _obscureDesktopPassword,
      decoration: _desktopInputDecoration('New password (leave blank to keep current)').copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscureDesktopPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: kPrimaryBlue,
            size: 22,
          ),
          onPressed: () => setState(() => _obscureDesktopPassword = !_obscureDesktopPassword),
        ),
      ),
    );
  }
}
