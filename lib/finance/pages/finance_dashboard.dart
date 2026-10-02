import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/auth_provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';

import 'package:kobac/finance/widgets/finance_drawer.dart';
import 'package:kobac/finance/widgets/finance_role_pages.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';
import 'package:kobac/finance/widgets/finance_web_shell.dart';

/// Root Finance entry point returned by `roleToHome` for `UserRole.finance`.
/// Desktop/PWA gets the persistent sidebar shell; mobile gets a bottom-nav +
/// drawer shell.
///
/// The FINANCE role gets its own read-only [AcademicYearsProvider] bound to
/// the finance academic-year API ([kFinanceAcademicYearsPath]) - it never
/// calls the School Admin academic-year endpoints and never changes role.
class FinanceDashboardScreen extends StatelessWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().feesEnabled)
      return Scaffold(
        backgroundColor: kAdminBg,
        appBar: AppBar(
          title: const Text('Finance'),
          actions: [
            TextButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              child: const Text('Logout'),
            ),
          ],
        ),
        body: const FinanceNotEnabledView(),
      );
    return ChangeNotifierProvider<AcademicYearsProvider>(
      create: (_) =>
          AcademicYearsProvider(service: AcademicYearsService.finance()),
      child: isDesktopWebAdminLayout(context)
          ? const FinanceWebShell()
          : const FinanceMobileShell(),
    );
  }
}

const Map<String, String> _kDrawerLabelToPageKey = {
  'Dashboard': 'financeDashboard',
  'Class Fees': 'financeClassFees',
  'Student Discounts': 'financeStudentDiscounts',
  'Generate Fees': 'financeGenerateFees',
  'Fee Ledger': 'financeFeeLedger',
  'Collect Payment': 'financeCollectPayment',
  'Payment History': 'financePaymentHistory',
  'Profile': 'profile',
};

/// The 4 bottom-nav tabs, in index order. Every other page-key is a "sub"
/// destination reached via the drawer or from within another page - it
/// renders with a back button instead of a bottom-nav tab highlighted.
const List<String> _kTabPageKeys = [
  'financeDashboard',
  'financeFeeLedger',
  'financeCollectPayment',
  'profile',
];

class FinanceMobileShell extends StatefulWidget {
  const FinanceMobileShell({super.key});

  @override
  State<FinanceMobileShell> createState() => _FinanceMobileShellState();
}

class _FinanceMobileShellState extends State<FinanceMobileShell> {
  String _selectedPage = 'financeDashboard';
  Object? _selectedArguments;
  int _lastTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _navItems = [
    (icon: Icons.grid_view_rounded, label: 'Dashboard'),
    (icon: Icons.list_alt_rounded, label: 'Fee Ledger'),
    (icon: Icons.payments_rounded, label: 'Collect'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  void _navigateToPage(String pageKey, {Object? arguments}) {
    setState(() {
      _selectedPage = pageKey;
      _selectedArguments = arguments;
      final tabIndex = _kTabPageKeys.indexOf(pageKey);
      if (tabIndex != -1) _lastTabIndex = tabIndex;
    });
  }

  void _onDrawerNavigate(String label) {
    final pageKey = _kDrawerLabelToPageKey[label];
    if (pageKey != null) _navigateToPage(pageKey);
  }

  String? get _currentDrawerLabel {
    for (final entry in _kDrawerLabelToPageKey.entries) {
      if (entry.value == _selectedPage) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isTabPage = _kTabPageKeys.contains(_selectedPage);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kAdminBg,
      drawer: FinanceDrawer(
        currentLabel: _currentDrawerLabel,
        onNavigateRoot: _onDrawerNavigate,
      ),
      body: SafeArea(
        child: FinancePageChrome(
          header: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: isTabPage
                ? FinanceRootPageHeader(
                    title: 'Finance',
                    subtitle: context.watch<AuthProvider>().school?.name,
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  )
                : Row(
                    children: [
                      InkWell(
                        onTap: () =>
                            _navigateToPage(_kTabPageKeys[_lastTabIndex]),
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
                      const SizedBox(width: 12),
                      const Text(
                        'Finance',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: kAdminNavy,
                        ),
                      ),
                    ],
                  ),
          ),
          child: buildFinanceRolePage(
            _selectedPage,
            _selectedArguments,
            _navigateToPage,
          ),
        ),
      ),
      // The keyboard covers the bar anyway; dropping it frees the height for
      // forms instead of squeezing the page between keyboard and navigation.
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : FinanceBottomNav(
              items: _navItems,
              index: _lastTabIndex,
              onChange: (i) => _navigateToPage(_kTabPageKeys[i]),
            ),
    );
  }
}
