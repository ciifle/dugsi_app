import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kobac/services/fees_service.dart';
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/shared/widgets/fees_feature_guard.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

const List<String> kFeeStatusOptions = ['UNPAID', 'PARTIAL', 'PAID'];

class AdminFeesScreen extends StatefulWidget {
  final bool openCreateOnLoad;

  const AdminFeesScreen({Key? key, this.openCreateOnLoad = false}) : super(key: key);

  @override
  State<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends State<AdminFeesScreen> {
  late Future<FeeResult<List<FeeModel>>> _feesFuture;
  List<StudentModel> _students = [];
  bool _refLoaded = false;
  int? _filterStudentId;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadRefData();
    _loadFees();
    if (widget.openCreateOnLoad && _refLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreateFee());
    }
  }

  Future<void> _loadRefData() async {
    final r = await StudentsService().listStudents();
    if (!mounted) return;
    setState(() {
      if (r is StudentSuccess<List<StudentModel>>) _students = r.data;
      _refLoaded = true;
    });
    // Schedule dialog for next frame so BuildContext is valid (avoid post-await invalid context).
    if (widget.openCreateOnLoad && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openCreateFee();
      });
    }
  }

  void _loadFees() {
    setState(() {
      _feesFuture = FeesService().listFees();
    });
  }

  String _studentName(int id) {
    for (final s in _students) { if (s.id == id) return s.studentName; }
    return '—';
  }
  String _studentEmis(int id) {
    for (final s in _students) { if (s.id == id) return s.emisNumber; }
    return '—';
  }

  List<FeeModel> get _filteredFees {
    var list = _allFees;
    if (_filterStudentId != null) list = list.where((f) => f.studentId == _filterStudentId).toList();
    if (_filterStatus != null && _filterStatus!.isNotEmpty) list = list.where((f) => f.status == _filterStatus).toList();
    return list;
  }

  List<FeeModel> _allFees = [];

  Future<void> _openCreateFee() async {
    if (!_refLoaded) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CreateFeeDialog(
        students: _students,
        onSave: (payload) => _createFeeFromDialog(ctx, payload),
      ),
    );
    if (created == true && mounted) {
      _loadFees();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fee created'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<bool> _createFeeFromDialog(BuildContext ctx, Map<String, dynamic> payload) async {
    final result = await FeesService().createFee(payload);
    if (result is FeeSuccess) return true;
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text((result as FeeError).message), backgroundColor: Colors.red),
      );
    }
    return false;
  }

  Future<void> _openUpdateStatus(FeeModel fee) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _UpdateFeeStatusDialog(
        fee: fee,
        currentStatus: fee.status,
        onSave: (status) => _updateStatusFromDialog(ctx, fee.id, status),
      ),
    );
    if (updated == true && mounted) {
      _loadFees();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<bool> _updateStatusFromDialog(BuildContext ctx, int id, String status) async {
    final result = await FeesService().updateFeeStatus(id, {'status': status});
    if (result is FeeSuccess) return true;
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text((result as FeeError).message), backgroundColor: Colors.red),
      );
    }
    return false;
  }

  Future<void> _deleteFee(FeeModel fee) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete fee record?',
      message: 'Delete this fee record for ${_studentName(fee.studentId)}?',
    );
    if (confirmed != true) return;
    final result = await FeesService().deleteFee(fee.id);
    if (!mounted) return;
    if (result is FeeSuccess) {
      _loadFees();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fee deleted'), backgroundColor: kPrimaryGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as FeeError).message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeesFeatureGuard(
      child: Scaffold(
        backgroundColor: kBgColor,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kBgColor, kPrimaryBlue.withOpacity(0.02)],
              ),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    _BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text('Fees', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                    ),
                    _AddButton(onPressed: _openCreateFee),
                  ],
                ),
              ),
              if (_refLoaded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Select3D<int?>(
                          value: _filterStudentId,
                          label: 'Student',
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('All students')),
                            ..._students.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text('${s.studentName} (${s.emisNumber.trim().isEmpty ? '—' : s.emisNumber})'))),
                          ],
                          onChanged: (v) => setState(() => _filterStudentId = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Select3D<String?>(
                          value: _filterStatus,
                          label: 'Status',
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('All')),
                            ...kFeeStatusOptions.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
                          ],
                          onChanged: (v) => setState(() => _filterStatus = v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadFees(),
                  color: kPrimaryGreen,
                  child: FutureBuilder<FeeResult<List<FeeModel>>>(
                    future: _feesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                      }
                      if (snapshot.hasError) {
                        return _ErrorState(
                          message: userFriendlyMessage(snapshot.error!, null, 'AdminFeesScreen'),
                          onRetry: _loadFees,
                        );
                      }
                      final result = snapshot.data;
                      if (result == null) return const Center(child: Text('No data'));
                      if (result is FeeError) {
                        return _ErrorState(message: result.message, onRetry: _loadFees);
                      }
                      _allFees = (result as FeeSuccess<List<FeeModel>>).data;
                      final list = _filteredFees;
                      if (list.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.payment_rounded, size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text('No fee records', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _openCreateFee,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Create Fee'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final fee = list[index];
                          return _FeeCard(
                            fee: fee,
                            studentName: fee.studentName ?? _studentName(fee.studentId),
                            emis: fee.emisNumber ?? _studentEmis(fee.studentId),
                            onTap: () => _openFeeDetail(fee),
                            onUpdateStatus: () => _openUpdateStatus(fee),
                            onDelete: () => _deleteFee(fee),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _openFeeDetail(FeeModel fee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FeeDetailScreen(
          fee: fee,
          studentName: fee.studentName ?? _studentName(fee.studentId),
          emis: fee.emisNumber ?? _studentEmis(fee.studentId),
          onUpdateStatus: () => _openUpdateStatus(fee),
          onDelete: () => _deleteFee(fee),
          onPop: () => _loadFees(),
        ),
      ),
    ).then((_) => _loadFees());
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  final FeeModel fee;
  final String studentName;
  final String emis;
  final VoidCallback onTap;
  final VoidCallback onUpdateStatus;
  final VoidCallback onDelete;

  const _FeeCard({
    required this.fee,
    required this.studentName,
    required this.emis,
    required this.onTap,
    required this.onUpdateStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: [
            BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kCardRadius),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.payment_rounded, color: kPrimaryBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(studentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                    Text('Amount: ${fee.amount} · Paid: ${fee.paidAmount ?? 0} · Remaining: ${fee.remainingAmount ?? fee.amount}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    if (fee.status != null) Text('Status: ${fee.status}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.edit_outlined, size: 22, color: kPrimaryGreen), onPressed: onUpdateStatus, tooltip: 'Update Status'),
              IconButton(icon: Icon(Icons.delete_outline, size: 22, color: Colors.red[400]), onPressed: onDelete, tooltip: 'Delete'),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeeDetailScreen extends StatelessWidget {
  final FeeModel fee;
  final String studentName;
  final String emis;
  final VoidCallback onUpdateStatus;
  final VoidCallback onDelete;
  final VoidCallback onPop;

  const _FeeDetailScreen({
    required this.fee,
    required this.studentName,
    required this.emis,
    required this.onUpdateStatus,
    required this.onDelete,
    required this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  const Expanded(child: Text('Fee Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue))),
                  TextButton.icon(onPressed: onUpdateStatus, icon: const Icon(Icons.edit, size: 18), label: const Text('Update Status')),
                  IconButton(icon: Icon(Icons.delete_outline, color: Colors.red[400]), onPressed: onDelete, tooltip: 'Delete'),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FormCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(studentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                      if (emis.isNotEmpty && emis != '—') Text('EMIS: $emis', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      const SizedBox(height: 20),
                      _DetailRow('Amount', '${fee.amount}'),
                      _DetailRow('Paid Amount', '${fee.paidAmount ?? 0}'),
                      _DetailRow('Remaining', '${fee.remainingAmount ?? fee.amount}'),
                      if (fee.status != null) _DetailRow('Status', fee.status!),
                      if (fee.createdAt != null) _DetailRow('Created', fee.createdAt!),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kPrimaryBlue)),
        ],
      ),
    );
  }
}

class _CreateFeeDialog extends StatefulWidget {
  final List<StudentModel> students;
  final Future<bool> Function(Map<String, dynamic> payload) onSave;

  const _CreateFeeDialog({required this.students, required this.onSave});

  @override
  State<_CreateFeeDialog> createState() => _CreateFeeDialogState();
}

class _CreateFeeDialogState extends State<_CreateFeeDialog> {
  int? _studentId;
  final _amount = TextEditingController(text: '0');
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student'), backgroundColor: Colors.red),
      );
      return;
    }
    final amount = num.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await widget.onSave({'student_id': _studentId, 'amount': amount});
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: FormCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Create Fee', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
            const SizedBox(height: 20),
            Select3D<int?>(
              value: _studentId,
              label: 'Student',
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Select student')),
                ...widget.students.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text('${s.studentName} (${s.emisNumber.trim().isEmpty ? '—' : s.emisNumber})'))),
              ],
              onChanged: (v) => setState(() => _studentId = v),
            ),
            const SizedBox(height: 16),
            Input3D(
              controller: _amount,
              label: 'Amount',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: _submitting ? null : () => Navigator.pop(context), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: PrimaryButton3D(label: 'Create', onPressed: _submit, loading: _submitting, height: 48)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateFeeStatusDialog extends StatefulWidget {
  final FeeModel fee;
  final String? currentStatus;
  final Future<bool> Function(String status) onSave;

  const _UpdateFeeStatusDialog({required this.fee, this.currentStatus, required this.onSave});

  @override
  State<_UpdateFeeStatusDialog> createState() => _UpdateFeeStatusDialogState();
}

class _UpdateFeeStatusDialogState extends State<_UpdateFeeStatusDialog> {
  late String _status;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus ?? 'UNPAID';
    if (!kFeeStatusOptions.contains(_status)) _status = kFeeStatusOptions.first;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await widget.onSave(_status);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: FormCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Update Fee Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
            const SizedBox(height: 12),
            Text(
              'Amounts cannot be edited manually. Status is usually auto-calculated; only change if necessary.',
              style: TextStyle(fontSize: 13, color: Colors.orange[800]),
            ),
            const SizedBox(height: 20),
            Select3D<String>(
              value: _status,
              label: 'Status',
              items: kFeeStatusOptions.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _status = v ?? 'UNPAID'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: _submitting ? null : () => Navigator.pop(context), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: PrimaryButton3D(label: 'Save', onPressed: _submit, loading: _submitting, height: 48)),
              ],
            ),
          ],
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

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kPrimaryGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryGreen.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add_rounded, color: kPrimaryGreen, size: 24),
      ),
    );
  }
}
