import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:kobac/exam_fees/models/exam_fee_models.dart';
import 'package:kobac/exam_fees/pages/exam_fees_page.dart';
import 'package:kobac/exam_fees/services/exam_fee_service.dart';
import 'package:kobac/exam_fees/state/exam_fees_controller.dart';
import 'package:kobac/models/auth_me_models.dart';
import 'package:kobac/school_admin/widgets/web_sidebar.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/pdf_file_result.dart';

// ---------------------------------------------------------------------------
// Fake backend mirroring examFee.service.js (cents maths, statuses, atomic
// bulk, 409 setting-in-use, pagination, feature gate).
// ---------------------------------------------------------------------------

http.Response _json(Object v, [int s = 200]) =>
    http.Response(jsonEncode(v), s, headers: {'content-type': 'application/json'});

int _c(num v) => (v * 100).round();
double _d(int cents) => cents / 100;

class Fee {
  final int id, studentId;
  final String name, emis;
  int original, amount, paid;
  String? waiver;
  Fee(this.id, this.studentId, this.name, this.emis, double orig,
      {double? amt, double paid = 0, this.waiver})
      : original = _c(orig),
        amount = _c(amt ?? orig),
        paid = _c(paid);
  String get status => waiver != null
      ? 'WAIVED'
      : amount - paid <= 0
          ? 'PAID'
          : paid > 0
              ? 'PARTIAL'
              : 'UNPAID';
  Map<String, Object?> json() => {
        'student_exam_fee_id': id,
        'student_id': studentId,
        'student_name': name,
        'emis_number': emis,
        'academic_year_id': 2,
        'exam_id': 70,
        'class_id': 25,
        // MySQL DECIMALs sometimes arrive as strings.
        'original_amount': _d(original).toStringAsFixed(2),
        'amount': _d(waiver != null ? 0 : amount),
        'paid_amount': _d(paid),
        'remaining_amount': _d(waiver != null ? 0 : amount - paid),
        'status': status,
        'is_waived': waiver != null,
        'adjustment_reason': amount != original && waiver == null ? 'Sibling discount' : null,
        'waiver_reason': waiver,
      };
}

class ExamFeeFixture {
  final requests = <http.Request>[];
  bool disabled = false;
  Map<String, Object?>? bulkError;
  Completer<void>? generateGate, receiptGate;

  final fees = <Fee>[
    Fee(501, 1001, 'Ahmed Ali', 'EMIS-1001', 10),
    Fee(502, 1002, 'Bashir Omar', 'EMIS-1002', 10, amt: 6.5, paid: 3.25),
    Fee(503, 1003, 'Caaliya Noor', 'EMIS-1003', 10, paid: 10),
    Fee(504, 1004, 'Deeq Hassan', 'EMIS-1004', 10, waiver: 'Orphan support'),
  ];
  final settings = <int, Map<String, Object?>>{
    25: {'id': 900, 'amount': 10},
  };
  bool generated26 = false;
  final payments = <Map<String, Object?>>[];
  int _nextPayment = 1;

  List<http.Request> where(String m, String suffix) =>
      requests.where((r) => r.method == m && r.url.path.endsWith(suffix)).toList();

  Map<String, Object?> _scope({bool cls = true}) => {
        'academic_year': {'id': 2, 'name': '2026-2027'},
        'exam': {'id': 70, 'name': 'Midterm', 'exam_type': 'MIDTERM', 'date': null},
        if (cls) 'class': {'id': 25, 'name': 'Form 3'},
      };

  Map<String, Object?> _summary() {
    int sum(int Function(Fee) f) => fees.fold(0, (a, x) => a + f(x));
    int count(String s) => fees.where((f) => f.status == s).length;
    return {
      'generated_students': fees.length,
      'not_generated_students': 1,
      'total_original': _d(sum((f) => f.original)),
      'total_charged': _d(sum((f) => f.waiver != null ? 0 : f.amount)),
      'total_collected': _d(sum((f) => f.paid)),
      'outstanding': _d(sum((f) => f.waiver != null ? 0 : f.amount - f.paid)),
      'paid_count': count('PAID'),
      'partial_count': count('PARTIAL'),
      'unpaid_count': count('UNPAID'),
      'waived_count': count('WAIVED'),
      'total_waived_value': 10,
    };
  }

  Fee _fee(int id) => fees.firstWhere((f) => f.id == id);

  Map<String, Object?> _detail(Fee f) => {
        'student': {'id': f.studentId, 'name': f.name, 'emis_number': f.emis},
        'exam': {'id': 70, 'name': 'Midterm'},
        'class': {'id': 25, 'name': 'Form 3'},
        'academic_year': {'id': 2, 'name': '2026-2027'},
        'fee': f.json(),
        'adjustment': null,
        'waiver': f.waiver == null ? null : {'reason': f.waiver, 'by': {'id': 1, 'name': 'Admin'}},
        'payments': [for (final p in payments) if (p['student_exam_fee_id'] == f.id) p],
      };

  Map<String, Object?> _pay(Fee f, int cents, String method) {
    f.paid += cents;
    final id = _nextPayment++;
    final p = {
      'id': id,
      'receipt_number': 'EXAM-20261002-${id.toString().padLeft(6, '0')}',
      'amount': _d(cents),
      'method': method,
      'reference_number': null,
      'notes': null,
      'paid_at': '2026-10-02T09:15:00.000Z',
      'recorded_by': {'id': 1, 'name': 'School Admin'},
      'student_exam_fee_id': f.id,
      'student': {'id': f.studentId, 'name': f.name, 'emis_number': f.emis},
      'exam': {'id': 70, 'name': 'Midterm'},
      'class': {'id': 25, 'name': 'Form 3'},
      'academic_year': {'id': 2, 'name': '2026-2027'},
    };
    payments.insert(0, p);
    return p;
  }

  Future<http.Response> call(http.Request r) async {
    final path = r.url.path;
    final q = r.url.queryParameters;
    final body = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(r.body) as Map<String, dynamic>;
    if (path.endsWith('/exams')) {
      return _json({
        'exams': q['academic_year_id'] == '1'
            ? [{'id': 60, 'name': 'Final 2025', 'academic_year_id': 1}]
            : [{'id': 70, 'name': 'Midterm', 'academic_year_id': 2}],
      });
    }
    if (path.endsWith('/classes')) {
      return _json({
        'classes': [
          {'id': 25, 'name': 'Form 3'},
          {'id': 26, 'name': 'Form 4'},
        ],
      });
    }
    if (!path.contains('/exam-fees')) return _json({'message': 'Route not found'}, 404);
    requests.add(r);
    if (disabled) {
      return _json({
        'message': 'Exam Fee Custom is not enabled for this school.',
        'code': 'EXAM_FEE_CUSTOM_NOT_ENABLED',
      }, 403);
    }
    final m = r.method;
    if (path.endsWith('/settings') && m == 'GET') {
      return _json({
        ..._scope(cls: false),
        'classes': [
          for (final (id, name) in [(25, 'Form 3'), (26, 'Form 4')])
            {
              'class_id': id,
              'class_name': name,
              'configured': settings[id] != null,
              'setting': settings[id],
              'generated_count': id == 25 ? 4 : (generated26 ? 3 : 0),
            },
        ],
      });
    }
    if (path.endsWith('/settings') && m == 'PUT') {
      final cls = body['class_id'] as int;
      final created = settings[cls] == null;
      settings[cls] = {'id': created ? 901 : settings[cls]!['id'], 'amount': body['amount']};
      return _json({..._scope(), 'created': created, 'setting': settings[cls]}, created ? 201 : 200);
    }
    if (path.contains('/settings/') && m == 'DELETE') {
      if (path.endsWith('/900')) {
        return _json({
          'message': 'This exam fee setting has generated student fees and cannot be deleted.',
          'code': 'EXAM_FEE_SETTING_IN_USE',
          'generated_count': 4,
        }, 409);
      }
      settings.remove(26);
      return _json({'message': 'Exam fee setting deleted', 'id': 901});
    }
    if (path.endsWith('/generate/preview')) {
      return _json({
        ..._scope(),
        'setting': settings[26],
        'current_amount': settings[26]?['amount'],
        'can_generate': settings[26] != null && !generated26,
        'message': null,
        'counts': {
          'eligible': 4,
          'will_generate': generated26 ? 0 : 3,
          'already_generated': generated26 ? 4 : 1,
          'already_generated_in_other_class': 1,
          'differs_from_current_setting': 0,
        },
        'students_to_generate': [],
        'already_generated': [],
      });
    }
    if (path.endsWith('/generate')) {
      if (generateGate != null) await generateGate!.future;
      final created = generated26 ? 0 : 3;
      generated26 = true;
      return _json({
        ..._scope(),
        'setting': settings[26],
        'amount': settings[26]?['amount'],
        'eligible': 4,
        'created': created,
        'already_generated': 4 - created,
        'differs_from_current_setting': 0,
      });
    }
    if (path.endsWith('/register')) {
      return _json({
        ..._scope(),
        'setting': settings[25],
        'summary': _summary(),
        'students': [for (final f in fees) f.json()],
        'not_generated': [
          {'student_id': 1005, 'student_name': 'Hodan Farah', 'emis_number': 'EMIS-1005', 'enrollment_status': 'active'},
        ],
        'generated_in_other_class': [
          {'student_id': 1006, 'student_name': 'Ilhan Yusuf', 'emis_number': null, 'student_exam_fee_id': 777, 'class_id': 26, 'class_name': 'Form 4'},
        ],
      });
    }
    if (path.endsWith('/summary')) return _json({..._scope(), 'summary': _summary()});
    final feeMatch = RegExp(r'/student-fees/(\d+)(/\w+)?$').firstMatch(path);
    if (feeMatch != null) {
      final f = _fee(int.parse(feeMatch.group(1)!));
      final action = feeMatch.group(2);
      if (action == '/amount') {
        final cents = _c(body['amount'] as num);
        if (cents < f.paid) {
          return _json({'message': 'Amount cannot be less than paid', 'code': 'EXAM_FEE_AMOUNT_BELOW_PAID'}, 400);
        }
        f.amount = cents;
      } else if (action == '/waive') {
        f.waiver = body['reason'] as String;
      } else if (action == '/unwaive') {
        f.waiver = null;
        f.amount = f.original;
      }
      return _json(_detail(f));
    }
    if (path.endsWith('/payments') && m == 'POST') {
      final f = _fee(body['student_exam_fee_id'] as int);
      final cents = _c(body['amount'] as num);
      if (cents > f.amount - f.paid) {
        return _json({'message': 'exceeds', 'code': 'EXAM_FEE_PAYMENT_EXCEEDS_BALANCE'}, 400);
      }
      final p = _pay(f, cents, body['method'] as String);
      return _json({
        'payment': p,
        'fee': {'student_exam_fee_id': f.id, 'amount': _d(f.amount), 'paid_amount': _d(f.paid), 'remaining_amount': _d(f.amount - f.paid), 'status': f.status},
      }, 201);
    }
    if (path.endsWith('/collections')) {
      if (bulkError != null) return _json(bulkError!, 400);
      final results = [];
      var total = 0;
      for (final e in (body['entries'] as List).cast<Map>()) {
        final f = fees.firstWhere((x) => x.studentId == e['student_id']);
        final cents = _c(e['amount'] as num);
        total += cents;
        results.add({'student_id': f.studentId, 'payment': _pay(f, cents, body['method'] as String)});
      }
      return _json({..._scope(), 'payment_count': results.length, 'total_collected': _d(total), 'results': results}, 201);
    }
    if (path.endsWith('/payments') && m == 'GET') {
      var list = [...payments];
      if (q['method'] != null) list = list.where((p) => p['method'] == q['method']).toList();
      final page = int.parse(q['page'] ?? '1'), limit = int.parse(q['limit'] ?? '50');
      final slice = list.skip((page - 1) * limit).take(limit).toList();
      return _json({'payments': slice, 'pagination': {'page': page, 'limit': limit, 'total': list.length}});
    }
    final payMatch = RegExp(r'/payments/(\d+)(/receipt)?$').firstMatch(path);
    if (payMatch != null) {
      final p = payments.firstWhere((x) => x['id'] == int.parse(payMatch.group(1)!));
      if (payMatch.group(2) != null) {
        if (receiptGate != null) await receiptGate!.future;
        return http.Response.bytes(utf8.encode('%PDF-1.4 receipt'), 200, headers: {
          'content-type': 'application/pdf',
          'content-disposition': 'attachment; filename="exam-fee-receipt-${p['receipt_number']}.pdf"',
        });
      }
      return _json({'payment': p, 'fee': _fee(p['student_exam_fee_id'] as int).json()});
    }
    return _json({'message': 'Route not found'}, 404);
  }
}

// ---------------------------------------------------------------------------

class _Auth extends AuthProvider {
  bool on;
  bool fees;
  _Auth({this.on = true, this.fees = false});
  @override
  bool get examFeeCustomEnabled => on;
  @override
  bool get feesEnabled => fees;
  @override
  void disableExamFeeAccess() {
    on = false;
    notifyListeners();
  }
}

final _y2 = AcademicYear(id: 2, name: '2026-2027', startDate: DateTime(2026, 9, 1), endDate: DateTime(2027, 6, 30), isActive: true);
final _y1 = AcademicYear(id: 1, name: '2025-2026', startDate: DateTime(2025, 9, 1), endDate: DateTime(2026, 6, 30), isActive: false);

class _Years extends AcademicYearsProvider {
  _Years() {
    years = [_y2, _y1];
    activeYear = _y2;
  }
  @override
  Future<void> ensureLoaded() async {}
}

Future<T> _with<T>(ExamFeeFixture f, Future<T> Function() body) =>
    http.runWithClient(body, () => MockClient(f.call));

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> _pick(WidgetTester t, String label, String item) async {
  await _tap(t, find.widgetWithText(DropdownButtonFormField<int>, label));
  await t.tap(find.text(item).last);
  await t.pumpAndSettle();
}

Future<ExamFeesController> _pump(
  WidgetTester t, {
  _Auth? auth,
  Size size = const Size(390, 844),
  bool desktop = false,
  bool selectAll = true,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final c = ExamFeesController();
  addTearDown(c.dispose);
  final page = ExamFeesPage(controller: c, desktopOverride: desktop, embedBodyOnly: desktop);
  await t.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth ?? _Auth()),
      ChangeNotifierProvider<AcademicYearsProvider>.value(value: _Years()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: desktop
            ? Row(children: [
                const SizedBox(width: 260),
                Expanded(child: page),
              ])
            : page,
      ),
    ),
  ));
  await t.pumpAndSettle();
  if (selectAll && (auth?.on ?? true)) {
    await _pick(t, 'Exam', 'Midterm');
    await _pick(t, 'Class', 'Form 3');
  }
  return c;
}

Finder _stat(String label, String value) => find.descendant(
      of: find.byKey(ValueKey('register-summary-$label')),
      matching: find.text(value),
    );

void main() {
  tearDown(() => ApiClient().setToken(null));

  group('feature flag', () {
    test('parsed from /me schoolFeatures; missing/null stays null', () {
      expect(SchoolFeatures.fromJson({'examFeeCustomEnabled': true}).examFeeCustomEnabled, isTrue);
      expect(SchoolFeatures.fromJson({'exam_fee_custom_enabled': 1}).examFeeCustomEnabled, isTrue);
      expect(SchoolFeatures.fromJson({'examFeeCustomEnabled': false}).examFeeCustomEnabled, isFalse);
      expect(SchoolFeatures.fromJson({'feesEnabled': true}).examFeeCustomEnabled, isNull);
      expect(SchoolFeatures.fromJson({'examFeeCustomEnabled': null}).examFeeCustomEnabled, isNull);
      final restored = SchoolFeatures.fromJson(
        const SchoolFeatures(examFeeCustomEnabled: true).toJson(),
      );
      expect(restored.examFeeCustomEnabled, isTrue, reason: 'persisted with the session');
    });

    for (final (label, features, expected) in [
      ('true', {'feesEnabled': false, 'examsEnabled': true, 'examFeeCustomEnabled': true}, true),
      ('false', {'feesEnabled': true, 'examsEnabled': true, 'examFeeCustomEnabled': false}, false),
      ('missing (fails closed)', {'feesEnabled': true, 'examsEnabled': true}, false),
      ('null (fails closed)', {'feesEnabled': true, 'examFeeCustomEnabled': null}, false),
    ]) {
      test('AuthProvider.examFeeCustomEnabled via real login when $label', () async {
        FlutterSecureStorage.setMockInitialValues({});
        final auth = AuthProvider();
        await http.runWithClient(() async {
          expect(await auth.loginWithIdentifier('admin@school.test', 'secret'), isNull);
        }, () => MockClient((r) async {
          final user = {'id': 1, 'name': 'Admin', 'email': 'admin@school.test', 'role': 'SCHOOL_ADMIN'};
          if (r.url.path.endsWith('/auth/login')) return _json({'token': 't', 'user': user});
          return _json({
            'user': user,
            'profile': user,
            'feesEnabled': features['feesEnabled'],
            'schoolFeatures': features,
            'school': {'id': 1, 'name': 'Test School'},
          });
        }));
        expect(auth.examFeeCustomEnabled, expected);
        // Independent of payments.
        expect(auth.feesEnabled, features['feesEnabled'] == true);
      });
    }

    testWidgets('sidebar shows Exam Fees only when ON, independent of Payments', (t) async {
      t.view.physicalSize = const Size(1440, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      for (final (on, fees) in [(true, false), (false, true), (false, false), (true, true)]) {
        await t.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
          value: _Auth(on: on, fees: fees),
          child: MaterialApp(home: Scaffold(body: WebSidebar(selectedPage: 'exams', onNavigate: (_) {}))),
        ));
        await t.pumpAndSettle();
        expect(find.text('Exam Fees'), on ? findsOneWidget : findsNothing, reason: 'on=$on fees=$fees');
        expect(find.text('Finance'), fees ? findsOneWidget : findsNothing);
      }
    });

    testWidgets('direct route is blocked when OFF and makes no exam-fee request', (t) async {
      final f = ExamFeeFixture();
      await _with(f, () async {
        await _pump(t, auth: _Auth(on: false), selectAll: false);
        expect(find.byKey(const ValueKey('exam-fees-not-enabled')), findsOneWidget);
        expect(find.text('Register'), findsNothing);
      });
      expect(f.requests, isEmpty);
    });

    testWidgets('disabled while open: 403 locks the module and hides navigation', (t) async {
      final f = ExamFeeFixture();
      final auth = _Auth();
      await _with(f, () async {
        final c = await _pump(t, auth: auth);
        expect(find.text('Ahmed Ali'), findsOneWidget);
        f.disabled = true;
        c.setTab(ExamFeesTab.setup);
        await t.pumpAndSettle();
        expect(c.featureDisabled, isTrue);
        expect(auth.on, isFalse);
        expect(find.byKey(const ValueKey('exam-fees-not-enabled')), findsOneWidget);
        expect(find.text('Exam Fees are not enabled'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    });
  });

  group('models', () {
    test('money keeps decimals; string DECIMALs parse; cents compare', () {
      expect(examFeeMoney('6.50'), 6.5);
      expect(examFeeMoney(6.5), 6.5);
      expect(toCents(6.5), 650);
      expect(parseMoneyInput('6.5'), 6.5);
      expect(parseMoneyInput('1,250.00'), 1250);
      expect(parseMoneyInput('6.555'), isNull);
      expect(parseMoneyInput('abc'), isNull);
      expect(moneyInputText(6.5), '6.50');
    });

    test('register: statuses, WAIVED is not PAID, not-generated separate, action rules', () {
      final r = ExamFeeRegister.tryParse(jsonDecode(jsonEncode({
        'academic_year': {'id': 2},
        'exam': {'id': 70},
        'class': {'id': 25},
        'students': [for (final f in ExamFeeFixture().fees) f.json()],
        'not_generated': [{'student_id': 1005, 'student_name': 'Hodan'}],
        'summary': {},
      })))!;
      final byStatus = {for (final s in r.students) s.status: s};
      expect(byStatus.keys, containsAll(['UNPAID', 'PARTIAL', 'PAID', 'WAIVED']));
      final waived = byStatus['WAIVED']!;
      expect(waived.isWaived, isTrue);
      expect(waived.isPaid, isFalse);
      expect([waived.canCollect, waived.selectable, waived.canWaive], [false, false, false]);
      expect(waived.canUnwaive, isTrue);
      final paid = byStatus['PAID']!;
      expect([paid.canCollect, paid.selectable, paid.canWaive], [false, false, false]);
      final partial = byStatus['PARTIAL']!;
      expect(partial.amount, 6.5);
      expect(partial.remainingAmount, 3.25);
      expect([partial.canCollect, partial.canWaive], [true, false]);
      expect(byStatus['UNPAID']!.canWaive, isTrue);
      expect(r.notGenerated.single.displayName, 'Hodan');
      expect(r.students.any((s) => s.studentId == 1005), isFalse);
    });

    test('friendly backend error mapping', () {
      for (final (code, text) in [
        ('EXAM_FEE_CUSTOM_NOT_ENABLED', 'Exam Fees are not enabled for this school.'),
        ('EXAM_FEE_SETTING_IN_USE', 'This fee has already been generated for students and cannot be deleted.'),
        ('EXAM_FEE_PAYMENT_EXCEEDS_BALANCE', 'The payment is greater than the remaining balance.'),
        ('EXAM_FEE_ALREADY_PAID', 'This exam fee has already been fully paid.'),
        ('EXAM_FEE_WAIVED', "This student's exam fee has been waived."),
        ('EXAM_FEE_AMOUNT_BELOW_PAID', 'The new fee cannot be less than the amount already paid.'),
      ]) {
        expect(examFeeErrorMessage(code: code, fallback: 'x'), text);
      }
      expect(examFeeErrorMessage(code: 'EXAM_ACADEMIC_YEAR_MISMATCH', fallback: 'x'), contains('academic year'));
      expect(examFeeErrorMessage(statusCode: 500, backendMessage: 'ER_BAD_FIELD sql', fallback: 'x'),
          isNot(contains('sql')));
    });
  });

  group('controller', () {
    test('selector cascade: year resets exam/class/register; exams are per year', () async {
      final f = ExamFeeFixture();
      final c = ExamFeesController();
      await _with(f, () async {
        c.setYears([_y2, _y1], _y2);
        await c.loadExams();
        await c.loadClasses();
        expect(c.exams.map((e) => e.name), ['Midterm']);
        c.selectExam(70);
        c.selectClass(25);
        await c.loadRegister();
        expect(c.register, isNotNull);
        c.toggleSelection(501);
        c.selectYear(1);
        expect([c.examId, c.classId, c.register], [null, null, null]);
        expect(c.selection, isEmpty);
        await c.loadExams();
        expect(c.exams.map((e) => e.name), ['Final 2025']);
      });
      expect(f.where('GET', '/register').last.url.queryParameters,
          {'academic_year_id': '2', 'exam_id': '70', 'class_id': '25'});
      c.dispose();
    });

    test('bulk: payload, PAID/WAIVED never selectable, atomic failure mutates nothing', () async {
      final f = ExamFeeFixture()
        ..bulkError = {
          'message': 'One or more collection entries are invalid. No payments were recorded.',
          'code': 'EXAM_FEE_COLLECTION_VALIDATION_FAILED',
          'errors': [
            {'index': 1, 'student_id': 1002, 'code': 'EXAM_FEE_PAYMENT_EXCEEDS_BALANCE', 'message': 'Payment amount exceeds the remaining exam fee balance.'},
          ],
        };
      final c = ExamFeesController();
      await _with(f, () async {
        c.setYears([_y2], _y2);
        c.selectExam(70);
        c.selectClass(25);
        await c.loadRegister();
        for (final id in [501, 502, 503, 504]) {
          c.toggleSelection(id);
        }
        expect(c.selection, {501, 502});
        final before = c.register!.students.map((s) => '${s.id}:${s.paidAmount}:${s.status}').toList();
        final loadsBefore = f.where('GET', '/register').length;
        final r = await c.collectBulk(
          entries: const [BulkCollectEntry(1001, 10), BulkCollectEntry(1002, 3.25)],
          method: 'MOBILE',
          referenceNumber: 'REF-9',
        );
        expect(r, isA<ExamFeeFailure>());
        final failure = r as ExamFeeFailure;
        expect(failure.entryErrors.single.studentId, 1002);
        expect(failure.message, contains('No payments were recorded'));
        expect(c.register!.students.map((s) => '${s.id}:${s.paidAmount}:${s.status}').toList(), before);
        expect(c.selection, {501, 502}, reason: 'selection kept for correction');
        expect(f.where('GET', '/register'), hasLength(loadsBefore), reason: 'no reload, no local edit');

        f.bulkError = null;
        final ok = await c.collectBulk(
          entries: const [BulkCollectEntry(1001, 10), BulkCollectEntry(1002, 3.25)],
          method: 'MOBILE',
        );
        expect(ok, isA<ExamFeeSuccess<BulkCollectionResult>>());
        expect(c.selection, isEmpty);
        expect(c.feeById(501)!.status, 'PAID', reason: 'reloaded from backend');
        expect(c.feeById(502)!.status, 'PAID');
      });
      final body = jsonDecode(f.where('POST', '/collections').first.body);
      expect(body, {
        'academic_year_id': 2,
        'exam_id': 70,
        'class_id': 25,
        'method': 'MOBILE',
        'reference_number': 'REF-9',
        'entries': [
          {'student_id': 1001, 'amount': 10.0},
          {'student_id': 1002, 'amount': 3.25},
        ],
      });
      c.dispose();
    });

    test('generate and receipt ignore repeated taps', () async {
      final f = ExamFeeFixture()
        ..settings[26] = {'id': 901, 'amount': 7.5}
        ..generateGate = Completer<void>()
        ..receiptGate = Completer<void>();
      f.payments.add({'id': 42, 'receipt_number': 'EXAM-1', 'amount': 1, 'student_exam_fee_id': 501});
      final c = ExamFeesController();
      await _with(f, () async {
        c.setYears([_y2], _y2);
        c.selectExam(70);
        final first = c.generate(26);
        expect(await c.generate(26), isNull);
        f.generateGate!.complete();
        final res = (await first) as ExamFeeSuccess<GenerationResult>;
        expect([res.data.created, res.data.alreadyGenerated, res.data.eligible], [3, 1, 4]);

        final r1 = c.downloadReceipt(42);
        expect(await c.downloadReceipt(42), isNull);
        f.receiptGate!.complete();
        final pdf = (await r1) as ExamFeeSuccess<PdfFileResult>;
        expect(pdf.data.filename, 'exam-fee-receipt-EXAM-1.pdf');
      });
      expect(f.where('POST', '/generate'), hasLength(1));
      expect(f.where('GET', '/receipt'), hasLength(1));
      c.dispose();
    });

    test('payment history filters and pagination go to the backend', () async {
      final f = ExamFeeFixture();
      for (var i = 0; i < 25; i++) {
        f._pay(f.fees.first, 10, i.isEven ? 'CASH' : 'BANK');
      }
      final c = ExamFeesController();
      await _with(f, () async {
        c.setYears([_y2], _y2);
        c.selectExam(70);
        await c.loadPayments();
        expect(c.paymentsPage!.total, 25);
        expect(c.paymentsPage!.payments, hasLength(20));
        await c.loadPayments(toPage: 2);
        expect(c.paymentsPage!.payments, hasLength(5));
        c.setPaymentFilters(method: 'BANK', start: DateTime(2026, 10, 1), searchText: 'EMIS-1001');
        await Future<void>.delayed(Duration.zero);
      });
      final last = f.where('GET', '/payments').last.url.queryParameters;
      expect(last, {
        'academic_year_id': '2',
        'exam_id': '70',
        'method': 'BANK',
        'start_date': '2026-10-01',
        'search': 'EMIS-1001',
        'page': '1',
        'limit': '20',
      });
      c.dispose();
    });
  });

  group('widgets', () {
    testWidgets('register: backend summary, statuses, not-generated, valid actions', (t) async {
      final f = ExamFeeFixture();
      await _with(f, () async {
        await _pump(t);
        expect(_stat('Students', '4'), findsOneWidget);
        expect(_stat('Total Charged', '26.50'), findsOneWidget, reason: '10 + 6.50 + 10 + 0 (waived)');
        expect(_stat('Collected', '13.25'), findsOneWidget);
        expect(_stat('Outstanding', '13.25'), findsOneWidget);
        for (final s in ['UNPAID', 'PARTIAL', 'PAID', 'WAIVED']) {
          expect(find.text(s), findsWidgets);
        }
        expect(find.text('6.50'), findsWidgets, reason: 'decimals preserved, never 7');
        expect(find.byKey(const ValueKey('not-generated-1005')), findsOneWidget);
        expect(find.text('NOT GENERATED'), findsOneWidget);
        expect(find.textContaining('Ilhan Yusuf — Form 4'), findsOneWidget);
        // Collect only where payable.
        expect(find.byKey(const ValueKey('collect-501')), findsOneWidget);
        expect(find.byKey(const ValueKey('collect-502')), findsOneWidget);
        expect(find.byKey(const ValueKey('collect-503')), findsNothing, reason: 'PAID');
        expect(find.byKey(const ValueKey('collect-504')), findsNothing, reason: 'WAIVED');
        expect(find.byKey(const ValueKey('select-503')), findsNothing);
        expect(find.byKey(const ValueKey('select-504')), findsNothing);
        await _tap(t, find.byKey(const ValueKey('actions-503')));
        expect(find.text('Waive'), findsNothing, reason: 'PAID cannot be waived');
        await t.tapAt(const Offset(5, 5));
        await t.pumpAndSettle();
        await _tap(t, find.byKey(const ValueKey('actions-504')));
        expect(find.text('Unwaive'), findsOneWidget);
        expect(find.text('Customize fee'), findsNothing);
      });
    });

    testWidgets('collect: overpay blocked locally; partial payment, receipt, refresh', (t) async {
      final f = ExamFeeFixture();
      await _with(f, () async {
        await _pump(t);
        await _tap(t, find.byKey(const ValueKey('collect-502')));
        expect(find.text('Collect Exam Fee'), findsOneWidget);
        final amount = find.byKey(const ValueKey('collect-amount'));
        expect(t.widget<TextField>(amount).controller!.text, '3.25', reason: 'defaults to remaining');
        await t.enterText(amount, '5');
        await _tap(t, find.byKey(const ValueKey('collect-submit')));
        expect(find.textContaining('greater than the remaining balance'), findsOneWidget);
        expect(f.where('POST', '/payments'), isEmpty);

        await t.enterText(amount, '1.25');
        await _tap(t, find.byKey(const ValueKey('collect-submit')));
        expect(find.text('Payment recorded successfully'), findsOneWidget);
        expect(find.text('EXAM-20261002-000001'), findsOneWidget);
        expect(find.byKey(const ValueKey('receipt-1')), findsOneWidget);
        await _tap(t, find.byKey(const ValueKey('collect-done')));
        expect(find.text('2.00'), findsWidgets, reason: 'register reloaded: 6.50 - 4.50 remaining');
      });
      expect(jsonDecode(f.where('POST', '/payments').single.body),
          {'student_exam_fee_id': 502, 'amount': 1.25, 'method': 'CASH'});
    });

    testWidgets('customize: below-paid blocked, reason required, then saved', (t) async {
      final f = ExamFeeFixture();
      await _with(f, () async {
        await _pump(t);
        await _tap(t, find.byKey(const ValueKey('actions-502')));
        await _tap(t, find.text('Customize fee'));
        await t.enterText(find.byKey(const ValueKey('customize-amount')), '3');
        await _tap(t, find.byKey(const ValueKey('customize-save')));
        expect(find.textContaining('cannot be less than'), findsOneWidget);
        expect(find.text('A reason is required.'), findsOneWidget);
        await t.enterText(find.byKey(const ValueKey('customize-amount')), '8.75');
        await t.enterText(find.byKey(const ValueKey('customize-reason')), 'Scholarship');
        await _tap(t, find.byKey(const ValueKey('customize-save')));
        expect(find.text('Exam fee updated.'), findsOneWidget);
        expect(find.text('8.75'), findsWidgets);
      });
      expect(jsonDecode(f.where('PATCH', '/amount').single.body), {'amount': 8.75, 'reason': 'Scholarship'});
    });

    testWidgets('waive then unwaive', (t) async {
      final f = ExamFeeFixture();
      await _with(f, () async {
        await _pump(t);
        await _tap(t, find.byKey(const ValueKey('actions-501')));
        await _tap(t, find.text('Waive'));
        expect(find.byKey(const ValueKey('waive-explanation')), findsOneWidget);
        expect(find.textContaining('not a payment'), findsOneWidget);
        await t.enterText(find.byKey(const ValueKey('waive-reason')), 'Hardship');
        await _tap(t, find.byKey(const ValueKey('waive-confirm')));
        expect(find.text('Exam fee waived.'), findsOneWidget);
        expect(find.byKey(const ValueKey('collect-501')), findsNothing, reason: 'waived cannot collect');

        await _tap(t, find.byKey(const ValueKey('actions-501')));
        await _tap(t, find.text('Unwaive'));
        expect(find.textContaining('original generated amount'), findsOneWidget);
        await _tap(t, find.byKey(const ValueKey('unwaive-confirm')));
        expect(find.text('Exam fee restored.'), findsOneWidget);
        expect(find.byKey(const ValueKey('collect-501')), findsOneWidget);
      });
      expect(jsonDecode(f.where('POST', '/waive').single.body), {'reason': 'Hardship'});
    });

    testWidgets('bulk collect: selection count, atomic error shown per student', (t) async {
      final f = ExamFeeFixture()
        ..bulkError = {
          'message': 'No payments were recorded.',
          'code': 'EXAM_FEE_COLLECTION_VALIDATION_FAILED',
          'errors': [
            {'index': 1, 'student_id': 1002, 'code': 'EXAM_FEE_ALREADY_PAID', 'message': 'paid'},
          ],
        };
      await _with(f, () async {
        await _pump(t);
        await _tap(t, find.byKey(const ValueKey('select-501')));
        await _tap(t, find.byKey(const ValueKey('select-502')));
        expect(find.text('Collect Selected (2)'), findsOneWidget);
        await _tap(t, find.byKey(const ValueKey('collect-selected')));
        expect(find.byKey(const ValueKey('bulk-row-1001')), findsOneWidget);
        expect(find.byKey(const ValueKey('bulk-total')), findsOneWidget);
        expect(find.text('Total: 13.25'), findsOneWidget);
        await _tap(t, find.byKey(const ValueKey('bulk-submit')));
        expect(find.byKey(const ValueKey('bulk-error-1002')), findsOneWidget);
        expect(find.text('This exam fee has already been fully paid.'), findsOneWidget);
        f.bulkError = null;
        await _tap(t, find.byKey(const ValueKey('bulk-submit')));
        expect(find.text('2 payments recorded successfully'), findsOneWidget);
        await _tap(t, find.byKey(const ValueKey('bulk-done')));
        expect(find.text('Collect Selected (2)'), findsNothing);
        expect(find.byKey(const ValueKey('collect-501')), findsNothing, reason: 'now PAID after reload');
      });
    });

    testWidgets('setup (desktop): set fee, 409 delete, preview -> generate', (t) async {
      final f = ExamFeeFixture();
      await _with(f, () async {
        final c = await _pump(t, size: const Size(1280, 900), desktop: true);
        c.setTab(ExamFeesTab.setup);
        await t.pumpAndSettle();
        expect(find.text('Configured Fee'), findsOneWidget);
        expect(find.text('Not configured'), findsOneWidget);

        await _tap(t, find.byKey(const ValueKey('set-fee-26')));
        expect(find.byKey(const ValueKey('setting-change-note')), findsOneWidget);
        await t.enterText(find.byKey(const ValueKey('setting-amount')), '0');
        await _tap(t, find.byKey(const ValueKey('setting-save')));
        expect(find.text('Enter an amount greater than 0.'), findsOneWidget);
        await t.enterText(find.byKey(const ValueKey('setting-amount')), '7.5');
        await _tap(t, find.byKey(const ValueKey('setting-save')));
        expect(find.text('Exam fee saved.'), findsOneWidget);
        expect(find.text('7.50'), findsOneWidget);

        // Class 25 has generated fees: no delete offered; force the API path.
        expect(find.byKey(const ValueKey('delete-setting-25')), findsNothing);
        final r = await c.deleteSetting(c.settings!.classes.first);
        expect((r as ExamFeeFailure).message,
            'This fee has already been generated for students and cannot be deleted.');

        await _tap(t, find.byKey(const ValueKey('generate-26')));
        expect(find.byKey(const ValueKey('preview-note')), findsOneWidget);
        expect(find.text('Will Be Generated'), findsOneWidget);
        await _tap(t, find.byKey(const ValueKey('generation-generate')));
        expect(find.byKey(const ValueKey('generation-result')), findsOneWidget);
        expect(find.descendant(of: find.byKey(const ValueKey('generation-result')), matching: find.text('3')),
            findsOneWidget);
        await _tap(t, find.byKey(const ValueKey('generation-done')));
        expect(t.takeException(), isNull);
      });
      expect(jsonDecode(f.where('PUT', '/settings').single.body),
          {'academic_year_id': 2, 'exam_id': 70, 'class_id': 26, 'amount': 7.5});
      expect(f.where('POST', '/generate/preview'), hasLength(1));
      expect(f.where('POST', '/generate'), hasLength(1));
    });

    testWidgets('payments: empty state, list, detail, receipt', (t) async {
      final f = ExamFeeFixture();
      await _with(f, () async {
        final c = await _pump(t);
        c.setTab(ExamFeesTab.payments);
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('payments-empty')), findsOneWidget);
        f._pay(f.fees.first, 650, 'CASH');
        await c.loadPayments();
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('payment-row-1')), findsOneWidget);
        expect(find.text('6.50'), findsWidgets);
        await _tap(t, find.byKey(const ValueKey('payment-row-1')));
        expect(find.byKey(const ValueKey('payment-detail')), findsOneWidget);
        expect(find.text('Recorded By'), findsOneWidget);
        expect(find.byKey(const ValueKey('receipt-1')), findsOneWidget);
      });
    });

    for (final (size, desktop) in [
      (const Size(360, 640), false),
      (const Size(360, 800), false),
      (const Size(390, 844), false),
      (const Size(412, 915), false),
      (const Size(1024, 768), true),
      (const Size(1366, 768), true),
      (const Size(1920, 1080), true),
    ]) {
      testWidgets('no overflow at $size (desktop=$desktop) across all tabs', (t) async {
        final f = ExamFeeFixture();
        f._pay(f.fees.first, 650, 'CASH');
        await _with(f, () async {
          final c = await _pump(t, size: size, desktop: desktop);
          expect(t.takeException(), isNull);
          for (final tab in ExamFeesTab.values) {
            c.setTab(tab);
            await t.pumpAndSettle();
            expect(t.takeException(), isNull, reason: '$tab');
          }
          // One vertical page scroll; wide tables may add a horizontal one.
          final vertical = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          );
          expect(vertical, findsOneWidget);
        });
      });
    }
  });
}
