import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../domain/models/eln_record.dart';
import '../../domain/repositories/eln_repository.dart';
import '../../domain/validation/eln_validator.dart';
import '../shared/app_banner.dart';

class ElnEditorScreen extends StatefulWidget {
  const ElnEditorScreen({super.key, required this.repository, this.initialRecord});

  final ElnRepository repository;
  final ElnRecord? initialRecord;

  @override
  State<ElnEditorScreen> createState() => _ElnEditorScreenState();
}

class _ElnEditorScreenState extends State<ElnEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final String _id;
  late final TextEditingController _lnNumber;
  late final TextEditingController _snils;
  late final TextEditingController _surname;
  late final TextEditingController _name;
  late final TextEditingController _patronymic;
  late final TextEditingController _birthDate;
  late final TextEditingController _issueDate;
  late final TextEditingController _previousLnNumber;
  late final TextEditingController _icd10;
  late final TextEditingController _clinicName;
  late final TextEditingController _clinicAddress;
  late final TextEditingController _clinicOgrn;
  late final TextEditingController _clinicId;
  late final TextEditingController _openingDoctor;
  late final TextEditingController _workStartDate;
  late final TextEditingController _otherCode;
  late final TextEditingController _otherDate;
  late final TextEditingController _hospitalStart;
  late final TextEditingController _hospitalEnd;
  late final TextEditingController _breachCode;
  late final TextEditingController _breachDate;
  late final TextEditingController _mseDirection;
  late final TextEditingController _mseRegistration;
  late final TextEditingController _mseExamination;
  late final TextEditingController _disabilityGroup;
  late final TextEditingController _carePersonSnils;
  late final TextEditingController _carePersonName;
  late final TextEditingController _carePersonBirthDate;
  late final TextEditingController _careRelationship;
  late final TextEditingController _carePeriodStart;
  late final TextEditingController _carePeriodEnd;
  late final TextEditingController _careDiagnosis;
  late final TextEditingController _careTreatmentType;

  final List<_PeriodControllers> _periods = <_PeriodControllers>[];
  String? _genderCode;
  String _reasonCode = '01';
  late final TextEditingController _additionalReasonCodeController;
  bool _isPrimary = true;
  bool _isDuplicate = false;
  bool _unconditional = false;
  bool _saving = false;

  ElnRecord? get _initial => widget.initialRecord;

  @override
  void initState() {
    super.initState();
    final item = _initial;
    _id = item?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _lnNumber = TextEditingController(text: item?.lnNumber ?? '');
    _snils = TextEditingController(text: item?.snils ?? '');
    _surname = TextEditingController(text: item?.surname ?? '');
    _name = TextEditingController(text: item?.name ?? '');
    _patronymic = TextEditingController(text: item?.patronymic ?? '');
    _birthDate = TextEditingController(text: formatDate(item?.birthDate).replaceAll('Не указана', ''));
    _issueDate = TextEditingController(text: item == null ? formatDate(DateTime.now()) : formatDate(item.issueDate).replaceAll('Не указана', ''));
    _previousLnNumber = TextEditingController(text: item?.previousLnNumber ?? '');
    _icd10 = TextEditingController(text: item?.icd10Code ?? '');
    _clinicName = TextEditingController(text: item?.clinicName ?? '');
    _clinicAddress = TextEditingController(text: item?.clinicAddress ?? '');
    _clinicOgrn = TextEditingController(text: item?.clinicOgrn ?? '');
    _clinicId = TextEditingController(text: item?.clinicId ?? '');
    _openingDoctor = TextEditingController(text: item?.openingDoctorName ?? '');
    _workStartDate = TextEditingController(text: formatDate(item?.workStartDate).replaceAll('Не указана', ''));
    _otherCode = TextEditingController(text: item?.otherResultCode ?? '');
    _otherDate = TextEditingController(text: formatDate(item?.otherResultDate).replaceAll('Не указана', ''));
    _hospitalStart = TextEditingController(text: formatDate(item?.hospitalStartDate).replaceAll('Не указана', ''));
    _hospitalEnd = TextEditingController(text: formatDate(item?.hospitalEndDate).replaceAll('Не указана', ''));
    _breachCode = TextEditingController(text: item?.breachCode ?? '');
    _breachDate = TextEditingController(text: formatDate(item?.breachDate).replaceAll('Не указана', ''));
    _mseDirection = TextEditingController(text: formatDate(item?.mseDirectionDate).replaceAll('Не указана', ''));
    _mseRegistration = TextEditingController(text: formatDate(item?.mseRegistrationDate).replaceAll('Не указана', ''));
    _mseExamination = TextEditingController(text: formatDate(item?.mseExaminationDate).replaceAll('Не указана', ''));
    _disabilityGroup = TextEditingController(text: item?.disabilityGroupCode ?? '');
    _carePersonSnils = TextEditingController(text: item?.carePersonSnils ?? '');
    _carePersonName = TextEditingController(text: item?.carePersonName ?? '');
    _carePersonBirthDate = TextEditingController(text: formatDate(item?.carePersonBirthDate).replaceAll('Не указана', ''));
    _careRelationship = TextEditingController(text: item?.careRelationshipCode ?? '');
    _carePeriodStart = TextEditingController(text: formatDate(item?.carePeriodStart).replaceAll('Не указана', ''));
    _carePeriodEnd = TextEditingController(text: formatDate(item?.carePeriodEnd).replaceAll('Не указана', ''));
    _careDiagnosis = TextEditingController(text: item?.careDiagnosisCode ?? '');
    _careTreatmentType = TextEditingController(text: item?.careTreatmentType ?? '');
    _genderCode = item?.genderCode;
    _reasonCode = item?.reasonCode ?? '01';
    _additionalReasonCodeController = TextEditingController(text: item?.additionalReasonCode ?? '');
    _isPrimary = item?.isPrimary ?? true;
    _isDuplicate = item?.isDuplicate ?? false;
    _unconditional = item?.unconditionalConfirmation ?? false;

    if (item != null && item.treatmentPeriods.isNotEmpty) {
      for (final period in item.treatmentPeriods) {
        _periods.add(_PeriodControllers.fromModel(period));
      }
    } else {
      _periods.add(_PeriodControllers());
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _lnNumber, _snils, _surname, _name, _patronymic, _birthDate, _issueDate,
      _previousLnNumber, _icd10, _clinicName, _clinicAddress, _clinicOgrn,
      _clinicId, _openingDoctor, _workStartDate, _otherCode, _otherDate,
      _hospitalStart, _hospitalEnd, _breachCode, _breachDate, _mseDirection,
      _mseRegistration, _mseExamination, _disabilityGroup, _carePersonSnils,
      _carePersonName, _carePersonBirthDate, _careRelationship, _carePeriodStart,
      _carePeriodEnd, _careDiagnosis, _careTreatmentType, _additionalReasonCodeController,
    ]) {
      controller.dispose();
    }
    for (final period in _periods) {
      period.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final current = parseRuDate(controller.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      helpText: 'Выберите дату',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );
    if (selected != null) controller.text = formatDate(selected);
  }

  Widget _dateField(String label, TextEditingController controller, {bool required = false}) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickDate(controller),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) return 'Заполните поле';
        if (value != null && value.trim().isNotEmpty && parseRuDate(value) == null) return 'Формат даты: ДД.ММ.ГГГГ';
        return null;
      },
      decoration: InputDecoration(labelText: label, hintText: 'ДД.ММ.ГГГГ', suffixIcon: const Icon(Icons.calendar_month_outlined)),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool required = false,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? extraValidator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) return 'Заполните поле';
        return extraValidator?.call(value);
      },
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  ElnRecord _buildRecord() {
    final old = _initial;
    return ElnRecord(
      id: _id,
      lnNumber: _lnNumber.text.trim(),
      snils: _snils.text.trim(),
      surname: _surname.text.trim(),
      name: _name.text.trim(),
      patronymic: _patronymic.text.trim(),
      birthDate: parseRuDate(_birthDate.text),
      genderCode: _genderCode ?? '',
      isPrimary: _isPrimary,
      isDuplicate: _isDuplicate,
      previousLnNumber: _previousLnNumber.text.trim(),
      issueDate: parseRuDate(_issueDate.text),
      reasonCode: _reasonCode,
      additionalReasonCode: _additionalReasonCodeController.text.trim(),
      icd10Code: _icd10.text.trim().toUpperCase(),
      clinicName: _clinicName.text.trim(),
      clinicAddress: _clinicAddress.text.trim(),
      clinicOgrn: _clinicOgrn.text.trim(),
      clinicId: _clinicId.text.trim(),
      openingDoctorName: _openingDoctor.text.trim(),
      treatmentPeriods: _periods.map((period) => period.toModel()).toList(),
      workStartDate: parseRuDate(_workStartDate.text),
      otherResultCode: _otherCode.text.trim(),
      otherResultDate: parseRuDate(_otherDate.text),
      hospitalStartDate: parseRuDate(_hospitalStart.text),
      hospitalEndDate: parseRuDate(_hospitalEnd.text),
      breachCode: _breachCode.text.trim(),
      breachDate: parseRuDate(_breachDate.text),
      mseDirectionDate: parseRuDate(_mseDirection.text),
      mseRegistrationDate: parseRuDate(_mseRegistration.text),
      mseExaminationDate: parseRuDate(_mseExamination.text),
      disabilityGroupCode: _disabilityGroup.text.trim(),
      carePersonSnils: _carePersonSnils.text.trim(),
      carePersonName: _carePersonName.text.trim(),
      carePersonBirthDate: parseRuDate(_carePersonBirthDate.text),
      careRelationshipCode: _careRelationship.text.trim(),
      carePeriodStart: parseRuDate(_carePeriodStart.text),
      carePeriodEnd: parseRuDate(_carePeriodEnd.text),
      careDiagnosisCode: _careDiagnosis.text.trim().toUpperCase(),
      careTreatmentType: _careTreatmentType.text.trim(),
      unconditionalConfirmation: _unconditional,
      writtenAgreementFlag: true,
      sfrStateCode: old?.sfrStateCode ?? '',
      sfrHash: old?.sfrHash ?? '',
      localStatus: LocalElnStatus.draft,
      createdAt: old?.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      await widget.repository.saveDraft(_buildRecord());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Черновик сохранён в памяти приложения. В СФР ничего не отправлено.')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _checkFields() async {
    final record = _buildRecord();
    final issues = ElnValidator.validateForOpening(record, requireAllocatedNumber: false);
    final controlsValid = _formKey.currentState!.validate();
    final allValid = issues.isEmpty && controlsValid;
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(allValid ? 'Базовые проверки пройдены' : 'Найдены замечания: ${issues.length + (controlsValid ? 0 : 1)}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: allValid
                ? const Text('Локальные базовые проверки пройдены. Это не означает, что ЭЛН соответствует полному ФЛК СФР или готов к отправке: номер ЭЛН, электронные подписи и проверка XML пока не подключены.')
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (!controlsValid)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 9),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.error_outline, size: 18, color: Color(0xFFB45B53)),
                          SizedBox(width: 8),
                          Expanded(child: Text('Есть незаполненные поля или ошибки формата. Посмотрите поля, выделенные под формой.')),
                        ]),
                      ),
                    ...issues.map((issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.error_outline, size: 18, color: Color(0xFFB45B53)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(issue.message)),
                      ]),
                    )),
                  ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Закрыть'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_initial == null ? 'Новый черновик ЭЛН' : 'Редактирование черновика'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Назад', onPressed: () => Navigator.of(context).pop()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          children: [
            const AppBanner(
              title: 'Черновик не является официальным ЭЛН',
              message: 'Номер должен быть запрошен у СФР. Перед отправкой потребуются УКЭП МО, подпись врача, при необходимости подпись председателя ВК, шифрование XML и ГОСТ TLS. Сейчас эти действия не выполняются.',
              warning: true,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              number: '01',
              title: 'Данные ЭЛН',
              subtitle: 'Номер и тип листка будут окончательно подтверждены при взаимодействии с СФР.',
              children: [
                _responsiveFields(context, [
                  _textField('Номер ЭЛН', _lnNumber, hint: 'Будет получен через getNewLNNum', readOnly: true),
                  DropdownButtonFormField<bool>(
                    value: _isPrimary,
                    decoration: const InputDecoration(labelText: 'Тип листка'),
                    items: const [DropdownMenuItem(value: true, child: Text('Первичный')), DropdownMenuItem(value: false, child: Text('Продолжение'))],
                    onChanged: (value) => setState(() => _isPrimary = value ?? true),
                  ),
                  DropdownButtonFormField<bool>(
                    value: _isDuplicate,
                    decoration: const InputDecoration(labelText: 'Экземпляр'),
                    items: const [DropdownMenuItem(value: false, child: Text('Оригинал')), DropdownMenuItem(value: true, child: Text('Дубликат'))],
                    onChanged: (value) => setState(() => _isDuplicate = value ?? false),
                  ),
                  if (!_isPrimary) _textField('Номер предыдущего ЭЛН', _previousLnNumber, required: true),
                  _dateField('Дата выдачи', _issueDate, required: true),
                ]),
              ],
            ),
            _SectionCard(
              number: '02',
              title: 'Пациент',
              subtitle: 'СНИЛС и дата рождения будут сверяться с данными СФР.',
              children: [
                _responsiveFields(context, [
                  _textField('СНИЛС', _snils, required: true, hint: '11 цифр', keyboardType: TextInputType.number),
                  _textField('Фамилия', _surname, required: true),
                  _textField('Имя', _name, required: true),
                  _textField('Отчество', _patronymic),
                  _dateField('Дата рождения', _birthDate, required: true),
                  DropdownButtonFormField<String>(
                    value: _genderCode,
                    decoration: const InputDecoration(labelText: 'Пол'),
                    validator: (value) => value == null ? 'Выберите пол' : null,
                    items: const [DropdownMenuItem(value: '0', child: Text('Мужской')), DropdownMenuItem(value: '1', child: Text('Женский'))],
                    onChanged: (value) => setState(() => _genderCode = value),
                  ),
                ]),
              ],
            ),
            _SectionCard(
              number: '03',
              title: 'Медицинские сведения',
              subtitle: 'Причина нетрудоспособности и МКБ-10 выбираются врачом по медицинским документам.',
              children: [
                _responsiveFields(context, [
                  DropdownButtonFormField<String>(
                    value: _reasonCode,
                    decoration: const InputDecoration(labelText: 'Причина нетрудоспособности'),
                    items: const [
                      DropdownMenuItem(value: '01', child: Text('01 · Заболевание')),
                      DropdownMenuItem(value: '02', child: Text('02 · Травма')),
                      DropdownMenuItem(value: '03', child: Text('03 · Карантин')),
                      DropdownMenuItem(value: '05', child: Text('05 · Беременность и роды')),
                      DropdownMenuItem(value: '06', child: Text('06 · Протезирование в стационаре')),
                      DropdownMenuItem(value: '08', child: Text('08 · Долечивание в санатории')),
                      DropdownMenuItem(value: '09', child: Text('09 · Уход за членом семьи')),
                      DropdownMenuItem(value: '10', child: Text('10 · Иное состояние')),
                      DropdownMenuItem(value: '11', child: Text('11 · Социально значимое заболевание')),
                      DropdownMenuItem(value: '12', child: Text('12 · Заболевание ребёнка до 7 лет')),
                      DropdownMenuItem(value: '13', child: Text('13 · Ребёнок-инвалид')),
                      DropdownMenuItem(value: '14', child: Text('14 · Поствакцинальное осложнение / онкология у ребёнка')),
                      DropdownMenuItem(value: '15', child: Text('15 · ВИЧ-инфицированный ребёнок')),
                    ],
                    onChanged: (value) => setState(() => _reasonCode = value ?? '01'),
                  ),
                  _textField('Дополнительный код причины', _additionalReasonCodeController, hint: 'Например 017, 018, 019, 020, 021'),
                  _textField('Диагноз по МКБ-10', _icd10, required: true, hint: 'Например J06.9'),
                  _textField('Врач, открывающий ЭЛН', _openingDoctor, required: true, hint: 'Фамилия И. О.'),
                ]),
                if (_reasonCode == '09') ...[
                  const SizedBox(height: 16),
                  const Text('Сведения по уходу за членом семьи', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _responsiveFields(context, [
                    _textField('ФИО члена семьи', _carePersonName, required: true),
                    _textField('СНИЛС члена семьи', _carePersonSnils, required: true, keyboardType: TextInputType.number),
                    _dateField('Дата рождения члена семьи', _carePersonBirthDate, required: true),
                    _textField('Код родственной связи', _careRelationship, required: true, hint: '38 мать, 39 отец, 40 опекун, 41 попечитель, 42 иной родственник'),
                    _dateField('Начало периода ухода', _carePeriodStart, required: true),
                    _dateField('Окончание периода ухода', _carePeriodEnd, required: true),
                    _textField('Диагноз по уходу, МКБ-10', _careDiagnosis, required: true),
                    _textField('Условия медпомощи', _careTreatmentType, required: true, hint: 'Код справочника СФР'),
                  ]),
                ],
              ],
            ),
            _SectionCard(
              number: '04',
              title: 'Периоды освобождения от работы',
              subtitle: 'Для открытия нужен первый период; при продлении будут добавляться следующие периоды.',
              children: [
                ...List.generate(_periods.length, (index) => _periodEditor(index)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _periods.length >= 20 ? null : () => setState(() => _periods.add(_PeriodControllers())),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить период'),
                  ),
                ),
              ],
            ),
            _SectionCard(
              number: '05',
              title: 'Медицинская организация',
              subtitle: 'Реквизиты должны совпадать с реестром МО в СФР и данными сертификата подписи.',
              children: [
                _responsiveFields(context, [
                  _textField('Наименование МО', _clinicName, required: true),
                  _textField('ОГРН МО', _clinicOgrn, required: true, keyboardType: TextInputType.number),
                  _textField('Адрес МО', _clinicAddress, required: true, maxLines: 2),
                  _textField('Внутренний код МО (необязательно)', _clinicId),
                ]),
              ],
            ),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E9ED))),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E9ED))),
              title: const Text('Дополнительные сведения: стационар, нарушения режима, МСЭ и закрытие'),
              subtitle: const Text('Поля для последующих этапов и статусов ЭЛН'),
              children: [
                _responsiveFields(context, [
                  _dateField('Стационар: дата поступления', _hospitalStart),
                  _dateField('Стационар: дата выписки', _hospitalEnd),
                  _textField('Код нарушения режима', _breachCode, hint: '23–28 по справочнику СФР'),
                  _dateField('Дата нарушения режима', _breachDate),
                  _dateField('Дата направления на МСЭ', _mseDirection),
                  _dateField('Дата регистрации документов МСЭ', _mseRegistration),
                  _dateField('Дата освидетельствования МСЭ', _mseExamination),
                  _textField('Код группы инвалидности / утраты трудоспособности', _disabilityGroup),
                  _dateField('Приступить к работе с', _workStartDate),
                  _textField('Результат «Иное»: код', _otherCode, hint: 'Код из справочника СФР'),
                  _dateField('Результат «Иное»: дата', _otherDate),
                ]),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _unconditional,
                  onChanged: (value) => setState(() => _unconditional = value ?? false),
                  title: const Text('Безусловное подтверждение данных пациента'),
                  subtitle: const Text('Отмечать только при наличии законного основания и после сверки данных.'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: _saving ? null : _checkFields, child: const Text('Проверить поля')),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveDraft,
                  icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                  label: const Text('Сохранить черновик'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Все сведения сейчас существуют только в оперативной памяти и будут потеряны при закрытии приложения. Не вводите данные реальных пациентов в этот прототип.', textAlign: TextAlign.end, style: TextStyle(color: Color(0xFF8B5E10), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _periodEditor(int index) {
    final period = _periods[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E9ED))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Период ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
          if (_periods.length > 1) IconButton(tooltip: 'Удалить период', onPressed: () => setState(() { _periods.removeAt(index).dispose(); }), icon: const Icon(Icons.delete_outline, color: Color(0xFFB45B53))),
        ]),
        const SizedBox(height: 8),
        _responsiveFields(context, [
          _dateField('С какого числа', period.startDate, required: true),
          _dateField('По какое число', period.endDate, required: true),
          _textField('Должность врача', period.doctorPosition, required: true, hint: 'Например врач-терапевт'),
          _textField('ФИО врача', period.doctorName, required: true),
          _textField('ФИО председателя ВК', period.chairmanName, hint: 'Если требуется'),
        ]),
      ]),
    );
  }

  Widget _responsiveFields(BuildContext context, List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 850 ? 2 : 1;
      const gap = 12.0;
      final width = (constraints.maxWidth - (cols - 1) * gap) / cols;
      return Wrap(spacing: gap, runSpacing: 14, children: children.map((child) => SizedBox(width: width, child: child)).toList());
    });
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.number, required this.title, required this.subtitle, required this.children});
  final String number;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E9ED))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFEAF4F4), borderRadius: BorderRadius.circular(10)), child: Text(number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF176B69)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF62727F), height: 1.4))])),
          ]),
          const SizedBox(height: 18),
          ...children,
        ]),
      );
}

class _PeriodControllers {
  _PeriodControllers({DateTime? start, DateTime? end})
      : startDate = TextEditingController(text: start == null ? '' : formatDate(start)),
        endDate = TextEditingController(text: end == null ? '' : formatDate(end)),
        doctorPosition = TextEditingController(),
        doctorName = TextEditingController(),
        chairmanName = TextEditingController();

  factory _PeriodControllers.fromModel(TreatmentPeriod period) {
    final result = _PeriodControllers(start: period.startDate, end: period.endDate);
    result.doctorPosition.text = period.doctorPosition;
    result.doctorName.text = period.doctorName;
    result.chairmanName.text = period.commissionChairName;
    return result;
  }

  final TextEditingController startDate;
  final TextEditingController endDate;
  final TextEditingController doctorPosition;
  final TextEditingController doctorName;
  final TextEditingController chairmanName;

  TreatmentPeriod toModel() => TreatmentPeriod(
        startDate: parseRuDate(startDate.text),
        endDate: parseRuDate(endDate.text),
        doctorPosition: doctorPosition.text.trim(),
        doctorName: doctorName.text.trim(),
        commissionChairName: chairmanName.text.trim(),
      );

  void dispose() {
    startDate.dispose();
    endDate.dispose();
    doctorPosition.dispose();
    doctorName.dispose();
    chairmanName.dispose();
  }
}
