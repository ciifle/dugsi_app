# Teacher Flow — Backend Specification (Full Contract & Root-Cause Guide)

This document defines the **exact** backend contract for teacher endpoints and the **failure modes** that cause the Flutter app to show zeros (0 classes, 0 assignments, no students, no timetable). Use it to trace and fix backend issues.

---

## Critical rule: ID resolution

- **JWT** identifies `users.id` (the authenticated user).
- **Teacher row** is resolved by `teachers.user_id = users.id` → use `teachers.id` for all teacher-scoped data.
- **Never** use `users.id` where `teacher_assignments.teacher_id` or timetable/teacher linkage expects `teachers.id`.
- **Client never sends `teacher_id`**; the server must resolve it from the JWT.

---

## 1. GET /api/teacher/dashboard

**Auth:** `Authorization: Bearer <JWT>` (required).

**Behavior:**

1. Resolve teacher: `teachers.user_id = req.user.id` (from JWT). If no row → **403** with message e.g. "Teacher profile not found".
2. Load:
   - **assignedClasses:** distinct classes from this teacher’s assignments (e.g. from `teacher_assignments` join `classes` where `teacher_assignments.teacher_id = teachers.id`).
   - **assignments:** rows from `teacher_assignments` for this teacher, each including **class** and **subject** (join `classes`, `subjects`). Use `teachers.id`, not `users.id`.
   - **timetables:** timetable entries for this teacher (linked via teacher assignment / class / subject as per your schema), each with class and subject info.
3. Return a single JSON object. Flutter accepts either top-level keys or a `data` wrapper (see below).

**Response (200) — top-level or under `data`:**

If you use a wrapper, Flutter expects either:

```json
{
  "teacher": { "id": 1, "userId": 10, ... },
  "assignedClasses": [
    { "id": 1, "name": "Grade 10A" }
  ],
  "assignments": [
    {
      "id": 1,
      "class": { "id": 1, "name": "Grade 10A" },
      "subject": { "id": 1, "name": "Mathematics" }
    }
  ],
  "timetables": [
    {
      "id": 1,
      "day": "Monday",
      "startTime": "08:00",
      "endTime": "09:00",
      "classId": 1,
      "className": "Grade 10A",
      "subjectId": 1,
      "subjectName": "Mathematics",
      "class": { "id": 1, "name": "Grade 10A" },
      "subject": { "id": 1, "name": "Mathematics" }
    }
  ]
}
```

Or wrapped:

```json
{
  "data": {
    "assignedClasses": [ ... ],
    "assignments": [ ... ],
    "timetables": [ ... ]
  }
}
```

**Field rules:**

- Use **null** or omit missing class/subject; do **not** use `0` for IDs when the entity exists (avoids "class 0" in the app).
- **assignedClasses:** array of `{ id, name }` (or `class_id`/`class_name`).
- **assignments:** each item must have **class** and **subject** (object with `id` and `name`) or flat `classId`/`className`/`subjectId`/`subjectName`.
- **timetables:** each entry must have day, startTime, endTime, and class/subject (nested or flat classId, className, subjectId, subjectName).

**403:** When no teacher row exists for `req.user.id`, return 403 with a clear message (e.g. "Teacher profile not found"). Do **not** return 200 with empty arrays when the teacher is missing.

---

## 2. GET /api/teacher/assignments

**Auth:** Bearer JWT.

**Behavior:**

1. Resolve teacher by `teachers.user_id = req.user.id`. If none → 403.
2. Return assignments for `teachers.id` (e.g. from `teacher_assignments` where `teacher_id = teachers.id`), each with **class** and **subject** (join classes, subjects).

**Response (200):** Array of assignment objects, or object with key `assignments`/`data`/`items`. Flutter unwraps `data` if present. Each item: `id`, `class` (or classId/className), `subject` (or subjectId/subjectName).

**403:** Teacher profile not found or not allowed.

---

## 3. GET /api/teacher/classes/{class_id}/students

**Auth:** Bearer JWT.

**Behavior:**

1. Resolve teacher: `teachers.user_id = req.user.id` → 403 if no teacher.
2. **Verify** the teacher is assigned to this class: e.g. exists in `teacher_assignments` where `teacher_id = teachers.id` and `class_id = :class_id`. If not → 403.
3. Return students in that class (and same school as teacher). Use `class_id` from path.

**Response (200):** Object with `students` (or `data`/`items`) array. Each student: `id`, optionally `name`/`studentName`, `emisNumber`/`emis_number`.

**403:** Not assigned to this class or teacher not found. **404:** Class not found or endpoint not enabled.

---

## 4. GET /api/teacher/timetable

**Auth:** Bearer JWT.

**Behavior:**

1. Resolve teacher by `teachers.user_id = req.user.id` → 403 if none.
2. Return timetable entries for this teacher (using `teachers.id` in your timetable/assignment linkage). Each entry must include day, start/end time, and class + subject (id and name).

**Response (200):** Same shape as dashboard `timetables` array (or under `data`). Flutter can use either dashboard timetables or this dedicated endpoint if the app calls it.

---

## 5. Failure modes (exact root causes)

| Symptom | Likely cause | What to check |
|--------|---------------|----------------|
| 0 classes, 0 assignments, empty timetable | Queries use `users.id` instead of `teachers.id` | All teacher_assignments / timetable queries must use `teachers.id` from `teachers.user_id = req.user.id`. |
| 0 classes, 0 assignments | No teacher row for user | `teachers.user_id` must match `users.id` for the logged-in user. Add diagnostic: `SELECT * FROM teachers WHERE user_id = ?`. |
| 0 classes, 0 assignments | teacher_assignments missing or wrong FKs | Table must have `teacher_id` → `teachers.id`, `class_id` → `classes.id`, `subject_id` → `subjects.id`. Run migration if missing. |
| Dashboard returns 200 but empty arrays | Associations not included | Dashboard query must **include** Class and Subject (e.g. eager load) so each assignment has `class` and `subject`. |
| Assignments have class_id but Flutter shows "Unassigned" | Wrong key names | Flutter expects `class`/`Class` object with `id` and `name`, or flat `classId`/`className`. No `class 0` when real class exists. |
| Class students returns 403 for valid class | Assignment check uses users.id | Verify assignment by `teacher_assignments.teacher_id = teachers.id` and `teacher_assignments.class_id = :class_id`. |
| Teacher exists but dashboard returns empty | Silent join/where failure | Log resolved `teachers.id`, then count teacher_assignments and timetables for that id. Ensure includes/joins are correct. |

---

## 6. DB schema expectations

- **teachers:** `id`, `user_id` (FK to users.id), school_id, ...
- **teacher_assignments:** `id`, `teacher_id` (FK to teachers.id), `class_id` (FK to classes.id), `subject_id` (FK to subjects.id), ...
- **timetable:** Must link to teacher (e.g. via teacher_assignment or teacher_id). Use `teachers.id` in filters.

If your timetable table links by subject/class only, you must still filter by teacher (e.g. via teacher_assignments) so only this teacher’s slots are returned.

---

## 7. Diagnostic / debug (backend)

Add temporary logging:

- `req.user.id` (from JWT)
- Resolved `teachers.id` (from teachers.user_id = req.user.id)
- Count of teacher_assignments for that teachers.id
- Count of timetable rows for that teacher
- Response payload shape (assignedClasses length, assignments length, timetables length)

This pinpoints whether the failure is “no teacher row”, “wrong id in query”, or “missing includes”.

---

## 8. Flutter side (this repo)

- **Dashboard:** `TeacherService.getDashboard()` — unwraps `data` if present, derives `assignedClasses` from `assignments` if backend omits it.
- **Classes screen:** Uses `getDashboard()` and shows classes from `assignedClasses` or from assignments.
- **Assignments screen:** Uses `getDashboard()` and shows `assignments`.
- **Timetable:** Uses `getDashboard().timetables` (and optionally GET /api/teacher/timetable if used).
- **Students:** `listStudentsByClass(classId)` — unwraps `data` if present.
- **403:** Shown as “Teacher profile not found” or “Not allowed”; no silent zeros.

Once the backend returns non-empty dashboard (and correct 403 when teacher is missing), the app will show real classes, assignments, timetable, and students for assigned classes.

---

## 9. Swagger / OpenAPI

- Document GET /api/teacher/dashboard, /assignments, /classes/{class_id}/students, /timetable.
- Response examples must match the shapes above (assignedClasses, assignments, timetables with class/subject).
- Document 403 for missing teacher profile and for class students when not assigned.
