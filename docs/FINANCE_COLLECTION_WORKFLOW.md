# Finance monthly collections

Implemented in the Flutter repository only. API contracts follow the completed backend work supplied in the conversation; no backend files were opened or modified for this task.

## API integration

Both roles share typed models and `FinanceCollectionService`. FINANCE uses `api/finance`; School Admin uses `api/school-admin/finance`. The existing authenticated ApiClient supplies the token.

- `GET students`: academic_year_id, optional class_id/search, page and limit. Parses students with student_id, student_name, emis_number, class_id, class_name, academic_year_id, and pagination. Membership lookup does not request fees.
- `GET collections/class`: academic_year_id, class_id, billing_month and billing_year. Parses academicYear, class, billingPeriod and students. Financial values remain nullable for missing fees.
- `POST collections/class`: the four scope values and payments containing student_id/method. The normal class workflow deliberately omits amount, instructing the backend to use the current remaining balance under lock. Displayed totals sum the last fetched remaining balances and are not authoritative. Each response entry is parsed as an ordinary individual payment/receipt result.
- `POST payments`: the existing individual path retains explicit amount, method, optional reference and notes (500 maximum).

## Final report

1. **Flutter files changed:**
   - `lib/finance/models/finance_collection.dart` — typed students, periods, register rows, batch requests/results and student validation issues.
   - `lib/finance/services/finance_collection_service.dart` — role-scoped lookup, register, bulk collection and collection-change notifications.
   - `lib/finance/services/finance_payment_service.dart` — notify dashboards after successful individual collection.
   - `lib/finance/pages/class_collection_page.dart` — monthly register and batch collection.
   - `lib/finance/pages/collect_payment_page.dart` — stable entry point into the new workflow.
   - `lib/finance/pages/individual_payment_page.dart` — preserved individual flow, now with real student lookup and explicit stable focus.
   - `lib/finance/pages/student_discounts_page.dart` — enrollment-based lookup for both roles.
   - `lib/finance/pages/finance_dashboard_page.dart` — mounted dashboards refetch after collection.
   - `lib/finance/widgets/finance_ui.dart` — optional stable FocusNode on the shared search field.
   - `lib/finance/widgets/finance_student_picker.dart` — stable picker FocusNode.
   - `test/finance_class_collection_test.dart` — new service/model/widget tests.
   - `test/finance_collect_payment_search_test.dart`, `test/finance_keyboard_test.dart`, `test/finance_admin_ui_test.dart`, `test/finance_workflows_test.dart` — updated workflow expectations and student API fixtures.
   - This report. Existing unrelated working-tree changes were preserved.
2. **Collect redesign:** Primary title is Collect Fees with “Record monthly fee collections for students.” Existing Collect navigation routes and the four bottom-navigation items are preserved.
3. **Academic year:** Uses the existing AcademicYearsProvider, ensureFinanceYears, selectedFinanceYear and FinanceYearSelector; preserves the shared remembered selection and active-year default behavior.
4. **Month:** Calendar month/year options derive from academic-year start/end dates. Current month is selected when valid, otherwise the first valid month. Invalid/missing date ranges expose no selectable billing period.
5. **Class:** Loads real classes from class-fees for the selected year; no hardcoded class IDs or names. Filters reset selection and request generations discard superseded responses.
6. **Register:** Displays every returned student, EMIS, fee, already paid, remaining balance, and status. Uses backend snapshot amounts only.
7. **Search:** Class filtering is local over the complete fetched register. Individual payment and discount selection call the new students endpoint with name/EMIS and year context; discount selection also retains class scope.
8. **Focus:** Controllers and FocusNodes live in State and are disposed normally. Search stays mounted through loading/results and keyboard resize. Individual/picker searches debounce for 250 ms without dismissing focus.
9. **Selection:** One or multiple eligible students can be selected/deselected. Checkboxes never persist payments.
10. **Select All:** Selects eligible rows currently shown by the class search; label explicitly says “Select all eligible shown.” Paid, zero-balance, fully discounted and missing-fee rows cannot be selected. Existing selections outside the search remain counted.
11. **Method:** Confirmation requires CASH, MOBILE, BANK or CARD. A selected row can override the batch method.
12. **Confirmation:** Uses the shared AdminFeatureDialog with class, billing period, selected count, displayed total and payment method. Explicitly states that payments were already received by the school.
13. **Bulk save:** Uses one transactional backend request. Saving locks local controls and prevents repeated taps. Success clears selection and refetches the register; statuses are never optimistically invented.
14. **Failure:** Shows safe batch messages and student names alongside mapped validation errors. Retains filters and selections on rejection. An uncertain network response disables resubmission until balances are refreshed and tells the user to check history.
15. **Missing fees:** Shows “Fee not generated,” null financial values as dashes, a period-specific notice, and the existing Generate Fees navigation action. No silent generation request.
16. **Individual:** Secondary Individual Payment action retains student lookup → fee periods → form → existing payment endpoint → individual receipt dialog. Existing ledger preselection links still work.
17. **Partial:** Existing explicit amount validation, method, reference and notes remain supported by the individual flow. Notes retain maxLength 500 and service validation. Normal class collection records the backend's remaining amount.
18. **Discounts:** Both roles now find enrolled students through the corresponding Finance students endpoint; FINANCE no longer needs a fee row and never uses School Admin student endpoints.
19. **Dashboard:** Successful collection emits a change notification. Mounted dashboards refetch totals and recent payments. Dashboards opened afterward already load through their normal API lifecycle.
20. **Receipts/history:** No client-only batch ledger. Existing payment history navigation, individual receipt API and download helper remain intact.
21. **Mobile:** Compact shared white Finance cards, navy typography, green/amber/status accents, responsive filters and scrollable page content.
22. **Desktop/PWA:** Existing shell retained; a register table replaces the cards when enough content width is available. Horizontal scrolling protects the table at tighter desktop widths.
23. **Responsive tests:** Covered 360×640, 360×800, 390×844 and 412×915 with simulated keyboard insets, plus desktop register behavior and existing broader responsive suites. No test-reported overflow or focus loss.
24. **Finance tests:** Focused new collection tests (12) and individual search tests (14) passed. The initial full Finance run identified old endpoint/title fixtures; after updates, the affected 55 UI/keyboard tests passed. All 171 Finance tests are included in the passing full repository run.
25. **Full tests:** `flutter test --no-pub --reporter expanded`: 599 passed.
26. **Analyzer:** Focused `flutter analyze --no-pub lib/finance test/finance_class_collection_test.dart test/finance_collect_payment_search_test.dart test/finance_keyboard_test.dart` passed with no issues. Full `flutter analyze --no-pub` reports 1,253 existing repository issues, including errors in old `build/finance-edit-backups/*.dart` files dated September 19 and unrelated warnings/information. No analyzer exclusions or unrelated code were changed to hide them.
27. **Web release:** `flutter build web --release --no-pub` passed; output is `build/web`. Existing dependencies report Wasm dry-run incompatibilities, which do not block the standard JavaScript release build.
28. **Boundary:** All task source/test changes are Dart files under this Flutter repository, plus this Markdown report. No Express, Swagger, migration, SQL or other backend files were introduced. The backend repository was not modified.
29. **Remaining verification:** No live school payments were submitted; automated API tests use mock responses. Real-device/browser and live-service acceptance testing remain separate from widget tests. Existing repository-wide analyzer issues remain outside this task.

Finance can select an academic year, month and class, view the class fee register, select one or multiple students who paid, and save the collection in one operation. Individual and partial payments remain available. Student search uses the Finance student endpoint and no longer depends on generated fee rows.
