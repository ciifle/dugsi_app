# Teacher: Students by Class — Backend API Spec

The Flutter app calls this endpoint for **attendance** and **marks entry**. The backend at `https://api.dugsi.so` may not implement it yet. When it does, the teacher UI will show real students for the selected class.

---

## Endpoint

**GET** `/api/teacher/classes/{class_id}/students`

- **Auth:** `Authorization: Bearer <JWT_TOKEN>` (required).
- **Path:** `class_id` — integer, the class ID.

---

## Behavior

1. Resolve teacher from JWT: `users.id` → `teachers.user_id` → `teachers.id`.
2. **Verify** the teacher has an assignment for this class:
   - e.g. `teacher_assignments` where `teacher_id = teachers.id` and `class_id = :class_id`.
3. If not assigned to that class → **403 Forbidden**.
4. Return students in that class, scoped to the same school as the teacher:
   - e.g. `students` where `class_id = :class_id` and `school_id` matches teacher’s school.

---

## Response (200)

```json
{
  "students": [
    { "id": 2, "studentName": "Ahmed Hassan", "emisNumber": "EM001" },
    { "id": 3, "studentName": "Fatima Ali", "emisNumber": "EM002" }
  ]
}
```

- `id` (number): student ID (used for attendance `student_id` and marks `student_id`).
- `studentName` (string): display name (optional; app falls back to `Student {id}`).
- `emisNumber` (string): optional.

Other fields (e.g. `class_id`, `email`) are optional; the app only requires `id` and optionally `studentName` / `emisNumber`.

---

## Error responses

- **401** — Missing or invalid JWT.
- **403** — Teacher not assigned to this class (or teacher profile not found).
- **404** — Class not found.

---

## Swagger

Add to your OpenAPI/Swagger spec:

- **Path:** `GET /api/teacher/classes/{class_id}/students`
- **Security:** Bearer JWT.
- **Parameters:** path `class_id` (integer, required).
- **Responses:** 200 (body above), 401, 403, 404.

---

## Client usage (this repo)

- **Service:** `lib/services/teacher_service.dart` → `listStudentsByClass(int classId)`.
- **Screens:**  
  - `lib/teacher/pages/attendance_mark.dart` — class selector from assignments, then loads students for that class.  
  - `lib/teacher/pages/teacher_marks_screen.dart` — add-mark dialog uses this list for student dropdown (or fallback to manual student ID if endpoint returns 404).

No school-admin endpoints are used in the teacher UI; only teacher-scoped APIs are called.
