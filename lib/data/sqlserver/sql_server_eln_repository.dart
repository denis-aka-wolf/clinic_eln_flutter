import 'package:flutter/foundation.dart';

import '../../domain/models/eln_record.dart';
import '../../domain/repositories/eln_repository.dart';
import 'sql_server_data_store.dart';

class SqlServerElnRepository extends ElnRepository {
  SqlServerElnRepository(this._store);

  final SqlServerDataStore _store;
  final List<ElnRecord> _records = <ElnRecord>[];
  final List<AuditEntry> _auditEntries = <AuditEntry>[];

  @override
  List<ElnRecord> get records => List<ElnRecord>.unmodifiable(_records);
  @override
  List<AuditEntry> get auditEntries => List<AuditEntry>.unmodifiable(_auditEntries);

  Future<void> load() async {
    _records
      ..clear()
      ..addAll((await _store.readRecords('ELN')).map((row) {
        final payload = row['payload_json'] ?? row['PAYLOAD_JSON'];
        return ElnRecord.fromJson(SqlServerDataStore.decodePayload(payload.toString()));
      }));
    _auditEntries
      ..clear()
      ..addAll((await _store.readAudit('ELN')).map((row) => AuditEntry(
            at: DateTime.tryParse('${row['created_at_utc'] ?? row['CREATED_AT_UTC'] ?? ''}') ?? DateTime.now(),
            action: '${row['action_name'] ?? row['ACTION_NAME'] ?? ''}',
            result: '${row['outcome'] ?? row['OUTCOME'] ?? ''}',
            details: '${row['details'] ?? row['DETAILS'] ?? ''}',
          )));
    notifyListeners();
  }

  @override
  Future<void> saveDraft(ElnRecord record) async {
    final now = DateTime.now();
    final updated = record.copyWith(localStatus: LocalElnStatus.draft, updatedAt: now);
    await _store.upsertRecord(
      recordType: 'ELN',
      recordId: updated.id,
      payload: SqlServerDataStore.encodePayload(updated.toJson()),
      localStatus: updated.localStatus.name,
    );
    await _store.writeAudit(
      module: 'ELN',
      action: 'Сохранение черновика',
      outcome: 'Выполнено',
      details: 'Черновик ЭЛН сохранён в базе данных Медиалог. Передача в СФР не выполнялась.',
    );
    final index = _records.indexWhere((item) => item.id == updated.id);
    if (index < 0) {
      _records.insert(0, updated);
    } else {
      _records[index] = updated;
    }
    _auditEntries.insert(0, AuditEntry(
      at: now,
      action: 'Сохранение черновика',
      result: 'Выполнено',
      details: 'Черновик сохранён в SQL Server; отправка в СФР не выполнялась.',
    ));
    notifyListeners();
  }

  @override
  Future<void> deleteDraft(String id) async {
    final item = _records.where((record) => record.id == id).firstOrNull;
    if (item == null || item.localStatus != LocalElnStatus.draft) return;
    await _store.deleteDraft(recordType: 'ELN', recordId: id);
    await _store.writeAudit(
      module: 'ELN',
      action: 'Удаление черновика',
      outcome: 'Выполнено',
      details: 'Удалён локальный черновик ЭЛН; запрос в СФР не выполнялся.',
    );
    _records.removeWhere((record) => record.id == id);
    _auditEntries.insert(0, AuditEntry(
      at: DateTime.now(),
      action: 'Удаление черновика',
      result: 'Выполнено',
      details: 'Локальный черновик удалён из базы данных Медиалог.',
    ));
    notifyListeners();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
