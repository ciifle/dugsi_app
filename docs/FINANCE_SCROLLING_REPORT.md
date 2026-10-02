# Finance scrolling report

## Correction: fixed shell navigation

The later user correction supersedes the earlier scrolling-header behavior described below. FinancePageSurface now lays out the shell header above an Expanded content viewport. The Finance top bar, school identity, menu/back controls, desktop sidebar and mobile bottom navigation stay fixed. Only page titles, descriptions, filters, summaries, forms, records and pagination scroll together. Desktop shell titles now say Finance, with the actual page title inside the scroll. The separate School Admin mobile menu also keeps its back control and Finance heading fixed while its description and menu content scroll.

Updated widget tests assert fixed header geometry and visibility while page titles and long content scroll, at all four requested phone sizes; mobile bottom navigation and desktop sidebar assertions remain. The full suite passed 645 tests. Final targeted checks and release build results are recorded in FINANCE_SCROLLING_CORRECTION.md. No Finance service or backend behavior changed.

The Finance top bar, drawer/menu control, school identity and mobile bottom navigation remain fixed. Only the Finance page content between the top and bottom navigation scrolls as one continuous area. Page titles, descriptions, filters, cards/forms, records and pagination scroll together.

## Previous implementation record (superseded where it describes scrolling navigation)

Scope: Dugsi Flutter/PWA only. The preceding monthly collection workflow is preserved. This layout update does not change services, calculations, payment contracts, receipts, or backend files.

1. **Audit:** Dashboard, Finance menu, Users, Class Fees, Discounts, Generate Fees, Fee Ledger, Student Ledger, monthly Collection, Individual Payment, Payment History, Payment Details and Profile. The menu already uses one ListView. Payment Details and editing forms remain branded, internally scrollable dialogs.
2. **Shared layout:** FinancePageSurface owns the vertical SingleChildScrollView, with responsive content padding and 32 pixels of trailing space. FinancePageChrome supplies shell headers inside that scroll. FinancePageFrame also places standalone back navigation inside it. Removed the artificial minimum page height.
3. **Fee Ledger:** Header, title, filters, cards/table and pagination share the page viewport. Twenty-row tests verify the heading leaves the screen and pagination remains reachable.
4. **Payment History:** Same layout; no separate scrolling payment box. Receipt, details and filtering actions remain intact.
5. **Collect Fees:** Academic year/month/class controls, search, summary, full class register and final save action flow together. Twenty-student tests reach the final student and save action on every requested phone size.
6. **Dashboard:** Summary, charts and recent payments use the shared page scroll without an inner vertical scroll.
7. **Profile:** Profile cards and actions flow inside the shared viewport.
8. **Finance Users:** Removed the fixed heading/filter and Expanded records arrangement. Pagination is in the page flow.
9. **Class Fees:** Class cards/table share the heading and filters' viewport; long fixtures reach Class 19.
10. **Student Discounts:** Student cards/table share the page viewport; long fixtures reach Discount Student 19.
11. **Generate Fees:** Controls, preview and generation results use the shared viewport; removed its redundant vertical scroll.
12. **Individual Payment:** Student/fee selection, amount, method, reference, notes and final actions share the page scroll. The return-to-class action is also inside it. Student Ledger keeps its title visible structurally during loading and errors, and its tables share the same page scroll.
13. **Keyboard:** Existing controller/focus lifetimes and manual keyboard dismissal are preserved. Expanded mobile filters no longer create a competing vertical scroll. Existing keyboard/search tests pass; multiline text fields may still scroll their own text normally.
14. **Bottom navigation:** Remains outside the body, fixed in the Scaffold, with existing keyboard hiding. Tests verify its rectangle stays fixed and pagination appears above it.
15. **Desktop/PWA:** Finance and School Admin Finance headers move with content; the sidebar stays fixed. Non-Finance School Admin pages retain their existing layout. Horizontal table scrolling remains supported.
16. **Nested scrolling:** Removed page-level nested SingleChildScrollViews, fixed Expanded record regions, the filter panel's height cap/scroll, and skeleton scrolling. Dialogs and navigation drawers remain independently scrollable where appropriate.
17. **Pagination:** Fee Ledger, Payment History and Users have state-owned scroll controllers. Page changes return to the top. Ordinary list loading retains current records, with a progress indicator and temporarily blocked record actions, avoiding collapse during refresh.
18. **Widget coverage:** Added 46 scrolling tests: ten pages and full-class collection at 360x640, 360x800, 390x844 and 412x915, plus fixed mobile navigation and desktop sidebar/header behavior. Uses twenty-record fixtures for ledger/history/users/classes/discounts/collection. Existing modal, keyboard, search and workflow tests provide additional regression coverage.
19. **Full tests:** `flutter test --no-pub --reporter expanded` passed: 645 tests, including all 46 new scrolling tests.
20. **Analyzer:** Focused analysis of all Finance source, the modified School Admin shell and affected tests passes with no issues. Full analysis reports 1,238 existing repository issues; no exclusions were added to hide them.
21. **Web release:** `flutter build web --release --no-pub` passed in 198.4 seconds; output is `build/web`. Existing dependency Wasm dry-run incompatibility warnings do not prevent the standard JavaScript release build.
22. **Remaining issues:** Repository-wide analyzer findings remain. `git diff --check` also reports pre-existing whitespace in `lib/shared/pages/login_screen.dart`, which was not edited for this task. Widget tests use mocked APIs and simulated screen/keyboard sizes; physical-device and live-service acceptance testing was not performed. No live payments were submitted. The column-based shared scroll builds all rows on the current page; unusually large unpaginated registers may eventually benefit from sliver virtualization.

Changed layout files: `lib/finance/widgets/finance_ui.dart`, `finance_web_shell.dart`, Finance page files under `lib/finance/pages/`, and `lib/school_admin/widgets/web_admin_shell.dart`. Tests: `test/finance_page_scrolling_test.dart`.

All Finance pages now use a page-level vertical scroll. The page header, title, filters and content scroll together, while the Finance bottom navigation remains fixed. Fee Ledger and Payment History no longer use a fixed top section with only the records scrolling.
