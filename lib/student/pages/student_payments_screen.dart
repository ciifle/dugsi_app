import 'package:flutter/material.dart';
import 'package:kobac/student/finance/student_finance_page.dart';

/// Compatibility route for existing navigation. Student Finance is read-only.
class StudentPaymentsScreen extends StatelessWidget {
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const StudentPaymentsScreen({
    super.key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });
  @override
  Widget build(BuildContext context) =>
      StudentFinancePage(embedBodyOnly: embedBodyOnly, initialPayments: true);
}
