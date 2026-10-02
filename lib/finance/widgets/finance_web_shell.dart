import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/web_top_bar.dart';
import 'package:kobac/services/auth_provider.dart';

import 'package:kobac/finance/widgets/finance_role_pages.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';
import 'package:kobac/finance/widgets/finance_web_sidebar.dart';

/// FINANCE role's own persistent desktop/PWA shell — the same layout as
/// School Admin's [WebAdminShell] (sidebar + [WebTopBar] + content), with a
/// disjoint page-key namespace (`finance*`) and the same content pages
/// (`basePath: kFinanceRoleBasePath`).
class FinanceWebShell extends StatefulWidget {
  const FinanceWebShell({super.key});

  @override
  State<FinanceWebShell> createState() => _FinanceWebShellState();
}

class _FinanceWebShellState extends State<FinanceWebShell> {
  String _selectedPage = 'financeDashboard';
  Object? _selectedArguments;

  void _navigateToPage(String pageKey, {Object? arguments}) {
    setState(() {
      _selectedPage = pageKey;
      _selectedArguments = arguments;
    });
  }

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidebarWidth = screenWidth >= 1200 ? 260.0 : 220.0;

    return Scaffold(
      backgroundColor: kAdminBg,
      body: Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: FinanceWebSidebar(
              width: sidebarWidth,
              selectedPage: _selectedPage,
              onNavigate: _navigateToPage,
            ),
          ),
          Expanded(
            child: FinancePageChrome(
              header: WebTopBar(
                title: 'Finance',
                onNavigateToPage: _navigateToPage,
                onLogout: _handleLogout,
              ),
              child: buildFinanceRolePage(
                _selectedPage,
                _selectedArguments,
                _navigateToPage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
