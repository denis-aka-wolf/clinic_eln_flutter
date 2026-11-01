import '../models/eln_record.dart';

class ValidationIssue {
  const ValidationIssue({required this.field, required this.message});
  final String field;
  final String message;
}

/// Базовые проверки клиента. Полный ФЛК СФР значительно шире и должен
/// дополняться правилами из приложенного файла «ФЛК_ЭЛН.xlsx».
class ElnValidator {
  static const reasonCodes = <String>{
    '01', '02', '03', '05', '06', '08', '09', '10', '11', '12', '13', '14', '15',
  };

  static List<ValidationIssue> validateForOpening(
    ElnRecord record, {
    bool requireAllocatedNumber = true,
  }) {
    final issues = <ValidationIssue>[];
    void required(String field, String value, String label) {
      if (value.trim().isEmpty) {
        issues.add(ValidationIssue(field: field, message: '$label обязательно для заполнения.'));
      }
    }

    if (requireAllocatedNumber) {
      required('lnNumber', record.lnNumber, 'Номер ЭЛН');
    }
    required('snils', record.snils, 'СНИЛС');
    required('surname', record.surname, 'Фамилия пациента');
    required('name', record.name, 'Имя пациента');
    required('clinicName', record.clinicName, 'Наименование медицинской организации');
    required('clinicAddress', record.clinicAddress, 'Адрес медицинской организации');
    required('clinicOgrn', record.clinicOgrn, 'ОГРН медицинской организации');
    required('icd10Code', record.icd10Code, 'Диагноз по МКБ-10');
    required('openingDoctorName', record.openingDoctorName, 'Врач, открывающий ЭЛН');

    if (!_isValidSnils(record.snils)) {
      issues.add(const ValidationIssue(
        field: 'snils',
        message: 'СНИЛС должен содержать 11 цифр и проходить проверку контрольного числа.',
      ));
    }
    if (record.birthDate == null) {
      issues.add(const ValidationIssue(field: 'birthDate', message: 'Укажите дату рождения.'));
    } else if (record.birthDate!.isAfter(DateTime.now())) {
      issues.add(const ValidationIssue(field: 'birthDate', message: 'Дата рождения не может быть в будущем.'));
    }
    if (!{'0', '1'}.contains(record.genderCode)) {
      issues.add(const ValidationIssue(field: 'genderCode', message: 'Выберите пол пациента.'));
    }
    if (record.additionalReasonCode.trim().isNotEmpty &&
        !{'017', '018', '019', '020', '021'}.contains(record.additionalReasonCode.trim())) {
      issues.add(const ValidationIssue(field: 'additionalReasonCode', message: 'Проверьте дополнительный код причины по справочнику СФР.'));
    }
    if (record.issueDate == null) {
      issues.add(const ValidationIssue(field: 'issueDate', message: 'Укажите дату выдачи ЭЛН.'));
    }
    if (!RegExp(r'^\d{13}$|^\d{15}$').hasMatch(record.clinicOgrn.trim())) {
      issues.add(const ValidationIssue(field: 'clinicOgrn', message: 'ОГРН/ОГРНИП должен содержать 13 или 15 цифр.'));
    }
    if (!reasonCodes.contains(record.reasonCode)) {
      issues.add(const ValidationIssue(field: 'reasonCode', message: 'Выберите допустимый код причины нетрудоспособности.'));
    }
    if (!RegExp(r'^[A-ZА-Я]\d{2}(?:\.\d{1,2})?$').hasMatch(record.icd10Code.trim().toUpperCase())) {
      issues.add(const ValidationIssue(field: 'icd10Code', message: 'Проверьте формат кода МКБ-10, например J06.9.'));
    }
    if (!record.isPrimary && record.previousLnNumber.trim().isEmpty) {
      issues.add(const ValidationIssue(field: 'previousLnNumber', message: 'Для продолжения укажите номер предыдущего ЭЛН.'));
    }
    if (record.treatmentPeriods.isEmpty) {
      issues.add(const ValidationIssue(field: 'treatmentPeriods', message: 'Добавьте хотя бы один период освобождения от работы.'));
    }
    for (var i = 0; i < record.treatmentPeriods.length; i++) {
      final period = record.treatmentPeriods[i];
      final prefix = 'Период ${i + 1}';
      if (period.startDate == null) {
        issues.add(ValidationIssue(field: 'period${i + 1}Start', message: '$prefix: укажите дату начала.'));
      }
      if (period.endDate == null) {
        issues.add(ValidationIssue(field: 'period${i + 1}End', message: '$prefix: укажите дату окончания.'));
      }
      if (period.startDate != null && period.endDate != null && period.endDate!.isBefore(period.startDate!)) {
        issues.add(ValidationIssue(field: 'period${i + 1}End', message: '$prefix: дата окончания раньше даты начала.'));
      }
      if (period.doctorPosition.trim().isEmpty) {
        issues.add(ValidationIssue(field: 'period${i + 1}DoctorPosition', message: '$prefix: укажите должность врача.'));
      }
      if (period.doctorName.trim().isEmpty) {
        issues.add(ValidationIssue(field: 'period${i + 1}DoctorName', message: '$prefix: укажите ФИО врача.'));
      }
    }
    if (record.hospitalStartDate != null && record.hospitalEndDate != null &&
        record.hospitalEndDate!.isBefore(record.hospitalStartDate!)) {
      issues.add(const ValidationIssue(field: 'hospitalEndDate', message: 'Дата выписки из стационара раньше даты поступления.'));
    }
    if (record.carePeriodStart != null && record.carePeriodEnd != null &&
        record.carePeriodEnd!.isBefore(record.carePeriodStart!)) {
      issues.add(const ValidationIssue(field: 'carePeriodEnd', message: 'Окончание периода ухода раньше его начала.'));
    }
    if (record.breachCode.isNotEmpty && record.breachDate == null) {
      issues.add(const ValidationIssue(field: 'breachDate', message: 'Для нарушения режима укажите дату.'));
    }
    if (record.breachDate != null && record.breachCode.isEmpty) {
      issues.add(const ValidationIssue(field: 'breachCode', message: 'Для даты нарушения режима укажите код.'));
    }
    if (record.reasonCode == '09') {
      if (!{'38', '39', '40', '41', '42'}.contains(record.careRelationshipCode.trim())) {
        issues.add(const ValidationIssue(field: 'careRelationshipCode', message: 'Укажите код родственной связи из справочника СФР (38–42).'));
      }
      required('carePersonName', record.carePersonName, 'ФИО члена семьи, за которым осуществляется уход');
      required('careRelationshipCode', record.careRelationshipCode, 'Родственная связь');
      if (!_isValidSnils(record.carePersonSnils)) {
        issues.add(const ValidationIssue(field: 'carePersonSnils', message: 'Для ухода проверьте СНИЛС члена семьи.'));
      }
      if (record.carePersonBirthDate == null) {
        issues.add(const ValidationIssue(field: 'carePersonBirthDate', message: 'Для ухода укажите дату рождения члена семьи.'));
      }
      if (record.carePeriodStart == null || record.carePeriodEnd == null) {
        issues.add(const ValidationIssue(field: 'carePeriodStart', message: 'Для ухода укажите период ухода.'));
      }
      required('careDiagnosisCode', record.careDiagnosisCode, 'Диагноз члена семьи по МКБ-10');
      required('careTreatmentType', record.careTreatmentType, 'Условия оказания медицинской помощи при уходе');
    }
    return issues;
  }

  static List<ValidationIssue> validateForClosing(ElnRecord record) {
    final issues = <ValidationIssue>[];
    if (record.workStartDate == null && record.otherResultCode.trim().isEmpty) {
      issues.add(const ValidationIssue(
        field: 'workStartDate',
        message: 'При закрытии ЭЛН заполните дату выхода на работу или код результата «Иное».',
      ));
    }
    if (record.otherResultCode.trim().isNotEmpty && record.otherResultDate == null) {
      issues.add(const ValidationIssue(field: 'otherResultDate', message: 'Для результата «Иное» укажите дату.'));
    }
    if (record.mseDirectionDate != null && record.workStartDate != null) {
      issues.add(const ValidationIssue(field: 'mseDirectionDate', message: 'Проверьте сведения: одновременно указаны направление на МСЭ и выход на работу.'));
    }
    return issues;
  }

  static bool _isValidSnils(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return false;
    final firstNine = digits.substring(0, 9);
    final givenControl = int.tryParse(digits.substring(9));
    if (givenControl == null) return false;
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += int.parse(firstNine[i]) * (9 - i);
    }
    var control = 0;
    if (sum < 100) {
      control = sum;
    } else if (sum == 100 || sum == 101) {
      control = 0;
    } else {
      control = sum % 101;
      if (control == 100) control = 0;
    }
    return control == givenControl;
  }
}
