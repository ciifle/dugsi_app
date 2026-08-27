import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/models/auth_me_models.dart';
import 'package:kobac/services/pdf_file_result.dart';
import 'package:kobac/utils/school_logo_url.dart';

void main() {
  test('school branding parses nullable auth/me fields', () {
    final school = SchoolBranding.fromJson({
      'id': 3,
      'name': 'Abdiaziiz School',
      'address': 'District',
      'location': 'Warta Nabada',
      'logo_path': '/uploads/schools/3/logo.png',
      'logo_url': 'http://api.dugsi.so/uploads/schools/3/logo.png',
    });

    expect(school.id, 3);
    expect(school.name, 'Abdiaziiz School');
    expect(school.logoPath, '/uploads/schools/3/logo.png');
    expect(school.logoUrl, contains('api.dugsi.so'));
    expect(SchoolBranding.fromJson({'id': '4'}).logoUrl, isNull);
  });

  test('school feature flags remain separate from school branding', () {
    final features = SchoolFeatures.fromJson({
      'feesEnabled': false,
      'examsEnabled': true,
    });
    expect(features.feesEnabled, isFalse);
    expect(features.examsEnabled, isTrue);
  });

  test('only the trusted Dugsi API HTTP logo is upgraded', () {
    expect(
      normalizeSchoolLogoUrl('http://api.dugsi.so/uploads/logo.png'),
      'https://api.dugsi.so/uploads/logo.png',
    );
    expect(
      normalizeSchoolLogoUrl('http://example.com/logo.png'),
      'http://example.com/logo.png',
    );
    expect(
      normalizeSchoolLogoUrl('https://api.dugsi.so/uploads/logo.png'),
      'https://api.dugsi.so/uploads/logo.png',
    );
    expect(normalizeSchoolLogoUrl('  '), isNull);
  });

  test('PDF filename is preserved and sanitized from Content-Disposition', () {
    expect(
      pdfFilenameFromContentDisposition(
        'attachment; filename="School Exam Passes.pdf"',
      ),
      'School Exam Passes.pdf',
    );
    expect(
      pdfFilenameFromContentDisposition(
        "attachment; filename*=UTF-8''Hall%20Report.pdf",
      ),
      'Hall Report.pdf',
    );
  });
}
