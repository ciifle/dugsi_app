# Backend: School-Level Fees/Payment Feature Flag

This document specifies what the **backend** must implement so the Flutter app can hide fees/payment UI per school. The Flutter app has been updated to read a `feesEnabled` flag and hide all fee/payment UI when it is false.

---

## 1. Where to store the flag

**Preferred:** Add to the **School** model/entity (or existing school settings table):

- `fees_enabled` (boolean, default `true` for backward compatibility)

If the project already has a generic **school settings** or **feature flags** structure, use that instead and add a key such as `fees_enabled`.

**Alternative:** If auth/me is built from a join with school, add the flag to the **auth/me response** at the top level or under a `school` object (see below).

---

## 2. Expose the flag to the app

The app loads user/profile early via **GET /api/auth/me**. The backend must include whether fees are enabled for the **current user’s school** in that response.

**Option A – Top-level (simplest for the app):**

```json
{
  "user": { ... },
  "profile": { ... },
  "feesEnabled": true
}
```

**Option B – Nested under `school`:**

```json
{
  "user": { ... },
  "profile": { ... },
  "school": {
    "id": 1,
    "name": "...",
    "fees_enabled": true
  }
}
```

The Flutter app already supports both:

- Top-level: `data['feesEnabled']`
- Nested: `data['school']['fees_enabled']` or `data['school']['feesEnabled']`

Use **camelCase** (`feesEnabled`) in JSON if that matches the rest of the API; otherwise **snake_case** (`fees_enabled`) is also parsed.

---

## 3. Super admin: school create/update

- **Create school:** Allow setting `fees_enabled` (or equivalent) in the request body. Default to `true` if omitted.
- **Update school:** Allow updating `fees_enabled`.
- **Validation:** Treat as boolean (or string "true"/"false").
- **Response:** Include the flag in the school create/update response so the admin UI can show it.
- **Swagger/OpenAPI:** Document the new request/response field(s).

---

## 4. Protect fee/payment endpoints

When the **school** associated with the request has `fees_enabled === false`:

- Return **403 Forbidden** (or 404 if you prefer to hide existence).
- Optionally return a body such as:  
  `{ "message": "Fees are not enabled for this school." }`

Apply this to all fee- and payment-related endpoints, for example:

- List/create/update/delete fees
- List payments / payment history
- Record payment / pay fee
- Any other endpoints that read or write fee/payment data for the school

The Flutter app already handles 403 from fee endpoints (e.g. student pay-fee screen) and will show a friendly message when the feature is disabled.

---

## 5. Default for existing schools

- **Migration:** Add the column with default `true` so existing schools keep current behaviour.
- **Existing rows:** No need to backfill; default value is enough.

---

## 6. Summary checklist (backend)

- [ ] Add `fees_enabled` (or equivalent) to school model/settings.
- [ ] Migration: default `true`.
- [ ] Include flag in **GET /api/auth/me** (top-level `feesEnabled` or `school.fees_enabled` / `school.feesEnabled`).
- [ ] Super admin: school create/update accept and return the flag.
- [ ] All fee/payment endpoints check the flag and return 403 when disabled.
- [ ] Update Swagger/OpenAPI for changed request/response schemas.

---

## 7. Flutter side (already done)

- **Auth:** `AuthMeResponse` and `AuthProvider` expose `feesEnabled` (default `true` when null).
- **Persistence:** `AuthStorage` persists `feesEnabled` so it survives app restarts.
- **UI:** All fee/payment menu items, dashboard cards, tabs, and screens are hidden or guarded when `feesEnabled` is false; direct navigation to a fee screen shows a “not enabled” message.

No further Flutter changes are required once the backend returns the flag and protects the endpoints as above.
