import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';

/// GET /api/teacher/notices item. Backend (teacher.controller#teacherNotices)
/// returns every Notice row of the teacher's school:
/// `{notices: [{id, schoolId, title, content, createdAt, updatedAt}]}`,
/// ordered by id DESC. There are no audience, draft or expiry fields.
class TeacherNotice {
  final int id;
  final int? schoolId;
  final String title;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TeacherNotice({
    required this.id,
    required this.title,
    required this.content,
    this.schoolId,
    this.createdAt,
    this.updatedAt,
  });

  static int? _int(Object? v) =>
      v is int ? v : (v is String ? int.tryParse(v) : null);

  /// Null when the item is not a notice (no positive id).
  static TeacherNotice? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = _int(raw['id']);
    if (id == null || id <= 0) return null;
    return TeacherNotice(
      id: id,
      schoolId: _int(raw['schoolId'] ?? raw['school_id']),
      title: '${raw['title'] ?? ''}'.trim(),
      content: '${raw['content'] ?? ''}'.trim(),
      createdAt: DateTime.tryParse('${raw['createdAt'] ?? raw['created_at']}'),
      updatedAt: DateTime.tryParse('${raw['updatedAt'] ?? raw['updated_at']}'),
    );
  }

  bool get edited =>
      createdAt != null &&
      updatedAt != null &&
      updatedAt!.difference(createdAt!).inMinutes >= 1;
}

sealed class TeacherNoticesResult {}

class TeacherNoticesLoaded extends TeacherNoticesResult {
  final List<TeacherNotice> notices;

  /// Items dropped because they belonged to another school (should be 0).
  final int foreignDropped;
  TeacherNoticesLoaded(this.notices, {this.foreignDropped = 0});
}

class TeacherNoticesFailed extends TeacherNoticesResult {
  final String message;
  final int? statusCode;
  TeacherNoticesFailed(this.message, [this.statusCode]);
}

class TeacherNoticesService {
  TeacherNoticesService({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

  static const path = 'api/teacher/notices';

  /// [schoolId] is the signed-in teacher's school: any item from another
  /// school is discarded (the backend already scopes by school; this is a
  /// second guard so a misconfigured server can never show foreign notices).
  Future<TeacherNoticesResult> list({int? schoolId}) async {
    final http.Response response;
    try {
      response = await _client.get(apiUrl(path));
    } catch (_) {
      return TeacherNoticesFailed(
        'Could not reach the server. Check your connection and try again.',
      );
    }
    final code = response.statusCode;
    if (code != 200) {
      return TeacherNoticesFailed(switch (code) {
        401 => 'Your session has expired. Please sign in again.',
        403 => 'Your account is not allowed to view teacher notices.',
        404 => 'Teacher notices are not available on this server.',
        >= 500 => 'The server could not load notices. Please try again.',
        _ => 'Could not load notices ($code).',
      }, code);
    }
    Object? body;
    try {
      // Notice text is free-form; decode as UTF-8 even if a proxy drops
      // the charset (http would otherwise fall back to Latin-1).
      body = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
    } catch (_) {}
    final rawList = body is Map
        ? body['notices']
        : (body is List ? body : null);
    if (rawList is! List) {
      return TeacherNoticesFailed(
        'The server sent an unexpected response. Please try again.',
        code,
      );
    }
    var dropped = 0;
    final notices = <TeacherNotice>[];
    for (final raw in rawList) {
      final n = TeacherNotice.tryParse(raw);
      if (n == null) continue;
      if (schoolId != null && n.schoolId != null && n.schoolId != schoolId) {
        dropped++;
        continue;
      }
      notices.add(n);
    }
    // Newest first: by creation time, then id (the backend's own order).
    notices.sort((a, b) {
      final at = a.createdAt, bt = b.createdAt;
      if (at != null && bt != null && at != bt) return bt.compareTo(at);
      return b.id.compareTo(a.id);
    });
    return TeacherNoticesLoaded(notices, foreignDropped: dropped);
  }
}
