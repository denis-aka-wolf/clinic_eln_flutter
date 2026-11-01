import '../../domain/models/mchd_record.dart';

/// Контракт будущей интеграции с модулем управления доверенностями СФР.
/// МЧД взаимодействует с отдельным сервисом СЭДО, а не с WSDL создания ЭЛН.
abstract class SfrMchdGateway {
  Future<List<MchdAuthority>> getAuthorityClassifier();
  Future<MchdSubmissionResult> submitForRegistration(MchdRecord record);
  Future<MchdRemoteStatus> getStatus(String mchdId);
  Future<MchdSubmissionResult> requestRevocation(String mchdId, String reason);
}

class MchdSubmissionResult {
  const MchdSubmissionResult({
    required this.accepted,
    this.remoteId = '',
    this.message = '',
  });

  final bool accepted;
  final String remoteId;
  final String message;
}

class MchdRemoteStatus {
  const MchdRemoteStatus({
    required this.status,
    this.registryId = '',
    this.message = '',
  });

  final MchdStatus status;
  final String registryId;
  final String message;
}

/// Безопасная заглушка: вместо фиктивного запроса явно сообщает, что интеграция
/// ещё не подключена. Это не позволяет принять локальное состояние за статус СФР.
class UnavailableSfrMchdGateway implements SfrMchdGateway {
  const UnavailableSfrMchdGateway();

  Never _notConnected() => throw StateError(
        'Интеграция МЧД с СФР ещё не подключена. Операция не отправлялась.',
      );

  @override
  Future<List<MchdAuthority>> getAuthorityClassifier() async => _notConnected();

  @override
  Future<MchdSubmissionResult> submitForRegistration(MchdRecord record) async => _notConnected();

  @override
  Future<MchdRemoteStatus> getStatus(String mchdId) async => _notConnected();

  @override
  Future<MchdSubmissionResult> requestRevocation(String mchdId, String reason) async => _notConnected();
}
