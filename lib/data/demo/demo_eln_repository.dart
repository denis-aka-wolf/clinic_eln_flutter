import '../../domain/models/eln_record.dart';
import '../../domain/repositories/eln_repository.dart';

/// Деморепозиторий хранит данные только в памяти процесса.
/// Не использовать с реальными данными пациентов: постоянное защищённое
/// хранилище будет подключено отдельным этапом.
class DemoElnRepository extends ElnRepository {
  final List<ElnRecord> _records = <ElnRecord>[];
  final List<AuditEntry> _auditEntries = <AuditEntry>[];

  @override
  List<ElnRecord> get records => List.unmodifiable(_records);

  @override
  List<AuditEntry> get auditEntries => List.unmodifiable(_auditEntries);

  @override
  Future<void> saveDraft(ElnRecord record) async {
    final now = DateTime.now();
    final updated = record.copyWith(
      localStatus: LocalElnStatus.draft,
      updatedAt: now,
    );
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      _records.insert(0, updated);
    } else {
      _records[index] = updated;
    }
    _auditEntries.insert(
      0,
      AuditEntry(
        at: now,
        action: 'Сохранение черновика',
        result: 'Выполнено локально',
        details: 'Данные сохранены в памяти приложения. В СФР ничего не отправлялось.',
      ),
    );
    notifyListeners();
  }

  @override
  Future<void> deleteDraft(String id) async {
    _records.removeWhere((item) => item.id == id && item.localStatus == LocalElnStatus.draft);
    _auditEntries.insert(
      0,
      AuditEntry(
        at: DateTime.now(),
        action: 'Удаление черновика',
        result: 'Выполнено локально',
        details: 'Запись удалена из оперативной памяти приложения.',
      ),
    );
    notifyListeners();
  }
}
