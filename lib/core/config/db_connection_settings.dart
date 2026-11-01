
enum DbAuthenticationMode { sqlServer, windowsIntegrated }

/// Конфигурация подключения к SQL Server.
/// Пароль присутствует в памяти только на время работы и сохраняется только
/// внутри зашифрованного файла settings.<profile>.v1.enc.
class DbConnectionSettings {
  const DbConnectionSettings({
    required this.server,
    this.port = 1433,
    required this.database,
    this.driver = 'ODBC Driver 18 for SQL Server',
    this.authenticationMode = DbAuthenticationMode.sqlServer,
    this.username = '',
    this.password = '',
    this.encrypt = true,
    this.trustServerCertificate = false,
    this.connectionTimeoutSeconds = 10,
  });

  final String server;
  final int port;
  final String database;
  final String driver;
  final DbAuthenticationMode authenticationMode;
  final String username;
  final String password;
  final bool encrypt;
  final bool trustServerCertificate;
  final int connectionTimeoutSeconds;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'server': server,
        'port': port,
        'database': database,
        'driver': driver,
        'authenticationMode': authenticationMode.name,
        'username': username,
        'password': password,
        'encrypt': encrypt,
        'trustServerCertificate': trustServerCertificate,
        'connectionTimeoutSeconds': connectionTimeoutSeconds,
      };

  factory DbConnectionSettings.fromJson(Map<String, dynamic> json) {
    final modeName = json['authenticationMode']?.toString();
    return DbConnectionSettings(
      server: (json['server'] ?? '').toString(),
      port: int.tryParse('${json['port'] ?? 1433}') ?? 1433,
      database: (json['database'] ?? '').toString(),
      driver: (json['driver'] ?? 'ODBC Driver 18 for SQL Server').toString(),
      authenticationMode: DbAuthenticationMode.values.firstWhere(
        (mode) => mode.name == modeName,
        orElse: () => DbAuthenticationMode.sqlServer,
      ),
      username: (json['username'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      encrypt: json['encrypt'] != false,
      trustServerCertificate: json['trustServerCertificate'] == true,
      connectionTimeoutSeconds:
          int.tryParse('${json['connectionTimeoutSeconds'] ?? 10}') ?? 10,
    );
  }

  /// Строка создаётся только в памяти и никогда не записывается в журнал.
  String toOdbcConnectionString() {
    final cleanServer = server.trim();
    final serverAddress = cleanServer.contains('\\')
        ? cleanServer
        : cleanServer.startsWith('tcp:')
            ? (cleanServer.contains(',') ? cleanServer : '$cleanServer,$port')
            : cleanServer.contains(',')
                ? 'tcp:$cleanServer'
                : 'tcp:$cleanServer,$port';
    final parts = <String>[
      'DRIVER=${_brace(driver)}',
      'SERVER=${_brace(serverAddress)}',
      'DATABASE=${_brace(database.trim())}',
      'Encrypt=${encrypt ? 'Yes' : 'No'}',
      'TrustServerCertificate=${trustServerCertificate ? 'Yes' : 'No'}',
      'Connection Timeout=${connectionTimeoutSeconds.clamp(3, 60)}',
    ];
    if (authenticationMode == DbAuthenticationMode.windowsIntegrated) {
      parts.add('Trusted_Connection=Yes');
    } else {
      parts.add('UID=${_brace(username)}');
      parts.add('PWD=${_brace(password)}');
    }
    return '${parts.join(';')};';
  }

  /// ODBC connection string values are braced so semicolons in credentials
  /// are not parsed as option separators; a closing brace is doubled.
  static String _brace(String value) {
    final escaped = value.replaceAll('}', '}}');
    return '{$escaped}';
  }

  /// Fingerprint in memory only, used to ensure a successful test belongs to
  /// the exact visible form values. It is not a password hash for storage.
  String get inMemoryTestFingerprint => Object.hash(
        server, port, database, driver, authenticationMode, username, password,
        encrypt, trustServerCertificate, connectionTimeoutSeconds,
      ).toString();
}
