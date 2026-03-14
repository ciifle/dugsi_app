import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

/// Fee model. Backend returns flattened root-level fields (studentName, emisNumber, amount, status, paidAmount, remainingAmount, Payments).
/// Do not parse nested User for fees.
class FeeModel {
  final int id;
  final int studentId;
  final num amount;
  final num? paidAmount;
  final num? remainingAmount;
  final String? status;
  final String? createdAt;
  /// Flattened from API (root-level).
  final String? studentName;
  final String? emisNumber;
  final List<dynamic>? payments;

  const FeeModel({
    required this.id,
    required this.studentId,
    required this.amount,
    this.paidAmount,
    this.remainingAmount,
    this.status,
    this.createdAt,
    this.studentName,
    this.emisNumber,
    this.payments,
  });

  factory FeeModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    num parseNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }
    String? strOpt(dynamic v) => v == null ? null : v.toString().trim();
    List<dynamic>? payList;
    final p = json['Payments'] ?? json['payments'];
    if (p is List) payList = p;
    return FeeModel(
      id: parseId(json['id'] ?? json['fee_id']),
      studentId: parseId(json['student_id'] ?? json['studentId'] ?? 0),
      amount: parseNum(json['amount'] ?? 0),
      paidAmount: json['paid_amount'] != null || json['paidAmount'] != null ? parseNum(json['paid_amount'] ?? json['paidAmount']) : null,
      remainingAmount: json['remaining_amount'] != null || json['remainingAmount'] != null ? parseNum(json['remaining_amount'] ?? json['remainingAmount']) : null,
      status: strOpt(json['status']),
      createdAt: strOpt(json['created_at'] ?? json['createdAt']),
      studentName: strOpt(json['studentName'] ?? json['student_name']),
      emisNumber: strOpt(json['emisNumber'] ?? json['emis_number']),
      payments: payList,
    );
  }
}

sealed class FeeResult<T> {}

class FeeSuccess<T> extends FeeResult<T> {
  final T data;
  FeeSuccess(this.data);
}

class FeeError extends FeeResult<Never> {
  final String message;
  final int? statusCode;
  FeeError(this.message, [this.statusCode]);
}

final _client = ApiClient();
const _base = 'api/school-admin/fees';

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

class FeesService {
  FeesService._();
  static final FeesService _instance = FeesService._();
  factory FeesService() => _instance;

  Future<FeeResult<List<FeeModel>>> listFees() async {
    try {
      final response = await _client.get(apiUrl(_base));
      devLogResponse('FeesService.listFees', response.statusCode, response.body);
      if (response.statusCode != 200) {
        return FeeError(_errorMessage(response) ?? 'Could not load fees.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is List) list = data;
        else if (raw['fees'] is List) list = raw['fees'] as List<dynamic>;
        else if (raw['items'] is List) list = raw['items'] as List<dynamic>;
        else {
          List<dynamic>? found;
          for (final value in raw.values) {
            if (value is List) { found = value; break; }
          }
          if (found == null) return FeeError(_errorMessage(response) ?? 'Invalid response.');
          list = found;
        }
      } else {
        return FeeError('Invalid response from server.');
      }
      final fees = <FeeModel>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try { fees.add(FeeModel.fromJson(e)); } catch (_) {}
        }
      }
      return FeeSuccess(fees);
    } catch (e, st) {
      return FeeError(userFriendlyMessage(e, st, 'FeesService.listFees'));
    }
  }

  Future<FeeResult<FeeModel>> getFee(int id) async {
    try {
      final response = await _client.get(apiUrl('$_base/$id'));
      devLogResponse('FeesService.getFee', response.statusCode, response.body);
      if (response.statusCode == 404) return FeeError('Fee not found.', 404);
      if (response.statusCode != 200) {
        return FeeError(_errorMessage(response) ?? 'Could not load fee.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['fee'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return FeeError('Invalid response from server.');
      }
      return FeeSuccess(FeeModel.fromJson(map));
    } catch (e, st) {
      return FeeError(userFriendlyMessage(e, st, 'FeesService.getFee'));
    }
  }

  Future<FeeResult<FeeModel>> createFee(Map<String, dynamic> payload) async {
    try {
      final body = <String, dynamic>{
        'student_id': payload['student_id'] is int ? payload['student_id'] as int : int.tryParse(payload['student_id'].toString()) ?? 0,
        'amount': payload['amount'] is num ? payload['amount'] : num.tryParse(payload['amount'].toString()) ?? 0,
      };
      final response = await _client.post(apiUrl(_base), body: body);
      devLogResponse('FeesService.createFee', response.statusCode, response.body);
      if (response.statusCode == 201) {
        final raw = _parseJson(response.body);
        if (raw == null || raw is! Map) return FeeError('Invalid response from server.');
        final m = raw as Map<String, dynamic>;
        final map = m['fee'] ?? m['data'] ?? m;
        if (map is! Map<String, dynamic>) return FeeError('Invalid response from server.');
        return FeeSuccess(FeeModel.fromJson(map));
      }
      if (response.statusCode == 400) return FeeError(_errorMessage(response) ?? 'Invalid data.', 400);
      return FeeError(_errorMessage(response) ?? 'Request failed.', response.statusCode);
    } catch (e, st) {
      return FeeError(userFriendlyMessage(e, st, 'FeesService.createFee'));
    }
  }

  Future<FeeResult<FeeModel>> updateFeeStatus(int id, Map<String, dynamic> payload) async {
    try {
      final status = payload['status'] is String ? payload['status'] as String : payload['status'].toString();
      final response = await _client.patch(apiUrl('$_base/$id'), body: {'status': status});
      devLogResponse('FeesService.updateFeeStatus', response.statusCode, response.body);
      if (response.statusCode == 404) return FeeError('Fee not found.', 404);
      if (response.statusCode != 200) {
        return FeeError(_errorMessage(response) ?? 'Could not update status.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw['fee'] as Map<String, dynamic>? ?? raw['data'] as Map<String, dynamic>? ?? raw;
      } else {
        return FeeError('Invalid response from server.');
      }
      return FeeSuccess(FeeModel.fromJson(map));
    } catch (e, st) {
      return FeeError(userFriendlyMessage(e, st, 'FeesService.updateFeeStatus'));
    }
  }

  Future<FeeResult<bool>> deleteFee(int id) async {
    try {
      final response = await _client.delete(apiUrl('$_base/$id'));
      devLogResponse('FeesService.deleteFee', response.statusCode, response.body);
      if (response.statusCode == 404) return FeeError('Fee not found.', 404);
      if (response.statusCode != 200) {
        return FeeError(_errorMessage(response) ?? 'Could not delete.', response.statusCode);
      }
      return FeeSuccess(true);
    } catch (e, st) {
      return FeeError(userFriendlyMessage(e, st, 'FeesService.deleteFee'));
    }
  }
}
