# Desktop Web/PWA redesign — 12 September 2026

Only the Flutter Web/PWA desktop admin UI was redesigned. The mobile app pages and mobile drawer remain visually unchanged. Timetable, Levels, Shifts, and Teacher Day Off now use the supplied full-width desktop reference design, the Web sidebar is more compact with true click-to-expand/click-to-collapse groups, and multiple teacher days off are grouped side-by-side in one desktop table row.

The presentation uses the existing `kIsWeb && width >= 1024` boundary. At 960px the existing narrow web presentation remains. The existing topbar, service contracts, backend and database were not redesigned or modified for this task. Earlier authorized safe-delete and timetable-generator work remains in the workspace.

## Requested report

| # | Area | Result |
|---|---|---|
| 1 | Web sidebar | Compact persistent navigation retains school branding, all routes and feature gates, selected states and Logout. The timetable group is labelled Time Table. |
| 2 | Row heights | Parent content reduces from 54px to 38px, with outer vertical margins reduced from 6px to 2px. Child padding reduces from 20px to 14px vertically, indentation from 60px to 24px, and separators from 17px to 2px. Labels remain one line. |
| 3 | Expand/collapse | Expansion is independent from route selection. Clicking an active parent collapses it completely; the parent remains highlighted. A route change opens the appropriate group. |
| 4 | Timetable | Full-width page and table, seven requested columns, wrapping filter/action toolbar, weekday tabs, Add Slot, year context, totals and pagination. Existing generation, print, clear-year and slot handlers remain connected. Desktop clear-year dialog is bounded and scrollable. |
| 5 | Levels | Actual totals, search and full-width table with create, assign and safe-delete actions. No unsupported Edit or invented created-date field. |
| 6 | Shifts | Actual totals, search and full-width table retain create, edit, class assignment and delete. No fabricated description/date fields. |
| 7 | Teacher Day Off | Year selector, random generation, manual entry, actual teacher/entry totals and coverage calculated from the intersection with loaded teacher IDs. |
| 8 | Multiple days | One row per teacher; distinct days are compact wrapping chips with individual removal. One group Edit opens the existing multi-day editor; one group Delete confirms the listed days and uses existing individual delete endpoints. On a failure it stops and reloads the records. |
| 9 | Responsive widths | 960, 1024, 1130, 1280, 1366, 1440 and 1920px checked. 29 desktop render/sidebar tests pass, including dialog bounds, table width, chip placement and absence of layout exceptions. See the browser limitation below. Compact desktop tables scroll horizontally. |
| 10 | Mobile regression | Four 390×844 screenshot comparisons pass pixel-for-pixel. Timetable and Teacher Day Off are compared with reconstructed HEAD-source baselines; Levels and Shifts are compared with their preserved narrow presentation branches, retaining earlier authorized changes. Mobile drawer source is unchanged. APK regression build succeeds. |
| 11 | Files | Listed below, separately from earlier work already in the workspace. |
| 12 | flutter analyze | Run successfully as a check: **0 errors**, 116 warnings and 1,128 informational diagnostics remain across the repository. The command exits 1 because of those diagnostics; it is not a clean lint result. |
| 13 | flutter test | **317 tests pass** in the full native suite. Additional desktop-branch render checks: **29 pass**. Mobile screenshot comparisons: **4 pass**. |
| 14 | flutter build web | **Pass**, final output in `build/web`. Standard JavaScript release build succeeds. Existing dependency incompatibilities are reported by the optional Wasm dry run. |

## Browser verification limitation

The browser plugin reported no available browser. Flutter's Chrome JavaScript and Wasm test runners both stalled before executing tests; a minimal browser smoke test stalled too. Consequently, this report does **not** claim live Chrome/PWA interaction validation.

For the fallback, `tool/prepare_desktop_render_check.cjs` generates copies under `build/` that enable the desktop platform guard on Flutter's native test renderer. Production guards are untouched. The same desktop widgets, fixtures, callbacks and seven viewport sizes are exercised, and previews are captured with Roboto and Material icons. These previews include the content and sidebar; the unchanged app topbar is outside the test harness. Fixtures are test data, not production records.

## Changed files for this redesign

- `lib/school_admin/widgets/web_admin_reference_kit.dart` — shared desktop header, statistics, cards, controls, table, search and pagination.
- `lib/school_admin/widgets/web_sidebar.dart` — compact navigation and independent expansion state.
- `lib/school_admin/pages/admin_timetable_screen.dart` — desktop body and desktop dialog sizing.
- `lib/school_admin/pages/exam_hall_management_pages.dart` — separate desktop Levels and Shifts presentations.
- `lib/school_admin/pages/teacher_day_off_page.dart` — separate desktop presentation and group action.
- `test/web_admin_desktop_test.dart`, `test/web_sidebar_parity_test.dart` — layout, dialog and navigation checks.
- `test/support/font_io.dart`, `test/support/font_web.dart`, `test/support/roboto-regular.ttf`, `test/support/roboto_license.txt` — test-only font loading; not added to app assets.
- `tool/prepare_desktop_render_check.cjs`, `tool/prepare_mobile_visual_check.cjs` — reproducible render comparisons with generated-source cleanup.
- This report.

## Preview artifacts

- [Timetable, 1366px](../build/desktop_ui_check/timetable_1366.png)
- [Levels, 1366px](../build/desktop_ui_check/levels_1366.png)
- [Shifts, 1366px](../build/desktop_ui_check/shifts_1366.png)
- [Teacher Day Off, 1366px](../build/desktop_ui_check/days_1366.png)
- Corresponding compact previews: `build/desktop_ui_check/*_1024.png`.
- Mobile before/after pairs: `build/mobile_ui_baseline/*_before.png` and `*_after.png`.

## Reproduce the extra render checks

Run these sequentially. Generated Dart copies are removed after verification so they do not add duplicate diagnostics to `flutter analyze`; screenshots remain under `build/`.

```powershell
node tool/prepare_desktop_render_check.cjs
flutter test --no-pub --update-goldens build/desktop_ui_check_test.dart
node tool/prepare_desktop_render_check.cjs --cleanup

node tool/prepare_mobile_visual_check.cjs
flutter test --no-pub build/mobile_visual_comparison_test.dart
node tool/prepare_mobile_visual_check.cjs --cleanup
```

When the Chrome runner is working, the real web-platform tests can be run directly:

```powershell
flutter test --no-pub --platform chrome test/web_admin_desktop_test.dart
```

No deployment to `portal.dugsi.so` was performed.
