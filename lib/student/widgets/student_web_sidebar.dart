import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kPrimaryGreen = Color(0xFF5AB04B);
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
    final feesEnabled = auth.feesEnabled;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8ECF2)),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.asset(
                    'assets/splash_image.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dugsi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _kPrimaryBlue,
                        ),
                      ),
                      Text(
                        'STUDENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kTextSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (className != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    className,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
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
              gradient: selected
                  ? const LinearGradient(
                      colors: [_kPrimaryBlue, _kPrimaryGreen],
                    )
                  : null,
              color: selected ? null : Colors.transparent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? Colors.white : _kPrimaryBlue,
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
                        color: selected ? Colors.white : _kPrimaryBlue,
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
