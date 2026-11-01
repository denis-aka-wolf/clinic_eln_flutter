/// Локальный статус карточки в нашей МИС. Он не заменяет статус ЭЛН в СФР.
enum LocalElnStatus {
  draft('Черновик'),
  needsReview('Требует проверки'),
  readyForSignature('Готов к подписанию'),
  queued('Ожидает отправки'),
  sent('Отправлен в СФР'),
  accepted('Принят СФР'),
  rejected('Отклонён СФР');

  const LocalElnStatus(this.title);
  final String title;
}

class SfrElnState {
  const SfrElnState(this.code, this.title);
  final String code;
  final String title;

  static const opened = SfrElnState('010', 'Открыт');
  static const extended = SfrElnState('020', 'Продлён');
  static const closed = SfrElnState('030', 'Закрыт');
  static const sentToMse = SfrElnState('040', 'Направлен на МСЭ');
  static const completedMse = SfrElnState('050', 'Дополнен данными МСЭ');
  static const insurerCompleted = SfrElnState('060', 'Заполнен страхователем');
  static const insurerRegistry = SfrElnState('070', 'Заполнен страхователем (реестр)');
  static const paid = SfrElnState('080', 'Пособие выплачено');
  static const disabled = SfrElnState('090', 'Действия прекращены');
  static const noticeToClinic = SfrElnState('091', 'Направлено извещение МО');

  static const all = <SfrElnState>[
    opened,
    extended,
    closed,
    sentToMse,
    completedMse,
    insurerCompleted,
    insurerRegistry,
    paid,
    disabled,
    noticeToClinic,
  ];

  static SfrElnState? fromCode(String? code) {
    for (final state in all) {
      if (state.code == code) return state;
    }
    return null;
  }
}

class TreatmentPeriod {
  const TreatmentPeriod({
    this.startDate,
    this.endDate,
    this.doctorPosition = '',
    this.doctorName = '',
    this.commissionChairName = '',
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String doctorPosition;
  final String doctorName;
  final String commissionChairName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'doctorPosition': doctorPosition,
        'doctorName': doctorName,
        'commissionChairName': commissionChairName,
      };

  factory TreatmentPeriod.fromJson(Map<String, dynamic> json) => TreatmentPeriod(
        startDate: _parseElnDate(json['startDate']),
        endDate: _parseElnDate(json['endDate']),
        doctorPosition: _jsonText(json['doctorPosition']),
        doctorName: _jsonText(json['doctorName']),
        commissionChairName: _jsonText(json['commissionChairName']),
      );
}

DateTime? _parseElnDate(dynamic value) =>
    value == null || value.toString().isEmpty ? null : DateTime.tryParse(value.toString());
String _jsonText(dynamic value, [String fallback = '']) => value == null ? fallback : value.toString();

/// Черновая доменная модель. Не является готовым DTO для SOAP: маппинг XML
/// должен быть сделан строго по WSDL/XSD СФР и проверен на тестовом контуре.
class ElnRecord {
  ElnRecord({
    required this.id,
    this.lnNumber = '',
    this.snils = '',
    this.surname = '',
    this.name = '',
    this.patronymic = '',
    this.birthDate,
    this.genderCode = '0',
    this.isPrimary = true,
    this.isDuplicate = false,
    this.previousLnNumber = '',
    this.issueDate,
    this.reasonCode = '01',
    this.additionalReasonCode = '',
    this.icd10Code = '',
    this.clinicName = '',
    this.clinicAddress = '',
    this.clinicOgrn = '',
    this.clinicId = '',
    this.openingDoctorName = '',
    List<TreatmentPeriod>? treatmentPeriods,
    this.workStartDate,
    this.otherResultCode = '',
    this.otherResultDate,
    this.hospitalStartDate,
    this.hospitalEndDate,
    this.breachCode = '',
    this.breachDate,
    this.mseDirectionDate,
    this.mseRegistrationDate,
    this.mseExaminationDate,
    this.disabilityGroupCode = '',
    this.carePersonSnils = '',
    this.carePersonName = '',
    this.carePersonBirthDate,
    this.careRelationshipCode = '',
    this.carePeriodStart,
    this.carePeriodEnd,
    this.careDiagnosisCode = '',
    this.careTreatmentType = '',
    this.unconditionalConfirmation = false,
    this.writtenAgreementFlag = true,
    this.sfrStateCode = '',
    this.sfrHash = '',
    this.localStatus = LocalElnStatus.draft,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : treatmentPeriods = treatmentPeriods ?? <TreatmentPeriod>[],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String lnNumber;
  final String snils;
  final String surname;
  final String name;
  final String patronymic;
  final DateTime? birthDate;
  /// По спецификации МО ЭЛН 2.3: 0 = мужской, 1 = женский.
  final String genderCode;
  final bool isPrimary;
  final bool isDuplicate;
  final String previousLnNumber;
  final DateTime? issueDate;
  final String reasonCode;
  final String additionalReasonCode;
  final String icd10Code;
  final String clinicName;
  final String clinicAddress;
  final String clinicOgrn;
  final String clinicId;
  final String openingDoctorName;
  final List<TreatmentPeriod> treatmentPeriods;
  final DateTime? workStartDate;
  final String otherResultCode;
  final DateTime? otherResultDate;
  final DateTime? hospitalStartDate;
  final DateTime? hospitalEndDate;
  final String breachCode;
  final DateTime? breachDate;
  final DateTime? mseDirectionDate;
  final DateTime? mseRegistrationDate;
  final DateTime? mseExaminationDate;
  final String disabilityGroupCode;
  final String carePersonSnils;
  final String carePersonName;
  final DateTime? carePersonBirthDate;
  final String careRelationshipCode;
  final DateTime? carePeriodStart;
  final DateTime? carePeriodEnd;
  final String careDiagnosisCode;
  final String careTreatmentType;
  final bool unconditionalConfirmation;
  final bool writtenAgreementFlag;
  final String sfrStateCode;
  final String sfrHash;
  final LocalElnStatus localStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get patientFullName =>
      [surname, name, patronymic].where((part) => part.trim().isNotEmpty).join(' ');

  SfrElnState? get sfrState => SfrElnState.fromCode(sfrStateCode);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'lnNumber': lnNumber,
        'snils': snils,
        'surname': surname,
        'name': name,
        'patronymic': patronymic,
        'birthDate': birthDate?.toIso8601String(),
        'genderCode': genderCode,
        'isPrimary': isPrimary,
        'isDuplicate': isDuplicate,
        'previousLnNumber': previousLnNumber,
        'issueDate': issueDate?.toIso8601String(),
        'reasonCode': reasonCode,
        'additionalReasonCode': additionalReasonCode,
        'icd10Code': icd10Code,
        'clinicName': clinicName,
        'clinicAddress': clinicAddress,
        'clinicOgrn': clinicOgrn,
        'clinicId': clinicId,
        'openingDoctorName': openingDoctorName,
        'treatmentPeriods': treatmentPeriods.map((item) => item.toJson()).toList(),
        'workStartDate': workStartDate?.toIso8601String(),
        'otherResultCode': otherResultCode,
        'otherResultDate': otherResultDate?.toIso8601String(),
        'hospitalStartDate': hospitalStartDate?.toIso8601String(),
        'hospitalEndDate': hospitalEndDate?.toIso8601String(),
        'breachCode': breachCode,
        'breachDate': breachDate?.toIso8601String(),
        'mseDirectionDate': mseDirectionDate?.toIso8601String(),
        'mseRegistrationDate': mseRegistrationDate?.toIso8601String(),
        'mseExaminationDate': mseExaminationDate?.toIso8601String(),
        'disabilityGroupCode': disabilityGroupCode,
        'carePersonSnils': carePersonSnils,
        'carePersonName': carePersonName,
        'carePersonBirthDate': carePersonBirthDate?.toIso8601String(),
        'careRelationshipCode': careRelationshipCode,
        'carePeriodStart': carePeriodStart?.toIso8601String(),
        'carePeriodEnd': carePeriodEnd?.toIso8601String(),
        'careDiagnosisCode': careDiagnosisCode,
        'careTreatmentType': careTreatmentType,
        'unconditionalConfirmation': unconditionalConfirmation,
        'writtenAgreementFlag': writtenAgreementFlag,
        'sfrStateCode': sfrStateCode,
        'sfrHash': sfrHash,
        'localStatus': localStatus.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ElnRecord.fromJson(Map<String, dynamic> json) {
    final rawPeriods = json['treatmentPeriods'];
    final periods = rawPeriods is List
        ? rawPeriods
            .whereType<Map>()
            .map((item) => TreatmentPeriod.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <TreatmentPeriod>[];
    final statusName = json['localStatus']?.toString();
    return ElnRecord(
      id: _jsonText(json['id']),
      lnNumber: _jsonText(json['lnNumber']),
      snils: _jsonText(json['snils']),
      surname: _jsonText(json['surname']),
      name: _jsonText(json['name']),
      patronymic: _jsonText(json['patronymic']),
      birthDate: _parseElnDate(json['birthDate']),
      genderCode: _jsonText(json['genderCode'], '0'),
      isPrimary: json['isPrimary'] != false,
      isDuplicate: json['isDuplicate'] == true,
      previousLnNumber: _jsonText(json['previousLnNumber']),
      issueDate: _parseElnDate(json['issueDate']),
      reasonCode: _jsonText(json['reasonCode'], '01'),
      additionalReasonCode: _jsonText(json['additionalReasonCode']),
      icd10Code: _jsonText(json['icd10Code']),
      clinicName: _jsonText(json['clinicName']),
      clinicAddress: _jsonText(json['clinicAddress']),
      clinicOgrn: _jsonText(json['clinicOgrn']),
      clinicId: _jsonText(json['clinicId']),
      openingDoctorName: _jsonText(json['openingDoctorName']),
      treatmentPeriods: periods,
      workStartDate: _parseElnDate(json['workStartDate']),
      otherResultCode: _jsonText(json['otherResultCode']),
      otherResultDate: _parseElnDate(json['otherResultDate']),
      hospitalStartDate: _parseElnDate(json['hospitalStartDate']),
      hospitalEndDate: _parseElnDate(json['hospitalEndDate']),
      breachCode: _jsonText(json['breachCode']),
      breachDate: _parseElnDate(json['breachDate']),
      mseDirectionDate: _parseElnDate(json['mseDirectionDate']),
      mseRegistrationDate: _parseElnDate(json['mseRegistrationDate']),
      mseExaminationDate: _parseElnDate(json['mseExaminationDate']),
      disabilityGroupCode: _jsonText(json['disabilityGroupCode']),
      carePersonSnils: _jsonText(json['carePersonSnils']),
      carePersonName: _jsonText(json['carePersonName']),
      carePersonBirthDate: _parseElnDate(json['carePersonBirthDate']),
      careRelationshipCode: _jsonText(json['careRelationshipCode']),
      carePeriodStart: _parseElnDate(json['carePeriodStart']),
      carePeriodEnd: _parseElnDate(json['carePeriodEnd']),
      careDiagnosisCode: _jsonText(json['careDiagnosisCode']),
      careTreatmentType: _jsonText(json['careTreatmentType']),
      unconditionalConfirmation: json['unconditionalConfirmation'] == true,
      writtenAgreementFlag: json['writtenAgreementFlag'] != false,
      sfrStateCode: _jsonText(json['sfrStateCode']),
      sfrHash: _jsonText(json['sfrHash']),
      localStatus: LocalElnStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => LocalElnStatus.draft,
      ),
      createdAt: _parseElnDate(json['createdAt']),
      updatedAt: _parseElnDate(json['updatedAt']),
    );
  }

  ElnRecord copyWith({
    String? lnNumber,
    String? snils,
    String? surname,
    String? name,
    String? patronymic,
    DateTime? birthDate,
    String? genderCode,
    bool? isPrimary,
    bool? isDuplicate,
    String? previousLnNumber,
    DateTime? issueDate,
    String? reasonCode,
    String? additionalReasonCode,
    String? icd10Code,
    String? clinicName,
    String? clinicAddress,
    String? clinicOgrn,
    String? clinicId,
    String? openingDoctorName,
    List<TreatmentPeriod>? treatmentPeriods,
    DateTime? workStartDate,
    String? otherResultCode,
    DateTime? otherResultDate,
    DateTime? hospitalStartDate,
    DateTime? hospitalEndDate,
    String? breachCode,
    DateTime? breachDate,
    DateTime? mseDirectionDate,
    DateTime? mseRegistrationDate,
    DateTime? mseExaminationDate,
    String? disabilityGroupCode,
    String? carePersonSnils,
    String? carePersonName,
    DateTime? carePersonBirthDate,
    String? careRelationshipCode,
    DateTime? carePeriodStart,
    DateTime? carePeriodEnd,
    String? careDiagnosisCode,
    String? careTreatmentType,
    bool? unconditionalConfirmation,
    bool? writtenAgreementFlag,
    String? sfrStateCode,
    String? sfrHash,
    LocalElnStatus? localStatus,
    DateTime? updatedAt,
  }) {
    return ElnRecord(
      id: id,
      lnNumber: lnNumber ?? this.lnNumber,
      snils: snils ?? this.snils,
      surname: surname ?? this.surname,
      name: name ?? this.name,
      patronymic: patronymic ?? this.patronymic,
      birthDate: birthDate ?? this.birthDate,
      genderCode: genderCode ?? this.genderCode,
      isPrimary: isPrimary ?? this.isPrimary,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      previousLnNumber: previousLnNumber ?? this.previousLnNumber,
      issueDate: issueDate ?? this.issueDate,
      reasonCode: reasonCode ?? this.reasonCode,
      additionalReasonCode: additionalReasonCode ?? this.additionalReasonCode,
      icd10Code: icd10Code ?? this.icd10Code,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      clinicOgrn: clinicOgrn ?? this.clinicOgrn,
      clinicId: clinicId ?? this.clinicId,
      openingDoctorName: openingDoctorName ?? this.openingDoctorName,
      treatmentPeriods: treatmentPeriods ?? this.treatmentPeriods,
      workStartDate: workStartDate ?? this.workStartDate,
      otherResultCode: otherResultCode ?? this.otherResultCode,
      otherResultDate: otherResultDate ?? this.otherResultDate,
      hospitalStartDate: hospitalStartDate ?? this.hospitalStartDate,
      hospitalEndDate: hospitalEndDate ?? this.hospitalEndDate,
      breachCode: breachCode ?? this.breachCode,
      breachDate: breachDate ?? this.breachDate,
      mseDirectionDate: mseDirectionDate ?? this.mseDirectionDate,
      mseRegistrationDate: mseRegistrationDate ?? this.mseRegistrationDate,
      mseExaminationDate: mseExaminationDate ?? this.mseExaminationDate,
      disabilityGroupCode: disabilityGroupCode ?? this.disabilityGroupCode,
      carePersonSnils: carePersonSnils ?? this.carePersonSnils,
      carePersonName: carePersonName ?? this.carePersonName,
      carePersonBirthDate: carePersonBirthDate ?? this.carePersonBirthDate,
      careRelationshipCode: careRelationshipCode ?? this.careRelationshipCode,
      carePeriodStart: carePeriodStart ?? this.carePeriodStart,
      carePeriodEnd: carePeriodEnd ?? this.carePeriodEnd,
      careDiagnosisCode: careDiagnosisCode ?? this.careDiagnosisCode,
      careTreatmentType: careTreatmentType ?? this.careTreatmentType,
      unconditionalConfirmation:
          unconditionalConfirmation ?? this.unconditionalConfirmation,
      writtenAgreementFlag: writtenAgreementFlag ?? this.writtenAgreementFlag,
      sfrStateCode: sfrStateCode ?? this.sfrStateCode,
      sfrHash: sfrHash ?? this.sfrHash,
      localStatus: localStatus ?? this.localStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
