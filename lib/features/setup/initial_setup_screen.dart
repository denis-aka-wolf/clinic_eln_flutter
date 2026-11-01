import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/config/db_connection_settings.dart';
import '../../data/sqlserver/sql_server_data_store.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({
    super.key,
    this.initialBaseFilesRoot,
    this.initialSettings,
    this.message,
    this.onCancel,
    required this.onSaveAndInitialize,
  });

  final String? initialBaseFilesRoot;
  final DbConnectionSettings? initialSettings;
  final String? message;
  final VoidCallback? onCancel;
  final Future<void> Function(String baseFilesRoot, DbConnectionSettings settings)
      onSaveAndInitialize;

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  late final TextEditingController _serverController;
  late final TextEditingController _portController;
  late final TextEditingController _databaseController;
  late final TextEditingController _driverController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _timeoutController;

  String? _baseFilesRoot;
  DbAuthenticationMode _authMode = DbAuthenticationMode.sqlServer;
  bool _encrypt = true;
  bool _trustServerCertificate = false;
  bool _testing = false;
  bool _saving = false;
  bool _passwordVisible = false;
  bool _connectionTestPassed = false;
  String? _statusText;
  bool _statusIsError = false;
  String? _testedFingerprint;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSettings;
    _baseFilesRoot = widget.initialBaseFilesRoot;
    _serverController = TextEditingController(text: initial?.server ?? '');
    _portController = TextEditingController(text: '${initial?.port ?? 1433}');
    _databaseController = TextEditingController(text: initial?.database ?? 'Medialog');
    _driverController = TextEditingController(text: initial?.driver ?? 'ODBC Driver 18 for SQL Server');
    _usernameController = TextEditingController(text: initial?.username ?? '');
    _passwordController = TextEditingController(text: initial?.password ?? '');
    _timeoutController = TextEditingController(text: '${initial?.connectionTimeoutSeconds ?? 10}');
    _authMode = initial?.authenticationMode ?? DbAuthenticationMode.sqlServer;
    _encrypt = initial?.encrypt ?? true;
    _trustServerCertificate = initial?.trustServerCertificate ?? false;
  }

  @override
  void dispose() {
    _serverController.dispose();
    _portController.dispose();
    _databaseController.dispose();
    _driverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  void _markConnectionDirty() {
    if (!_connectionTestPassed && _statusText == null) return;
    setState(() {
      _connectionTestPassed = false;
      _testedFingerprint = null;
      _statusText = null;
    });
  }

  Future<void> _selectBaseFiles() async {
    final selected = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Выберите каталог BaseFiles или каталог, в котором его создать',
      initialDirectory: _baseFilesRoot,
    );
    if (selected == null || selected.trim().isEmpty) return;
    final normalized = p.normalize(selected);
    final root = p.basename(normalized).toLowerCase() == 'basefiles'
        ? normalized
        : p.join(normalized, 'BaseFiles');
    setState(() => _baseFilesRoot = root);
  }

  DbConnectionSettings? _buildSettings({bool showValidation = true}) {
    final server = _serverController.text.trim();
    final database = _databaseController.text.trim();
    final driver = _driverController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    final timeout = int.tryParse(_timeoutController.text.trim());
    String? error;
    if (server.isEmpty) error = 'Укажи имя SQL Server или экземпляра.';
    if (error == null && database.isEmpty) error = 'Укажи имя базы данных Медиалог.';
    if (error == null && driver.isEmpty) error = 'Укажи имя установленного ODBC-драйвера.';
    if (error == null && port == null && !_serverController.text.contains('\\')) {
      error = 'Порт должен быть числом, например 1433.';
    }
    if (error == null && port != null && (port < 1 || port > 65535)) error = 'Порт должен быть от 1 до 65535.';
    if (error == null && (timeout == null || timeout < 3 || timeout > 60)) {
      error = 'Тайм-аут должен быть от 3 до 60 секунд.';
    }
    if (error == null && _authMode == DbAuthenticationMode.sqlServer && _usernameController.text.trim().isEmpty) {
      error = 'Укажи логин SQL Server.';
    }
    if (error != null) {
      if (showValidation) _showStatus(error, error: true);
      return null;
    }
    return DbConnectionSettings(
      server: server,
      port: port ?? 1433,
      database: database,
      driver: driver,
      authenticationMode: _authMode,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      encrypt: _encrypt,
      trustServerCertificate: _trustServerCertificate,
      connectionTimeoutSeconds: timeout!,
    );
  }

  Future<void> _testConnection() async {
    final settings = _buildSettings();
    if (settings == null) return;
    setState(() {
      _testing = true;
      _statusText = 'Проверяем подключение к SQL Server…';
      _statusIsError = false;
      _connectionTestPassed = false;
    });
    try {
      final info = await SqlServerDataStore.testConnection(settings);
      if (!mounted) return;
      setState(() {
        _connectionTestPassed = true;
        _testedFingerprint = settings.inMemoryTestFingerprint;
        _statusIsError = false;
        _statusText = 'Подключение успешно. База: ${info.databaseName}; пользователь SQL: ${info.loginName}. Таблицы приложения пока не проверялись.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _connectionTestPassed = false;
        _testedFingerprint = null;
        _statusIsError = true;
        _statusText = _safeError(error);
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _saveAndInitialize() async {
    final root = _baseFilesRoot;
    if (root == null || root.trim().isEmpty) {
      _showStatus('Сначала выбери каталог BaseFiles.', error: true);
      return;
    }
    final settings = _buildSettings();
    if (settings == null) return;
    if (!_connectionTestPassed || _testedFingerprint != settings.inMemoryTestFingerprint) {
      _showStatus('Сначала проверь подключение с текущими параметрами.', error: true);
      return;
    }

    final approved = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Подготовить базу данных?'),
            content: SelectableText(
              'Будут созданы только две служебные таблицы приложения: '
              'dbo.ELN_AppData и dbo.ELN_AuditLog в базе «${settings.database}» на сервере «${settings.server}».\n\n'
              'Существующие таблицы Медиалог не изменяются. Новые таблицы будут содержать черновики ЭЛН, карточки МЧД и журнал действий. Продолжить?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Создать таблицы')),
            ],
          ),
        ) ??
        false;
    if (!approved || !mounted) return;

    setState(() {
      _saving = true;
      _statusText = 'Подключаемся, подготавливаем хранилище и шифруем настройки…';
      _statusIsError = false;
    });
    try {
      await widget.onSaveAndInitialize(root, settings);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusText = _safeError(error);
        _statusIsError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _safeError(Object error) {
    // Some ODBC drivers include connection-string fragments in exception text.
    // Do not show the raw message because it could disclose the SQL password.
    return 'Не удалось завершить операцию. Проверь доступ к SQL Server, имя ODBC-драйвера, '
        'права пользователя и настройки TLS. Тип ошибки: ${error.runtimeType}.';
  }

  void _showStatus(String text, {required bool error}) {
    if (!mounted) return;
    setState(() {
      _statusText = text;
      _statusIsError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final root = _baseFilesRoot;
    final currentFingerprint = _buildSettings(showValidation: false)?.inMemoryTestFingerprint;
    final canSave = root != null && root.isNotEmpty && _connectionTestPassed && currentFingerprint == _testedFingerprint && !_saving && !_testing;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Первичная настройка · Клиника ЭЛН', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: widget.onCancel == null ? null : IconButton(
          tooltip: 'Вернуться',
          onPressed: (_saving || _testing) ? null : widget.onCancel,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
            children: [
              const Text('Где хранить настройки и как подключаться к Медиалог', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Сначала выбери BaseFiles и укажи SQL Server. Приложение не создаёт и не меняет таблицы Медиалог: для своих данных используются отдельные таблицы с префиксом ELN_.', style: TextStyle(color: Color(0xFF62727F), height: 1.45)),
              if (widget.message != null && widget.message!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoBox(message: widget.message!, error: true),
              ],
              const SizedBox(height: 20),
              _SectionCard(
                number: '1',
                title: 'Каталог BaseFiles',
                subtitle: 'В нём будет создан подкаталог ELN. Настройки подключения сохраняются в отдельный зашифрованный файл профиля Windows.',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.folder_outlined, color: Color(0xFF176B69)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(root ?? 'Каталог ещё не выбран', style: const TextStyle(fontWeight: FontWeight.w600))),
                    OutlinedButton.icon(onPressed: (_saving || _testing) ? null : _selectBaseFiles, icon: const Icon(Icons.folder_open), label: const Text('Выбрать')),
                  ]),
                  if (root != null) ...[
                    const SizedBox(height: 8),
                    SelectableText(p.join(root, 'ELN', 'settings.<локальный-профиль>.v1.enc'), style: const TextStyle(fontSize: 12, color: Color(0xFF176B69))),
                  ],
                ]),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                number: '2',
                title: 'SQL Server · база Медиалог',
                subtitle: 'Установка должна иметь Microsoft ODBC Driver for SQL Server. По умолчанию используется ODBC Driver 18 с шифрованием соединения.',
                child: Column(children: [
                  Row(children: [
                    Expanded(child: TextField(controller: _serverController, onChanged: (_) => _markConnectionDirty(), decoration: const InputDecoration(labelText: 'SQL Server / адрес / экземпляр', hintText: 'например, MEDIALOG-SQL или server\\MEDIALOG'))),
                    const SizedBox(width: 12),
                    SizedBox(width: 150, child: TextField(controller: _portController, onChanged: (_) => _markConnectionDirty(), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'TCP-порт', hintText: '1433'))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: _databaseController, onChanged: (_) => _markConnectionDirty(), decoration: const InputDecoration(labelText: 'Имя базы данных', hintText: 'Medialog'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _driverController, onChanged: (_) => _markConnectionDirty(), decoration: const InputDecoration(labelText: 'Имя ODBC-драйвера'))),
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DbAuthenticationMode>(
                    value: _authMode,
                    decoration: const InputDecoration(labelText: 'Способ авторизации'),
                    items: const [
                      DropdownMenuItem(value: DbAuthenticationMode.sqlServer, child: Text('Логин и пароль SQL Server')),
                      DropdownMenuItem(value: DbAuthenticationMode.windowsIntegrated, child: Text('Windows Integrated Authentication')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() { _authMode = value; _connectionTestPassed = false; _testedFingerprint = null; _statusText = null; });
                    },
                  ),
                  if (_authMode == DbAuthenticationMode.sqlServer) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(controller: _usernameController, onChanged: (_) => _markConnectionDirty(), decoration: const InputDecoration(labelText: 'Логин SQL Server', hintText: 'отдельный пользователь для ELN'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _passwordController, onChanged: (_) => _markConnectionDirty(), obscureText: !_passwordVisible, decoration: InputDecoration(labelText: 'Пароль', suffixIcon: IconButton(onPressed: () => setState(() => _passwordVisible = !_passwordVisible), icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility))))),
                    ]),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: _timeoutController, onChanged: (_) => _markConnectionDirty(), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Тайм-аут подключения (сек.)'))),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ]),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _encrypt,
                    title: const Text('Шифровать соединение с SQL Server (Encrypt=Yes)'),
                    subtitle: const Text('Рекомендуется оставить включённым.'),
                    onChanged: (value) => setState(() { _encrypt = value ?? true; _connectionTestPassed = false; _testedFingerprint = null; _statusText = null; }),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _trustServerCertificate,
                    title: const Text('Доверять сертификату SQL Server без проверки цепочки'),
                    subtitle: const Text('Менее безопасно. Включать только если сертификат сервера ещё не настроен.'),
                    onChanged: (value) => setState(() { _trustServerCertificate = value ?? false; _connectionTestPassed = false; _testedFingerprint = null; _statusText = null; }),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              if (_statusText != null) ...[
                _InfoBox(message: _statusText!, error: _statusIsError),
                const SizedBox(height: 12),
              ],
              Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.end, children: [
                OutlinedButton.icon(
                  onPressed: (_testing || _saving) ? null : _testConnection,
                  icon: _testing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.network_check),
                  label: Text(_testing ? 'Проверяем…' : 'Проверить соединение'),
                ),
                FilledButton.icon(
                  onPressed: canSave ? _saveAndInitialize : null,
                  icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock_outline),
                  label: Text(_saving ? 'Подготавливаем…' : 'Сохранить и подготовить БД'),
                ),
              ]),
              const SizedBox(height: 20),
              const _InfoBox(
                message: 'Безопасность: файл конфигурации шифруется AES-256-GCM; ключ защищается хранилищем учётных данных операционной системы. Пароль не записывается в открытом виде и не выводится в журнал. Доступ к ELN-таблицам в SQL Server нужно ограничить отдельными правами.',
                error: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.number, required this.title, required this.subtitle, required this.child});
  final String number;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E9ED)), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFEAF4F4), borderRadius: BorderRadius.circular(9)), child: Text(number, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF176B69)))),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Color(0xFF62727F), fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          child,
        ]),
      );
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.message, required this.error});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFFF0ED) : const Color(0xFFEAF4F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: error ? const Color(0xFFFFD1C8) : const Color(0xFFC8E5E2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(error ? Icons.error_outline : Icons.info_outline, color: error ? const Color(0xFF9C3424) : const Color(0xFF176B69)),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: error ? const Color(0xFF8E2E20) : const Color(0xFF215B59), height: 1.4, fontSize: 13))),
        ]),
      );
}
