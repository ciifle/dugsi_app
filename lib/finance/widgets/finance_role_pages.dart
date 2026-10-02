import 'package:flutter/material.dart';

import 'package:kobac/finance/pages/class_fees_page.dart';
import 'package:kobac/finance/pages/collect_payment_page.dart';
import 'package:kobac/finance/pages/fee_ledger_page.dart';
import 'package:kobac/finance/pages/finance_dashboard_page.dart';
import 'package:kobac/finance/pages/finance_profile_page.dart';
import 'package:kobac/finance/pages/generate_fees_page.dart';
import 'package:kobac/finance/pages/payment_history_page.dart';
import 'package:kobac/finance/pages/student_discounts_page.dart';
import 'package:kobac/finance/pages/student_fee_ledger_page.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

/// Base path of the FINANCE-role API (School Admin embeds the same pages with
/// `api/school-admin/finance`).
const String kFinanceRoleBasePath = 'api/finance';

typedef FinanceNavigate = void Function(String pageKey, {Object? arguments});

/// The one page switch shared by the FINANCE desktop and mobile shells.
/// Pages scoped to an academic year sit behind [FinanceYearsGate]; Payment
/// History and Profile do not need a year and always render.
Widget buildFinanceRolePage(String pageKey, Object? arguments, FinanceNavigate navigate) {
  Widget gated(Widget page) => FinanceYearsGate(child: page);
  switch (pageKey) {
    case 'financeClassFees':
      return gated(ClassFeesPage(basePath: kFinanceRoleBasePath, embedBodyOnly: true, onNavigateToPage: navigate));
    case 'financeStudentDiscounts':
      return gated(StudentDiscountsPage(basePath: kFinanceRoleBasePath, embedBodyOnly: true, onNavigateToPage: navigate));
    case 'financeGenerateFees':
      return gated(GenerateFeesPage(basePath: kFinanceRoleBasePath, embedBodyOnly: true, onNavigateToPage: navigate));
    case 'financeFeeLedger':
      return gated(FeeLedgerPage(basePath: kFinanceRoleBasePath, embedBodyOnly: true, onNavigateToPage: navigate));
    case 'financeStudentLedger':
      final args = arguments as Map<String, dynamic>;
      return gated(StudentFeeLedgerPage(
        basePath: kFinanceRoleBasePath,
        studentId: args['studentId'] as int,
        academicYearId: args['academicYearId'] as int,
        embedBodyOnly: true,
        onNavigateToPage: navigate,
      ));
    case 'financeCollectPayment':
      return gated(CollectPaymentPage(
        basePath: kFinanceRoleBasePath,
        embedBodyOnly: true,
        onNavigateToPage: navigate,
        initial: arguments is Map<String, dynamic> ? arguments : null,
      ));
    case 'financePaymentHistory':
      return PaymentHistoryPage(basePath: kFinanceRoleBasePath, embedBodyOnly: true, onNavigateToPage: navigate);
    case 'profile':
      return const FinanceProfilePage(embedBodyOnly: true);
    case 'financeDashboard':
    default:
      return gated(FinanceDashboardPage(basePath: kFinanceRoleBasePath, embedBodyOnly: true, onNavigateToPage: navigate));
  }
}
