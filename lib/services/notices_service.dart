import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

/// Notice model (school-admin scope).
class NoticeModel {
  final int id;
  final String title;
  final String content;
  final String? createdAt;

  const NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    this.createdAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String str(dynamic v) => v == null ? '' : v.toString().trim();
    String? strOpt(dynamic v) => v == null ? null : v.toString().trim();
    return NoticeModel(
      id: parseId(json['id'] ?? json['notice_id']),
      title: str(json['title']),
      content: str(json['content']),
      createdAt: strOpt(json['created_at'] ?? json['createdAt']),
    );
  }
}

sealed class NoticeResult<T> {}

class NoticeSuccess<T> extends NoticeResult<T> {
  final T data;
  NoticeSuccess(this.data);
}

class NoticeError extends NoticeResult<Never> {
  final String message;
  final int? statusCode;
  NoticeError(this.message, [this.statusCode]);
}

final _client = ApiClient();
const _base = 'api/school-admin/notices';

dynamic _parseJson(String body) {
  try {
    return body.isNotEmpty ? jsonDecode(body) : null;
  } catch (_) {
    return null;
  }
}

String? _errorMessage(http.Response response) {
  if (response.body.isEmpty) return null;
  try {
    final m = jsonDecode(response.body);
    if (m is Map && m['message'] != null) return m['message'] as String;
    if (m is Map && m['error'] != null) return m['error'] as String;
  } catch (_) {}
  return null;
}

class NoticesService {
  NoticesService._();
  static final NoticesService _instance = NoticesService._();
  factory NoticesService() => _instance;

  /// POST /api/school-admin/notices  Body: { "title", "content" }
  Future<NoticeResult<NoticeModel>> createNotice(Map<String, dynamic> data) async {
    try {
      final body = {
        'title': data['title'] is String ? data['title'] as String : data['title'].toString(),
        'content': data['content'] is String ? data['content'] as String : data['content'].toString(),
      };
      final response = await _client.post(apiUrl(_base), body: body);
      devLogResponse('NoticesService.createNotice', response.statusCode, response.body);
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map) return NoticeError('Invalid response from server.');
        final m = raw as Map<String, dynamic>;
        final map = m['notice'] ?? m['data'] ?? m;
        if (map is! Map<String, dynamic>) return NoticeError('Invalid response from server.');
        return NoticeSuccess(NoticeModel.fromJson(map));
      }
      if (response.statusCode == 400) return NoticeError(_errorMessage(response) ?? 'Invalid data.', 400);
      return NoticeError(_errorMessage(response) ?? 'Request failed.', response.statusCode);
    } catch (e, st) {
      return NoticeError(userFriendlyMessage(e, st, 'NoticesService.createNotice'));
    }
  }

  /// GET /api/school-admin/notices
  Future<NoticeResult<List<NoticeModel>>> listNotices() async {
    try {
      final response = await _client.get(apiUrl(_base));
      devLogResponse('NoticesService.listNotices', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return NoticeError(_errorMessage(response) ?? 'Could not load notices.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is List) list = data;
        else if (raw['notices'] is List) list = raw['notices'] as List<dynamic>;
        else if (raw['items'] is List) list = raw['items'] as List<dynamic>;
        else {
          List<dynamic>? found;
          for (final value in raw.values) {
            if (value is List) { found = value; break; }
          }
          if (found == null) return NoticeError(_errorMessage(response) ?? 'Invalid response.');
          list = found;
        }
      } else {
        return NoticeError('Invalid response from server.');
      }
      final notices = <NoticeModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try { notices.add(NoticeModel.fromJson(e)); } catch (_) {}
        }
      }
      return NoticeSuccess(notices);
    } catch (e, st) {
      return NoticeError(userFriendlyMessage(e, st, 'NoticesService.listNotices'));
    }
  }

  /// GET /api/school-admin/notices/{id}
  Future<NoticeResult<NoticeModel>> getNotice(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('NoticesService.getNotice', response.statusCode, response.body);
      if (response.statusCode == 404) return NoticeError('Notice not found.', 404);
      if (response.statusCode != 200) {
        return NoticeError(_errorMessage(response) ?? 'Could not load notice.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['notice'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return NoticeError('Invalid response from server.');
      }
      return NoticeSuccess(NoticeModel.fromJson(map));
    } catch (e, st) {
      return NoticeError(userFriendlyMessage(e, st, 'NoticesService.getNotice'));
    }
  }

  /// PATCH /api/school-admin/notices/{id}
  Future<NoticeResult<NoticeModel>> updateNotice(int id, Map<String, dynamic> data) async {
    try {
      final body = {
        'title': data['title'] is String ? data['title'] as String : data['title'].toString(),
        'content': data['content'] is String ? data['content'] as String : data['content'].toString(),
      };
      final response = await _client.patch(apiUrl('$_base/$id'), body: body);
      devLogResponse('NoticesService.updateNotice', response.statusCode, response.body);
      if (response.statusCode == 404) return NoticeError('Notice not found.', 404);
      if (response.statusCode != 200) {
        return NoticeError(_errorMessage(response) ?? 'Could not update.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['notice'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return NoticeError('Invalid response from server.');
      }
      return NoticeSuccess(NoticeModel.fromJson(map));
    } catch (e, st) {
      return NoticeError(userFriendlyMessage(e, st, 'NoticesService.updateNotice'));
    }
  }

  /// DELETE /api/school-admin/notices/{id}
  Future<NoticeResult<bool>> deleteNotice(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('NoticesService.deleteNotice', response.statusCode, response.body);
      if (response.statusCode == 404) return NoticeError('Notice not found.', 404);
      if (response.statusCode != 200) {
        return NoticeError(_errorMessage(response) ?? 'Could not delete.', response.statusCode);
      }
      return NoticeSuccess(true);
    } catch (e, st) {
      return NoticeError(userFriendlyMessage(e, st, 'NoticesService.deleteNotice'));
    }
  }
}
