# School Admin desktop Web/PWA branding cleanup

The School Admin Web/PWA no longer exposes the Parents page or route. The Web sidebar now uses the actual Dugsi logo asset rather than the generic icon, and all desktop Web/PWA loading, error, retry, selection, and action states use the Dugsi navy/green brand theme instead of Flutter’s default purple. The mobile app UI was not changed.

## Requested results

1. **Parents sidebar item:** removed completely. Students retains All Students and Add Student, with its existing compact expand/collapse behavior.
2. **Parents web route:** removed from the shell page map. Retired internal navigation keys resolve to Students. `/parents`, `/admin/parents` and `/school-admin/parents` (including trailing slashes/query strings) resolve through the normal authenticated root entry point, yielding the dashboard for a signed-in school admin and the normal login flow otherwise.
3. **Dead references:** the web shell no longer imports or creates `AdminParentsScreen`. Remaining web mentions are confined to the compatibility redirect helper. Mobile Parents pages, drawer links, models and services remain intact.
4. **Logo source:** `assets/dugsi logo-04.png`, with a literal space in the Flutter asset key.
5. **pubspec:** unchanged; the existing `assets/` declaration already includes the PNG.
6. **Logo implementation:** `Image.asset`, `BoxFit.contain`, a 48px header image region and responsive width. Layout clips the source image’s empty canvas padding without stretching its artwork. The optional school name appears below with ellipsis. School branding no longer replaces the Dugsi logo.
7. **Purple root cause:** `lib/main.dart` seeded the inherited Material color scheme with `Colors.deepPurple`. Unstyled retry buttons, spinners and selections inherited that scheme.
8. **Global correction:** the desktop-web builder applies `webAdminTheme` above the Navigator so dialogs, date pickers and menu routes inherit it too. It reuses `FormTheme3D.primaryBlue`, `primaryGreen`, `errorRed` and existing neutral tokens. The color scheme, progress indicators, text/outlined/elevated/filled buttons, checkbox/radio/switch states, input focus and text selection are configured. The existing native theme is retained verbatim.
9. **Loading/error/retry checks:** a real Levels page request was held pending, failed with HTTP 500, then retried successfully through a mock client. Loading and Retry inherited navy. Other tests exercise default indicators and the selected-control theme values.
10. **Remaining purple:** two intentional native/narrow-layout fallbacks remain: the original root theme seed in `lib/main.dart`, and the non-desktop release button in `admin_marks_screen.dart`. Desktop web overrides both. The desktop Friday day-off chip was changed from a purple hex color to navy. The School Admin hexadecimal-color audit found no remaining saturated purple literals.
11. **Responsive checks:** 960, 1024, 1130, 1280, 1366, 1440 and 1920px. Logo decoding, sidebar navigation and state controls pass at every size. An additional 29 desktop-branch render/dialog checks pass. Production still uses the existing 1024px desktop-web breakpoint; at 960px the existing narrow presentation and theme are retained.
12. **Files:** listed below.
13. **flutter analyze:** zero errors; 116 existing warnings and 1,128 informational diagnostics remain. Exit code 1 reflects those diagnostics, not a compile failure.
14. **flutter test:** all **327 tests pass**. Additional generated desktop render checks: **29 pass**.
15. **flutter build web:** succeeds. The built `assets/assets/dugsi%20logo-04.png` is byte-identical to the source PNG. The standard JavaScript build succeeds; the existing optional Wasm dry-run dependency warnings remain.

## Files changed for this task

- `lib/main.dart`
- `lib/school_admin/widgets/web_admin_theme.dart`
- `lib/school_admin/widgets/web_admin_legacy_routes.dart`
- `lib/school_admin/widgets/web_admin_shell.dart`
- `lib/school_admin/widgets/web_sidebar.dart`
- `lib/school_admin/pages/admin_marks_screen.dart`
- `lib/school_admin/pages/teacher_day_off_page.dart`
- `test/web_branding_test.dart`
- `test/web_sidebar_parity_test.dart`
- `test/web_admin_desktop_test.dart`
- This report.

## Verification limits and preview

[Sidebar/logo and themed desktop preview](../build/desktop_ui_check/levels_1366.png)

Browser automation remains unavailable in this session; the earlier minimal Chrome test runner also stalled before running tests. No live browser hard-refresh or deployed-site old-URL navigation is claimed. Asset decoding and built-file equality were verified locally, and route compatibility was checked in tests. Desktop screenshots use the previously documented native-renderer fallback with test-only copies; production platform guards are unchanged.

No backend, database, API contracts, mobile drawer or mobile theme changes were made. No APK build was run because this task changed presentation/navigation only. No deployment was performed.
