import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../domain/repositories/eln_repository.dart';
import '../shared/app_banner.dart';

class ExchangeLogScreen extends StatelessWidget {
  const ExchangeLogScreen({super.key, required this.repository});

  final ElnRepository repository;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final entries = repository.auditEntries;
        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          children: [
            const Text('Журнал обмена', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Локальный журнал действий прототипа. Запросов к СФР пока нет.', style: TextStyle(color: Color(0xFF62727F), fontSize: 15)),
            const SizedBox(height: 18),
            const AppBanner(
              title: 'Интеграция с СФР не активирована',
              message: 'В этой версии фиксируются только локальные действия. Сетевые запросы, создание реальных ЭЛН и подписание документов программно заблокированы до подключения криптографического моста и тестирования на контуре СФР.',
              warning: true,
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 18),
            if (entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E9ED))),
                child: const Column(children: [
                  Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF84939D)),
                  SizedBox(height: 10),
                  Text('Записей пока нет', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  SizedBox(height: 5),
                  Text('Сохраните черновик ЭЛН, чтобы увидеть событие в журнале.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF62727F))),
                ]),
              )
            else
              ...entries.map((entry) => Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE2E9ED))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.history, color: Color(0xFF176B69)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(entry.action, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(entry.details, style: const TextStyle(color: Color(0xFF62727F), height: 1.4)),
                        const SizedBox(height: 6),
                        Text('${entry.result} · ${formatDateTime(entry.at)}', style: const TextStyle(fontSize: 11, color: Color(0xFF7B8992))),
                      ])),
                    ]),
                  )),
          ],
        );
      },
    );
  }
}
