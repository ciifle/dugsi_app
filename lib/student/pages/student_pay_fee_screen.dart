import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/shared/widgets/fees_feature_guard.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE0E9F5);
const Color kSoftGreen = Color(0xFFE4F1E2);
const Color kErrorColor = Color(0xFFEF4444);
const Color kTextPrimary = Color(0xFF1A1E1F);

const List<String> kPaymentMethods = ['CASH', 'MOBILE_MONEY', 'BANK', 'CARD'];

class StudentPayFeeScreen extends StatefulWidget {
  final int? preselectedFeeId;

  const StudentPayFeeScreen({Key? key, this.preselectedFeeId}) : super(key: key);

  @override
  State<StudentPayFeeScreen> createState() => _StudentPayFeeScreenState();
}

class _StudentPayFeeScreenState extends State<StudentPayFeeScreen> {
  late Future<StudentResult<List<StudentFeeModel>>> _feesFuture;
  int? _feeId;
  final _amountController = TextEditingController(text: '0');
  String _method = kPaymentMethods.first;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _feesFuture = StudentService().listFees();
    _feeId = widget.preselectedFeeId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_feeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a fee'), backgroundColor: kErrorColor),
      );
      return;
    }
    final amount = num.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0'), backgroundColor: kErrorColor),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final result = await StudentService().payFee(feeId: _feeId!, amount: amount, method: _method);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result is StudentSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful'), backgroundColor: kPrimaryGreen),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as StudentError).message), backgroundColor: kErrorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeesFeatureGuard(
      child: Scaffold(
        backgroundColor: kSoftBlue,
        body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kSoftBlue, kSoftGreen],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Pay Fee',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FutureBuilder<StudentResult<List<StudentFeeModel>>>(
                    future: _feesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
                        );
                      }
                      if (snapshot.data is StudentError) {
                        final err = snapshot.data as StudentError;
                        if (err.statusCode == 403) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 28),
                                const SizedBox(width: 12),
                                Expanded(child: Text(err.message, style: TextStyle(fontSize: 14, color: Colors.orange.shade900))),
                              ],
                            ),
                          );
                        }
                        return Center(child: Text(err.message, style: const TextStyle(color: kErrorColor)));
                      }
                      final fees = snapshot.data is StudentSuccess<List<StudentFeeModel>>
                          ? (snapshot.data as StudentSuccess<List<StudentFeeModel>>).data
                          : <StudentFeeModel>[];
                      final unpaidOrPartial = fees.where((f) => f.status == 'UNPAID' || f.status == 'PARTIAL').toList();
                      if (unpaidOrPartial.isEmpty && fees.isEmpty) {
                        return const Center(child: Text('No fees to pay.'));
                      }
                      int? initialFeeId = _feeId;
                      if (initialFeeId == null && unpaidOrPartial.isNotEmpty) initialFeeId = unpaidOrPartial.first.id;
                      if (_feeId == null && initialFeeId != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _feeId = initialFeeId);
                        });
                      }
                      return FormCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Select3D<int?>(
                              value: _feeId,
                              label: 'Fee',
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('Select fee')),
                                ...(unpaidOrPartial.isEmpty ? fees : unpaidOrPartial).map((f) {
                                  return DropdownMenuItem<int?>(
                                    value: f.id,
                                    child: Text('Fee #${f.id} — ${f.amount} (remaining: ${f.remainingAmount})'),
                                  );
                                }),
                              ],
                              onChanged: (v) => setState(() => _feeId = v),
                            ),
                            const SizedBox(height: 16),
                            Input3D(
                              controller: _amountController,
                              label: 'Amount',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                            ),
                            const SizedBox(height: 16),
                            Select3D<String>(
                              value: _method,
                              label: 'Payment method',
                              items: kPaymentMethods.map((m) => DropdownMenuItem<String>(value: m, child: Text(m))).toList(),
                              onChanged: (v) => setState(() => _method = v ?? kPaymentMethods.first),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 54,
                              child: PrimaryButton3D(
                                label: 'Submit Payment',
                                onPressed: _submit,
                                loading: _submitting,
                              ),
                            ),
                          ],
                        ),
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
}
