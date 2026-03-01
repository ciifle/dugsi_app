import 'package:flutter/material.dart';
import 'package:kobac/services/parents_service.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);

class EditParentScreen extends StatefulWidget {
  final int parentId;

  const EditParentScreen({Key? key, required this.parentId}) : super(key: key);

  @override
  State<EditParentScreen> createState() => _EditParentScreenState();
}

class _EditParentScreenState extends State<EditParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadParent();
  }

  Future<void> _loadParent() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await ParentsService().getParent(widget.parentId);
    if (!mounted) return;
    if (result is ParentError) {
      setState(() {
        _loading = false;
        _loadError = result.message;
      });
      return;
    }
    final p = (result as ParentSuccess<ParentModel>).data;
    _name.text = p.name;
    _email.text = p.email;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
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
    if (v == null || v.isEmpty) return null;
    if (v.length < 8) return 'At least 8 characters if provided';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
    };
    final pwd = _password.text.trim();
    if (pwd.isNotEmpty) body['password'] = pwd;
    final result = await ParentsService().updateParent(widget.parentId, body);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result is ParentSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parent updated'), backgroundColor: kPrimaryGreen),
      );
      Navigator.of(context).pop(true);
      return;
    }
    final err = result as ParentError;
    String msg = err.message;
    if (err.statusCode == 409) msg = 'Email already exists';
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
              _buildTopBar('Edit Parent'),
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
                                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                  const SizedBox(height: 12),
                                  Text(_loadError!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _loadParent,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
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
                                    title: 'Account Info',
                                    children: [
                                      Input3D(controller: _name, label: 'Name', validator: _required, textCapitalization: TextCapitalization.words),
                                      const SizedBox(height: 18),
                                      Input3D(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress, validator: _emailFormat),
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
      ),
    );
  }
}
