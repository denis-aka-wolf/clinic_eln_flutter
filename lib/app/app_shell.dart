import 'package:flutter/material.dart';

import '../core/config/db_connection_settings.dart';
import '../domain/models/eln_record.dart';
import '../domain/repositories/eln_repository.dart';
import '../domain/repositories/mchd_repository.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/eln_editor/eln_editor_screen.dart';
import '../features/exchange_log/exchange_log_screen.dart';
import '../features/registry/eln_registry_screen.dart';
import '../features/mchd/mchd_registry_screen.dart';
import '../features/settings/connection_settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.repository, required this.mchdRepository, required this.dbSettings, required this.baseFilesRoot, required this.configFilePath, required this.onEditDatabase});

  final ElnRepository repository;
  final MchdRepository mchdRepository;
  final DbConnectionSettings dbSettings;
  final String baseFilesRoot;
  final String configFilePath;
  final VoidCallback onEditDatabase;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _destinations = <NavigationRailDestination>[
    NavigationRailDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: Text('Рабочий стол')),
    NavigationRailDestination(icon: Icon(Icons.folder_copy_outlined), selectedIcon: Icon(Icons.folder_copy), label: Text('Реестр ЭЛН')),
    NavigationRailDestination(icon: Icon(Icons.assignment_ind_outlined), selectedIcon: Icon(Icons.assignment_ind), label: Text('МЧД')),
    NavigationRailDestination(icon: Icon(Icons.sync_alt_outlined), selectedIcon: Icon(Icons.sync_alt), label: Text('Обмен')),
    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Подключение')),
  ];

  Future<void> _createEln() async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => ElnEditorScreen(repository: widget.repository),
    ));
  }

  Future<void> _openEln(ElnRecord record) async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => ElnEditorScreen(repository: widget.repository, initialRecord: record),
    ));
  }

  Widget _selectedPage() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(repository: widget.repository, onCreateEln: _createEln);
      case 1:
        return ElnRegistryScreen(repository: widget.repository, onCreateEln: _createEln, onOpenEln: _openEln);
      case 2:
        return MchdRegistryScreen(repository: widget.mchdRepository);
      case 3:
        return ExchangeLogScreen(repository: widget.repository);
      case 4:
        return ConnectionSettingsScreen(settings: widget.dbSettings, baseFilesRoot: widget.baseFilesRoot, configFilePath: widget.configFilePath, onEditDatabase: widget.onEditDatabase);
      default:
        return DashboardScreen(repository: widget.repository, onCreateEln: _createEln);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.local_hospital_outlined, color: Color(0xFF176B69)),
          SizedBox(width: 10),
          Text('Клиника · ЭЛН', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: const Color(0xFFFFF3D9), borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [Icon(Icons.science_outlined, size: 15, color: Color(0xFF8A5B12)), SizedBox(width: 5), Text('Режим разработки', style: TextStyle(fontSize: 11, color: Color(0xFF8A5B12), fontWeight: FontWeight.w700))]),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 920;
        return Row(children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: compact ? NavigationRailLabelType.all : NavigationRailLabelType.none,
            extended: !compact && constraints.maxWidth >= 1240,
            minWidth: 78,
            minExtendedWidth: 205,
            backgroundColor: Colors.white,
            destinations: _destinations,
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E9ED)),
          Expanded(child: _selectedPage()),
        ]);
      }),
    );
  }
}
