import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

int _id(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

Map<String, dynamic>? _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

bool _bool(dynamic value, [bool fallback = true]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  return const {
    '1',
    'true',
    'active',
    'yes',
  }.contains(value.toString().toLowerCase());
}

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

class Shift {
  final int id;
  final String name;
  final bool isActive;
  final int classCount;

  const Shift({
    required this.id,
    required this.name,
    this.isActive = true,
    this.classCount = 0,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    final active = json['is_active'] ?? json['isActive'] ?? json['active'];
    return Shift(
      id: _id(json['id'] ?? json['shift_id']),
      name: (json['name'] ?? json['shift_name'] ?? '').toString().trim(),
      isActive: _bool(active),
      classCount: _id(
        json['class_count'] ?? json['classCount'] ?? json['classes_count'],
      ),
    );
  }
}

sealed class ShiftResult<T> {}

class ShiftSuccess<T> extends ShiftResult<T> {
  final T data;
  ShiftSuccess(this.data);
}

class ShiftError extends ShiftResult<Never> {
  final String message;
  final int? statusCode;
  ShiftError(this.message, [this.statusCode]);
}

class ShiftsService {
  ShiftsService._();
  static final instance = ShiftsService._();
  factory ShiftsService() => instance;

  final ApiClient _client = ApiClient();
  static const _base = 'api/school-admin/shifts';

  dynamic _decode(String body) {
    try {
      return body.isEmpty ? null : jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _message(dynamic raw, String fallback) {
    final map = _map(raw);
    final text = (map?['message'] ?? map?['error'] ?? '').toString();
    return text.trim().isNotEmpty &&
            !text.toLowerCase().contains('<html') &&
            !text.toLowerCase().contains('sql')
        ? text
        : fallback;
  }

  Shift? _value(dynamic raw) {
    final root = _map(raw);
    final value = _map(root?['shift']) ?? _map(root?['data']) ?? root;
    return value == null || (value['id'] == null && value['shift_id'] == null)
        ? null
        : Shift.fromJson(value);
  }

  Future<ShiftResult<List<Shift>>> list() async {
    try {
      final response = await _client.get(apiUrl(_base));
      final raw = _decode(response.body);
      if (response.statusCode != 200) {
        return ShiftError(
          _message(raw, 'Could not load shifts.'),
          response.statusCode,
        );
      }
      return ShiftSuccess(
        _items(raw, 'shifts')
            .whereType<Map>()
            .map((e) => Shift.fromJson(Map<String, dynamic>.from(e)))
            .where((shift) => shift.id > 0)
            .toList(),
      );
    } catch (e, st) {
      return ShiftError(userFriendlyMessage(e, st, 'ShiftsService.list'));
    }
  }

  Future<ShiftResult<Shift>> create({
    required String name,
    bool isActive = true,
  }) async {
    try {
      final response = await _client.post(
        apiUrl(_base),
        body: {'name': name.trim(), 'is_active': isActive},
      );
      final raw = _decode(response.body);
      if (response.statusCode != 200 && response.statusCode != 201) {
        return ShiftError(
          _message(raw, 'Could not create shift.'),
          response.statusCode,
        );
      }
      final value = _value(raw);
      if (value == null) return ShiftError('Invalid server response.');
      return ShiftSuccess(value);
    } catch (e, st) {
      return ShiftError(userFriendlyMessage(e, st, 'ShiftsService.create'));
    }
  }

  Future<ShiftResult<Shift>> update(
    int id, {
    String? name,
    bool? isActive,
  }) async {
    try {
      final response = await _client.patch(
        apiUrl('$_base/$id'),
        body: {
          if (name != null) 'name': name.trim(),
          if (isActive != null) 'is_active': isActive,
        },
      );
      final raw = _decode(response.body);
      if (response.statusCode == 404) {
        return ShiftError('Shift not found.', 404);
      }
      if (response.statusCode != 200) {
        return ShiftError(
          _message(raw, 'Could not update shift.'),
          response.statusCode,
        );
      }
      final value = _value(raw);
      if (value == null) return ShiftError('Invalid server response.');
      return ShiftSuccess(value);
    } catch (e, st) {
      return ShiftError(userFriendlyMessage(e, st, 'ShiftsService.update'));
    }
  }

  Future<ShiftResult<bool>> delete(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      final raw = _decode(response.body);
      if (response.statusCode == 404) {
        return ShiftError('Shift not found.', 404);
      }
      if (response.statusCode == 409) {
        final backend = _message(raw, '');
        return ShiftError(
          backend.isNotEmpty
              ? backend
              : 'This shift is assigned to one or more classes. Reassign those classes before deleting it.',
          409,
        );
      }
      if (response.statusCode != 200 && response.statusCode != 204) {
        return ShiftError(
          _message(raw, 'Could not delete shift.'),
          response.statusCode,
        );
      }
      return ShiftSuccess(true);
    } catch (e, st) {
      return ShiftError(userFriendlyMessage(e, st, 'ShiftsService.delete'));
    }
  }

  Future<ShiftResult<bool>> assignClasses(
    int shiftId,
    List<int> classIds,
  ) async {
    try {
      final response = await _client.patch(
        apiUrl('$_base/$shiftId/classes'),
        body: {'class_ids': classIds},
      );
      final raw = _decode(response.body);
      if (response.statusCode != 200) {
        return ShiftError(
          _message(raw, 'Could not assign classes.'),
          response.statusCode,
        );
      }
      return ShiftSuccess(true);
    } catch (e, st) {
      return ShiftError(
        userFriendlyMessage(e, st, 'ShiftsService.assignClasses'),
      );
    }
  }
}

class ShiftsProvider extends ChangeNotifier {
  final ShiftsService service;
  ShiftsProvider({ShiftsService? service})
    : service = service ?? ShiftsService();

  List<Shift> shifts = const [];
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
    final result = await service.list();
    if (result is ShiftSuccess<List<Shift>>) {
      shifts = result.data;
    } else {
      error = (result as ShiftError).message;
    }
    _loaded = true;
    loading = false;
    notifyListeners();
  }

  Future<ShiftResult<Shift>> create({
    required String name,
    bool isActive = true,
  }) async {
    submitting = true;
    notifyListeners();
    final result = await service.create(name: name, isActive: isActive);
    submitting = false;
    if (result is ShiftSuccess<Shift>) await refresh();
    notifyListeners();
    return result;
  }

  Future<ShiftResult<Shift>> update(
    int id, {
    String? name,
    bool? isActive,
  }) async {
    submitting = true;
    notifyListeners();
    final result = await service.update(id, name: name, isActive: isActive);
    submitting = false;
    if (result is ShiftSuccess<Shift>) await refresh();
    notifyListeners();
    return result;
  }

  Future<ShiftResult<bool>> delete(int id) async {
    submitting = true;
    notifyListeners();
    final result = await service.delete(id);
    submitting = false;
    if (result is ShiftSuccess<bool>) await refresh();
    notifyListeners();
    return result;
  }

  Future<ShiftResult<bool>> assignClasses(
    int shiftId,
    List<int> classIds,
  ) async {
    submitting = true;
    notifyListeners();
    final result = await service.assignClasses(shiftId, classIds);
    submitting = false;
    if (result is ShiftSuccess<bool>) await refresh();
    notifyListeners();
    return result;
  }
}
