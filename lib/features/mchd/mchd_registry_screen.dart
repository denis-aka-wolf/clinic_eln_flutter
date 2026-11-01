import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../domain/models/mchd_record.dart';
import '../../domain/repositories/mchd_repository.dart';
import '../shared/app_banner.dart';
import 'mchd_editor_screen.dart';

class MchdRegistryScreen extends StatefulWidget {
  const MchdRegistryScreen({super.key, required this.repository});

  final MchdRepository repository;

  @override
  State<MchdRegistryScreen> createState() => _MchdRegistryScreenState();
}

enum _MchdFilter { all, drafts, registered, attention, revoked }

class _MchdRegistryScreenState extends State<MchdRegistryScreen> {
  final _searchController = TextEditingController();
  _MchdFilter _filter = _MchdFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createDraft() async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => MchdEditorScreen(repository: widget.repository, mode: MchdEditorMode.createDraft),
    ));
  }

  Future<void> _addExisting() async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => MchdEditorScreen(repository: widget.repository, mode: MchdEditorMode.addExisting),
    ));
  }

  Future<void> _editDraft(MchdRecord record) async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => MchdEditorScreen(
        repository: widget.repository,
        mode: MchdEditorMode.createDraft,
        initialRecord: record,
      ),
    ));
  }

  Future<void> _editExistingMetadata(MchdRecord record) async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => MchdEditorScreen(
        repository: widget.repository,
        mode: MchdEditorMode.addExisting,
        initialRecord: record,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
        final all = widget.repository.records;
        final query = _searchController.text.trim().toLowerCase();
        final filtered = all.where((record) {
          final matchesQuery = query.isEmpty ||
              record.number.toLowerCase().contains(query) ||
              record.principalName.toLowerCase().contains(query) ||
              record.representativeName.toLowerCase().contains(query) ||
              record.representativeInn.replaceAll(RegExp(r'\D'), '').contains(query.replaceAll(RegExp(r'\D'), '')) ||
              record.authorityCodes.toLowerCase().contains(query);
          if (!matchesQuery) return false;
          switch (_filter) {
            case _MchdFilter.all:
              return true;
            case _MchdFilter.drafts:
              return record.status == MchdStatus.draft || record.status == MchdStatus.readyForSignature;
            case _MchdFilter.registered:
              return record.status == MchdStatus.registered;
            case _MchdFilter.attention:
              return record.status == MchdStatus.needsReview ||
                  record.status == MchdStatus.rejected ||
                  record.status == MchdStatus.expired ||
                  (record.status == MchdStatus.registered && record.isExpiredByDate);
            case _MchdFilter.revoked:
              return record.status == MchdStatus.revoked || record.status == MchdStatus.revocationRequested;
          }
        }).toList();

        final drafts = all.where((r) => r.status == MchdStatus.draft).length;
        final registered = all.where((r) => r.status == MchdStatus.registered && r.isEffectiveByDate).length;
        final attention = all.where((r) => r.status == MchdStatus.needsReview || r.status == MchdStatus.rejected || r.status == MchdStatus.expired || (r.status == MchdStatus.registered && r.isExpiredByDate)).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Машиночитаемые доверенности', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Доверенности представителей клиники для взаимодействия с СФР.', style: TextStyle(color: Color(0xFF62727F), fontSize: 15)),
              ])),
              const SizedBox(width: 16),
              OutlinedButton.icon(onPressed: _addExisting, icon: const Icon(Icons.playlist_add), label: const Text('Добавить существующую')),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _createDraft, icon: const Icon(Icons.add), label: const Text('Создать МЧД')),
            ]),
            const SizedBox(height: 18),
            const AppBanner(
              title: 'Управление МЧД пока работает локально',
              message: 'Можно создавать черновики и вести список уже оформленных доверенностей. Подписание УКЭП, отправка в СФР, проверка регистрации и отзыв ещё не подключены. Локальная запись не подтверждает юридическую силу МЧД. МЧД также не заменяет обязательную персональную подпись врача на медицинских сведениях ЭЛН.',
            ),
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, constraints) {
              final narrow = constraints.maxWidth < 920;
              final cards = [
                _MetricCard(label: 'Всего в списке', value: '${all.length}', icon: Icons.folder_copy_outlined, tone: _MetricTone.neutral),
                _MetricCard(label: 'Черновики', value: '$drafts', icon: Icons.edit_note_outlined, tone: _MetricTone.blue),
                _MetricCard(label: 'Активные по датам', value: '$registered', icon: Icons.verified_outlined, tone: _MetricTone.green),
                _MetricCard(label: 'Требуют внимания', value: '$attention', icon: Icons.warning_amber_outlined, tone: _MetricTone.orange),
              ];
              if (narrow) {
                return Wrap(spacing: 10, runSpacing: 10, children: cards.map((card) => SizedBox(width: (constraints.maxWidth - 10) / 2, child: card)).toList());
              }
              return Row(children: [for (var i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: cards[i])]]);
            }),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Поиск по номеру, организации, представителю или коду полномочия',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _filterChip(_MchdFilter.all, 'Все'),
              _filterChip(_MchdFilter.drafts, 'Черновики'),
              _filterChip(_MchdFilter.registered, 'Зарегистрированные'),
              _filterChip(_MchdFilter.attention, 'Требуют внимания'),
              _filterChip(_MchdFilter.revoked, 'Отзыв / отозваны'),
            ]),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              _EmptyMchd(hasAnyRecords: all.isNotEmpty, onCreate: _createDraft, onAddExisting: _addExisting)
            else
              ...filtered.map((record) => _MchdListTile(
                    record: record,
                    onTap: () => _showDetails(record),
                  )),
            if (widget.repository.auditEntries.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('Последнее действие', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E9ED))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.history, color: Color(0xFF62727F)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.repository.auditEntries.first.action, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(widget.repository.auditEntries.first.details, style: const TextStyle(color: Color(0xFF62727F), fontSize: 12)),
                    const SizedBox(height: 3),
                    Text(formatDateTime(widget.repository.auditEntries.first.at), style: const TextStyle(color: Color(0xFF87949D), fontSize: 11)),
                  ])),
                ]),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _filterChip(_MchdFilter filter, String label) => FilterChip(
        label: Text(label),
        selected: _filter == filter,
        onSelected: (_) => setState(() => _filter = filter),
      );

  Future<void> _showDetails(MchdRecord record) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.assignment_ind_outlined, color: Color(0xFF176B69)),
          const SizedBox(width: 10),
          Expanded(child: Text(record.number.isEmpty ? 'Карточка МЧД' : 'МЧД ${record.number}')),
        ]),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            _DetailRow(label: 'Статус в приложении', value: record.status.title),
            _DetailRow(label: 'Доверитель', value: record.principalName),
            _DetailRow(label: 'ИНН / ОГРН', value: '${record.principalInn} / ${record.principalOgrn}'),
            if (record.principalKpp.isNotEmpty) _DetailRow(label: 'КПП', value: record.principalKpp),
            _DetailRow(label: 'Представитель', value: record.representativeName),
            _DetailRow(label: 'ИНН представителя', value: record.representativeInn.isEmpty ? 'Не указан' : record.representativeInn),
            _DetailRow(label: 'СНИЛС представителя', value: record.representativeSnils.isEmpty ? 'Не указан' : record.representativeSnils),
            _DetailRow(label: 'Срок действия', value: '${formatDate(record.validFrom)} – ${formatDate(record.validTo)}'),
            _DetailRow(label: 'Коды полномочий', value: record.authorityCodes.isEmpty ? 'Не указаны' : record.authorityCodes),
            _DetailRow(label: 'Описание полномочий', value: record.authorityDescription.isEmpty ? 'Не указано' : record.authorityDescription),
            if (record.registryId.isNotEmpty) _DetailRow(label: 'Идентификатор реестра СФР', value: record.registryId),
            if (record.rejectionReason.isNotEmpty) _DetailRow(label: 'Причина отказа', value: record.rejectionReason),
            if (record.sourceNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(record.sourceNote, style: const TextStyle(color: Color(0xFF8A5B12), fontSize: 12)),
            ],
          ])),
        ),
        actions: [
          if (record.isDraft)
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _editDraft(record);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Редактировать'),
            ),
          if (record.isDraft)
            TextButton.icon(
              onPressed: () async {
                await widget.repository.deleteDraft(record.id);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Удалить черновик'),
            ),
          if (record.status == MchdStatus.needsReview)
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _editExistingMetadata(record);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Исправить реквизиты'),
            ),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Закрыть')),
        ],
      ),
    );
  }
}

class _MchdListTile extends StatelessWidget {
  const _MchdListTile({required this.record, required this.onTap});

  final MchdRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = record.status == MchdStatus.registered && record.isExpiredByDate ? MchdStatus.expired : record.status;
    final tone = _statusTone(status);
    final permissions = record.authorityCodes.trim().isEmpty
        ? 'Полномочия ещё не указаны'
        : record.authorityCodes.trim().split(RegExp(r'[\n,;]+')).where((value) => value.trim().isNotEmpty).take(3).join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E9ED))),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFEAF4F4), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.assignment_ind_outlined, color: Color(0xFF176B69))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record.number.isEmpty ? 'Черновик МЧД' : 'МЧД ${record.number}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(record.principalName, style: const TextStyle(color: Color(0xFF344957), fontSize: 13)),
              const SizedBox(height: 3),
              Text('Представитель: ${record.representativeName}', style: const TextStyle(color: Color(0xFF62727F), fontSize: 12)),
              const SizedBox(height: 3),
              Text(permissions, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF87949D), fontSize: 11)),
            ])),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _StatusChip(label: status.title, tone: tone),
              const SizedBox(height: 7),
              Text('${formatDate(record.validFrom)} – ${formatDate(record.validTo)}', style: const TextStyle(fontSize: 11, color: Color(0xFF62727F))),
              if (record.status == MchdStatus.registered && record.isExpiredByDate)
                const Text('Срок истёк', style: TextStyle(fontSize: 10, color: Color(0xFFB36A14)))
              else if (record.status == MchdStatus.registered && record.isUpcomingByDate)
                const Text('Ещё не действует', style: TextStyle(fontSize: 10, color: Color(0xFF62727F))),
            ]),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF8997A0)),
          ]),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 176, child: Text(label, style: const TextStyle(color: Color(0xFF62727F), fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(child: SelectableText(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});
  final String label;
  final _MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(40)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyMchd extends StatelessWidget {
  const _EmptyMchd({required this.hasAnyRecords, required this.onCreate, required this.onAddExisting});
  final bool hasAnyRecords;
  final VoidCallback onCreate;
  final VoidCallback onAddExisting;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E9ED))),
        child: Column(children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFEAF4F4), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.assignment_ind_outlined, size: 30, color: Color(0xFF176B69))),
          const SizedBox(height: 16),
          Text(hasAnyRecords ? 'По заданным условиям ничего не найдено' : 'Реестр МЧД пока пуст', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text('Создайте черновик или внесите реквизиты ранее оформленной доверенности.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF62727F))),
          if (!hasAnyRecords) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              OutlinedButton.icon(onPressed: onAddExisting, icon: const Icon(Icons.playlist_add), label: const Text('Добавить существующую')),
              FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Создать черновик')),
            ]),
          ],
        ]),
      );
}

enum _MetricTone { neutral, blue, green, orange }

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.tone});
  final String label;
  final String value;
  final IconData icon;
  final _MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(tone);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E9ED))),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF62727F))),
        ])),
      ]),
    );
  }
}

_MetricTone _statusTone(MchdStatus status) {
  switch (status) {
    case MchdStatus.draft:
    case MchdStatus.readyForSignature:
      return _MetricTone.blue;
    case MchdStatus.registered:
    case MchdStatus.signed:
      return _MetricTone.green;
    case MchdStatus.needsReview:
    case MchdStatus.rejected:
    case MchdStatus.expired:
      return _MetricTone.orange;
    case MchdStatus.submitted:
    case MchdStatus.revocationRequested:
      return _MetricTone.neutral;
    case MchdStatus.revoked:
      return _MetricTone.orange;
  }
}

Color _toneColor(_MetricTone tone) {
  switch (tone) {
    case _MetricTone.neutral:
      return const Color(0xFF62727F);
    case _MetricTone.blue:
      return const Color(0xFF4466A6);
    case _MetricTone.green:
      return const Color(0xFF287A58);
    case _MetricTone.orange:
      return const Color(0xFFB36A14);
  }
}
