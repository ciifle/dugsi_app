import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/shared/widgets/fees_feature_guard.dart';
import 'package:kobac/services/auth_provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

import 'package:kobac/finance/pages/class_fees_page.dart';
import 'package:kobac/finance/pages/collect_payment_page.dart';
import 'package:kobac/finance/pages/finance_dashboard_page.dart';
import 'package:kobac/finance/pages/finance_users_page.dart';
import 'package:kobac/finance/pages/fee_ledger_page.dart';
import 'package:kobac/finance/pages/generate_fees_page.dart';
import 'package:kobac/finance/pages/payment_history_page.dart';
import 'package:kobac/finance/pages/student_discounts_page.dart';
import 'package:kobac/finance/pages/student_fee_ledger_page.dart';

const String kSchoolAdminFinanceBasePath = 'api/school-admin/finance';

/// School Admin's mobile entry point into Finance (pushed from [AppDrawer]'s
/// "Finance" tile — mobile has no room for a full sidebar, so this is a
/// simple menu of pushed standalone pages instead of the embedded
/// page-key/shell system desktop uses).
class FinanceAdminMobileMenuPage extends StatelessWidget {
  const FinanceAdminMobileMenuPage({super.key});

  static const _groups = [
    (
      title: 'Overview',
      items: [(icon: Icons.dashboard_rounded, label: 'Dashboard')],
    ),
    (
      title: 'Setup',
      items: [
        (icon: Icons.people_alt_outlined, label: 'Finance Users'),
        (icon: Icons.class_outlined, label: 'Class Fees'),
        (icon: Icons.percent_rounded, label: 'Student Discounts'),
      ],
    ),
    (
      title: 'Billing',
      items: [
        (icon: Icons.receipt_long_rounded, label: 'Generate Fees'),
        (icon: Icons.list_alt_rounded, label: 'Fee Ledger'),
      ],
    ),
    (
      title: 'Payments',
      items: [
        (icon: Icons.payments_rounded, label: 'Collect Payment'),
        (icon: Icons.history_rounded, label: 'Payment History'),
      ],
    ),
  ];

  void _open(BuildContext context, String label) {
    const keys = {
      'Dashboard': 'financeDashboard',
      'Finance Users': 'financeUsers',
      'Class Fees': 'financeClassFees',
      'Student Discounts': 'financeStudentDiscounts',
      'Generate Fees': 'financeGenerateFees',
      'Fee Ledger': 'financeFeeLedger',
      'Collect Payment': 'financeCollectPayment',
      'Payment History': 'financePaymentHistory',
    };
    _navigate(context, keys[label] ?? 'financeDashboard');
  }

  void _navigate(BuildContext context, String key, {Object? arguments}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => _page(routeContext, key, arguments),
      ),
    );
  }

  Widget _page(BuildContext context, String key, Object? arguments) {
    void navigate(String key, {Object? arguments}) =>
        _navigate(context, key, arguments: arguments);
    Widget page;
    switch (key) {
      case 'financeUsers':
        page = FinanceUsersPage(onNavigateToPage: navigate);
        break;
      case 'financeClassFees':
        page = ClassFeesPage(
          basePath: kSchoolAdminFinanceBasePath,
          onNavigateToPage: navigate,
        );
        break;
      case 'financeStudentDiscounts':
        page = StudentDiscountsPage(
          basePath: kSchoolAdminFinanceBasePath,
          onNavigateToPage: navigate,
        );
        break;
      case 'financeGenerateFees':
        page = GenerateFeesPage(
          basePath: kSchoolAdminFinanceBasePath,
          onNavigateToPage: navigate,
        );
        break;
      case 'financeFeeLedger':
        page = FeeLedgerPage(
          basePath: kSchoolAdminFinanceBasePath,
          onNavigateToPage: navigate,
        );
        break;
      case 'financeCollectPayment':
        page = CollectPaymentPage(
          basePath: kSchoolAdminFinanceBasePath,
          onNavigateToPage: navigate,
          initial: arguments is Map<String, dynamic> ? arguments : null,
        );
        break;
      case 'financePaymentHistory':
        page = PaymentHistoryPage(
          basePath: kSchoolAdminFinanceBasePath,
          onNavigateToPage: navigate,
        );
        break;
      case 'financeStudentLedger':
        final args = arguments as Map<String, dynamic>;
        page = StudentFeeLedgerPage(
          basePath: kSchoolAdminFinanceBasePath,
          studentId: args['studentId'] as int,
          academicYearId: args['academicYearId'] as int,
          onNavigateToPage: navigate,
        );
        break;
      case 'financeDashboard':
      default:
        page = FinanceDashboardPage(
          basePath: kSchoolAdminFinanceBasePath,
          onNavigateToPage: navigate,
        );
    }
    return FeesFeatureGuard(child: page);
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().feesEnabled) {
      return const FinancePageFrame(
        embedBodyOnly: false,
        child: FinanceNotEnabledView(),
      );
    }
    return Scaffold(
      backgroundColor: kAdminBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kAdminBorder),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: kAdminNavy,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const FinancePageHeader(title: 'Finance'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const Text(
                      'Manage school fees, collections and student balances.',
                      style: TextStyle(color: kAdminTextSecondary),
                    ),
                    for (final group in _groups) ...[
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          group.title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .6,
                            color: kAdminTextSecondary,
                          ),
                        ),
                      ),
                      FinanceCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < group.items.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  indent: 60,
                                  color: kAdminBorder,
                                ),
                              _MenuRow(
                                icon: group.items[i].icon,
                                label: group.items[i].label,
                                onTap: () =>
                                    _open(context, group.items[i].label),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kAdminNavy.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: kAdminNavy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: kAdminNavy,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: kAdminTextSecondary,
            size: 22,
          ),
        ],
      ),
    ),
  );
}
