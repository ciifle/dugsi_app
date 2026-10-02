import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/services/auth_provider.dart';

/// Finance's own desktop sidebar (root shell only — School Admin embeds the
/// same Finance pages into its own [WebSidebar]/[WebAdminShell] instead).
/// Deliberately flat (no expand/collapse) — Finance has few enough
/// destinations that a grouped-but-flat list stays concise, per the "keep
/// navigation concise" guidance.
class FinanceWebSidebar extends StatelessWidget {
  final String selectedPage;
  final void Function(String pageKey, {Object? arguments}) onNavigate;
  final double width;

  const FinanceWebSidebar({
    super.key,
    required this.selectedPage,
    required this.onNavigate,
    this.width = 260,
  });

  @override
  Widget build(BuildContext context) {
    final school = context.watch<AuthProvider>().school;
    final schoolName = school?.name?.trim();
    return Container(
      width: width - 16,
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: kAdminNavy.withValues(alpha: .09), blurRadius: 26, offset: const Offset(4, 8)),
        ],
      ),
      child: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kAdminBorder, width: 1)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  LayoutBuilder(builder: (context, box) {
                    final imageWidth = box.maxWidth / .58;
                    return ClipRect(child: SizedBox(height: 48, width: box.maxWidth, child: OverflowBox(maxWidth: imageWidth, maxHeight: imageWidth * 596 / 843, child: Image.asset('assets/dugsi logo-04.png', width: imageWidth, fit: BoxFit.contain))));
                  }),
                  const SizedBox(height: 4),
                  const Text(
                    'Finance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kAdminNavy),
                  ),
                  if (schoolName != null && schoolName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      schoolName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: kAdminTextSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  _item(context, 'Dashboard', Icons.dashboard_rounded, 'financeDashboard'),
                  _sectionLabel('Fee Management'),
                  _item(context, 'Class Fees', Icons.class_outlined, 'financeClassFees'),
                  _item(context, 'Student Discounts', Icons.percent_rounded, 'financeStudentDiscounts'),
                  _item(context, 'Generate Fees', Icons.receipt_long_rounded, 'financeGenerateFees'),
                  _item(context, 'Fee Ledger', Icons.list_alt_rounded, 'financeFeeLedger'),
                  _sectionLabel('Payments'),
                  _item(context, 'Collect Payment', Icons.payments_rounded, 'financeCollectPayment'),
                  _item(context, 'Payment History', Icons.history_rounded, 'financePaymentHistory'),
                  _sectionLabel(''),
                  _item(context, 'Profile', Icons.person_outline_rounded, 'profile'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC73737)),
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    child: label.isEmpty
        ? const Divider(height: 1, color: kAdminBorder)
        : Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kAdminTextSecondary,
              letterSpacing: .4,
            ),
          ),
  );

  Widget _item(BuildContext context, String label, IconData icon, String pageKey) {
    final active = selectedPage == pageKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: () => onNavigate(pageKey),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? kAdminNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: active ? Colors.white : kAdminNavy),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? Colors.white : const Color(0xFF2D2D2D),
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
