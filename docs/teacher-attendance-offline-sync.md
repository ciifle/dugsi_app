# Teacher attendance offline sync

Backend contract: `dugsi_backend/sms-backend/docs/attendance-offline-sync.md` (read-only; no backend changes).

## Endpoints used (all existing, Bearer JWT)

- `GET /api/teacher/dashboard` — assignments, timetables, academic year, teacher profile id
- `GET /api/teacher/classes/{id}/students?academic_year_id=` — enrolled roster
- `GET /api/teacher/attendance/settings` — `timezone`, `grace_minutes`
- `POST /api/teacher/attendance/sync` — up to 10 submissions per request (contract allows 50)
- `GET /api/teacher/attendance/submissions?after_id=` — only while something is still `pending approval`

## Business rule

Valid attendance needs no School Admin approval. The server accepts any receipt after the lesson
starts — during the lesson, within grace, after grace, or on a later day — as `accepted`, and audits
the receipt as `lessonSnapshot.receipt_window` (`open` / `late`). The grace period only decides that
audit label and how long a teacher may correct (PATCH) their own attendance. `pending approval` is
returned only for unverifiable lesson times (`UNVERIFIABLE_SCHEDULE`); submissions the previous
backend release queued as `LATE_SERVER_RECEIPT` stay pending until a School Admin decides them.

## Storage

`shared_preferences` (Android SharedPreferences; `localStorage` on mobile and desktop PWA). Keys are
prefixed `teacher_attendance_v1_<schoolId>_<userId>_`:

- `cache_snapshot` — dashboard + policy + download time
- `cache_roster_<year>_<classId>` — enrolled students
- `entry_<idempotencyKey>` — one key per submission, so tabs never overwrite each other
- `lease` — 60 s best-effort cross-tab sync lock (server idempotency is the real guard)

Logout removes `cache_*` for that teacher and keeps `entry_*`. Session expiry (401) clears nothing.
Another account, or the same user in another school, uses a different prefix and sees nothing.

## Submission

Payload (immutable once saved, resent byte-identical on retry): `idempotency_key` (48 hex chars),
`school_id`, `teacher_id` (teacher profile id from the dashboard; the server checks both),
`academic_year_id`, `class_id`, `timetable_id`, `date`, `recorded_at` (UTC, millisecond precision,
as the backend regex requires) and explicit PRESENT/ABSENT `records`.

A save is allowed only for a lesson in the cached timetable, for an assigned class, on a matching
weekday, not in the future, for students in the cached roster. A lesson can't be saved twice
unless the server rejected the earlier submission.

## States

| State | Meaning |
|---|---|
| Saved Offline | Stored on device, not attempted yet |
| Pending Sync | Attempted; network, server (5xx/408/429) or session problem. Retried with the same key |
| Syncing | Request in flight |
| Synchronized | `accepted` / `already synced` (on time or late), or approved by admin. Uses the server `synced_at` |
| Pending Review | `pending approval`: historical `LATE_SERVER_RECEIPT` or `UNVERIFIABLE_SCHEDULE`. Not stored yet, never re-posted |
| Rejected | `rejected` (validation or admin rejection, with the admin's reason). Kept until the teacher removes it |
| Conflict | `conflict` (`ATTENDANCE_ALREADY_RECORDED`, `IDEMPOTENCY_KEY_REUSED`, changed data at approval) |
| Sync Failed | Request-level 4xx, or an older-app record the server can't accept |

An HTTP 200 is never enough for "Synchronized": the result for that record's idempotency key must
say `accepted` / `already synced`. "Pending Sync" means only "not yet confirmed by the server".

The screen shows device capture time and server receipt time separately. Only the server decides
timeliness.

## HTTP responses from POST /api/teacher/attendance/sync

Paths are built as `<API_URL>/api/teacher/<endpoint>`; `API_URL` must not end in `/api`. POST is only
ever sent to `attendance/sync` (enforced in code); `attendance/submissions` is GET-only history.

| Response | Record state | Automatic retry |
|---|---|---|
| 200 with matching `accepted` / `already synced` | Synchronized | — |
| 200 `pending approval` | Pending Review | decisions polled every 5 min |
| 200 `rejected` / `conflict` | Rejected / Conflict (reason shown) | never (same key can't succeed) |
| 200 without a matching receipt, non-JSON 200, network failure | Pending Sync | yes, same key |
| 404 (route not on this server) | Pending Sync, "service not available" banner | yes, with backoff |
| 401 | Pending Sync, "session expired" banner | after sign-in |
| 403 | Pending Sync, "access denied" banner | yes, with backoff |
| 400 / 409 / 422 (request refused) | Sync Failed, server message shown | no; Retry/Sync Now only |
| 408 / 429 / 5xx | Pending Sync | yes, with backoff (30 s → 10 min) |

## Triggers

App start/login, app resume, connectivity change (`connectivity_plus`, as a hint only), every 30 s
(with exponential backoff to 10 min after failures), Sync Now, and immediately after each save.
Reachability comes only from a real API response: a DNS/socket/timeout failure or a non-JSON 200
(captive portal) counts as offline. After a 401, automatic retries stop until the token changes.

Nothing runs while the Android process is killed or the PWA tab is suspended; sync resumes on next open.

## Early lessons, rejections and older records

- **Timing hint:** when the school timezone has a fixed offset (Africa/Mogadishu and other EAT/Gulf
  zones, UTC), the screen estimates "not started yet" or "grace period ended" from the device clock,
  applying the server's AFTERNOON +12 h rule. A lesson that has not started cannot be saved; a
  lesson past its end + grace period can be saved normally and is accepted without approval. For
  other timezones no estimate is shown and the server decides.
- **Rejection reasons:** server codes (`LESSON_NOT_STARTED`, `STUDENT_NOT_ENROLLED`,
  `ATTENDANCE_ALREADY_RECORDED`, `ADMIN_REJECTED` + admin note, etc.) are shown in plain language;
  `INVALID_SUBMISSION` shows the server's message.
- **Resubmit:** only for `LESSON_NOT_STARTED`, `INVALID_SUBMISSION`/`VALIDATION_FAILED`, and older
  records in a format the server can't accept. It saves a copy with a new key, the same marks and the
  original capture time; the original stays listed as "Replaced". Refused if anything else on the
  device covers the same lesson; the server still refuses if attendance already exists.
- **Older-version records:** checked against the API contract on load. Valid ones are retried with
  their original key. Invalid ones (e.g. microsecond `recorded_at` from earlier Android builds) are
  never sent, never deleted, and offer Resubmit, or "remove and take again" if they contain LATE.

## School Admin

Normal navigation is Take Attendance, Attendance Records and Reports, identical on Android, mobile
web and desktop web (one shared `AdminAttendanceScreen`). Teacher attendance, on time or late, is
ordinary attendance and appears in the register and reports with no admin action. There is no
approval queue, badge, counter or Sync control for School Admins. The policy dialog (timezone,
grace) opens from **Attendance policy** in the header.

A **Legacy Review** tab (short label "Legacy") appears only while
`GET /api/school-admin/attendance/submissions?status=pending approval` returns items: submissions
the previous backend queued as `LATE_SERVER_RECEIPT`, or unverifiable lesson times. It lists only
those, marked `LEGACY PENDING`. A remembered Legacy tab never becomes the landing tab, and the tab
disappears once nothing is pending and the admin leaves it.

- `POST /api/school-admin/attendance/submissions/{id}/decision`: the app sends
  `{"decision":"approve"}` (plain confirmation, no note field) and
  `{"decision":"reject","note":"<reason>"}` (reason required, shown to the teacher). An outdated
  backend that still requires `note` for approvals answers 400; the app then shows "The server did
  not accept the approval" and leaves the submission pending.
- A successful approval reloads any open report; history (accepted, approved, rejected, conflict)
  is never deleted by the app.

## Tests

`test/teacher_attendance_sync_test.dart` (service, mocked contract),
`test/teacher_attendance_layout_test.dart` (390 px and 1440 px widgets) and
`test/admin_attendance_review_test.dart` (Legacy Review and screen navigation at phone, tablet and
desktop widths), `test/admin_attendance_platform_parity_test.dart` (same Attendance flow and no
approval/Sync UI on 10 layouts) and `test/app_update_test.dart` (PWA update prompt keeps the
offline queue).

## Real-device checklist

Use a staging API (`--dart-define=API_URL=…`) and a staging teacher with a lesson today. Record
pass/fail and the time on the device for each step.

**Setup**
1. Install the release APK on an Android phone; open the PWA over HTTPS in Chrome (phone) and on desktop.
2. Sign in online, open Attendance, tap Sync Now. Confirm classes, lesson, students and
   "Grace period: N minutes (timezone)" show. Counter shows "All attendance sent".

**Airplane mode**
3. Turn on airplane mode. Reopen Attendance: classes, lessons and students still load; "Offline" banner shows.
4. Mark Present/Absent and save. Expect "Saved Offline", counter "1 pending sync", no error text.
5. Try saving the same lesson again: refused with a clear message.
6. Force-close the app (Android) / hard-reload the tab (PWA). Record still listed with the same state.
7. Wi-Fi on but no internet (router unplugged, or captive portal): still "Pending Sync", no error.

**Reconnection**
8. Turn airplane mode off and leave the screen open: record turns "Synchronized" within ~30 s, counter
   returns to "All attendance sent". Repeat with Retry instead of waiting.
9. Queue two or three lessons offline, reconnect: all sync once each; check the server has exactly
   one register per lesson.
10. Kill connectivity during a sync (toggle airplane mode while "Syncing"): record returns to
    "Pending Sync" and later syncs without a duplicate.

**Early lesson**
11. Before a lesson starts (school time), select it: "has not started yet" shows and saving is
    blocked. After the start time it saves. After lesson end + grace it also saves, showing
    "Attendance can be submitted after the lesson…" with no approval wording.

**Authentication expiry**
12. Save offline, expire/revoke the JWT on staging, reconnect: "Session expired" banner; record stays
    "Pending Sync". Sign in as the same teacher: it syncs without re-entering marks.
13. Log out, sign in as a different teacher on the same device: first teacher's records and classes
    are not visible. Sign back in as the first teacher: pending record is still there and syncs.

**Late attendance (no approval)**
14. Save offline during a lesson, stay offline until after lesson end + grace, then reconnect:
    "Synchronized" with no review wording; device capture and server receipt times both shown.
    As School Admin, the lesson is in Take Attendance (register), Records and Reports
    immediately; there is no Approve/Reject, badge or Sync control anywhere.
15. Online, take attendance for a lesson that ended hours ago: saves and synchronizes directly.

**Historical pending (only if the previous backend queued any)**
16. As School Admin, a "Legacy Review" tab is shown (no badge) listing them as `LEGACY PENDING`.
    Approve one (plain confirmation, no text field, no keyboard); teacher taps Sync Now:
    "Synchronized", and it appears in reports.
17. Reject another with a reason: teacher sees "Rejected" plus the reason; no Resubmit offered.

**Older app version**
18. Install the previous build, save a record offline, install this build over it (no uninstall).
    Record shows "Saved by an earlier app version" and either syncs with its original key, or
    offers Resubmit; it is never silently removed.
