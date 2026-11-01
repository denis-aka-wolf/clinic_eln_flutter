import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../domain/models/eln_record.dart';
import '../../domain/repositories/eln_repository.dart';
import '../shared/app_banner.dart';

class ElnRegistryScreen extends StatefulWidget {
  const ElnRegistryScreen({super.key, required this.repository, required this.onCreateEln, required this.onOpenEln});

  final ElnRepository repository;
  final VoidCallback onCreateEln;
  final ValueChanged<ElnRecord> onOpenEln;

  @override
  State<ElnRegistryScreen> createState() => _ElnRegistryScreenState();
}

class _ElnRegistryScreenState extends State<ElnRegistryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
        final query = _searchController.text.trim().toLowerCase();
        final records = widget.repository.records.where((record) {
          if (query.isEmpty) return true;
          return record.patientFullName.toLowerCase().contains(query) ||
              record.lnNumber.toLowerCase().contains(query) ||
              record.snils.replaceAll(RegExp(r'\D'), '').contains(query.replaceAll(RegExp(r'\D'), ''));
        }).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Реестр ЭЛН', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Черновики и записи, полученные из СФР после подключения интеграции.', style: TextStyle(color: Color(0xFF62727F), fontSize: 15)),
              ])),
              const SizedBox(width: 16),
              FilledButton.icon(onPressed: widget.onCreateEln, icon: const Icon(Icons.add), label: const Text('Новый ЭЛН')),
            ]),
            const SizedBox(height: 18),
            const AppBanner(
              title: 'Номер ЭЛН пока не выдаётся автоматически',
              message: 'В прототипе номер появится после реализации операции getNewLNNum. Не вводите сюда номер реального больничного вручную и не используйте эти черновики для отправки в СФР.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Поиск по ФИО, номеру ЭЛН или СНИЛС',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 14),
            if (records.isEmpty)
              _EmptyRegistry(hasAnyRecords: widget.repository.records.isNotEmpty, onCreate: widget.onCreateEln)
            else
              ...records.map((record) => _ElnListTile(record: record, onTap: () => widget.onOpenEln(record))),
          ],
        );
      },
    );
  }
}

class _EmptyRegistry extends StatelessWidget {
  const _EmptyRegistry({required this.hasAnyRecords, required this.onCreate});
  final bool hasAnyRecords;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E9ED))),
        child: Column(children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFEAF4F4), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.folder_open_outlined, size: 30, color: Color(0xFF176B69))),
          const SizedBox(height: 16),
          Text(hasAnyRecords ? 'Ничего не найдено' : 'Реестр пока пуст', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(hasAnyRecords ? 'Измените параметры поиска.' : 'Создайте черновик и заполните основные сведения ЭЛН.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF62727F))),
          if (!hasAnyRecords) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Создать черновик')),
          ],
        ]),
      );
}

class _ElnListTile extends StatelessWidget {
  const _ElnListTile({required this.record, required this.onTap});
  final ElnRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E9ED))),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEAF4F4), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medical_information_outlined, color: Color(0xFF176B69))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(record.patientFullName.isEmpty ? 'Пациент не указан' : record.patientFullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text('ЭЛН: ${record.lnNumber.isEmpty ? 'номер не получен' : record.lnNumber}  ·  СНИЛС: ${record.snils.isEmpty ? 'не указан' : record.snils}', style: const TextStyle(color: Color(0xFF62727F), fontSize: 12)),
                const SizedBox(height: 3),
                Text('Обновлён: ${formatDateTime(record.updatedAt)}', style: const TextStyle(color: Color(0xFF7B8992), fontSize: 11)),
              ])),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _StatusChip(label: record.localStatus.title, color: const Color(0xFF4466A6)),
                const SizedBox(height: 7),
                Text(record.sfrState?.title ?? 'Нет статуса СФР', style: const TextStyle(fontSize: 11, color: Color(0xFF62727F))),
              ]),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF8997A0)),
            ]),
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}
