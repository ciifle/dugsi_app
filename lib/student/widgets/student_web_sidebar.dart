import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kPrimaryGreen = Color(0xFF5AB04B);
const Color _kTextPrimary = Color(0xFF2D3436);
const Color _kTextSecondary = Color(0xFF6B7280);

class StudentWebSidebar extends StatelessWidget {
  final String selectedPage;
  final void Function(String pageKey, {Object? arguments}) onNavigate;
  final double width;

  const StudentWebSidebar({
    super.key,
    required this.selectedPage,
    required this.onNavigate,
    this.width = 260,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final prof = auth.studentProfile;
    final name = prof?.studentName?.trim().isNotEmpty == true
        ? prof!.studentName!.trim()
        : (user?.name?.trim().isNotEmpty == true ? user!.name.trim() : 'Student');
    final className = prof?.className?.trim().isNotEmpty == true ? prof!.className!.trim() : null;
    final emis = user?.emisNumber?.trim().isNotEmpty == true
        ? user!.emisNumber!.trim()
        : '—';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final feesEnabled = auth.feesEnabled;

    return Container(
      width: width - 16,
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kPrimaryBlue.withValues(alpha: .09),
            blurRadius: 26,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8ECF2)),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/dugsi logo-04.png',
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: _StudentIdentityCard(
              initials: initials.isEmpty ? 'S' : initials,
              name: name,
              className: className ?? 'Class unavailable',
              emis: emis,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _StudentNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  pageKey: 'dashboard',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _StudentNavItem(
                  icon: Icons.schedule_rounded,
                  label: 'Timetable',
                  pageKey: 'timetable',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _StudentNavItem(
                  icon: Icons.grade_rounded,
                  label: 'Marks',
                  pageKey: 'marks',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _StudentNavItem(
                  icon: Icons.stars_rounded,
                  label: 'Results',
                  pageKey: 'results',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _StudentNavItem(
                  icon: Icons.insights_rounded,
                  label: 'Academic Performance',
                  pageKey: 'performance',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                if (feesEnabled) ...[
                  _StudentNavItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Fees',
                    pageKey: 'fees',
                    selectedPage: selectedPage,
                    onNavigate: onNavigate,
                  ),
                  _StudentNavItem(
                    icon: Icons.payment_rounded,
                    label: 'Payments',
                    pageKey: 'payments',
                    selectedPage: selectedPage,
                    onNavigate: onNavigate,
                  ),
                ],
                _StudentNavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Attendance',
                  pageKey: 'attendance',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _StudentNavItem(
                  icon: Icons.campaign_rounded,
                  label: 'Notices',
                  pageKey: 'notices',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _StudentNavItem(
                  icon: Icons.message_rounded,
                  label: 'Messages',
                  pageKey: 'messages',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
                _StudentNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  pageKey: 'profile',
                  selectedPage: selectedPage,
                  onNavigate: onNavigate,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: _StudentLogoutCard(
              onTap: () async => context.read<AuthProvider>().logout(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentIdentityCard extends StatelessWidget {
  final String initials;
  final String name;
  final String className;
  final String emis;

  const _StudentIdentityCard({
    required this.initials,
    required this.name,
    required this.className,
    required this.emis,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: _kPrimaryBlue,
              foregroundColor: Colors.white,
              child: Text(initials,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _kPrimaryBlue,
                          fontWeight: FontWeight.w700)),
                  Text('$className • $emis',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _kTextSecondary, fontSize: 10.5)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kPrimaryGreen.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text('STUDENT',
                        style: TextStyle(
                            color: _kPrimaryGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StudentLogoutCard extends StatelessWidget {
  final Future<void> Function() onTap;
  const _StudentLogoutCard({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF2C7C7)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x10C73737),
                    blurRadius: 12,
                    offset: Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Color(0xFFC73737), size: 19),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Logout',
                          style: TextStyle(
                              color: Color(0xFFC73737),
                              fontWeight: FontWeight.w700)),
                      Text('Sign out of your account',
                          style: TextStyle(
                              color: _kTextSecondary, fontSize: 9.5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFC73737), size: 18),
              ],
            ),
          ),
        ),
      );
}

class _StudentNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String pageKey;
  final String selectedPage;
  final void Function(String pageKey, {Object? arguments}) onNavigate;

  const _StudentNavItem({
    required this.icon,
    required this.label,
    required this.pageKey,
    required this.selectedPage,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedPage == pageKey ||
        (pageKey == 'messages' &&
            (selectedPage == 'newMessage' || selectedPage == 'chat')) ||
        (pageKey == 'marks' && selectedPage == 'marksTotal');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onNavigate(pageKey),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected
                  ? _kPrimaryBlue.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? _kPrimaryBlue : _kTextSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? _kPrimaryBlue : _kTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
