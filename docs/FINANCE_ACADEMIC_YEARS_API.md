# FINANCE role: academic years (contract in use by the Flutter app)

The FINANCE role reads academic years from its own endpoint. School Admin is
unchanged and keeps `/api/school-admin/academic-years` (+ `/active`).

```
GET /api/finance/academic-years          (role FINANCE, Finance feature enabled)
200 { "success": true,
      "data": [ { "id": 3, "school_id": 1, "name": "2026-2027",
                  "start_date": "...", "end_date": "...", "is_active": 1 } ] }
```

* Ordered newest `start_date` first. The active year is the row with
  `is_active == 1`; with no active row the app uses the existing rule (newest).
* There is no `/active` or write endpoint for FINANCE; the client only issues
  this one GET.
* `403 { code: "FINANCE_NOT_ENABLED" }` shows the existing Finance-disabled state.
* Other failures show "Could not load academic years." with Retry.

Flutter: `AcademicYearsService.finance()` (`lib/services/academic_years_service.dart`)
feeds a FINANCE-scoped `AcademicYearsProvider` created in `FinanceDashboardScreen`;
all Finance pages read that shared provider (no per-page year requests).

Runtime note: the dashboard responds with the year under `academicYear`
(camelCase) although Swagger documents `academic_year`; `FinanceDashboard`,
the fee-generation result and the fee-ledger page accept both.
