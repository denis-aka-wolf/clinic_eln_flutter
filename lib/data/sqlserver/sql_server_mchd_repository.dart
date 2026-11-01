import 'package:flutter/foundation.dart';

import '../../domain/models/mchd_record.dart';
import '../../domain/repositories/mchd_repository.dart';
import 'sql_server_data_store.dart';

class SqlServerMchdRepository extends MchdRepository {
  SqlServerMchdRepository(this._store);

  final SqlServerDataStore _store;
  final List<MchdRecord> _records = <MchdRecord>[];
  final List<MchdAuditEntry> _auditEntries = <MchdAuditEntry>[];

  @override
  List<MchdRecord> get records => List<MchdRecord>.unmodifiable(_records);
  @override
  List<MchdAuditEntry> get auditEntries => List<MchdAuditEntry>.unmodifiable(_auditEntries);

  Future<void> load() async {
    _records
      ..clear()
      ..addAll((await _store.readRecords('MCHD')).map((row) {
        final payload = row['payload_json'] ?? row['PAYLOAD_JSON'];
        return MchdRecord.fromJson(SqlServerDataStore.decodePayload(payload.toString()));
      }));
    _auditEntries
      ..clear()
      ..addAll((await _store.readAudit('MCHD')).map((row) => MchdAuditEntry(
            at: DateTime.tryParse('${row['created_at_utc'] ?? row['CREATED_AT_UTC'] ?? ''}') ?? DateTime.now(),
            action: '${row['action_name'] ?? row['ACTION_NAME'] ?? ''}',
            result: '${row['outcome'] ?? row['OUTCOME'] ?? ''}',
            details: '${row['details'] ?? row['DETAILS'] ?? ''}',
          )));
    notifyListeners();
  }

  @override
  Future<void> save(MchdRecord record) async {
    final now = DateTime.now();
    final updated = record.copyWith(updatedAt: now);
    await _persist(updated);
    final action = updated.status == MchdStatus.draft
        ? 'Сохранение черновика МЧД'
        : 'Обновление карточки МЧД';
    final details = updated.status == MchdStatus.draft
        ? 'Черновик МЧД сохранён в базе данных Медиалог. В СФР ничего не отправлялось.'
        : 'Карточка МЧД обновлена локально; статус СФР не проверялся.';
    await _store.writeAudit(module: 'MCHD', action: action, outcome: 'Выполнено', details: details);
    _addOrReplace(updated);
    _appendAudit(action, details);
    notifyListeners();
  }

  @override
  Future<void> addExistingForReview(MchdRecord record) async {
    final now = DateTime.now();
    final updated = record.copyWith(
      status: MchdStatus.needsReview,
      sourceNote: record.sourceNote.isEmpty
          ? 'Реквизиты внесены вручную. XML, подпись и регистрация СФР не проверены.'
          : record.sourceNote,
      updatedAt: now,
    );
    await _persist(updated);
    const action = 'Добавление существующей МЧД';
    const details = 'Реквизиты сохранены в SQL Server; сверка с реестром СФР не выполнялась.';
    await _store.writeAudit(module: 'MCHD', action: action, outcome: 'Выполнено', details: details);
    _addOrReplace(updated);
    _appendAudit(action, details);
    notifyListeners();
  }

  @override
  Future<void> deleteDraft(String id) async {
    final matches = _records.where((item) => item.id == id).toList();
    if (matches.isEmpty || !matches.first.isDraft) return;
    await _store.deleteDraft(recordType: 'MCHD', recordId: id);
    const action = 'Удаление черновика МЧД';
    const details = 'Локальный черновик МЧД удалён из базы данных; запрос в СФР не выполнялся.';
    await _store.writeAudit(module: 'MCHD', action: action, outcome: 'Выполнено', details: details);
    _records.removeWhere((item) => item.id == id);
    _appendAudit(action, details);
    notifyListeners();
  }

  Future<void> _persist(MchdRecord record) => _store.upsertRecord(
        recordType: 'MCHD',
        recordId: record.id,
        payload: SqlServerDataStore.encodePayload(record.toJson()),
        localStatus: record.status.name,
      );

  void _addOrReplace(MchdRecord record) {
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index < 0) {
      _records.insert(0, record);
    } else {
      _records[index] = record;
    }
  }

  void _appendAudit(String action, String details) {
    _auditEntries.insert(0, MchdAuditEntry(
      at: DateTime.now(),
      action: action,
      result: 'Выполнено',
      details: details,
    ));
  }
}
