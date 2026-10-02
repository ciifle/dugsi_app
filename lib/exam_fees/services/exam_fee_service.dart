import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:kobac/exam_fees/models/exam_fee_models.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/services/attendance_diagnostics.dart' show safeAttendanceBody;
import 'package:kobac/services/pdf_file_result.dart';

/// Exam Fee Custom API (School Admin): /api/school-admin/exam-fees/*.
///
/// Uses the shared authenticated [ApiClient]; school_id and the recording
/// user always come from the JWT on the backend and are never sent.
sealed class ExamFeeResult<T> {}

class ExamFeeSuccess<T> extends ExamFeeResult<T> {
  final T data;
  ExamFeeSuccess(this.data);
}

class ExamFeeFailure extends ExamFeeResult<Never> {
  /// Friendly, user-safe text.
  final String message;
  final int? statusCode;

  /// Backend code, e.g. EXAM_FEE_PAYMENT_EXCEEDS_BALANCE.
  final String? code;

  /// Bulk collection validation errors (nothing was recorded).
  final List<BulkEntryError> entryErrors;

  ExamFeeFailure(
    this.message, {
    this.statusCode,
    this.code,
    this.entryErrors = const [],
  });

  bool get featureDisabled => code == kExamFeeNotEnabledCode;
}

const String kExamFeeNotEnabledCode = 'EXAM_FEE_CUSTOM_NOT_ENABLED';

/// Friendly text for known backend codes; other backend messages are shown
/// only when they look like plain validation text (never SQL/stack traces).
String examFeeErrorMessage({
  String? code,
  int? statusCode,
  String? backendMessage,
  required String fallback,
}) {
  switch (code) {
    case kExamFeeNotEnabledCode:
      return 'Exam Fees are not enabled for this school.';
    case 'EXAM_FEE_SETTING_IN_USE':
      return 'This fee has already been generated for students and cannot be deleted.';
    case 'EXAM_FEE_PAYMENT_EXCEEDS_BALANCE':
      return 'The payment is greater than the remaining balance.';
    case 'EXAM_FEE_ALREADY_PAID':
      return 'This exam fee has already been fully paid.';
    case 'EXAM_FEE_WAIVED':
      return "This student's exam fee has been waived.";
    case 'EXAM_FEE_ALREADY_WAIVED':
      return "This student's exam fee is already waived.";
    case 'EXAM_FEE_NOT_WAIVED':
      return "This student's exam fee is not waived.";
    case 'EXAM_FEE_HAS_PAYMENTS':
      return 'An exam fee that already has payments cannot be waived.';
    case 'EXAM_FEE_AMOUNT_BELOW_PAID':
      return 'The new fee cannot be less than the amount already paid.';
    case 'EXAM_ACADEMIC_YEAR_MISMATCH':
      return 'The selected exam does not belong to the selected academic year. Choose an exam from this year.';
    case 'EXAM_ACADEMIC_YEAR_MISSING':
      return 'This exam has no academic year and cannot be used for exam fees.';
    case 'EXAM_FEE_SETTING_REQUIRED':
      return 'No exam fee is configured for this class and exam.';
    case 'EXAM_FEE_REASON_REQUIRED':
      return 'Please enter a reason.';
    case 'EXAM_FEE_INVALID_AMOUNT':
    case 'EXAM_FEE_AMOUNT_REQUIRED':
      return 'Enter an amount greater than 0.';
    case 'EXAM_FEE_COLLECTION_VALIDATION_FAILED':
      return 'Some selected students could not be collected. No payments were recorded.';
    case 'EXAM_FEE_DUPLICATE_STUDENTS':
      return 'A student was selected more than once. No payments were recorded.';
  }
  if (statusCode == 401) return 'Your session has expired. Please sign in again.';
  if (statusCode == 403) return 'You do not have permission to manage exam fees.';
  if (statusCode != null && statusCode >= 500) {
    return 'The server could not complete this request. Please try again in a moment.';
  }
  final text = backendMessage?.trim() ?? '';
  final lower = text.toLowerCase();
  final unsafe = text.isEmpty ||
      text.length > 200 ||
      lower.contains('sql') ||
      lower.contains('column') ||
      lower.contains('er_') ||
      lower.contains('<html') ||
      lower.contains('stack') ||
      lower.contains('constraint');
  return unsafe ? fallback : text;
}

/// Debug-only diagnostics; never logs headers (token).
void _log(String tag, Map<String, Object?> fields) {
  if (!kDebugMode) return;
  final b = StringBuffer(tag);
  fields.forEach((k, v) {
    if (v != null) b.write('\n$k: $v');
  });
  debugPrint(b.toString(), wrapWidth: 1024);
}

const String _base = 'api/school-admin/exam-fees';

class ExamFeeService {
  ExamFeeService._();
  static final ExamFeeService _instance = ExamFeeService._();
  factory ExamFeeService() => _instance;

  final ApiClient _client = ApiClient();

  dynamic _decode(String body) {
    try {
      return body.isEmpty ? null : jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _scope({int? academicYearId, int? examId, int? classId}) => {
    if (academicYearId != null) 'academic_year_id': '$academicYearId',
    if (examId != null) 'exam_id': '$examId',
    if (classId != null) 'class_id': '$classId',
  };

  ExamFeeFailure _failure(String op, http.Response r, String fallback) {
    final raw = _decode(r.body);
    final map = raw is Map ? raw : const {};
    final code = map['code']?.toString();
    _log('[EXAM FEE ERROR]', {
      'Operation': op,
      'Endpoint': '${r.request?.method} ${r.request?.url.path}',
      'HTTP': r.statusCode,
      'Code': code,
      'Body': safeAttendanceBody(r.body),
    });
    final errors = map['errors'] is List
        ? (map['errors'] as List)
              .whereType<Map>()
              .map((e) => BulkEntryError.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const <BulkEntryError>[];
    return ExamFeeFailure(
      examFeeErrorMessage(
        code: code,
        statusCode: r.statusCode,
        backendMessage: map['message']?.toString(),
        fallback: fallback,
      ),
      statusCode: r.statusCode,
      code: code,
      entryErrors: errors,
    );
  }

  /// One request/parse pipeline for every JSON endpoint.
  Future<ExamFeeResult<T>> _call<T>(
    String op,
    Future<http.Response> Function() send,
    T? Function(dynamic json) parse,
    String fallback, {
    Set<int> ok = const {200, 201},
  }) async {
    final http.Response r;
    try {
      r = await send();
    } catch (e, st) {
      return ExamFeeFailure(userFriendlyMessage(e, st, 'ExamFeeService.$op'));
    }
    if (!ok.contains(r.statusCode)) return _failure(op, r, fallback);
    try {
      final data = parse(_decode(r.body));
      if (data == null) {
        _log('[EXAM FEE ERROR]', {
          'Operation': '$op (parse)',
          'HTTP': r.statusCode,
          'Body': safeAttendanceBody(r.body),
        });
        return ExamFeeFailure(
          'The server sent an unexpected response. Please try again.',
          statusCode: r.statusCode,
        );
      }
      return ExamFeeSuccess(data);
    } catch (e, st) {
      _log('[EXAM FEE ERROR]', {'Operation': '$op (parse)', 'Exception': e, 'StackTrace': st});
      return ExamFeeFailure(
        'The server sent an unexpected response. Please try again.',
        statusCode: r.statusCode,
      );
    }
  }

  Uri _url(String path, [Map<String, String>? query]) {
    final uri = apiUrl('$_base$path');
    return query == null || query.isEmpty ? uri : uri.replace(queryParameters: query);
  }

  // --- Settings + generation -------------------------------------------------

  Future<ExamFeeResult<ExamFeeSettingsResult>> getSettings({
    required int academicYearId,
    required int examId,
  }) => _call(
    'getSettings',
    () => _client.get(_url('/settings', _scope(academicYearId: academicYearId, examId: examId))),
    ExamFeeSettingsResult.tryParse,
    'Could not load exam fee settings.',
  );

  Future<ExamFeeResult<ExamFeeSetting?>> saveSetting({
    required int academicYearId,
    required int examId,
    required int classId,
    required double amount,
  }) => _call<ExamFeeSetting?>(
    'saveSetting',
    () => _client.put(
      _url('/settings'),
      body: {
        'academic_year_id': academicYearId,
        'exam_id': examId,
        'class_id': classId,
        'amount': amount,
      },
    ),
    (json) => json is Map ? ExamFeeSetting.tryParse(json['setting']) : null,
    'Could not save the exam fee.',
  );

  Future<ExamFeeResult<bool>> deleteSetting(int settingId) => _call(
    'deleteSetting',
    () => _client.delete(_url('/settings/$settingId')),
    (_) => true,
    'Could not delete the exam fee setting.',
  );

  Future<ExamFeeResult<GenerationPreview>> previewGeneration({
    required int academicYearId,
    required int examId,
    required int classId,
  }) => _call(
    'previewGeneration',
    () => _client.post(
      _url('/generate/preview'),
      body: {'academic_year_id': academicYearId, 'exam_id': examId, 'class_id': classId},
    ),
    GenerationPreview.tryParse,
    'Could not preview fee generation.',
  );

  Future<ExamFeeResult<GenerationResult>> generateFees({
    required int academicYearId,
    required int examId,
    required int classId,
  }) => _call(
    'generateFees',
    () => _client.post(
      _url('/generate'),
      body: {'academic_year_id': academicYearId, 'exam_id': examId, 'class_id': classId},
    ),
    (json) => json is Map
        ? GenerationResult.fromJson(Map<String, dynamic>.from(json))
        : null,
    'Could not generate exam fees.',
  );

  // --- Register / summary / student fee ------------------------------------

  Future<ExamFeeResult<ExamFeeRegister>> getRegister({
    required int academicYearId,
    required int examId,
    required int classId,
  }) => _call(
    'getRegister',
    () => _client.get(
      _url('/register', _scope(academicYearId: academicYearId, examId: examId, classId: classId)),
    ),
    ExamFeeRegister.tryParse,
    'Could not load the exam fee register.',
  );

  Future<ExamFeeResult<ExamFeeSummary>> getSummary({
    required int academicYearId,
    required int examId,
    int? classId,
  }) => _call(
    'getSummary',
    () => _client.get(
      _url('/summary', _scope(academicYearId: academicYearId, examId: examId, classId: classId)),
    ),
    (json) => json is Map && json['summary'] is Map
        ? ExamFeeSummary.fromJson(Map<String, dynamic>.from(json['summary'] as Map))
        : null,
    'Could not load the exam fee summary.',
  );

  Future<ExamFeeResult<StudentFeeDetail>> getStudentFee(int studentExamFeeId) => _call(
    'getStudentFee',
    () => _client.get(_url('/student-fees/$studentExamFeeId')),
    StudentFeeDetail.tryParse,
    'Could not load the student exam fee.',
  );

  Future<ExamFeeResult<StudentFeeDetail>> updateStudentFeeAmount(
    int studentExamFeeId, {
    required double amount,
    required String reason,
  }) => _call(
    'updateStudentFeeAmount',
    () => _client.patch(
      _url('/student-fees/$studentExamFeeId/amount'),
      body: {'amount': amount, 'reason': reason},
    ),
    StudentFeeDetail.tryParse,
    'Could not update the exam fee.',
  );

  Future<ExamFeeResult<StudentFeeDetail>> waiveStudentFee(
    int studentExamFeeId, {
    required String reason,
  }) => _call(
    'waiveStudentFee',
    () => _client.post(
      _url('/student-fees/$studentExamFeeId/waive'),
      body: {'reason': reason},
    ),
    StudentFeeDetail.tryParse,
    'Could not waive the exam fee.',
  );

  Future<ExamFeeResult<StudentFeeDetail>> unwaiveStudentFee(int studentExamFeeId) => _call(
    'unwaiveStudentFee',
    () => _client.post(_url('/student-fees/$studentExamFeeId/unwaive'), body: <String, dynamic>{}),
    StudentFeeDetail.tryParse,
    'Could not restore the exam fee.',
  );

  // --- Payments --------------------------------------------------------------

  Future<ExamFeeResult<PaymentRecordResult>> recordPayment({
    required int studentExamFeeId,
    required double amount,
    required String method,
    String? referenceNumber,
    String? notes,
  }) => _call(
    'recordPayment',
    () => _client.post(
      _url('/payments'),
      body: {
        'student_exam_fee_id': studentExamFeeId,
        'amount': amount,
        'method': method,
        if (referenceNumber != null && referenceNumber.trim().isNotEmpty)
          'reference_number': referenceNumber.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    ),
    PaymentRecordResult.tryParse,
    'Could not record the payment.',
  );

  /// Atomic: either every entry is recorded or none is.
  Future<ExamFeeResult<BulkCollectionResult>> collectBulk({
    required int academicYearId,
    required int examId,
    required int classId,
    required String method,
    required List<BulkCollectEntry> entries,
    String? referenceNumber,
    String? notes,
  }) => _call(
    'collectBulk',
    () => _client.post(
      _url('/collections'),
      body: {
        'academic_year_id': academicYearId,
        'exam_id': examId,
        'class_id': classId,
        'method': method,
        if (referenceNumber != null && referenceNumber.trim().isNotEmpty)
          'reference_number': referenceNumber.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'entries': [for (final e in entries) e.toJson()],
      },
    ),
    BulkCollectionResult.tryParse,
    'Could not collect the selected payments.',
  );

  Future<ExamFeeResult<ExamFeePaymentPage>> getPayments({
    int? academicYearId,
    int? examId,
    int? classId,
    String? method,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int limit = 20,
  }) => _call(
    'getPayments',
    () => _client.get(
      _url('/payments', {
        ..._scope(academicYearId: academicYearId, examId: examId, classId: classId),
        if (method != null && method.isNotEmpty) 'method': method,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'page': '$page',
        'limit': '$limit',
      }),
    ),
    ExamFeePaymentPage.tryParse,
    'Could not load exam fee payments.',
  );

  Future<ExamFeeResult<ExamFeePayment>> getPayment(int paymentId) => _call(
    'getPayment',
    () => _client.get(_url('/payments/$paymentId')),
    (json) => json is Map && json['payment'] is Map
        ? ExamFeePayment.fromJson(Map<String, dynamic>.from(json['payment'] as Map))
        : null,
    'Could not load the payment.',
  );

  /// Receipt PDF (binary). A 200 that is not a real PDF is an error.
  Future<ExamFeeResult<PdfFileResult>> downloadReceipt(int paymentId) async {
    const fallback = 'Could not download the receipt. Please try again.';
    final http.Response r;
    try {
      r = await _client.get(
        _url('/payments/$paymentId/receipt'),
        headers: const {'Accept': 'application/pdf'},
      );
    } catch (e, st) {
      return ExamFeeFailure(userFriendlyMessage(e, st, 'ExamFeeService.downloadReceipt'));
    }
    if (r.statusCode != 200) return _failure('downloadReceipt', r, fallback);
    final file = pdfFileResultFromResponse(r);
    final b = file?.bytes;
    final isPdf = b != null && b.length > 4 && b[0] == 0x25 && b[1] == 0x50 && b[2] == 0x44 && b[3] == 0x46;
    if (!isPdf) return ExamFeeFailure(fallback, statusCode: r.statusCode);
    return ExamFeeSuccess(file!);
  }
}
