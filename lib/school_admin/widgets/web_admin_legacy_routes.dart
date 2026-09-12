/// Retired web-only entry points. Shared mobile Parents pages remain available.
bool isRetiredWebAdminRoute(String? route) {
  final path = Uri.tryParse(route ?? '')?.path.replaceAll(RegExp(r'/+$'), '');
  return const {
    'parents',
    '/parents',
    '/admin/parents',
    '/school-admin/parents',
  }.contains(path);
}

String supportedWebAdminPage(String page) =>
    isRetiredWebAdminRoute(page) ? 'students' : page;
