import 'package:flutter/material.dart';

import '../../core/config/db_connection_settings.dart';
import '../../core/config/sfr_endpoints.dart';
import '../shared/app_banner.dart';

class ConnectionSettingsScreen extends StatelessWidget {
  const ConnectionSettingsScreen({super.key, required this.settings, required this.baseFilesRoot, required this.configFilePath, required this.onEditDatabase});

  final DbConnectionSettings settings;
  final String baseFilesRoot;
  final String configFilePath;
  final VoidCallback onEditDatabase;

  void _showNotConnected(BuildContext context, String check) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(check),
        content: const Text('Проверка пока недоступна: локальный криптографический мост ещё не подключён. Эта кнопка не отправляла запрос в СФР и не проверяла сертификаты.'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Понятно'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      children: [
        const Text('Подключение к СФР', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Параметры интеграции медицинской организации.', style: TextStyle(color: Color(0xFF62727F), fontSize: 15)),
        const SizedBox(height: 18),
        _SettingsCard(title: 'База данных Медиалог', children: [
          _StatusLine(label: 'Сервер', value: settings.server + (settings.server.contains('\\') ? '' : ', порт ${settings.port}'), icon: Icons.dns_outlined),
          const SizedBox(height: 10),
          _StatusLine(label: 'База данных', value: settings.database, icon: Icons.storage_outlined),
          const SizedBox(height: 10),
          _StatusLine(label: 'Драйвер', value: settings.driver, icon: Icons.memory_outlined),
          const SizedBox(height: 10),
          _StatusLine(label: 'Авторизация', value: settings.authenticationMode == DbAuthenticationMode.windowsIntegrated ? 'Windows Integrated' : 'SQL Server Login', icon: Icons.verified_user_outlined),
          const SizedBox(height: 10),
          const _StatusLine(label: 'Хранилище приложения', value: 'dbo.ELN_AppData + dbo.ELN_AuditLog', icon: Icons.table_chart_outlined),
          const SizedBox(height: 10),
          _StatusLine(label: 'Каталог BaseFiles', value: baseFilesRoot, icon: Icons.folder_outlined),
          const SizedBox(height: 10),
          _StatusLine(label: 'Файл конфигурации', value: '$configFilePath · AES-256-GCM', icon: Icons.lock_outline),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: onEditDatabase, icon: const Icon(Icons.settings_ethernet), label: const Text('Изменить настройки БД'))),
        ]),
        const SizedBox(height: 14),
        const AppBanner(
          title: 'Обмен с СФР не настроен',
          message: 'Подключение к SQL Server настроено отдельно. Обмен с СФР пока выключен: для него требуется TLS 1.2 с ГОСТ-криптографией, SOAP/XML-подпись и отдельный Windows-компонент с поддерживаемым криптопровайдером.',
          warning: true,
          icon: Icons.gpp_maybe_outlined,
        ),
        const SizedBox(height: 18),
        _SettingsCard(title: 'Контур и адрес', children: [
          const _StatusLine(label: 'Профиль', value: 'Медицинская организация (МО)', icon: Icons.local_hospital_outlined),
          const SizedBox(height: 12),
          const _StatusLine(label: 'Режим', value: 'Не настроен, сетевые запросы выключены', icon: Icons.cloud_off_outlined),
          const SizedBox(height: 14),
          const Text('WSDL из официальной страницы разработчика', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          SelectableText(SfrEndpoints.medicalOrganizationWsdl, style: const TextStyle(fontSize: 12, color: Color(0xFF176B69))),
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: () => _showNotConnected(context, 'Проверка сервиса'), icon: const Icon(Icons.network_check), label: const Text('Проверить соединение')),
        ]),
        const SizedBox(height: 14),
        _SettingsCard(title: 'Управление МЧД через СЭДО', children: [
          const _StatusLine(label: 'Сервис', value: 'СЭДО СФР · управление доверенностями', icon: Icons.assignment_ind_outlined),
          const SizedBox(height: 12),
          const Text('WSDL, опубликованный на странице СФР по МЧД', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          SelectableText(SfrEndpoints.mchdWsdl, style: const TextStyle(fontSize: 12, color: Color(0xFF176B69))),
          const SizedBox(height: 8),
          const Text('Это отдельный сервис от сервиса создания ЭЛН. Перед реальными операциями нужно реализовать сообщения СЭДО по спецификации МЧД, ГОСТ-криптографию и проверку подтверждений.', style: TextStyle(color: Color(0xFF62727F), fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => _showNotConnected(context, 'Проверка сервиса МЧД'), icon: const Icon(Icons.network_check), label: const Text('Проверить сервис МЧД')),
        ]),
        const SizedBox(height: 14),
        _SettingsCard(title: 'Сертификаты и подписи', children: [
          const _StatusLine(label: 'Сертификат МО', value: 'Не выбран', icon: Icons.badge_outlined),
          const SizedBox(height: 10),
          const _StatusLine(label: 'УКЭП руководителя / доверителя для МЧД', value: 'Не выбран; подписание МЧД не подключено', icon: Icons.assignment_ind_outlined),
          const SizedBox(height: 10),
          const _StatusLine(label: 'Ключ организации', value: 'Не проверен; закрытый ключ не импортировался', icon: Icons.key_outlined),
          const SizedBox(height: 10),
          const _StatusLine(label: 'Подпись врача / ВК', value: 'Не настроена', icon: Icons.draw_outlined),
          const SizedBox(height: 10),
          const _StatusLine(label: 'ГОСТ TLS 1.2', value: 'Не проверен', icon: Icons.lock_outline),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => _showNotConnected(context, 'Проверка криптографии'), icon: const Icon(Icons.verified_user_outlined), label: const Text('Проверить сертификаты')),
        ]),
        const SizedBox(height: 14),
        _SettingsCard(title: 'Что потребуется для подключения', children: const [
          _NumberedText(number: '1', text: 'Установленный и настроенный криптопровайдер, поддерживающий требуемую ГОСТ-криптографию и TLS 1.2.'),
          _NumberedText(number: '2', text: 'Действующий сертификат подписанта с доступом к закрытому ключу в локальном хранилище. Закрытый ключ не копируется в настройки Flutter.'),
          _NumberedText(number: '3', text: 'Сведения МО, ОГРН и идентификатор организации, совпадающие с реестром СФР.'),
          _NumberedText(number: '4', text: 'Подтверждённый тестовый контур СФР и успешная проверка подписания, шифрования, отправки SOAP и проверки подписи ответа.'),
        ]),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE2E9ED))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...children,
        ]),
      );
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 19, color: const Color(0xFF176B69)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF62727F)))),
      ]);
}

class _NumberedText extends StatelessWidget {
  const _NumberedText({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFEAF4F4), borderRadius: BorderRadius.circular(8)), child: Text(number, style: const TextStyle(color: Color(0xFF176B69), fontWeight: FontWeight.w800, fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45, color: Color(0xFF334753)))),
        ]),
      );
}
