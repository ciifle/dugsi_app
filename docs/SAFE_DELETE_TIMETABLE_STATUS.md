# Safe delete and timetable update — 2026-09-11

Dependency-aware deletion for Class, Level, and Academic Year is implemented and wired end to end. The contract was cross-checked against the live backend OpenAPI spec at `https://api.dugsi.so/api-docs/swagger.json` (tag "Safe Admin Deletion"), confirming every URL, method, and query parameter used by the client.

## Verified backend contract

| Entity | Preview | Confirmed delete |
|---|---|---|
| Class | `GET /api/school-admin/classes/{id}/delete-preview` | `DELETE /api/school-admin/classes/{id}?force=true` |
| Level | `GET /api/school-admin/levels/{id}/delete-preview` | `DELETE /api/school-admin/levels/{id}?force=true&class_action=detach\|delete` |
| Academic Year | `GET /api/school-admin/academic-years/{id}/delete-preview` | `DELETE /api/school-admin/academic-years/{id}?force=true[&confirm_active=true]` |

Preview responses carry `can_delete`, `requires_confirmation`, the entity object (`class`/`level`/`academic_year`, keyed by kind) and an `impact` map of foreign-key counts. `confirm_active` is only required (and only sent) when the academic year's `is_active` is true. A 409 on the delete call returns the same preview shape so the dialog can refresh and ask for confirmation again; 500 responses are treated as a safe generic failure. Per the spec, HTTP 200 unconditionally means "Deletion completed" — the client no longer requires a specific success-body field to treat a 200 as success.

## Entry points

- Class: `AdminClassesPage._deleteClass` (`lib/school_admin/pages/admin_classes.dart`).
- Level: `LevelsPage._delete` (`lib/school_admin/pages/exam_hall_management_pages.dart`) — this app manages levels inside Exam Hall Management, there is no separate "Levels" page.
- Academic Year: `_AcademicYearsPageState._delete` (`lib/school_admin/pages/academic_years_page.dart`), with a visible Delete button on every year card (active and inactive).

All three call `showAdminDeletionFlow` (`lib/school_admin/widgets/dependency_delete_dialog.dart`), which loads the preview, renders the shared confirmation dialog, and issues the confirmed/force delete only after explicit acknowledgment. No page still calls the legacy raw `ClassesService.deleteClass` / `ExamHallService.deleteLevel` methods (they remain only as sanitization-covered fallbacks exercised by tests).

## Shared academic-year state

`AcademicYearsProvider` (`lib/services/academic_years_service.dart`) tombstones deleted year IDs so in-flight/stale `list()`/`active()` responses can never resurrect a deleted year or its active status; `removeDeletedYear` clears it from `years` and `activeYear` immediately on confirmed delete. `admin_class_details_screen.dart` watches the provider and resets its selected year (with a "selected academic year was deleted" message) if the year it was viewing disappears.

## Raw database errors

`safeDeleteError` (`lib/services/delete_error_message.dart`) strips FOREIGN KEY/CONSTRAINT/SQL/Sequelize/stack-trace/HTML diagnostics from every delete path (preview, confirmed delete, and the legacy service methods) and falls back to "Unable to delete this item. Please try again."

## Validation

- `flutter analyze`: 0 errors (1,251 pre-existing warnings/info unrelated to this work, unchanged).
- `flutter test`: 231 passed, including `test/admin_deletion_contract_test.dart` (request/response contract, active/inactive year flags, stale-response filtering) and `test/dependency_delete_dialog_test.dart` (dialog behavior, sanitized errors, responsive layout).
