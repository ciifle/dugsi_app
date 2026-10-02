import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/finance/models/fee_generation.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

void main() {
  group('generationStatusColor', () {
    test('CONFIGURED is green (ready)', () {
      expect(generationStatusColor('CONFIGURED'), kAdminGreen);
    });

    test('NOT_CONFIGURED is amber (warning), never red', () {
      final color = generationStatusColor('NOT_CONFIGURED');
      expect(color, isNot(Colors.red));
      expect(color, const Color(0xFFF59E0B));
    });

    test('TERM_UNSUPPORTED is amber (warning), never red', () {
      expect(generationStatusColor('TERM_UNSUPPORTED'), const Color(0xFFF59E0B));
    });

    test('CYCLE_MISMATCH is amber (warning), never red', () {
      expect(generationStatusColor('CYCLE_MISMATCH'), const Color(0xFFF59E0B));
    });
  });

  group('generationStatusLabel', () {
    test('maps every known backend status to a human label', () {
      expect(generationStatusLabel('CONFIGURED'), 'Ready');
      expect(generationStatusLabel('NOT_CONFIGURED'), 'Not configured');
      expect(generationStatusLabel('TERM_UNSUPPORTED'), 'Term unsupported');
      expect(generationStatusLabel('CYCLE_MISMATCH'), 'Different cycle');
    });
  });

  group('FeeGenerationResult.fromJson', () {
    test('parses summary, classes, and warnings, including generate-only fields', () {
      final json = {
        'academic_year': {'id': 2, 'name': '2025/2026'},
        'period': {'billing_cycle': 'MONTHLY', 'billing_year': 2026, 'billing_month': 9},
        'summary': {
          'eligible_classes': 5,
          'configured_classes': 3,
          'unconfigured_classes': 2,
          'total_students': 40,
          'will_generate': 38,
          'already_generated': 2,
          'created': 38,
          'skipped_existing': 2,
          'discounted_students': 4,
          'free_students': 1,
          'gross_amount': 4000.0,
          'discount_amount': 100.0,
          'net_amount': 3900.0,
        },
        'classes': [
          {
            'class_id': 1,
            'class_name': '1A',
            'status': 'CONFIGURED',
            'configured_billing_cycle': 'MONTHLY',
            'amount': 100.0,
            'enrolled_students': 20,
            'will_generate': 20,
            'already_generated': 0,
            'discounted_students': 2,
            'free_students': 1,
            'gross_amount': 2000.0,
            'discount_amount': 40.0,
            'net_amount': 1960.0,
          },
        ],
        'warnings': [
          {'code': 'TERM_GENERATION_NOT_SUPPORTED', 'class_id': 2, 'class_name': '2A'},
        ],
      };
      final result = FeeGenerationResult.fromJson(json);
      expect(result.academicYearId, 2);
      expect(result.period.billingCycle, 'MONTHLY');
      expect(result.summary.created, 38);
      expect(result.summary.skippedExisting, 2);
      expect(result.classes.single.status, 'CONFIGURED');
      expect(result.warnings.single.code, 'TERM_GENERATION_NOT_SUPPORTED');
    });

    test('preview response has null created/skippedExisting', () {
      final json = {
        'academic_year': {'id': 2, 'name': '2025/2026'},
        'period': {'billing_cycle': 'YEARLY', 'billing_year': 2025, 'billing_month': 0},
        'summary': {
          'eligible_classes': 1,
          'configured_classes': 1,
          'unconfigured_classes': 0,
          'total_students': 5,
          'will_generate': 5,
          'already_generated': 0,
          'discounted_students': 0,
          'free_students': 0,
          'gross_amount': 500.0,
          'discount_amount': 0.0,
          'net_amount': 500.0,
        },
        'classes': [],
        'warnings': [],
      };
      final result = FeeGenerationResult.fromJson(json);
      expect(result.summary.created, isNull);
      expect(result.summary.skippedExisting, isNull);
    });
  });
}
