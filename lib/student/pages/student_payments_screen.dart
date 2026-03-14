import 'package:flutter/material.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/shared/widgets/fees_feature_guard.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE0E9F5);
const Color kSoftGreen = Color(0xFFE4F1E2);
const Color kErrorColor = Color(0xFFEF4444);
const Color kTextPrimary = Color(0xFF1A1E1F);
const Color kTextSecondary = Color(0xFF4F5A5E);

class StudentPaymentsScreen extends StatefulWidget {
  const StudentPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentPaymentsScreen> createState() => _StudentPaymentsScreenState();
}

class _StudentPaymentsScreenState extends State<StudentPaymentsScreen> {
  late Future<StudentResult<List<StudentPaymentModel>>> _future;

  @override
  void initState() {
    super.initState();
    _future = StudentService().listPayments();
  }

  void _refresh() {
    setState(() {
      _future = StudentService().listPayments();
    });
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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                          'Payment History',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  color: kPrimaryGreen,
                  child: FutureBuilder<StudentResult<List<StudentPaymentModel>>>(
                    future: _future,
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
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
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: kErrorColor.withOpacity(0.8)),
                                const SizedBox(height: 12),
                                Text(err.message, textAlign: TextAlign.center, style: const TextStyle(color: kTextPrimary, fontSize: 15)),
                              ],
                            ),
                          ),
                        );
                      }
                      final list = snapshot.data is StudentSuccess<List<StudentPaymentModel>>
                          ? (snapshot.data as StudentSuccess<List<StudentPaymentModel>>).data
                          : <StudentPaymentModel>[];
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.payment_rounded, size: 56, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text('No payments yet', style: TextStyle(fontSize: 16, color: kTextSecondary)),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final p = list[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: kPrimaryGreen.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: kPrimaryGreen, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Fee #${p.feeId}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                                      Text('${p.amount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryGreen)),
                                      Text(p.method ?? '—', style: TextStyle(fontSize: 13, color: kTextSecondary)),
                                      if (p.createdAt != null) Text(p.createdAt!, style: TextStyle(fontSize: 12, color: kTextSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
