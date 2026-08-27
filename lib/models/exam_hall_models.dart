int safeInt(dynamic value) => value is int
    ? value
    : value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ??
          double.tryParse(value?.toString() ?? '')?.toInt() ??
          0;

String safeText(dynamic value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

bool safeBool(dynamic value, [bool fallback = true]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  return const {
    '1',
    'true',
    'active',
    'yes',
  }.contains(value.toString().toLowerCase());
}

Map<String, dynamic> safeMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<dynamic> safeList(dynamic value) => value is List ? value : const [];

class SchoolLevel {
  final int id;
  final String name;
  final int sortOrder;
  final bool isActive;
  final int classCount;
  final List<LevelClass> classes;
  const SchoolLevel({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
    this.classCount = 0,
    this.classes = const [],
  });
  factory SchoolLevel.fromJson(Map<String, dynamic> json) {
    final classes = safeList(json['classes'] ?? json['Classes'])
        .whereType<Map>()
        .map((e) => LevelClass.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return SchoolLevel(
      id: safeInt(json['id'] ?? json['level_id']),
      name: safeText(json['name'] ?? json['level_name'], 'Unnamed level'),
      sortOrder: safeInt(json['sort_order'] ?? json['sortOrder']),
      isActive: safeBool(json['is_active'] ?? json['active'] ?? json['status']),
      classCount: safeInt(
        json['class_count'] ?? json['classCount'] ?? classes.length,
      ),
      classes: classes,
    );
  }
}

class LevelClass {
  final int id;
  final String name;
  final int? levelId;
  final String? levelName;
  const LevelClass({
    required this.id,
    required this.name,
    this.levelId,
    this.levelName,
  });
  factory LevelClass.fromJson(Map<String, dynamic> json) {
    final level = safeMap(json['level']);
    final rawId = json['level_id'] ?? level['id'];
    return LevelClass(
      id: safeInt(json['id'] ?? json['class_id']),
      name: safeText(json['name'] ?? json['class_name'], 'Unnamed class'),
      levelId: rawId == null ? null : safeInt(rawId),
      levelName: safeText(json['level_name'] ?? level['name']).isEmpty
          ? null
          : safeText(json['level_name'] ?? level['name']),
    );
  }
}

class ExamHall {
  final int id;
  final String name;
  final int capacity;
  final bool isActive;
  final int allocatedCount;
  const ExamHall({
    required this.id,
    required this.name,
    required this.capacity,
    this.isActive = true,
    this.allocatedCount = 0,
  });
  int get remaining => (capacity - allocatedCount).clamp(0, capacity);
  factory ExamHall.fromJson(Map<String, dynamic> json) => ExamHall(
    id: safeInt(json['id'] ?? json['hall_id']),
    name: safeText(json['name'] ?? json['hall_name'], 'Unnamed hall'),
    capacity: safeInt(json['capacity'] ?? json['hall_capacity']),
    isActive: safeBool(json['is_active'] ?? json['active'] ?? json['status']),
    allocatedCount: safeInt(json['allocated_count'] ?? json['allocatedCount']),
  );
}

class ExamHallAllocationStudent {
  final int id;
  final int studentId;
  final String name;
  final String emis;
  final String className;
  final String hallName;
  final String seat;
  final String shiftName;
  final bool valid;
  final String? reason;
  const ExamHallAllocationStudent({
    required this.id,
    required this.studentId,
    required this.name,
    this.emis = '',
    this.className = '',
    this.hallName = '',
    this.seat = '',
    this.shiftName = '',
    this.valid = true,
    this.reason,
  });
  factory ExamHallAllocationStudent.fromJson(Map<String, dynamic> json) {
    final student = safeMap(json['student']);
    final hall = safeMap(json['hall']);
    final classMap = safeMap(json['class']);
    final shiftMap = safeMap(json['shift'] ?? classMap['shift']);
    return ExamHallAllocationStudent(
      id: safeInt(json['allocation_id'] ?? json['id']),
      studentId: safeInt(json['student_id'] ?? json['id'] ?? student['id']),
      name: safeText(
        json['student_name'] ??
            student['studentName'] ??
            student['student_name'] ??
            student['name'],
        'Student',
      ),
      emis: safeText(
        json['emis'] ??
            json['emis_number'] ??
            student['emisNumber'] ??
            student['emis_number'],
      ),
      className: safeText(json['class_name'] ?? classMap['name']),
      hallName: safeText(json['hall_name'] ?? hall['name']),
      seat: safeText(json['seat_number'] ?? json['seat']),
      shiftName: safeText(
        json['shift_name'] ??
            shiftMap['name'] ??
            (json['shift'] is String ? json['shift'] : null) ??
            (classMap['shift'] is String ? classMap['shift'] : null),
      ),
      valid: safeBool(json['valid'] ?? json['is_valid']),
      reason: safeText(json['reason']).isEmpty
          ? null
          : safeText(json['reason']),
    );
  }
}

class ExamHallAllocationPreview {
  final int selected;
  final int valid;
  final int invalid;
  final int totalStudents;
  final int totalCapacity;
  final int availableCapacity;
  final int allocatable;
  final int unallocated;
  final bool canProcess;
  final String? previewToken;
  final dynamic allocationPlan;
  final List<ExamHallAllocationStudent> students;
  final List<Map<String, dynamic>> halls;
  final Map<String, dynamic> raw;
  const ExamHallAllocationPreview({
    this.selected = 0,
    this.valid = 0,
    this.invalid = 0,
    this.totalStudents = 0,
    this.totalCapacity = 0,
    this.availableCapacity = 0,
    this.allocatable = 0,
    this.unallocated = 0,
    this.canProcess = false,
    this.previewToken,
    this.allocationPlan,
    this.students = const [],
    this.halls = const [],
    this.raw = const {},
  });
  factory ExamHallAllocationPreview.fromJson(Map<String, dynamic> json) {
    final summary = safeMap(json['summary']);
    final students =
        safeList(
              json['students'] ??
                  json['allocations'] ??
                  json['invalid_students'],
            )
            .whereType<Map>()
            .map(
              (e) => ExamHallAllocationStudent.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
    return ExamHallAllocationPreview(
      selected: safeInt(
        json['selected'] ??
            json['selected_count'] ??
            summary['selected'] ??
            summary['selected_count'] ??
            json['requested'],
      ),
      valid: safeInt(
        json['valid'] ??
            json['valid_count'] ??
            summary['valid'] ??
            summary['valid_count'] ??
            json['allocatable'],
      ),
      invalid: safeInt(
        json['invalid'] ??
            json['invalid_count'] ??
            summary['invalid'] ??
            summary['invalid_count'] ??
            json['unallocated'],
      ),
      totalStudents: safeInt(
        json['total_students'] ?? summary['total_students'],
      ),
      totalCapacity: safeInt(
        json['total_capacity'] ??
            json['hall_capacity'] ??
            json['capacity'] ??
            summary['total_capacity'] ??
            summary['hall_capacity'] ??
            summary['capacity'],
      ),
      availableCapacity: safeInt(
        json['available_capacity'] ?? summary['available_capacity'],
      ),
      allocatable: safeInt(
        json['allocatable'] ??
            json['allocatable_count'] ??
            summary['allocatable'] ??
            summary['allocatable_count'],
      ),
      unallocated: safeInt(
        json['unallocated'] ??
            json['unallocated_count'] ??
            summary['unallocated'] ??
            summary['unallocated_count'],
      ),
      canProcess: safeBool(
        json['can_process'] ??
            json['canProcess'] ??
            summary['can_process'] ??
            summary['canProcess'],
        false,
      ),
      previewToken:
          safeText(json['preview_token'] ?? json['previewToken']).isEmpty
          ? null
          : safeText(json['preview_token'] ?? json['previewToken']),
      allocationPlan: json['allocation_plan'],
      students: students,
      halls: safeList(
        json['halls'] ??
            json['hall_breakdown'] ??
            summary['halls'] ??
            summary['hall_breakdown'],
      ).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      raw: json,
    );
  }
}

class ExamHallAllocationBatch {
  final int id;
  final String exam;
  final String academicYear;
  final String level;
  final String className;
  final String mode;
  final String halls;
  final int studentCount;
  final String date;
  final String status;
  final String shift;
  final String createdBy;
  final List<ExamHallAllocationStudent> students;
  const ExamHallAllocationBatch({
    required this.id,
    this.exam = '',
    this.academicYear = '',
    this.level = '',
    this.className = '',
    this.mode = '',
    this.halls = '',
    this.studentCount = 0,
    this.date = '',
    this.status = '',
    this.shift = '',
    this.createdBy = '',
    this.students = const [],
  });
  factory ExamHallAllocationBatch.fromJson(Map<String, dynamic> json) {
    String rel(String key, String nested) =>
        safeText(json[key] ?? safeMap(json[nested])['name']);
    final hallList = safeList(json['halls'])
        .map((e) => e is Map ? safeText(e['name']) : safeText(e))
        .where((e) => e.isNotEmpty)
        .join(', ');
    final students = safeList(json['students'] ?? json['allocations'])
        .whereType<Map>()
        .map(
          (e) =>
              ExamHallAllocationStudent.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
    return ExamHallAllocationBatch(
      id: safeInt(json['batch_id'] ?? json['id']),
      exam: rel('exam_name', 'exam'),
      academicYear: rel('academic_year_name', 'academic_year'),
      level: rel('level_name', 'level'),
      className: rel('class_name', 'class'),
      mode: safeText(json['mode'] ?? json['allocation_mode']),
      halls: safeText(json['hall_names'] ?? hallList),
      studentCount: safeInt(
        json['student_count'] ?? json['students_count'] ?? students.length,
      ),
      date: safeText(json['created_at'] ?? json['date']),
      status: safeText(json['status'], 'active'),
      shift: safeText(json['shift']),
      createdBy: safeText(
        json['created_by_name'] ?? safeMap(json['created_by'])['name'],
      ),
      students: students,
    );
  }
}

class ExamHallReportRow extends ExamHallAllocationStudent {
  const ExamHallReportRow({
    required super.id,
    required super.studentId,
    required super.name,
    super.emis,
    super.className,
    super.hallName,
    super.seat,
  });
  factory ExamHallReportRow.fromJson(Map<String, dynamic> json) {
    final r = ExamHallAllocationStudent.fromJson(json);
    return ExamHallReportRow(
      id: r.id,
      studentId: r.studentId,
      name: r.name,
      emis: r.emis,
      className: r.className,
      hallName: r.hallName,
      seat: r.seat,
    );
  }
}

class AdminExamPassCard {
  final int allocationId,
      studentId,
      classId,
      levelId,
      examId,
      academicYearId,
      hallId;
  final String studentName,
      emis,
      className,
      levelName,
      examName,
      examDate,
      academicYearName,
      hallName,
      seat,
      shift,
      schoolName,
      schoolAddress,
      studentPhoto,
      status;

  const AdminExamPassCard({
    required this.allocationId,
    this.studentId = 0,
    this.classId = 0,
    this.levelId = 0,
    this.examId = 0,
    this.academicYearId = 0,
    this.hallId = 0,
    this.studentName = '',
    this.emis = '',
    this.className = '',
    this.levelName = '',
    this.examName = '',
    this.examDate = '',
    this.academicYearName = '',
    this.hallName = '',
    this.seat = '',
    this.shift = '',
    this.schoolName = '',
    this.schoolAddress = '',
    this.studentPhoto = '',
    this.status = '',
  });

  factory AdminExamPassCard.fromJson(Map<String, dynamic> json) {
    final student = safeMap(json['student']);
    return AdminExamPassCard(
      allocationId: safeInt(json['allocation_id'] ?? json['id']),
      studentId: safeInt(json['student_id'] ?? student['id']),
      classId: safeInt(json['class_id']),
      levelId: safeInt(json['level_id']),
      examId: safeInt(json['exam_id']),
      academicYearId: safeInt(json['academic_year_id']),
      hallId: safeInt(json['hall_id']),
      studentName: safeText(
        json['student_name'] ?? student['studentName'] ?? student['name'],
        'Student',
      ),
      emis: safeText(
        json['emis_number'] ?? student['emisNumber'] ?? student['emis_number'],
      ),
      className: safeText(json['class_name']),
      levelName: safeText(json['level_name']),
      examName: safeText(json['exam_name']),
      examDate: safeText(json['exam_date']),
      academicYearName: safeText(json['academic_year_name']),
      hallName: safeText(json['hall_name']),
      seat: safeText(json['seat_number'] ?? json['seat']),
      shift: safeText(json['shift']),
      schoolName: safeText(json['school_name']),
      schoolAddress: safeText(json['school_address']),
      studentPhoto: safeText(json['student_photo']),
      status: safeText(json['status']),
    );
  }
}
