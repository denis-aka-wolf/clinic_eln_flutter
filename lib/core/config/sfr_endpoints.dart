class SfrEndpoints {
  SfrEndpoints._();

  /// Официальная страница разработчика публикует именно этот WSDL
  /// для медицинских организаций. Это адрес описания сервиса, а не
  /// доказательство готовности транспортного канала в данном приложении.
  static const medicalOrganizationWsdl =
      'https://eln.sfr.gov.ru/ws-mo-crypto/FileOperationsLnService?wsdl';

  /// Официальный сервис МО с подписанием/шифрованием.
  /// Транспортный endpoint будет подтверждён из актуального WSDL при реализации адаптера.
  static const medicalOrganizationService =
      'https://eln.sfr.gov.ru/ws-mo-crypto/FileOperationsLnService';

  /// Официальный WSDL СФР для сервиса СЭДО, используемого в том числе
  /// для управления МЧД. Это URL описания сервиса, не готовый SOAP-клиент.
  static const mchdWsdl =
      'https://ecp.sfr.gov.ru/sedo/soap/SedoGateway?wsdl';

  /// Не задаём тестовый адрес МЧД без подтверждения по актуальной инструкции.
  static const mchdTestWsdl = '';

  /// Не задаём тестовый адрес ЭЛН по догадке. Его следует брать из действующей
  /// тестовой спецификации/инструкции СФР, когда будет подключаться тестовый контур.
  static const testService = '';
}
