import '../../domain/models/eln_record.dart';

class SfrIntegrationNotReady implements Exception {
  const SfrIntegrationNotReady(this.message);
  final String message;

  @override
  String toString() => message;
}

class SfrOperationResult {
  const SfrOperationResult({
    required this.success,
    required this.message,
    this.requestId,
    this.sfrStatus,
    this.lnNumber,
    this.lnHash,
    this.rawResponse,
  });

  final bool success;
  final String message;
  final String? requestId;
  final String? sfrStatus;
  final String? lnNumber;
  final String? lnHash;
  final String? rawResponse;
}

/// Контракт интеграции по Спецификации ЭЛН МО 2.3.
/// Реализация намеренно не отправляет запросы: сначала подключим и проверим
/// отдельный Windows-мост CryptoPro/GOST TLS и тестовый контур СФР.
abstract class SfrElnGateway {
  Future<String> requestNewLnNumber();
  Future<List<String>> requestNewLnNumberRange(int count);
  Future<SfrOperationResult> submitEln(ElnRecord record);
  Future<ElnRecord?> getLnData({required String lnNumber, required String snils});
  Future<List<ElnRecord>> getLnListBySnils(String snils);
  Future<List<ElnRecord>> getLnListByDate(DateTime issueDate);
  Future<SfrOperationResult> disableLn({
    required String lnNumber,
    required String snils,
    required String reasonCode,
    required String reason,
  });
}

class UnconfiguredSfrElnGateway implements SfrElnGateway {
  const UnconfiguredSfrElnGateway();

  Never _notReady() => throw const SfrIntegrationNotReady(
        'Обмен с СФР не подключён. Отправка заблокирована до настройки CryptoPro, ГОСТ TLS, подписания XML и проверки ответа СФР.',
      );

  @override
  Future<String> requestNewLnNumber() async => _notReady();

  @override
  Future<List<String>> requestNewLnNumberRange(int count) async => _notReady();

  @override
  Future<SfrOperationResult> submitEln(ElnRecord record) async => _notReady();

  @override
  Future<ElnRecord?> getLnData({required String lnNumber, required String snils}) async => _notReady();

  @override
  Future<List<ElnRecord>> getLnListBySnils(String snils) async => _notReady();

  @override
  Future<List<ElnRecord>> getLnListByDate(DateTime issueDate) async => _notReady();

  @override
  Future<SfrOperationResult> disableLn({
    required String lnNumber,
    required String snils,
    required String reasonCode,
    required String reason,
  }) async => _notReady();
}
