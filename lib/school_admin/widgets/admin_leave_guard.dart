/// Lets the page currently shown inside the desktop School Admin shell veto
/// shell navigation (sidebar / top bar) while it holds unsaved work.
///
/// Mobile pages are pushed routes and use `PopScope` instead; this only
/// covers the desktop shell, which swaps pages without popping a route.
typedef AdminLeaveCheck = Future<bool> Function();

class AdminLeaveGuard {
  AdminLeaveGuard._();

  static AdminLeaveCheck? _check;

  static void register(AdminLeaveCheck check) => _check = check;

  static void unregister(AdminLeaveCheck check) {
    if (identical(_check, check)) _check = null;
  }

  /// True when navigation may proceed (no guard, or the user chose Discard).
  static Future<bool> confirmLeave() async {
    final check = _check;
    return check == null ? true : await check();
  }
}
