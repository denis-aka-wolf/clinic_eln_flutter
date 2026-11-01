import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_eln/core/config/db_connection_settings.dart';

void main() {
  group('DbConnectionSettings', () {
    test('builds a SQL Server ODBC connection string with encryption', () {
      const settings = DbConnectionSettings(
        server: 'sql-clinic-01',
        port: 1433,
        database: 'Medialog',
        username: 'eln_app',
        password: 'test-secret',
      );
      final connectionString = settings.toOdbcConnectionString();
      expect(connectionString, contains('DRIVER={ODBC Driver 18 for SQL Server}'));
      expect(connectionString, contains('SERVER={tcp:sql-clinic-01,1433}'));
      expect(connectionString, contains('DATABASE={Medialog}'));
      expect(connectionString, contains('Encrypt=Yes'));
      expect(connectionString, contains('TrustServerCertificate=No'));
      expect(connectionString, contains('PWD={test-secret}'));
    });

    test('does not append the port twice when server includes it', () {
      const settings = DbConnectionSettings(
        server: 'sql-clinic-01,1533',
        port: 1433,
        database: 'Medialog',
        username: 'eln_app',
        password: 'secret',
      );
      expect(
        settings.toOdbcConnectionString(),
        contains('SERVER={tcp:sql-clinic-01,1533}'),
      );
    });

    test('escapes braces and wraps semicolons in credentials', () {
      const settings = DbConnectionSettings(
        server: 'server',
        database: 'Medi;alog',
        username: 'eln',
        password: 'p;ass}word',
      );
      final string = settings.toOdbcConnectionString();
      expect(string, contains('DATABASE={Medi;alog}'));
      expect(string, contains('PWD={p;ass}}word}'));
    });

    test('uses Windows integrated authentication without SQL login values', () {
      const settings = DbConnectionSettings(
        server: 'sql-clinic-01',
        database: 'Medialog',
        authenticationMode: DbAuthenticationMode.windowsIntegrated,
      );
      final string = settings.toOdbcConnectionString();
      expect(string, contains('Trusted_Connection=Yes'));
      expect(string, isNot(contains('UID=')));
      expect(string, isNot(contains('PWD=')));
    });

    test('round trips settings JSON for encrypted-config serialization', () {
      const settings = DbConnectionSettings(
        server: 'server',
        database: 'Medialog',
        username: 'eln_app',
        password: 'secret',
      );
      final restored = DbConnectionSettings.fromJson(settings.toJson());
      expect(restored.server, settings.server);
      expect(restored.database, settings.database);
      expect(restored.password, settings.password);
      expect(restored.encrypt, isTrue);
      expect(restored.trustServerCertificate, isFalse);
    });
  });
}
