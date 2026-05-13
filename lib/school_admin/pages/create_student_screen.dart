import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:flutter/services.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';
import 'package:kobac/widgets/form_3d/date_picker_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);

class CreateStudentScreen extends StatefulWidget {
  final int? initialClassId;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const CreateStudentScreen({
    super.key, 
    this.initialClassId,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<CreateStudentScreen> createState() => _CreateStudentScreenState();
}

class _CreateStudentScreenState extends State<CreateStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emisNumber = TextEditingController();
  final _studentName = TextEditingController();
  final _motherName = TextEditingController();
  final _telephone = TextEditingController();
  final _birthPlace = TextEditingController();
  final _nationality = TextEditingController();
  final _studentState = TextEditingController();
  final _studentDistrict = TextEditingController();
  final _studentVillage = TextEditingController();
  final _guardianName = TextEditingController();
  final _schoolName = TextEditingController();
  final _className = TextEditingController();
  final _password = TextEditingController();
  final _ageController = TextEditingController();

  String _refugeeStatus = 'Not Refugee';
  String _orphanStatus = 'Not Orphan';
  String _sex = 'Male';
  String _disabilityStatus = 'No Disability';
  String _absenteeismStatus = 'Active';
  String _birthDate = '';
  String? _birthDateError;
  bool _submitting = false;
  bool _obscureDesktopPassword = true;
  List<ClassModel> _classes = [];
  int? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final result = await ClassesService().listClasses();
    if (!mounted) return;
    if (result is ClassSuccess<List<ClassModel>>) {
      setState(() {
        _classes = result.data;
        if (_selectedClassId == null && widget.initialClassId != null) {
          _selectedClassId = widget.initialClassId;
        }
      });
    }
  }

  @override
  void dispose() {
    _emisNumber.dispose();
    _studentName.dispose();
    _motherName.dispose();
    _telephone.dispose();
    _birthPlace.dispose();
    _nationality.dispose();
    _studentState.dispose();
    _studentDistrict.dispose();
    _studentVillage.dispose();
    _guardianName.dispose();
    _schoolName.dispose();
    _className.dispose();
    _password.dispose();
    _ageController.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _passwordLength(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < 8) return 'At least 8 characters';
    return null;
  }
  String? _ageValid(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = int.tryParse(v);
    if (n == null || n < 1 || n > 120) return 'Enter valid age (1–120)';
    return null;
  }

  String get _effectiveClassName {
    if (_selectedClassId != null) {
      try {
        return _classes.firstWhere((c) => c.id == _selectedClassId).name;
      } catch (_) {}
    }
    return _className.text.trim();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate.isNotEmpty ? _parseDate(_birthDate) ?? now : now.subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthDate = _formatDate(picked);
        _birthDateError = null;
      });
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(String s) {
    if (s.length != 10) return null;
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  Future<void> _submit() async {
    setState(() => _birthDateError = null);
    if (!_formKey.currentState!.validate() || _submitting) return;
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 1 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid age (1–120)'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_birthDate.isEmpty) {
      setState(() => _birthDateError = 'Select birth date');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select birth date'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await StudentsService().createStudent(
      createStudentPayload(
        emisNumber: _emisNumber.text.trim(),
        studentName: _studentName.text.trim(),
        motherName: _motherName.text.trim(),
        refugeeStatus: _refugeeStatus,
        orphanStatus: _orphanStatus,
        birthDate: _birthDate,
        sex: _sex,
        telephone: _telephone.text.trim(),
        birthPlace: _birthPlace.text.trim(),
        nationality: _nationality.text.trim(),
        studentState: _studentState.text.trim(),
        studentDistrict: _studentDistrict.text.trim(),
        studentVillage: _studentVillage.text.trim(),
        disabilityStatus: _disabilityStatus,
        guardianName: _guardianName.text.trim(),
        schoolName: _schoolName.text.trim(),
        className: _effectiveClassName,
        age: age,
        absenteeismStatus: _absenteeismStatus,
        password: _password.text,
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result is StudentSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student created'), backgroundColor: kPrimaryGreen),
      );
      final isDesktop = isDesktopWebAdminLayout(context);
      if (isDesktop && widget.onNavigateToPage != null) {
        widget.onNavigateToPage!('students');
      } else {
        Navigator.of(context).pop(true);
      }
      return;
    }
    final err = result as StudentError;
    final msg = err.message.trim().isNotEmpty
        ? err.message
        : (err.statusCode == 409 ? 'EMIS number already exists.' : 'Something went wrong. Please try again.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Widget _buildTopBar(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
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
      return _buildCreateStudentBody(context);
    }

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
              _buildTopBar('Add Student'),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      FormCard(
                        child: FormSection(
                          title: 'Personal Info',
                          children: [
                            Input3D(controller: _emisNumber, label: 'EMIS Number', validator: _required),
                            const SizedBox(height: 18),
                            Input3D(controller: _studentName, label: 'Student Name', validator: _required, textCapitalization: TextCapitalization.words),
                            const SizedBox(height: 18),
                            Input3D(controller: _motherName, label: "Mother's Name", validator: _required, textCapitalization: TextCapitalization.words),
                            const SizedBox(height: 18),
                            Select3D<String>(
                              value: _refugeeStatus,
                              label: 'Refugee Status',
                              items: const [
                                DropdownMenuItem(value: 'Refugee', child: Text('Refugee')),
                                DropdownMenuItem(value: 'Not Refugee', child: Text('Not Refugee')),
                              ],
                              onChanged: (v) => setState(() => _refugeeStatus = v ?? 'Not Refugee'),
                            ),
                            const SizedBox(height: 18),
                            Select3D<String>(
                              value: _orphanStatus,
                              label: 'Orphan Status',
                              items: const [
                                DropdownMenuItem(value: 'Orphan', child: Text('Orphan')),
                                DropdownMenuItem(value: 'Not Orphan', child: Text('Not Orphan')),
                              ],
                              onChanged: (v) => setState(() => _orphanStatus = v ?? 'Not Orphan'),
                            ),
                            const SizedBox(height: 18),
                            Select3D<String>(
                              value: _sex,
                              label: 'Gender',
                              items: const [
                                DropdownMenuItem(value: 'Male', child: Text('Male')),
                                DropdownMenuItem(value: 'Female', child: Text('Female')),
                              ],
                              onChanged: (v) => setState(() => _sex = v ?? 'Male'),
                            ),
                            const SizedBox(height: 18),
                            Select3D<String>(
                              value: _disabilityStatus,
                              label: 'Disability Status',
                              items: const [
                                DropdownMenuItem(value: 'No Disability', child: Text('No Disability')),
                                DropdownMenuItem(value: 'Disabled', child: Text('Disabled')),
                              ],
                              onChanged: (v) => setState(() => _disabilityStatus = v ?? 'No Disability'),
                            ),
                            const SizedBox(height: 18),
                            DatePicker3D(
                              label: 'Date of Birth',
                              value: _birthDate,
                              initialDate: _birthDate.isNotEmpty ? _parseDate(_birthDate) : null,
                              firstDate: DateTime(1990),
                              lastDate: DateTime.now(),
                              onDatePicked: (date) {
                                setState(() {
                                  _birthDate = _formatDate(date);
                                  _birthDateError = null;
                                });
                              },
                              errorText: _birthDateError,
                            ),
                            const SizedBox(height: 18),
                            Input3D(controller: _birthPlace, label: 'Birth Place', validator: _required),
                            const SizedBox(height: 18),
                            Input3D(controller: _nationality, label: 'Nationality', validator: _required),
                            const SizedBox(height: 18),
                            Input3D(controller: _studentState, label: 'State', validator: _required),
                            const SizedBox(height: 18),
                            Input3D(controller: _studentDistrict, label: 'District', validator: _required),
                            const SizedBox(height: 18),
                            Input3D(controller: _studentVillage, label: 'Village', validator: _required),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FormCard(
                        child: FormSection(
                          title: 'Academic Info',
                          children: [
                            Input3D(controller: _guardianName, label: 'Guardian Name', validator: _required),
                            const SizedBox(height: 18),
                            Input3D(controller: _schoolName, label: 'School Name', validator: _required),
                            const SizedBox(height: 18),
                            Select3D<int>(
                              value: _selectedClassId,
                              label: 'Class',
                              items: _classes.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name))).toList(),
                              onChanged: (v) => setState(() => _selectedClassId = v),
                            ),
                            const SizedBox(height: 18),
                            Input3D(
                              controller: _ageController,
                              label: 'Age',
                              validator: _ageValid,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            const SizedBox(height: 18),
                            Select3D<String>(
                              value: _absenteeismStatus,
                              label: 'Absenteeism Status',
                              items: const [
                                DropdownMenuItem(value: 'Active', child: Text('Active')),
                                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                              ],
                              onChanged: (v) => setState(() => _absenteeismStatus = v ?? 'Active'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FormCard(
                        child: FormSection(
                          title: 'Account',
                          children: [
                            PasswordInput3D(controller: _password, label: 'Password', validator: _passwordLength),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton3D(label: 'Create Student', onPressed: _submit, loading: _submitting),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateStudentBody(BuildContext context) {
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
                        field(_desktopTextField(controller: _emisNumber, label: 'EMIS Number', validator: _required)),
                        field(_desktopTextField(controller: _guardianName, label: 'Guardian Name', validator: _required, textCapitalization: TextCapitalization.words)),
                        field(_desktopTextField(controller: _studentName, label: 'Student Name', validator: _required, textCapitalization: TextCapitalization.words)),
                        field(_desktopTextField(controller: _schoolName, label: 'School Name', validator: _required)),
                        field(_desktopTextField(controller: _motherName, label: "Mother's Name", validator: _required, textCapitalization: TextCapitalization.words)),
                        field(_desktopSelectField<int>(
                          value: _selectedClassId,
                          label: 'Class',
                          items: _classes.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (v) => setState(() => _selectedClassId = v),
                        )),
                        field(_desktopTextField(
                          controller: _ageController,
                          label: 'Age',
                          validator: _ageValid,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        )),
                        field(DatePicker3D(
                          label: 'Date of Birth',
                          value: _birthDate,
                          initialDate: _birthDate.isNotEmpty ? _parseDate(_birthDate) : null,
                          firstDate: DateTime(1990),
                          lastDate: DateTime.now(),
                          onDatePicked: (date) {
                            setState(() {
                              _birthDate = _formatDate(date);
                              _birthDateError = null;
                            });
                          },
                          errorText: _birthDateError,
                        )),
                        field(_desktopSelectField<String>(
                          value: _sex,
                          label: 'Gender',
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                          ],
                          onChanged: (v) => setState(() => _sex = v ?? 'Male'),
                        )),
                        field(_desktopSelectField<String>(
                          value: _disabilityStatus,
                          label: 'Disability Status',
                          items: const [
                            DropdownMenuItem(value: 'No Disability', child: Text('No Disability')),
                            DropdownMenuItem(value: 'Disabled', child: Text('Disabled')),
                          ],
                          onChanged: (v) => setState(() => _disabilityStatus = v ?? 'No Disability'),
                        )),
                        field(_desktopSelectField<String>(
                          value: _refugeeStatus,
                          label: 'Refugee Status',
                          items: const [
                            DropdownMenuItem(value: 'Refugee', child: Text('Refugee')),
                            DropdownMenuItem(value: 'Not Refugee', child: Text('Not Refugee')),
                          ],
                          onChanged: (v) => setState(() => _refugeeStatus = v ?? 'Not Refugee'),
                        )),
                        field(_desktopSelectField<String>(
                          value: _orphanStatus,
                          label: 'Orphan Status',
                          items: const [
                            DropdownMenuItem(value: 'Orphan', child: Text('Orphan')),
                            DropdownMenuItem(value: 'Not Orphan', child: Text('Not Orphan')),
                          ],
                          onChanged: (v) => setState(() => _orphanStatus = v ?? 'Not Orphan'),
                        )),
                        field(_desktopSelectField<String>(
                          value: _absenteeismStatus,
                          label: 'Absenteeism Status',
                          items: const [
                            DropdownMenuItem(value: 'Active', child: Text('Active')),
                            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                          ],
                          onChanged: (v) => setState(() => _absenteeismStatus = v ?? 'Active'),
                        )),
                        field(_desktopTextField(controller: _birthPlace, label: 'Birth Place', validator: _required)),
                        field(_desktopTextField(controller: _nationality, label: 'Nationality', validator: _required)),
                        field(_desktopTextField(controller: _studentState, label: 'State', validator: _required)),
                        field(_desktopTextField(controller: _studentDistrict, label: 'District', validator: _required)),
                        field(_desktopTextField(controller: _studentVillage, label: 'Village', validator: _required)),
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
                                        widget.onNavigateToPage!('students');
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                  : const Text('Save Student'),
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
                                        widget.onNavigateToPage!('students');
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                  : const Text('Save Student'),
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
      labelStyle: const TextStyle(
        color: Color(0xFF374151),
        fontWeight: FontWeight.w500,
      ),
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
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
      validator: _passwordLength,
      obscureText: _obscureDesktopPassword,
      decoration: _desktopInputDecoration('Password').copyWith(
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
