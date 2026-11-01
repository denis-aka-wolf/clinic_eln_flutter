import 'dart:convert';

import 'package:dart_odbc/dart_odbc.dart';

import '../../core/config/db_connection_settings.dart';

class SqlServerConnectionInfo {
  const SqlServerConnectionInfo({
    required this.databaseName,
    required this.loginName,
    required this.serverVersion,
  });
  final String databaseName;
  final String loginName;
  final String serverVersion;
}

/// Connection and application-owned tables inside the selected Medialog DB.
/// Only dbo.ELN_AppData and dbo.ELN_AuditLog are created by this module.
/// No existing Medialog tables are modified.
class SqlServerDataStore {
  DartOdbc? _client;
  bool get isConnected => _client != null;

  static Future<SqlServerConnectionInfo> testConnection(
    DbConnectionSettings settings,
  ) async {
    final client = DartOdbc();
    try {
      await client.connectWithConnectionString(settings.toOdbcConnectionString());
      final rows = await client.execute(
        'SELECT DB_NAME() AS database_name, SUSER_SNAME() AS login_name, @@VERSION AS server_version',
      );
      if (rows.isEmpty) throw StateError('SQL Server не вернул результат проверки.');
      final row = rows.first;
      return SqlServerConnectionInfo(
        databaseName: _value(row, 'database_name'),
        loginName: _value(row, 'login_name'),
        serverVersion: _value(row, 'server_version'),
      );
    } finally {
      try {
        await client.disconnect();
      } catch (_) {
        // Preserve the original connection/test error.
      }
    }
  }

  Future<void> connect(DbConnectionSettings settings) async {
    await disconnect();
    final client = DartOdbc();
    try {
      await client.connectWithConnectionString(settings.toOdbcConnectionString());
      _client = client;
    } catch (_) {
      try {
        await client.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> disconnect() async {
    final client = _client;
    _client = null;
    if (client != null) await client.disconnect();
  }

  Future<bool> hasApplicationSchema() async {
    final rows = await _execute('''
SELECT CASE
 WHEN OBJECT_ID(N'dbo.ELN_AppData', N'U') IS NOT NULL
  AND OBJECT_ID(N'dbo.ELN_AuditLog', N'U') IS NOT NULL
 THEN 1 ELSE 0 END AS schema_ready
''');
    return rows.isNotEmpty && _value(rows.first, 'schema_ready') == '1';
  }

  /// Explicit first-run operation. No DROP/ALTER and no changes to Medialog's
  /// existing tables. Invoke only after user confirms the target database.
  Future<void> ensureApplicationSchema() async {
    await _execute('''
IF OBJECT_ID(N'dbo.ELN_AppData', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.ELN_AppData (
    RecordType NVARCHAR(16) NOT NULL,
    RecordId NVARCHAR(100) NOT NULL,
    PayloadJson NVARCHAR(MAX) NOT NULL,
    LocalStatus NVARCHAR(60) NOT NULL,
    CreatedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_ELN_AppData_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
    UpdatedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_ELN_AppData_UpdatedAtUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ELN_AppData PRIMARY KEY (RecordType, RecordId)
  )
END
''');
    await _execute('''
IF OBJECT_ID(N'dbo.ELN_AuditLog', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.ELN_AuditLog (
    AuditId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ELN_AuditLog PRIMARY KEY,
    CreatedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_ELN_AuditLog_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
    Module NVARCHAR(24) NOT NULL,
    ActionName NVARCHAR(120) NOT NULL,
    Outcome NVARCHAR(60) NOT NULL,
    Details NVARCHAR(2000) NOT NULL
  )
END
''');
  }

  Future<List<Map<String, dynamic>>> readRecords(String recordType) => _execute(
        '''SELECT RecordId AS record_id, PayloadJson AS payload_json, LocalStatus AS local_status
           FROM dbo.ELN_AppData WHERE RecordType = ? ORDER BY UpdatedAtUtc DESC''',
        params: <Object?>[recordType],
      );

  Future<void> upsertRecord({
    required String recordType,
    required String recordId,
    required String payload,
    required String localStatus,
  }) async {
    await _execute('''
IF EXISTS (SELECT 1 FROM dbo.ELN_AppData WHERE RecordType = ? AND RecordId = ?)
BEGIN
  UPDATE dbo.ELN_AppData
    SET PayloadJson = ?, LocalStatus = ?, UpdatedAtUtc = SYSUTCDATETIME()
    WHERE RecordType = ? AND RecordId = ?
END
ELSE
BEGIN
  INSERT INTO dbo.ELN_AppData (RecordType, RecordId, PayloadJson, LocalStatus, CreatedAtUtc, UpdatedAtUtc)
  VALUES (?, ?, ?, ?, SYSUTCDATETIME(), SYSUTCDATETIME())
END
''', params: <Object?>[
      recordType, recordId,
      payload, localStatus, recordType, recordId,
      recordType, recordId, payload, localStatus,
    ]);
  }

  Future<void> deleteDraft({
    required String recordType,
    required String recordId,
  }) async {
    await _execute(
      'DELETE FROM dbo.ELN_AppData WHERE RecordType = ? AND RecordId = ? AND LocalStatus = ?',
      params: <Object?>[recordType, recordId, 'draft'],
    );
  }

  Future<void> writeAudit({
    required String module,
    required String action,
    required String outcome,
    required String details,
  }) async {
    await _execute('''
INSERT INTO dbo.ELN_AuditLog (CreatedAtUtc, Module, ActionName, Outcome, Details)
VALUES (SYSUTCDATETIME(), ?, ?, ?, ?)
''', params: <Object?>[module, action, outcome, details]);
  }

  Future<List<Map<String, dynamic>>> readAudit(String module) => _execute('''
SELECT TOP (150)
  CreatedAtUtc AS created_at_utc,
  ActionName AS action_name,
  Outcome AS outcome,
  Details AS details
FROM dbo.ELN_AuditLog
WHERE Module = ?
ORDER BY AuditId DESC
''', params: <Object?>[module]);

  Future<List<Map<String, dynamic>>> _execute(
    String sql, {
    List<Object?> params = const <Object?>[],
  }) async {
    final client = _client;
    if (client == null) throw StateError('Подключение к SQL Server закрыто.');
    return client.execute(sql, params: params);
  }

  static String _value(Map<String, dynamic> row, String key) =>
      (row[key] ?? row[key.toUpperCase()] ?? '').toString();

  static String encodePayload(Map<String, dynamic> json) => jsonEncode(json);
  static Map<String, dynamic> decodePayload(String value) =>
      jsonDecode(value) as Map<String, dynamic>;
}
