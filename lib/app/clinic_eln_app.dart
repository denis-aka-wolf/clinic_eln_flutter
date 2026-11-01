import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;

import '../core/config/db_connection_settings.dart';
import '../core/security/base_files_config_store.dart';
import '../data/sqlserver/sql_server_data_store.dart';
import '../data/sqlserver/sql_server_eln_repository.dart';
import '../data/sqlserver/sql_server_mchd_repository.dart';
import '../domain/repositories/eln_repository.dart';
import '../domain/repositories/mchd_repository.dart';
import '../features/setup/initial_setup_screen.dart';
import 'app_shell.dart';

class ClinicElnApp extends StatefulWidget {
  const ClinicElnApp({super.key});

  @override
  State<ClinicElnApp> createState() => _ClinicElnAppState();
}

class _ClinicElnAppState extends State<ClinicElnApp> {
  final BaseFilesConfigStore _configStore = BaseFilesConfigStore();

  bool _booting = true;
  bool _showSetup = false;
  bool _active = false;
  String? _baseFilesRoot;
  String? _configFilePath;
  DbConnectionSettings? _settings;
  String? _setupMessage;
  SqlServerDataStore? _dataStore;
  SqlServerElnRepository? _elnRepository;
  SqlServerMchdRepository? _mchdRepository;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final root = await _configStore.readSavedBaseFilesRoot();
      if (root == null || root.trim().isEmpty) {
        _setBootstrapSetup(root: root, message: null);
        return;
      }
      _baseFilesRoot = root;
      final settings = await _configStore.loadSettings(root);
      _settings = settings;
      if (settings == null) {
        _setBootstrapSetup(root: root, message: 'В выбранном каталоге ещё нет сохранённых настроек подключения.');
        return;
      }
      await _activate(root, settings);
    } catch (error) {
      _setBootstrapSetup(
        root: _baseFilesRoot,
        message: 'Не удалось открыть сохранённую конфигурацию или подключиться к SQL Server. Настройки не были удалены. Тип ошибки: ${error.runtimeType}.',
      );
    }
  }

  void _setBootstrapSetup({required String? root, required String? message}) {
    if (!mounted) return;
    setState(() {
      _baseFilesRoot = root;
      _setupMessage = message;
      _showSetup = true;
      _booting = false;
    });
  }

  Future<void> _activate(String root, DbConnectionSettings settings) async {
    final newStore = SqlServerDataStore();
    try {
      await newStore.connect(settings);
      if (!await newStore.hasApplicationSchema()) {
        await newStore.disconnect();
        _setBootstrapSetup(
          root: root,
          message: 'SQL Server доступен, но служебные таблицы приложения не найдены. Проверь подключение и подтверди создание dbo.ELN_AppData и dbo.ELN_AuditLog.',
        );
        return;
      }
      final newElnRepository = SqlServerElnRepository(newStore);
      final newMchdRepository = SqlServerMchdRepository(newStore);
      await newElnRepository.load();
      await newMchdRepository.load();
      final configPath = await _configStore.configFilePath(root);

      final oldStore = _dataStore;
      final oldElnRepository = _elnRepository;
      final oldMchdRepository = _mchdRepository;
      if (!mounted) {
        await newStore.disconnect();
        return;
      }
      setState(() {
        _baseFilesRoot = root;
        _configFilePath = configPath;
        _settings = settings;
        _dataStore = newStore;
        _elnRepository = newElnRepository;
        _mchdRepository = newMchdRepository;
        _setupMessage = null;
        _active = true;
        _showSetup = false;
        _booting = false;
      });
      oldElnRepository?.dispose();
      oldMchdRepository?.dispose();
      if (oldStore != null && !identical(oldStore, newStore)) await oldStore.disconnect();
    } catch (_) {
      await newStore.disconnect();
      rethrow;
    }
  }

  Future<void> _activateWithSchemaCreation(String root, DbConnectionSettings settings) async {
    final newStore = SqlServerDataStore();
    try {
      await Directory(p.join(root, 'ELN')).create(recursive: true);
      await newStore.connect(settings);
      await newStore.ensureApplicationSchema();
      if (!await newStore.hasApplicationSchema()) {
        throw StateError('Не удалось создать служебные таблицы dbo.ELN_AppData и dbo.ELN_AuditLog.');
      }
      final newElnRepository = SqlServerElnRepository(newStore);
      final newMchdRepository = SqlServerMchdRepository(newStore);
      await newElnRepository.load();
      await newMchdRepository.load();
      await _configStore.saveBaseFilesRoot(root);
      await _configStore.saveSettings(root, settings);
      final configPath = await _configStore.configFilePath(root);

      final oldStore = _dataStore;
      final oldElnRepository = _elnRepository;
      final oldMchdRepository = _mchdRepository;
      if (!mounted) {
        await newStore.disconnect();
        return;
      }
      setState(() {
        _baseFilesRoot = root;
        _configFilePath = configPath;
        _settings = settings;
        _dataStore = newStore;
        _elnRepository = newElnRepository;
        _mchdRepository = newMchdRepository;
        _setupMessage = null;
        _active = true;
        _showSetup = false;
        _booting = false;
      });
      oldElnRepository?.dispose();
      oldMchdRepository?.dispose();
      if (oldStore != null && !identical(oldStore, newStore)) await oldStore.disconnect();
    } catch (_) {
      await newStore.disconnect();
      rethrow;
    }
  }

  void _openDatabaseSettings() {
    setState(() {
      _showSetup = true;
      _setupMessage = null;
    });
  }

  void _cancelSetup() {
    if (!_active) return;
    setState(() {
      _showSetup = false;
      _setupMessage = null;
    });
  }

  @override
  void dispose() {
    _elnRepository?.dispose();
    _mchdRepository?.dispose();
    final store = _dataStore;
    if (store != null) store.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF192D3A);
    const teal = Color(0xFF176B69);
    return MaterialApp(
      title: 'Клиника · ЭЛН',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: teal, primary: teal),
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F7F9),
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: ThemeData.light().textTheme.apply(bodyColor: ink, displayColor: ink),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE5E9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE5E9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: teal, width: 1.5),
          ),
        ),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showSetup || !_active || _settings == null || _baseFilesRoot == null) {
      return InitialSetupScreen(
        key: const ValueKey('initial-setup'),
        initialBaseFilesRoot: _baseFilesRoot,
        initialSettings: _settings,
        message: _setupMessage,
        onCancel: _active ? _cancelSetup : null,
        onSaveAndInitialize: _activateWithSchemaCreation,
      );
    }
    return AppShell(
      repository: _elnRepository!,
      mchdRepository: _mchdRepository!,
      dbSettings: _settings!,
      baseFilesRoot: _baseFilesRoot!,
      configFilePath: _configFilePath ?? p.join(_baseFilesRoot!, 'ELN', 'settings.<profile>.v1.enc'),
      onEditDatabase: _openDatabaseSettings,
    );
  }
}
