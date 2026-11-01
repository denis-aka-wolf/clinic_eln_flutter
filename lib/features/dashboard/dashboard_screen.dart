import 'package:flutter/material.dart';

import '../../domain/models/eln_record.dart';
import '../../domain/repositories/eln_repository.dart';
import '../shared/app_banner.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.repository, required this.onCreateEln});

  final ElnRepository repository;
  final VoidCallback onCreateEln;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final records = repository.records;
        final drafts = records.where((e) => e.localStatus == LocalElnStatus.draft).length;
        final accepted = records.where((e) => e.localStatus == LocalElnStatus.accepted).length;
        final rejected = records.where((e) => e.localStatus == LocalElnStatus.rejected).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Рабочий стол', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                      SizedBox(height: 6),
                      Text('Создание, заполнение и контроль электронных листков нетрудоспособности.',
                          style: TextStyle(color: Color(0xFF62727F), fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: onCreateEln,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать ЭЛН'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const AppBanner(
              title: 'Режим разработки: отправка в СФР отключена',
              message: 'Сейчас можно заполнять черновики и выполнять локальную проверку полей. Реальные номера, подпись, шифрование, ГОСТ TLS и отправка будут включены только после подключения и проверки криптографического модуля.',
              warning: true,
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 650 ? 2 : 1;
                const gap = 14.0;
                final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _MetricCard(width: width, title: 'Всего карточек', value: '${records.length}', icon: Icons.folder_open_outlined, color: const Color(0xFF176B69)),
                    _MetricCard(width: width, title: 'Черновики', value: '$drafts', icon: Icons.edit_note_outlined, color: const Color(0xFF4466A6)),
                    _MetricCard(width: width, title: 'Принято СФР', value: '$accepted', icon: Icons.verified_outlined, color: const Color(0xFF3F815A)),
                    _MetricCard(width: width, title: 'Отклонено', value: '$rejected', icon: Icons.error_outline, color: const Color(0xFFB45B53)),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            const Text('Что нужно подключить для реальной работы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const _RoadmapRow(number: '01', title: 'Параметры медицинской организации', subtitle: 'ОГРН, название, адрес и код МО должны совпадать со сведениями СФР.'),
            const _RoadmapRow(number: '02', title: 'Криптография и сертификаты', subtitle: 'Подпись МО, подпись врача, при необходимости подпись председателя ВК, шифрование XML и ГОСТ TLS 1.2.'),
            const _RoadmapRow(number: '03', title: 'Тестовый контур СФР', subtitle: 'Проверка получения номера, отправки тестового ЭЛН, ответа, статуса и хэша.'),
            const _RoadmapRow(number: '04', title: 'Защищённое хранилище', subtitle: 'Сохранение истории в БД клиники или отдельной защищённой БД. Текущий прототип хранит записи только в оперативной памяти.'),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.width, required this.title, required this.value, required this.icon, required this.color});
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E9ED))),
        child: Row(
          children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(title, style: const TextStyle(color: Color(0xFF62727F), fontSize: 12))])),
          ],
        ),
      );
}

class _RoadmapRow extends StatelessWidget {
  const _RoadmapRow({required this.number, required this.title, required this.subtitle});
  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E9ED))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(number, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF176B69))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Color(0xFF62727F), height: 1.4))])),
        ]),
      );
}
