import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/students_service.dart';

void main() {
  test('normalizes telephone formats and rejects invalid numbers', () {
    for (final input in [
      '0612345678',
      '612345678',
      '+252612345678',
      '252612345678',
      '+252 (61) 234-5678',
    ]) {
      expect(normalizeStudentTelephone(input), '0612345678');
    }
    for (final input in [
      '',
      '123',
      '06123456789',
      '+254612345678',
      '061abc5678',
      '0000000000',
    ]) {
      expect(normalizeStudentTelephone(input), isNull);
    }
  });
  group('StudentModel.fromJson', () {
    test('parses emisNumber from camelCase (API contract)', () {
      final json = {
        'id': 1,
        'emisNumber': 'EMIS-123',
        'studentName': 'Test Student',
      };
      final model = StudentModel.fromJson(json);
      expect(model.emisNumber, 'EMIS-123');
    });

    test('parses emis_number for legacy/backward compatibility', () {
      final json = {
        'id': 2,
        'emis_number': 'LEGACY-456',
        'student_name': 'Legacy Student',
      };
      final model = StudentModel.fromJson(json);
      expect(model.emisNumber, 'LEGACY-456');
    });

    test(
      'null or missing emisNumber yields empty string (safe for old DB rows)',
      () {
        final json = {'id': 3, 'studentName': 'Old Record'};
        final model = StudentModel.fromJson(json);
        expect(model.emisNumber, '');
      },
    );

    test('camelCase takes precedence over snake_case when both present', () {
      final json = {
        'id': 4,
        'emisNumber': 'Camel',
        'emis_number': 'Snake',
        'studentName': 'Both',
      };
      final model = StudentModel.fromJson(json);
      expect(model.emisNumber, 'Camel');
    });
  });

  group('createStudentPayload', () {
    test('serializes all creation fields into the POST request', () async {
      final payload = createStudentPayload(
        emisNumber: 'EMIS-001',
        studentName: 'Name',
        motherName: 'Mother',
        refugeeStatus: 'Not Refugee',
        orphanStatus: 'Not Orphan',
        birthDate: '2000-01-01',
        sex: 'Male',
        telephone: '+252 (61) 234-5678',
        birthPlace: '',
        nationality: '',
        studentState: '',
        studentDistrict: '',
        studentVillage: '',
        disabilityStatus: 'No Disability',
        guardianName: '',
        schoolName: 'School',
        classId: 4,
        age: 10,
        absenteeismStatus: 'Active',
        password: 'password123',
      );
      await http.runWithClient(
        () async {
          final result = await StudentsService().createStudent(payload);
          expect(result, isA<StudentSuccess<StudentModel>>());
        },
        () => MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/school-admin/students');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, payload);
          expect(body.keys.toSet(), {
            'emisNumber',
            'studentName',
            'motherName',
            'refugeeStatus',
            'orphanStatus',
            'birthDate',
            'sex',
            'class_id',
            'telephone',
            'birthPlace',
            'nationality',
            'studentState',
            'studentDistrict',
            'studentVillage',
            'disabilityStatus',
            'guardianName',
            'schoolName',
            'age',
            'absenteeismStatus',
            'password',
          });
          return http.Response(
            '{"student":{"id":1,"studentName":"Name"}}',
            201,
          );
        }),
      );
      expect(payload['telephone'], '0612345678');
      expect(payload['class_id'], 4);
      expect(payload.length, 20);
      expect(payload.containsKey('className'), false);
      expect(payload['emisNumber'], 'EMIS-001');
      expect(payload.containsKey('emis_number'), false);
    });
  });

  test(
    'creation preserves validation errors and explains class and EMIS errors',
    () async {
      for (final status in [400, 404, 409]) {
        await http.runWithClient(
          () async {
            final result =
                await StudentsService().createStudent({}) as StudentError;
            expect(result.statusCode, status);
            expect(
              result.message,
              status == 400
                  ? 'class_id is required'
                  : status == 404
                  ? 'The selected class was not found. Please select a valid class.'
                  : 'A student with this EMIS/registration number already exists.',
            );
          },
          () => MockClient(
            (_) async =>
                http.Response('{"message":"class_id is required"}', status),
          ),
        );
      }
    },
  );

  group('updateStudentPayload', () {
    test('sends emisNumber in camelCase when provided', () {
      final payload = updateStudentPayload(emisNumber: 'EMIS-002');
      expect(payload['emisNumber'], 'EMIS-002');
      expect(payload.containsKey('emis_number'), false);
    });

    test('omits emisNumber when null', () {
      final payload = updateStudentPayload(studentName: 'Updated');
      expect(payload.containsKey('emisNumber'), false);
      expect(payload['studentName'], 'Updated');
    });
  });

  test('selected enrollment overrides legacy class membership', () {
    final student = StudentModel.fromJson({
      'id': 9,
      'studentName': 'Amina',
      'emisNumber': 'E-9',
      'class_id': 1,
      'className': 'Old class',
      'selected_enrollment': {
        'id': 44,
        'status': 'Enrolled',
        'class_id': 8,
        'class': {'id': 8, 'name': 'Grade 8'},
        'academic_year': {'id': 3, 'name': '2025/26'},
      },
    });
    expect(student.classId, 8);
    expect(student.classDisplayName, 'Grade 8');
    expect(student.enrollmentId, 44);
    expect(student.enrollmentStatus, 'Enrolled');
    expect(student.academicYearId, 3);
    expect(student.academicYearName, '2025/26');
  });
}
