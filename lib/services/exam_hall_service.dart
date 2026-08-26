import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kobac/models/exam_hall_models.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/pdf_file_result.dart';

sealed class HallResult<T> {}

class HallSuccess<T> extends HallResult<T> {
  final T data;
  HallSuccess(this.data);
}

class HallError extends HallResult<Never> {
  final String message;
  final int? statusCode;
  HallError(this.message, [this.statusCode]);
}

Map<String, dynamic> buildManualAllocationPayload({
  required int academicYearId,
  required int levelId,
  required int classId,
  required int examId,
  required int hallId,
  required Set<int> selectedStudentIds,
}) {
  final ids = selectedStudentIds.where((id) => id > 0).toList()..sort();
  if (ids.length != selectedStudentIds.length || ids.isEmpty) {
    throw ArgumentError(
      'Every selected student ID must be a positive integer.',
    );
  }
  return <String, dynamic>{
    'academic_year_id': academicYearId,
    'level_id': levelId,
    'class_id': classId,
    'exam_id': examId,
    'hall_id': hallId,
    'student_ids': ids,
  };
}

Map<String, dynamic> buildRandomAllocationPayload({
  required int academicYearId,
  required int levelId,
  required int examId,
  required Set<int> selectedHallIds,
  int? classId,
}) {
  final hallIds = selectedHallIds.where((id) => id > 0).toList()..sort();
  if (hallIds.length != selectedHallIds.length || hallIds.isEmpty) {
    throw ArgumentError('Every selected hall ID must be a positive integer.');
  }
  return <String, dynamic>{
    'academic_year_id': academicYearId,
    'level_id': levelId,
    'exam_id': examId,
    'hall_ids': hallIds,
    if (classId != null) 'class_ids': <int>[classId],
  };
}

bool canProcessAllocationPreview({
  required ExamHallAllocationPreview? preview,
  required bool isRandom,
  required bool previewIsCurrent,
}) =>
    previewIsCurrent &&
    preview?.canProcess == true &&
    (!isRandom || (preview!.allocatable > 0 && preview.allocationPlan != null));

Map<String, dynamic> buildRandomProcessPayload({
  required Map<String, dynamic> previewRequest,
  required dynamic allocationPlan,
}) {
  if (allocationPlan == null) {
    throw ArgumentError('The allocation plan from preview is required.');
  }
  return <String, dynamic>{
    ...previewRequest,
    'allocation_plan': allocationPlan,
  };
}

ExamHallAllocationPreview parseAllocationPreviewResponse(dynamic raw) {
  final root = safeMap(raw);
  final data = safeMap(root['data']);
  final preview = safeMap(root['preview'] ?? data['preview']);
  final payload = preview.isNotEmpty
      ? Map<String, dynamic>.from(preview)
      : Map<String, dynamic>.from(data.isNotEmpty ? data : root);
  final allocationPlan =
      preview['allocation_plan'] ??
      data['allocation_plan'] ??
      root['allocation_plan'];
  if (allocationPlan != null) payload['allocation_plan'] = allocationPlan;
  return ExamHallAllocationPreview.fromJson(payload);
}

Map<String, String> buildExamPassFilters({
  required int academicYearId,
  required int examId,
  int? hallId,
  int? levelId,
  int? classId,
  String? shift,
}) => <String, String>{
  'academic_year_id': '$academicYearId',
  'exam_id': '$examId',
  if (hallId != null) 'hall_id': '$hallId',
  if (levelId != null) 'level_id': '$levelId',
  if (classId != null) 'class_id': '$classId',
  if (shift != null && shift.trim().isNotEmpty) 'shift': shift.trim(),
};

Map<String, dynamic> buildSelectedPassPrintPayload(Set<int> allocationIds) {
  final ids = allocationIds.where((id) => id > 0).toList()..sort();
  if (ids.isEmpty || ids.length != allocationIds.length) {
    throw ArgumentError('Allocation IDs must be positive integers.');
  }
  return {'allocation_ids': ids};
}

String individualExamPassPrintPath(int allocationId) {
  if (allocationId <= 0) {
    throw ArgumentError('Allocation ID must be a positive integer.');
  }
  return 'api/school-admin/exam-halls/passes/$allocationId/print';
}

Set<int> selectLoadedPassAllocationIds(Iterable<AdminExamPassCard> passes) =>
    passes.map((pass) => pass.allocationId).where((id) => id > 0).toSet();

List<dynamic> parseExamPassListResponse(dynamic raw) {
  if (raw is List) return raw;
  final root = safeMap(raw);
  final dataValue = root['data'];
  if (dataValue is List) return dataValue;
  final data = safeMap(dataValue);
  for (final value in [
    root['passes'],
    data['passes'],
    root['items'],
    data['items'],
  ]) {
    if (value is List) return value;
  }
  throw const FormatException('Exam pass list is missing from the response.');
}

/// Parses the school-admin hall collection response.
/// The live endpoint returns `{ "halls": [...] }`; legacy deployments may
/// wrap the same list in `data` or use `exam_halls`/`examHalls`.
List<dynamic> parseExamHallListResponse(dynamic raw) {
  if (raw is List) return raw;
  final root = safeMap(raw);
  final dataValue = root['data'];
  if (dataValue is List) return dataValue;
  final data = safeMap(dataValue);
  for (final value in [
    root['halls'],
    root['exam_halls'],
    root['examHalls'],
    root['items'],
    data['halls'],
    data['exam_halls'],
    data['examHalls'],
    data['items'],
  ]) {
    if (value is List) return value;
  }
  throw const FormatException('Exam hall list is missing from the response.');
}

class ExamHallService {
  ExamHallService._();
  static final instance = ExamHallService._();
  factory ExamHallService() => instance;
  final ApiClient _client = ApiClient();
  static const _admin = 'api/school-admin';
  dynamic _decode(String body) {
    try {
      return body.isEmpty ? null : jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _payload(dynamic raw, [String? key]) {
    final root = safeMap(raw);
    final data = safeMap(root['data']);
    final keyed = key == null
        ? null
        : (root[key] ?? data[key] ?? root['result'] ?? data['result']);
    return safeMap(keyed ?? (data.isNotEmpty ? data : root));
  }

  List<dynamic> _list(dynamic raw, String key) {
    if (raw is List) return raw;
    final root = safeMap(raw), data = safeMap(root['data']);
    final value =
        root[key] ??
        root['${key[0].toUpperCase()}${key.substring(1)}'] ??
        root['items'] ??
        data[key] ??
        data['${key[0].toUpperCase()}${key.substring(1)}'] ??
        data['items'] ??
        (root['data'] is List ? root['data'] : null);
    return value is List ? value : const [];
  }

  String _message(dynamic raw, String fallback) {
    final map = safeMap(raw);
    final data = safeMap(map['data']);
    final value = map['message'] ?? map['error'] ?? data['message'];
    final text = safeText(value);
    return text.isNotEmpty &&
            !text.toLowerCase().contains('<html') &&
            !text.toLowerCase().contains('sql')
        ? text
        : fallback;
  }

  bool _ok(int status) => status >= 200 && status < 300;

  Future<HallResult<List<SchoolLevel>>> levels() => _getList(
    '$_admin/levels',
    'levels',
    SchoolLevel.fromJson,
    'Could not load levels.',
  );
  Future<HallResult<SchoolLevel>> saveLevel({
    int? id,
    required String name,
    required int sortOrder,
    required bool active,
  }) => _write(
    id == null ? '$_admin/levels' : '$_admin/levels/$id',
    {'name': name.trim(), 'sort_order': sortOrder, 'is_active': active},
    id == null,
    'level',
    SchoolLevel.fromJson,
    'Could not save level.',
  );
  Future<HallResult<bool>> deleteLevel(int id) =>
      _delete('$_admin/levels/$id', 'Could not delete level.');
  Future<HallResult<List<LevelClass>>> classes({int? levelId}) => _getList(
    '$_admin/classes${levelId == null ? '' : '?level_id=$levelId'}',
    'classes',
    LevelClass.fromJson,
    'Could not load classes.',
  );
  Future<HallResult<List<ExamHallAllocationStudent>>> students({
    required int academicYearId,
    required int levelId,
    int? classId,
  }) {
    final query = <String, String>{
      'academic_year_id': '$academicYearId',
      'level_id': '$levelId',
      if (classId != null) 'class_id': '$classId',
    };
    return _getListUri(
      apiUrl('$_admin/students').replace(queryParameters: query),
      'students',
      ExamHallAllocationStudent.fromJson,
      'Could not load students.',
    );
  }

  Future<HallResult<bool>> assignClasses(
    int levelId,
    List<int> classIds,
  ) async {
    try {
      final response = await _client.patch(
        apiUrl('$_admin/levels/$levelId/classes'),
        body: {'class_ids': classIds},
      );
      final raw = _decode(response.body);
      return _ok(response.statusCode)
          ? HallSuccess(true)
          : HallError(
              _message(raw, 'Could not assign classes.'),
              response.statusCode,
            );
    } catch (e, st) {
      return HallError(
        userFriendlyMessage(e, st, 'ExamHallService.assignClasses'),
      );
    }
  }

  Future<HallResult<List<ExamHall>>> halls() async {
    try {
      final response = await _client.get(apiUrl('$_admin/exam-halls'));
      final raw = _decode(response.body);
      if (kDebugMode) {
        debugPrint(
          '[ExamHallService.halls] status=${response.statusCode} '
          'body=${response.body.length > 1200 ? '${response.body.substring(0, 1200)}…' : response.body}',
        );
      }
      if (!_ok(response.statusCode)) {
        return HallError(
          _message(raw, 'Unable to load exam halls.'),
          response.statusCode,
        );
      }
      final items = parseExamHallListResponse(raw);
      final halls = <ExamHall>[];
      for (final item in items) {
        if (item is! Map) {
          if (kDebugMode) {
            debugPrint('[ExamHallService.halls] skipped non-object hall item');
          }
          continue;
        }
        try {
          halls.add(ExamHall.fromJson(Map<String, dynamic>.from(item)));
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint('[ExamHallService.halls] hall parse failed: $error');
            debugPrintStack(stackTrace: stackTrace);
          }
        }
      }
      return HallSuccess(halls);
    } on FormatException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ExamHallService.halls] response parse failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return HallError('Unable to load exam halls. Please try again.');
    } catch (error, stackTrace) {
      return HallError(
        userFriendlyMessage(error, stackTrace, 'ExamHallService.halls'),
      );
    }
  }

  Future<HallResult<ExamHall>> saveHall({
    int? id,
    required String name,
    required int capacity,
    required bool active,
  }) => _write(
    id == null ? '$_admin/exam-halls' : '$_admin/exam-halls/$id',
    {
      'name': name.trim(),
      'capacity': capacity,
      'status': active ? 'active' : 'inactive',
      'is_active': active,
    },
    id == null,
    'exam_hall',
    ExamHall.fromJson,
    'Could not save exam hall.',
  );
  Future<HallResult<bool>> deleteHall(int id) =>
      _delete('$_admin/exam-halls/$id', 'Could not delete exam hall.');

  Future<HallResult<ExamHallAllocationPreview>> preview(
    Map<String, dynamic> body, {
    bool random = false,
  }) {
    if (kDebugMode) {
      final ids = body[random ? 'hall_ids' : 'student_ids'];
      debugPrint(
        '[ExamHallService.preview] endpoint=${random ? 'random/preview' : 'preview'} '
        'keys=${body.keys.toList()} ids=$ids '
        'idTypes=${ids is List ? ids.map((value) => value.runtimeType).toList() : const []}',
      );
    }
    return _postPreview(
      '$_admin/exam-halls/allocations/${random ? 'random/' : ''}preview',
      body,
    );
  }

  Future<HallResult<ExamHallAllocationBatch>> process(
    Map<String, dynamic> body, {
    bool random = false,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ExamHallService.process] endpoint=${random ? 'random/process' : 'process'} '
          'keys=${body.keys.toList()} hasAllocationPlan=${body['allocation_plan'] != null}',
        );
      }
      final response = await _client.post(
        apiUrl(
          '$_admin/exam-halls/allocations/${random ? 'random/' : ''}process',
        ),
        body: body,
      );
      final raw = _decode(response.body);
      return _ok(response.statusCode)
          ? HallSuccess(
              ExamHallAllocationBatch.fromJson(_payload(raw, 'allocation')),
            )
          : HallError(
              _message(raw, 'Allocation could not be processed.'),
              response.statusCode,
            );
    } catch (e, st) {
      return HallError(userFriendlyMessage(e, st, 'ExamHallService.process'));
    }
  }

  Future<HallResult<List<ExamHallAllocationBatch>>> history() => _getList(
    '$_admin/exam-halls/allocations/history',
    'allocations',
    ExamHallAllocationBatch.fromJson,
    'Could not load allocation history.',
  );
  Future<HallResult<ExamHallAllocationBatch>> allocation(int id) => _getOne(
    '$_admin/exam-halls/allocations/$id',
    'allocation',
    ExamHallAllocationBatch.fromJson,
    'Could not load allocation.',
  );
  Future<HallResult<bool>> cancelBatch(int id) => _patchEmpty(
    '$_admin/exam-halls/allocations/$id/cancel',
    'Could not cancel allocation.',
  );
  Future<HallResult<bool>> cancelStudent(int id) => _patchEmpty(
    '$_admin/exam-halls/allocations/students/$id/cancel',
    'Could not cancel student allocation.',
  );
  Future<HallResult<List<ExamHallReportRow>>> report(
    Map<String, String> query,
  ) async {
    final uri = apiUrl(
      '$_admin/exam-halls/report',
    ).replace(queryParameters: query);
    return _getListUri(
      uri,
      'students',
      ExamHallReportRow.fromJson,
      'Could not load hall report.',
    );
  }

  Future<HallResult<PdfFileResult>> reportPdf(
    Map<String, String> query, {
    required bool download,
  }) => _pdf(
    apiUrl(
      '$_admin/exam-halls/report/print',
    ).replace(queryParameters: {...query, 'download': '$download'}),
    'Could not generate hall report PDF.',
  );
  Future<HallResult<List<AdminExamPassCard>>> examPasses(
    Map<String, String> query,
  ) async {
    try {
      final response = await _client.get(
        apiUrl('$_admin/exam-halls/passes').replace(queryParameters: query),
      );
      final raw = _decode(response.body);
      if (!_ok(response.statusCode)) {
        return HallError(
          _message(raw, 'Unable to load exam pass cards.'),
          response.statusCode,
        );
      }
      return HallSuccess(
        parseExamPassListResponse(raw)
            .whereType<Map>()
            .map(
              (item) =>
                  AdminExamPassCard.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
      );
    } catch (e, st) {
      return HallError(
        userFriendlyMessage(e, st, 'ExamHallService.examPasses'),
      );
    }
  }

  Future<HallResult<PdfFileResult>> individualExamPassPdf(int allocationId) =>
      _pdf(
        apiUrl(individualExamPassPrintPath(allocationId)),
        'Could not generate exam pass card PDF.',
      );

  Future<HallResult<PdfFileResult>> filteredExamPassesPdf(
    Map<String, String> query,
  ) => _pdf(
    apiUrl('$_admin/exam-halls/passes/print').replace(queryParameters: query),
    'Could not generate exam pass cards PDF.',
  );

  Future<HallResult<PdfFileResult>> selectedExamPassesPdf(
    Set<int> allocationIds,
  ) => _postPdf(
    apiUrl('$_admin/exam-halls/passes/print'),
    buildSelectedPassPrintPayload(allocationIds),
    'Could not generate selected exam pass cards PDF.',
  );

  Future<HallResult<ExamHallAllocationPreview>> _postPreview(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post(apiUrl(path), body: body);
      final raw = _decode(response.body);
      if (!_ok(response.statusCode)) {
        return HallError(
          _message(raw, 'Preview could not be generated.'),
          response.statusCode,
        );
      }
      final preview = parseAllocationPreviewResponse(raw);
      if (kDebugMode && path.contains('/random/')) {
        debugPrint(
          '[ExamHallService.preview] responseHasAllocationPlan='
          '${preview.allocationPlan != null}',
        );
      }
      return HallSuccess(preview);
    } catch (e, st) {
      return HallError(userFriendlyMessage(e, st, 'ExamHallService.preview'));
    }
  }

  Future<HallResult<List<T>>> _getList<T>(
    String path,
    String key,
    T Function(Map<String, dynamic>) parser,
    String fallback,
  ) => _getListUri(apiUrl(path), key, parser, fallback);
  Future<HallResult<List<T>>> _getListUri<T>(
    Uri uri,
    String key,
    T Function(Map<String, dynamic>) parser,
    String fallback,
  ) async {
    try {
      final response = await _client.get(uri);
      final raw = _decode(response.body);
      if (!_ok(response.statusCode))
        return HallError(_message(raw, fallback), response.statusCode);
      return HallSuccess(
        _list(raw, key)
            .whereType<Map>()
            .map((e) => parser(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (e, st) {
      return HallError(userFriendlyMessage(e, st, 'ExamHallService.getList'));
    }
  }

  Future<HallResult<T>> _getOne<T>(
    String path,
    String key,
    T Function(Map<String, dynamic>) parser,
    String fallback,
  ) async {
    try {
      final response = await _client.get(apiUrl(path));
      final raw = _decode(response.body);
      return _ok(response.statusCode)
          ? HallSuccess(parser(_payload(raw, key)))
          : HallError(_message(raw, fallback), response.statusCode);
    } catch (e, st) {
      return HallError(userFriendlyMessage(e, st, 'ExamHallService.getOne'));
    }
  }

  Future<HallResult<T>> _write<T>(
    String path,
    Map<String, dynamic> body,
    bool post,
    String key,
    T Function(Map<String, dynamic>) parser,
    String fallback,
  ) async {
    try {
      final response = post
          ? await _client.post(apiUrl(path), body: body)
          : await _client.patch(apiUrl(path), body: body);
      final raw = _decode(response.body);
      return _ok(response.statusCode)
          ? HallSuccess(parser(_payload(raw, key)))
          : HallError(_message(raw, fallback), response.statusCode);
    } catch (e, st) {
      return HallError(userFriendlyMessage(e, st, 'ExamHallService.write'));
    }
  }

  Future<HallResult<bool>> _delete(String path, String fallback) async {
    try {
      final response = await _client.delete(apiUrl(path));
      final raw = _decode(response.body);
      return _ok(response.statusCode)
          ? HallSuccess(true)
          : HallError(_message(raw, fallback), response.statusCode);
    } catch (e, st) {
      return HallError(userFriendlyMessage(e, st, 'ExamHallService.delete'));
    }
  }

  Future<HallResult<bool>> _patchEmpty(String path, String fallback) async {
    try {
      final response = await _client.patch(apiUrl(path));
      final raw = _decode(response.body);
      return _ok(response.statusCode)
          ? HallSuccess(true)
          : HallError(_message(raw, fallback), response.statusCode);
    } catch (e, st) {
      return HallError(userFriendlyMessage(e, st, 'ExamHallService.cancel'));
    }
  }

  Future<HallResult<PdfFileResult>> _pdf(Uri uri, String fallback) async {
    try {
      final response = await _client.get(
        uri,
        headers: const {'Accept': 'application/pdf'},
      );
      final file = pdfFileResultFromResponse(response);
      if (file != null) return HallSuccess(file);
      return HallError(
        _message(_decode(response.body), fallback),
        response.statusCode,
      );
    } catch (e, st) {
      return HallError(userFriendlyMessage(e, st, 'ExamHallService.pdf'));
    }
  }

  Future<HallResult<PdfFileResult>> _postPdf(
    Uri uri,
    Map<String, dynamic> body,
    String fallback,
  ) async {
    try {
      final response = await _client.post(
        uri,
        headers: const {'Accept': 'application/pdf'},
        body: body,
      );
      final file = pdfFileResultFromResponse(response);
      if (file != null) return HallSuccess(file);
      return HallError(
        _message(_decode(response.body), fallback),
        response.statusCode,
      );
    } catch (e, st) {
      return HallError(userFriendlyMessage(e, st, 'ExamHallService.postPdf'));
    }
  }
}
