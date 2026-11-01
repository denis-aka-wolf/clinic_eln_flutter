import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_eln/core/date_format.dart';
import 'package:clinic_eln/domain/models/eln_record.dart';
import 'package:clinic_eln/domain/validation/eln_validator.dart';

void main() {
  group('parseRuDate', () {
    test('parses a real calendar date', () {
      expect(parseRuDate('14.10.2026'), DateTime(2026, 10, 14));
    });

    test('rejects impossible calendar dates', () {
      expect(parseRuDate('31.02.2026'), isNull);
    });

    test('rejects a different input format', () {
      expect(parseRuDate('2026-10-14'), isNull);
    });
  });

  group('ElnValidator', () {
    test('reports core required fields for an incomplete draft', () {
      final issues = ElnValidator.validateForOpening(
        ElnRecord(id: 'test-draft'),
        requireAllocatedNumber: false,
      );
      final fields = issues.map((issue) => issue.field).toSet();
      expect(fields, contains('snils'));
      expect(fields, contains('surname'));
      expect(fields, contains('clinicName'));
      expect(fields, contains('icd10Code'));
      expect(fields, contains('treatmentPeriods'));
    });

    test('known SFR state code is resolved', () {
      expect(SfrElnState.fromCode('010')?.title, 'Открыт');
      expect(SfrElnState.fromCode('999'), isNull);
    });

    test('closing requires a work date or an other-result code', () {
      final issues = ElnValidator.validateForClosing(ElnRecord(id: 'test-close'));
      expect(issues.any((issue) => issue.field == 'workStartDate'), isTrue);
    });
  });
}
