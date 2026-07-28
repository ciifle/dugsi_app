import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

int _id(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

Map<String, dynamic>? _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

List<dynamic> _items(dynamic raw, String key) {
  if (raw is List) return raw;
  final root = _map(raw);
  if (root == null) return const [];
  final data = root['data'];
  if (data is List) return data;
  final nested = _map(data);
  return (root[key] ?? root['items'] ?? nested?[key] ?? nested?['items'])
          as List<dynamic>? ??
      const [];
}

class AcademicYear {
  final int id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  const AcademicYear({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    required this.isActive,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    final active = json['is_active'] ?? json['isActive'] ?? json['active'];
    DateTime? date(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());
    return AcademicYear(
      id: _id(json['id'] ?? json['academic_year_id']),
      name: (json['name'] ?? json['academic_year_name'] ?? '').toString(),
      startDate: date(json['start_date'] ?? json['startDate']),
      endDate: date(json['end_date'] ?? json['endDate']),
      isActive: active == true || active == 1 || active?.toString() == '1',
    );
  }
}

sealed class AcademicYearResult<T> {}

class AcademicYearSuccess<T> extends AcademicYearResult<T> {
  final T data;
  AcademicYearSuccess(this.data);
}

class AcademicYearError extends AcademicYearResult<Never> {
  final String message;
  final int? statusCode;
  AcademicYearError(this.message, [this.statusCode]);
}

class AcademicYearsService {
  AcademicYearsService._();
  static final instance = AcademicYearsService._();
  factory AcademicYearsService() => instance;

  final ApiClient _client = ApiClient();
  static const _base = 'api/school-admin/academic-years';

  String _message(dynamic raw, String fallback) {
    final map = _map(raw);
    return (map?['message'] ?? map?['error'] ?? fallback).toString();
  }

  dynamic _decode(String body) {
    try {
      return body.isEmpty ? null : jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  Future<AcademicYearResult<List<AcademicYear>>> list() async {
    try {
      final response = await _client.get(apiUrl(_base));
      final raw = _decode(response.body);
      if (response.statusCode != 200) {
        return AcademicYearError(
          _message(raw, 'Could not load academic years.'),
          response.statusCode,
        );
      }
      return AcademicYearSuccess(
        _items(raw, 'academic_years')
            .whereType<Map>()
            .map((e) => AcademicYear.fromJson(Map<String, dynamic>.from(e)))
            .where((year) => year.id > 0)
            .toList(),
      );
    } catch (e, st) {
      return AcademicYearError(
        userFriendlyMessage(e, st, 'AcademicYearsService.list'),
      );
    }
  }

  Future<AcademicYearResult<AcademicYear?>> active() async {
    try {
      final response = await _client.get(apiUrl('$_base/active'));
      final raw = _decode(response.body);
      if (response.statusCode == 404 || response.statusCode == 204) {
        return AcademicYearSuccess(null);
      }
      if (response.statusCode != 200) {
        return AcademicYearError(
          _message(raw, 'Could not load the active academic year.'),
          response.statusCode,
        );
      }
      final root = _map(raw);
      final value = _map(root?['academic_year']) ?? _map(root?['data']) ?? root;
      return AcademicYearSuccess(
        value == null ||
                (value['id'] == null && value['academic_year_id'] == null)
            ? null
            : AcademicYear.fromJson(value),
      );
    } catch (e, st) {
      return AcademicYearError(
        userFriendlyMessage(e, st, 'AcademicYearsService.active'),
      );
    }
  }

  Future<AcademicYearResult<AcademicYear>> create({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client.post(
        apiUrl(_base),
        body: {
          'name': name.trim(),
          'start_date': _day(startDate),
          'end_date': _day(endDate),
        },
      );
      final raw = _decode(response.body);
      if (response.statusCode != 200 && response.statusCode != 201) {
        return AcademicYearError(
          _message(raw, 'Could not create academic year.'),
          response.statusCode,
        );
      }
      final root = _map(raw);
      final value = _map(root?['academic_year']) ?? _map(root?['data']) ?? root;
      if (value == null) return AcademicYearError('Invalid server response.');
      return AcademicYearSuccess(AcademicYear.fromJson(value));
    } catch (e, st) {
      return AcademicYearError(
        userFriendlyMessage(e, st, 'AcademicYearsService.create'),
      );
    }
  }

  Future<AcademicYearResult<AcademicYear>> activate(int id) async {
    try {
      final response = await _client.patch(apiUrl('$_base/$id/activate'));
      final raw = _decode(response.body);
      if (response.statusCode != 200) {
        return AcademicYearError(
          _message(raw, 'Could not activate academic year.'),
          response.statusCode,
        );
      }
      final root = _map(raw);
      final value = _map(root?['academic_year']) ?? _map(root?['data']) ?? root;
      if (value == null) return AcademicYearError('Invalid server response.');
      return AcademicYearSuccess(AcademicYear.fromJson(value));
    } catch (e, st) {
      return AcademicYearError(
        userFriendlyMessage(e, st, 'AcademicYearsService.activate'),
      );
    }
  }

  static String _day(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class AcademicYearsProvider extends ChangeNotifier {
  final AcademicYearsService service;
  AcademicYearsProvider({AcademicYearsService? service})
    : service = service ?? AcademicYearsService();

  List<AcademicYear> years = const [];
  AcademicYear? activeYear;
  bool loading = false;
  bool submitting = false;
  String? error;
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded || loading) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    final results = await Future.wait([service.list(), service.active()]);
    final listResult = results[0];
    final activeResult = results[1];
    if (listResult is AcademicYearSuccess<List<AcademicYear>>) {
      years = listResult.data;
    } else {
      error = (listResult as AcademicYearError).message;
    }
    if (activeResult is AcademicYearSuccess<AcademicYear?>) {
      activeYear = activeResult.data;
    } else {
      error ??= (activeResult as AcademicYearError).message;
    }
    _loaded = true;
    loading = false;
    notifyListeners();
  }

  Future<AcademicYearResult<AcademicYear>> create({
    required String name,
    required DateTime start,
    required DateTime end,
  }) async {
    submitting = true;
    notifyListeners();
    final result = await service.create(
      name: name,
      startDate: start,
      endDate: end,
    );
    submitting = false;
    if (result is AcademicYearSuccess<AcademicYear>) await refresh();
    notifyListeners();
    return result;
  }

  Future<AcademicYearResult<AcademicYear>> activate(int id) async {
    submitting = true;
    notifyListeners();
    final result = await service.activate(id);
    submitting = false;
    if (result is AcademicYearSuccess<AcademicYear>) await refresh();
    notifyListeners();
    return result;
  }
}
