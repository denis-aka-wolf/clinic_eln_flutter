/// Локальная модель машиночитаемой доверенности для взаимодействия с СФР.
/// Это модель черновика/карточки. Она не является утверждённым XML-форматом МЧД.
enum MchdStatus {
  draft('Черновик'),
  needsReview('Требует проверки'),
  readyForSignature('Готова к подписанию'),
  signed('Подписана'),
  submitted('Отправлена в СФР'),
  registered('Зарегистрирована в СФР'),
  rejected('Отказано в регистрации'),
  revocationRequested('Запрошен отзыв'),
  revoked('Отозвана'),
  expired('Истёк срок');

  const MchdStatus(this.title);

  final String title;
}

class MchdRecord {
  const MchdRecord({
    required this.id,
    required this.principalName,
    required this.principalInn,
    required this.principalOgrn,
    this.principalKpp = '',
    required this.representativeName,
    this.representativeInn = '',
    this.representativeSnils = '',
    this.number = '',
    required this.issuedAt,
    required this.validFrom,
    required this.validTo,
    this.authorityCodes = '',
    this.authorityDescription = '',
    this.status = MchdStatus.draft,
    this.registryId = '',
    this.rejectionReason = '',
    this.sourceNote = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  /// Номер/идентификатор МЧД, если уже присвоен источником.
  final String number;
  final String principalName;
  final String principalInn;
  final String principalOgrn;
  final String principalKpp;
  final String representativeName;
  final String representativeInn;
  final String representativeSnils;
  final DateTime issuedAt;
  final DateTime validFrom;
  final DateTime validTo;
  /// Коды из актуального классификатора полномочий СФР, разделённые переносами строк.
  final String authorityCodes;
  final String authorityDescription;
  final MchdStatus status;
  final String registryId;
  final String rejectionReason;
  /// Техническая пометка, например «Реквизиты внесены вручную, XML не проверен».
  final String sourceNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'number': number,
        'principalName': principalName,
        'principalInn': principalInn,
        'principalOgrn': principalOgrn,
        'principalKpp': principalKpp,
        'representativeName': representativeName,
        'representativeInn': representativeInn,
        'representativeSnils': representativeSnils,
        'issuedAt': issuedAt.toIso8601String(),
        'validFrom': validFrom.toIso8601String(),
        'validTo': validTo.toIso8601String(),
        'authorityCodes': authorityCodes,
        'authorityDescription': authorityDescription,
        'status': status.name,
        'registryId': registryId,
        'rejectionReason': rejectionReason,
        'sourceNote': sourceNote,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MchdRecord.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) =>
        value == null ? (fallback ?? DateTime.now()) : DateTime.tryParse(value.toString()) ?? (fallback ?? DateTime.now());
    String text(dynamic value) => value == null ? '' : value.toString();
    final statusName = json['status']?.toString();
    return MchdRecord(
      id: text(json['id']),
      number: text(json['number']),
      principalName: text(json['principalName']),
      principalInn: text(json['principalInn']),
      principalOgrn: text(json['principalOgrn']),
      principalKpp: text(json['principalKpp']),
      representativeName: text(json['representativeName']),
      representativeInn: text(json['representativeInn']),
      representativeSnils: text(json['representativeSnils']),
      issuedAt: parseDate(json['issuedAt']),
      validFrom: parseDate(json['validFrom']),
      validTo: parseDate(json['validTo']),
      authorityCodes: text(json['authorityCodes']),
      authorityDescription: text(json['authorityDescription']),
      status: MchdStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => MchdStatus.draft,
      ),
      registryId: text(json['registryId']),
      rejectionReason: text(json['rejectionReason']),
      sourceNote: text(json['sourceNote']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  bool get isDraft => status == MchdStatus.draft;

  bool get isEffectiveByDate {
    final date = _dateOnly(DateTime.now());
    final from = _dateOnly(validFrom);
    final to = _dateOnly(validTo);
    return !date.isBefore(from) && !date.isAfter(to);
  }

  bool get isExpiredByDate => _dateOnly(validTo).isBefore(_dateOnly(DateTime.now()));

  bool get isUpcomingByDate => _dateOnly(DateTime.now()).isBefore(_dateOnly(validFrom));

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  MchdRecord copyWith({
    String? id,
    String? number,
    String? principalName,
    String? principalInn,
    String? principalOgrn,
    String? principalKpp,
    String? representativeName,
    String? representativeInn,
    String? representativeSnils,
    DateTime? issuedAt,
    DateTime? validFrom,
    DateTime? validTo,
    String? authorityCodes,
    String? authorityDescription,
    MchdStatus? status,
    String? registryId,
    String? rejectionReason,
    String? sourceNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MchdRecord(
      id: id ?? this.id,
      number: number ?? this.number,
      principalName: principalName ?? this.principalName,
      principalInn: principalInn ?? this.principalInn,
      principalOgrn: principalOgrn ?? this.principalOgrn,
      principalKpp: principalKpp ?? this.principalKpp,
      representativeName: representativeName ?? this.representativeName,
      representativeInn: representativeInn ?? this.representativeInn,
      representativeSnils: representativeSnils ?? this.representativeSnils,
      issuedAt: issuedAt ?? this.issuedAt,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      authorityCodes: authorityCodes ?? this.authorityCodes,
      authorityDescription: authorityDescription ?? this.authorityDescription,
      status: status ?? this.status,
      registryId: registryId ?? this.registryId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      sourceNote: sourceNote ?? this.sourceNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MchdAuditEntry {
  const MchdAuditEntry({
    required this.at,
    required this.action,
    required this.result,
    required this.details,
  });

  final DateTime at;
  final String action;
  final String result;
  final String details;
}


/// Элемент официального классификатора полномочий СФР.
/// Код и текст должны загружаться из актуального классификатора, а не быть
/// захардкожены в интерфейсе.
class MchdAuthority {
  const MchdAuthority({
    required this.code,
    required this.name,
    this.description = '',
    this.activeFrom,
    this.activeTo,
  });

  final String code;
  final String name;
  final String description;
  final DateTime? activeFrom;
  final DateTime? activeTo;
}
