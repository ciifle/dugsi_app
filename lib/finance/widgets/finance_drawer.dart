import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/services/auth_provider.dart';

import 'package:kobac/finance/widgets/finance_ui.dart';

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}

/// Finance mobile drawer in the Admin drawer style: profile header card,
/// raised menu cards, pinned logout.
class FinanceDrawer extends StatelessWidget {
  final String? currentLabel;
  final void Function(String rootLabel) onNavigateRoot;

  const FinanceDrawer({super.key, this.currentLabel, required this.onNavigateRoot});

  static const _menuItems = [
    _MenuItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
    _MenuItem(icon: Icons.class_outlined, label: 'Class Fees'),
    _MenuItem(icon: Icons.percent_rounded, label: 'Student Discounts'),
    _MenuItem(icon: Icons.receipt_long_rounded, label: 'Generate Fees'),
    _MenuItem(icon: Icons.list_alt_rounded, label: 'Fee Ledger'),
    _MenuItem(icon: Icons.payments_rounded, label: 'Collect Payment'),
    _MenuItem(icon: Icons.history_rounded, label: 'Payment History'),
    _MenuItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final school = auth.school;
    final name = (user?.name ?? '').trim().isEmpty ? 'Finance' : user!.name;
    final email = user?.email ?? '';

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: kAdminBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: FinanceCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  FinanceInitialAvatar(name, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kAdminNavy)),
                      if (email.isNotEmpty)
                        Text(email, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: kAdminTextSecondary)),
                      if (school?.name != null) ...[
                        const SizedBox(height: 4),
                        Text(school!.name!, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: kAdminNavy, fontWeight: FontWeight.w600)),
                      ],
                    ]),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  for (final item in _menuItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DrawerCard(
                        item: item,
                        selected: item.label == currentLabel,
                        onTap: () {
                          Navigator.pop(context);
                          onNavigateRoot(item.label);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: Color(0xFFFFD2D7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await context.read<AuthProvider>().logout();
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerCard extends StatelessWidget {
  final _MenuItem item;
  final bool selected;
  final VoidCallback onTap;
  const _DrawerCard({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? kAdminNavy : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? kAdminNavy : kAdminBorder),
        boxShadow: [
          BoxShadow(color: kAdminNavy.withValues(alpha: selected ? .22 : .06), blurRadius: selected ? 14 : 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Icon(item.icon, size: 21, color: selected ? Colors.white : kAdminNavy),
        const SizedBox(width: 14),
        Expanded(
          child: Text(item.label,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : kAdminNavy)),
        ),
      ]),
    ),
  );
}
