import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/services/students_service.dart';

void main() {
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

    test('null or missing emisNumber yields empty string (safe for old DB rows)', () {
      final json = {
        'id': 3,
        'studentName': 'Old Record',
      };
      final model = StudentModel.fromJson(json);
      expect(model.emisNumber, '');
    });

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
    test('includes emisNumber in camelCase for API', () {
      final payload = createStudentPayload(
        emisNumber: 'EMIS-001',
        studentName: 'Name',
        motherName: 'Mother',
        refugeeStatus: 'Not Refugee',
        orphanStatus: 'Not Orphan',
        birthDate: '2000-01-01',
        sex: 'Male',
        telephone: '',
        birthPlace: '',
        nationality: '',
        studentState: '',
        studentDistrict: '',
        studentVillage: '',
        disabilityStatus: 'No Disability',
        guardianName: '',
        schoolName: 'School',
        className: 'Class 1',
        age: 10,
        absenteeismStatus: 'Active',
        password: 'password123',
      );
      expect(payload['emisNumber'], 'EMIS-001');
      expect(payload.containsKey('emis_number'), false);
    });
  });

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
}
