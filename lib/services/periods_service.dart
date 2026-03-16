import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

class PeriodModel {
  final int id;
  final int schoolId;
  final String name;
  final int periodNumber;
  final String shift;
  final String startTime;
  final String endTime;

  const PeriodModel({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.periodNumber,
    required this.shift,
    required this.startTime,
    required this.endTime,
  });

  factory PeriodModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    
    return PeriodModel(
      id: parseId(json['id']),
      schoolId: parseId(json['school_id'] ?? json['schoolId']),
      name: (json['name'] ?? '').toString(),
      periodNumber: parseId(json['period_number'] ?? json['periodNumber']),
      shift: (json['shift'] ?? '').toString(),
      startTime: _normalizeTime((json['start_time'] ?? json['startTime'] ?? '').toString()),
      endTime: _normalizeTime((json['end_time'] ?? json['endTime'] ?? '').toString()),
    );
  }

  static String _normalizeTime(String t) {
    if (t.isEmpty) return '00:00:00';
    final parts = t.trim().split(':');
    if (parts.length == 1) return '${parts[0].padLeft(2, '0')}:00:00';
    if (parts.length == 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
    if (parts.length >= 3) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:${parts[2].padLeft(2, '0')}';
    return t;
  }
}

sealed class PeriodResult<T> {}

class PeriodSuccess<T> extends PeriodResult<T> {
  final T data;
  PeriodSuccess(this.data);
}

class PeriodError extends PeriodResult<Never> {
  final String message;
  final int? statusCode;
  PeriodError(this.message, [this.statusCode]);
}

class PeriodsService {
  PeriodsService._();
  static final PeriodsService _instance = PeriodsService._();
  factory PeriodsService() => _instance;

  final _client = ApiClient();
  static const _base = 'api/school-admin/periods';

  Future<PeriodResult<List<PeriodModel>>> getPeriods({String? shift}) async {
    try {
      final uri = apiUrl(_base);
      final queryUri = shift != null && shift.isNotEmpty
          ? uri.replace(queryParameters: {'shift': shift})
          : uri;
          
      final response = await _client.get(queryUri);
      devLogResponse('PeriodsService.getPeriods', response.statusCode, response.body);
      
      if (response.statusCode != 200) {
        return PeriodError(_errorMessage(response) ?? 'Could not load periods.', response.statusCode);
      }
      
      final raw = _parseJson(response.body);
      List<dynamic> list = [];
      
      if (raw is Map<String, dynamic>) {
        if (raw['periods'] is List) {
          list = raw['periods'];
        } else if (raw['data'] is List) {
          list = raw['data'];
        }
      } else if (raw is List) {
        list = raw;
      }
      
      final periods = <PeriodModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          periods.add(PeriodModel.fromJson(e));
        }
      }
      
      return PeriodSuccess(periods);
    } catch (e, st) {
      return PeriodError(userFriendlyMessage(e, st, 'PeriodsService.getPeriods'));
    }
  }

  /// POST /api/school-admin/periods
  Future<PeriodResult<PeriodModel>> createPeriod(Map<String, dynamic> payload) async {
    try {
      final response = await _client.post(apiUrl(_base), body: payload);
      devLogResponse('PeriodsService.createPeriod', response.statusCode, response.body);
      
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map) return PeriodError('Invalid response from server.');
        final m = raw as Map<String, dynamic>;
        final periodMap = m['period'] ?? m['data'] ?? m;
        return PeriodSuccess(PeriodModel.fromJson(Map<String, dynamic>.from(periodMap)));
      }
      return PeriodError(_errorMessage(response) ?? 'Request failed. Please try again.', response.statusCode);
    } catch (e, st) {
      return PeriodError(userFriendlyMessage(e, st, 'PeriodsService.createPeriod'));
    }
  }

  /// PATCH /api/school-admin/periods/{id}
  Future<PeriodResult<PeriodModel>> updatePeriod(int id, Map<String, dynamic> payload) async {
    try {
      if (payload.isEmpty) return PeriodError('No fields to update.');
      final response = await _client.patch(apiUrl('$_base/$id'), body: payload);
      devLogResponse('PeriodsService.updatePeriod', response.statusCode, response.body);
      
      if (response.statusCode == 404) return PeriodError('Period not found.', 404);
      if (response.statusCode != 200) {
        return PeriodError(_errorMessage(response) ?? 'Could not update. Please try again.', response.statusCode);
      }
      
      final raw = _parseJson(response.body);
      if (raw == null || raw is! Map) return PeriodError('Invalid response from server.');
      final m = raw as Map<String, dynamic>;
      final periodMap = m['period'] ?? m['data'] ?? m;
      return PeriodSuccess(PeriodModel.fromJson(Map<String, dynamic>.from(periodMap)));
    } catch (e, st) {
      return PeriodError(userFriendlyMessage(e, st, 'PeriodsService.updatePeriod'));
    }
  }

  /// DELETE /api/school-admin/periods/{id}
  Future<PeriodResult<bool>> deletePeriod(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('PeriodsService.deletePeriod', response.statusCode, response.body);
      
      if (response.statusCode == 404) return PeriodError('Period not found.', 404);
      if (response.statusCode != 200) {
        return PeriodError(_errorMessage(response) ?? 'Could not delete. Please try again.', response.statusCode);
      }
      return PeriodSuccess(true);
    } catch (e, st) {
      return PeriodError(userFriendlyMessage(e, st, 'PeriodsService.deletePeriod'));
    }
  }

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
}
