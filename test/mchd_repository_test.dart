import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_eln/data/demo/demo_mchd_repository.dart';
import 'package:clinic_eln/domain/models/mchd_record.dart';

MchdRecord testRecord({MchdStatus status = MchdStatus.draft, String id = 'mchd-test'}) {
  final now = DateTime(2026, 10, 14);
  return MchdRecord(
    id: id,
    principalName: 'Медицинская организация',
    principalInn: '1234567890',
    principalOgrn: '1234567890123',
    representativeName: 'Иванов Иван Иванович',
    issuedAt: now,
    validFrom: now,
    validTo: DateTime(2027, 10, 14),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('DemoMchdRepository', () {
    test('сохраняет черновик в локальный реестр', () async {
      final repository = DemoMchdRepository();
      await repository.save(testRecord());

      expect(repository.records, hasLength(1));
      expect(repository.records.single.status, MchdStatus.draft);
      expect(repository.auditEntries, hasLength(1));
      expect(repository.auditEntries.single.details, contains('В СФР ничего не отправлялось'));
      repository.dispose();
    });

    test('существующая доверенность добавляется со статусом проверки', () async {
      final repository = DemoMchdRepository();
      await repository.addExistingForReview(testRecord(status: MchdStatus.registered));

      expect(repository.records.single.status, MchdStatus.needsReview);
      expect(repository.records.single.sourceNote, contains('не проверены'));
      repository.dispose();
    });

    test('удаляет черновик, но не удаляет другие статусы', () async {
      final repository = DemoMchdRepository();
      await repository.save(testRecord());
      await repository.save(testRecord(id: 'mchd-reviewed', status: MchdStatus.needsReview));

      await repository.deleteDraft('mchd-test');
      await repository.deleteDraft('mchd-reviewed');

      expect(repository.records, hasLength(1));
      expect(repository.records.single.id, 'mchd-reviewed');
      repository.dispose();
    });
  });
}
