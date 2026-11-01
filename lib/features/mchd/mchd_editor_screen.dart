import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../domain/models/mchd_record.dart';
import '../../domain/repositories/mchd_repository.dart';
import '../shared/app_banner.dart';

/// Создание локального черновика или ввод реквизитов уже существующей МЧД.
enum MchdEditorMode { createDraft, addExisting }

class MchdEditorScreen extends StatefulWidget {
  const MchdEditorScreen({
    super.key,
    required this.repository,
    required this.mode,
    this.initialRecord,
  });

  final MchdRepository repository;
  final MchdEditorMode mode;
  final MchdRecord? initialRecord;

  @override
  State<MchdEditorScreen> createState() => _MchdEditorScreenState();
}

class _MchdEditorScreenState extends State<MchdEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _principalName;
  late final TextEditingController _principalInn;
  late final TextEditingController _principalOgrn;
  late final TextEditingController _principalKpp;
  late final TextEditingController _representativeName;
  late final TextEditingController _representativeInn;
  late final TextEditingController _representativeSnils;
  late final TextEditingController _authorityCodes;
  late final TextEditingController _authorityDescription;
  late final TextEditingController _registryId;

  late DateTime _issuedAt;
  late DateTime _validFrom;
  late DateTime _validTo;
  bool _saving = false;

  bool get _isExisting => widget.mode == MchdEditorMode.addExisting;
  bool get _isEditingDraft => widget.initialRecord != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecord;
    final now = DateTime.now();
    _number = TextEditingController(text: initial?.number ?? '');
    _principalName = TextEditingController(text: initial?.principalName ?? '');
    _principalInn = TextEditingController(text: initial?.principalInn ?? '');
    _principalOgrn = TextEditingController(text: initial?.principalOgrn ?? '');
    _principalKpp = TextEditingController(text: initial?.principalKpp ?? '');
    _representativeName = TextEditingController(text: initial?.representativeName ?? '');
    _representativeInn = TextEditingController(text: initial?.representativeInn ?? '');
    _representativeSnils = TextEditingController(text: initial?.representativeSnils ?? '');
    _authorityCodes = TextEditingController(text: initial?.authorityCodes ?? '');
    _authorityDescription = TextEditingController(text: initial?.authorityDescription ?? '');
    _registryId = TextEditingController(text: initial?.registryId ?? '');
    _issuedAt = initial?.issuedAt ?? now;
    _validFrom = initial?.validFrom ?? DateTime(now.year, now.month, now.day);
    _validTo = initial?.validTo ?? DateTime(now.year + 1, now.month, now.day);
  }

  @override
  void dispose() {
    _number.dispose();
    _principalName.dispose();
    _principalInn.dispose();
    _principalOgrn.dispose();
    _principalKpp.dispose();
    _representativeName.dispose();
    _representativeInn.dispose();
    _representativeSnils.dispose();
    _authorityCodes.dispose();
    _authorityDescription.dispose();
    _registryId.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required String label, required DateTime current, required ValueChanged<DateTime> onPicked}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: label,
      locale: const Locale('ru'),
    );
    if (picked != null && mounted) setState(() => onPicked(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_validTo.isBefore(_validFrom)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Дата окончания не может быть раньше даты начала.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final initial = widget.initialRecord;
      final record = MchdRecord(
        id: initial?.id ?? 'mchd-${now.microsecondsSinceEpoch}',
        number: _number.text.trim(),
        principalName: _principalName.text.trim(),
        principalInn: _principalInn.text.trim(),
        principalOgrn: _principalOgrn.text.trim(),
        principalKpp: _principalKpp.text.trim(),
        representativeName: _representativeName.text.trim(),
        representativeInn: _representativeInn.text.trim(),
        representativeSnils: _representativeSnils.text.trim(),
        issuedAt: _issuedAt,
        validFrom: _validFrom,
        validTo: _validTo,
        authorityCodes: _authorityCodes.text.trim(),
        authorityDescription: _authorityDescription.text.trim(),
        status: _isExisting ? MchdStatus.needsReview : MchdStatus.draft,
        registryId: _registryId.text.trim(),
        sourceNote: _isExisting
            ? 'Реквизиты внесены вручную. XML, подпись и регистрация СФР не проверены.'
            : 'Локальный черновик. XML по схеме СФР не сформирован, подпись не создана.',
        createdAt: initial?.createdAt ?? now,
        updatedAt: now,
      );
      if (_isExisting) {
        await widget.repository.addExistingForReview(record);
      } else {
        await widget.repository.save(record);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isExisting ? 'Реквизиты добавлены в локальный реестр.' : 'Черновик МЧД сохранён локально.'),
      ));
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isExisting ? 'Добавить существующую МЧД' : (_isEditingDraft ? 'Редактирование черновика МЧД' : 'Новая МЧД');
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(tooltip: 'Назад', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
          children: [
            const AppBanner(
              title: 'МЧД для СФР, а не универсальный конструктор доверенностей',
              message: 'На этом этапе мы сохраняем только реквизиты. Для юридически значимой МЧД нужно сформировать XML по действующим XSD СФР, подписать его УКЭП доверителя и зарегистрировать через сервис СЭДО. Код полномочия необходимо выбирать из актуального классификатора СФР. МЧД не заменяет предусмотренную правилами ЭЛН подпись врача на медицинских блоках.',
            ),
            const SizedBox(height: 20),
            if (_isExisting) ...[
              _SectionTitle(title: 'Реквизиты уже оформленной доверенности', subtitle: 'Внесите сведения для внутреннего контроля. Приложение пока не сверяет их с реестром СФР.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _number,
                decoration: const InputDecoration(labelText: 'Номер / идентификатор МЧД', prefixIcon: Icon(Icons.tag)),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Укажите номер доверенности' : null,
              ),
              const SizedBox(height: 12),
            ] else ...[
              _SectionTitle(title: 'Новая доверенность', subtitle: 'Номер и статус регистрации должны быть получены из ответа СФР после подключения интеграции.'),
              const SizedBox(height: 12),
            ],
            _SectionTitle(title: 'Доверитель · медицинская организация', subtitle: 'Заполняйте по юридическим реквизитам организации.'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _principalName,
              decoration: const InputDecoration(labelText: 'Полное наименование МО *', prefixIcon: Icon(Icons.local_hospital_outlined)),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Укажите наименование организации' : null,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 780;
              final inn = TextFormField(
                controller: _principalInn,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ИНН организации *'),
                validator: (value) => !_digitsLength(value, const {10}) ? 'ИНН организации должен содержать 10 цифр' : null,
              );
              final ogrn = TextFormField(
                controller: _principalOgrn,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ОГРН *'),
                validator: (value) => !_digitsLength(value, const {13}) ? 'ОГРН должен содержать 13 цифр' : null,
              );
              final kpp = TextFormField(
                controller: _principalKpp,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'КПП'),
                validator: (value) => value == null || value.trim().isEmpty || _digitsLength(value, const {9}) ? null : 'КПП должен содержать 9 цифр',
              );
              if (wide) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: inn), const SizedBox(width: 12), Expanded(child: ogrn), const SizedBox(width: 12), Expanded(child: kpp)]);
              }
              return Column(children: [inn, const SizedBox(height: 12), ogrn, const SizedBox(height: 12), kpp]);
            }),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Представитель', subtitle: 'Сотрудник или иной представитель, которому выданы полномочия.'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _representativeName,
              decoration: const InputDecoration(labelText: 'ФИО представителя *', prefixIcon: Icon(Icons.person_outline)),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Укажите ФИО представителя' : null,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 780;
              final inn = TextFormField(
                controller: _representativeInn,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ИНН представителя'),
                validator: (value) => value == null || value.trim().isEmpty || _digitsLength(value, const {10, 12}) ? null : 'ИНН должен содержать 10 или 12 цифр',
              );
              final snils = TextFormField(
                controller: _representativeSnils,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'СНИЛС представителя'),
                validator: (value) => value == null || value.trim().isEmpty || _digitsLength(value, const {11}) ? null : 'СНИЛС должен содержать 11 цифр',
              );
              if (wide) return Row(children: [Expanded(child: inn), const SizedBox(width: 12), Expanded(child: snils)]);
              return Column(children: [inn, const SizedBox(height: 12), snils]);
            }),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Срок и полномочия', subtitle: 'Финальные ограничения по полномочиям будут проверяться по действующему классификатору СФР.'),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 780;
              final dateFrom = _DateField(label: 'Дата начала действия', date: _validFrom, onTap: () => _pickDate(label: 'Дата начала действия', current: _validFrom, onPicked: (date) => _validFrom = date));
              final dateTo = _DateField(label: 'Дата окончания действия', date: _validTo, onTap: () => _pickDate(label: 'Дата окончания действия', current: _validTo, onPicked: (date) => _validTo = date));
              final issued = _DateField(label: 'Дата выдачи', date: _issuedAt, onTap: () => _pickDate(label: 'Дата выдачи', current: _issuedAt, onPicked: (date) => _issuedAt = date));
              if (wide) {
                return Row(children: [Expanded(child: issued), const SizedBox(width: 12), Expanded(child: dateFrom), const SizedBox(width: 12), Expanded(child: dateTo)]);
              }
              return Column(children: [issued, const SizedBox(height: 10), dateFrom, const SizedBox(height: 10), dateTo]);
            }),
            const SizedBox(height: 12),
            TextFormField(
              controller: _authorityCodes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Коды полномочий СФР',
                hintText: 'Один код на строку',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _authorityDescription,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Описание полномочий', hintText: 'Кратко укажите, какие действия сможет выполнять представитель', alignLabelWithHint: true),
            ),
            if (_isExisting) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _registryId,
                decoration: const InputDecoration(labelText: 'Идентификатор в реестре СФР (если известен)', prefixIcon: Icon(Icons.numbers_outlined)),
              ),
            ],
            const SizedBox(height: 18),
            const Text('Проверки здесь предварительные. Правила заполнения, обязательные поля, формат XML и допустимые полномочия должны быть подтверждены схемами и классификатором СФР.', style: TextStyle(color: Color(0xFF62727F), fontSize: 12)),
            const SizedBox(height: 22),
            Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.end, children: [
              OutlinedButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Отмена')),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: Icon(_isExisting ? Icons.playlist_add_check : Icons.save_outlined),
                label: Text(_saving ? 'Сохранение…' : (_isExisting ? 'Добавить в локальный реестр' : 'Сохранить черновик')),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

bool _digitsLength(String? value, Set<int> allowedLengths) {
  if (value == null) return false;
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits == value.trim() && allowedLengths.contains(digits.length);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF62727F))),
      ]);
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.calendar_today_outlined)),
          child: Text(formatDate(date), style: const TextStyle(fontSize: 14)),
        ),
      );
}
