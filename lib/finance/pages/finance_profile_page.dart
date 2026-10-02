import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/services/auth_provider.dart';

import 'package:kobac/finance/widgets/finance_ui.dart';

/// FINANCE profile, built on the same structure as the School Admin profile:
/// a raised profile card (ringed avatar with status dot, name, role, email),
/// a school identity card, account details and a 3D logout button. Everything
/// shown comes from the authenticated `/me` data ([AuthProvider]); logout is
/// the app's normal [AuthProvider.logout].
class FinanceProfilePage extends StatelessWidget {
  final bool embedBodyOnly;
  const FinanceProfilePage({super.key, this.embedBodyOnly = false});

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Same confirmation modal the Admin app uses; the session is cleared by
  /// the app's normal [AuthProvider.logout].
  static Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showAdminFeatureConfirmation(
      context,
      title: 'Log out?',
      message: 'Are you sure you want to log out of Dugsi?',
      confirmLabel: 'Logout',
      icon: Icons.logout_rounded,
      confirmColor: Colors.red,
    );
    if (confirmed == true && context.mounted)
      await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final school = auth.school?.name?.trim() ?? '';
    final name = (user?.name ?? '').trim().isEmpty
        ? 'Finance User'
        : user!.name.trim();
    final email = (user?.email ?? '').trim();
    final role = financeLabel(
      user?.role ?? 'FINANCE',
    ); // "Finance", never raw FINANCE

    final body = LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 900;
        final header = const FinancePageHeader(
          title: 'My Profile',
          subtitle: 'Your account and school details.',
        );
        final profileCard = _ProfileCard(
          name: name,
          role: role,
          email: email,
          initials: _initials(name),
        );
        final details = _Section(
          title: 'Account Details',
          children: [
            _InfoRow('Full Name', name),
            _InfoRow('Email', email.isEmpty ? '—' : email),
            _InfoRow('Role', role),
            if (school.isNotEmpty) _InfoRow('School', school),
          ],
        );
        final logout = _LogoutButton(onTap: () => _confirmLogout(context));
        if (wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        profileCard,
                        if (school.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SchoolCard(school),
                        ],
                        const SizedBox(height: 16),
                        logout,
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: details),
                ],
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 14),
            profileCard,
            if (school.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SchoolCard(school),
            ],
            const SizedBox(height: 14),
            details,
            const SizedBox(height: 16),
            logout,
            const SizedBox(height: 16),
          ],
        );
      },
    );
    return FinancePageFrame(embedBodyOnly: embedBodyOnly, child: body);
  }
}

/// The Admin profile card: layered white/navy/black shadows, green-ringed
/// avatar with the online dot.
class _ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  final String email;
  final String initials;
  const _ProfileCard({
    required this.name,
    required this.role,
    required this.email,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        const BoxShadow(
          color: Colors.white,
          blurRadius: 18,
          offset: Offset(-6, -6),
          spreadRadius: .5,
        ),
        BoxShadow(
          color: kAdminNavy.withValues(alpha: .12),
          blurRadius: 28,
          offset: const Offset(10, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: .06),
          blurRadius: 14,
          offset: const Offset(5, 8),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: kAdminGreen.withValues(alpha: .6),
                  width: 2.5,
                ),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 8,
                    offset: Offset(-2, -2),
                  ),
                  BoxShadow(
                    color: kAdminNavy.withValues(alpha: .15),
                    blurRadius: 12,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFF5B9BD5).withValues(alpha: .2),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: kAdminNavy,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: kAdminGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kAdminNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _SchoolCard extends StatelessWidget {
  final String school;
  const _SchoolCard(this.school);

  @override
  Widget build(BuildContext context) => FinanceCard(
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: kAdminNavy.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.school_rounded, color: kAdminNavy),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'School',
                style: TextStyle(
                  fontSize: 12,
                  color: kAdminTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                school,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: kAdminNavy,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => FinanceCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kAdminNavy,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kAdminNavy,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The Admin profile's raised destructive button.
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            const BoxShadow(
              color: Colors.white,
              blurRadius: 8,
              offset: Offset(-2, -2),
            ),
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: .15),
              blurRadius: 14,
              offset: const Offset(4, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
