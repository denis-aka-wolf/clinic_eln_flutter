import '../../domain/models/mchd_record.dart';
import '../../domain/repositories/mchd_repository.dart';

/// Деморепозиторий. Не является постоянным хранилищем и не подключён к СФР.
class DemoMchdRepository extends MchdRepository {
  final List<MchdRecord> _records = <MchdRecord>[];
  final List<MchdAuditEntry> _auditEntries = <MchdAuditEntry>[];

  @override
  List<MchdRecord> get records => List.unmodifiable(_records);

  @override
  List<MchdAuditEntry> get auditEntries => List.unmodifiable(_auditEntries);

  @override
  Future<void> save(MchdRecord record) async {
    final now = DateTime.now();
    final toSave = record.copyWith(updatedAt: now);
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index < 0) {
      _records.insert(0, toSave);
    } else {
      _records[index] = toSave;
    }
    _writeAudit(
      action: record.status == MchdStatus.draft ? 'Сохранение черновика МЧД' : 'Обновление карточки МЧД',
      details: record.status == MchdStatus.draft
          ? 'Черновик сохранён только в памяти приложения. В СФР ничего не отправлялось.'
          : 'Локальные реквизиты обновлены. Статус регистрации в СФР не проверялся.',
    );
    notifyListeners();
  }

  @override
  Future<void> addExistingForReview(MchdRecord record) async {
    final now = DateTime.now();
    final toSave = record.copyWith(
      status: MchdStatus.needsReview,
      sourceNote: record.sourceNote.isEmpty
          ? 'Реквизиты внесены вручную. XML, подпись и регистрация СФР не проверены.'
          : record.sourceNote,
      updatedAt: now,
    );
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index < 0) {
      _records.insert(0, toSave);
    } else {
      _records[index] = toSave;
    }
    _writeAudit(
      action: 'Добавление существующей МЧД',
      details: 'Реквизиты внесены локально и требуют сверки с реестром СФР.',
    );
    notifyListeners();
  }

  @override
  Future<void> deleteDraft(String id) async {
    final matches = _records.where((item) => item.id == id).toList();
    if (matches.isEmpty || !matches.first.isDraft) return;
    _records.removeWhere((item) => item.id == id);
    _writeAudit(
      action: 'Удаление черновика МЧД',
      details: 'Черновик удалён из оперативной памяти. Запрос в СФР не выполнялся.',
    );
    notifyListeners();
  }

  void _writeAudit({required String action, required String details}) {
    _auditEntries.insert(
      0,
      MchdAuditEntry(
        at: DateTime.now(),
        action: action,
        result: 'Локальная операция',
        details: details,
      ),
    );
  }
}

