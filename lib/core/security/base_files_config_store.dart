import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;

import '../config/db_connection_settings.dart';

/// Stores all application-side settings in BaseFiles/ELN as authenticated
/// AES-256-GCM ciphertext. The encryption key and root-path pointer are kept
/// in the OS-protected credential store, not beside the encrypted file.
class BaseFilesConfigStore {
  BaseFilesConfigStore({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _basePathKey = 'clinic_eln.base_files_path.v1';
  static const String _masterKey = 'clinic_eln.settings_aes256_key.v1';
  static const String _profileIdKey = 'clinic_eln.settings_profile_id.v1';
  static const String _aadText = 'clinic-eln|database-settings|version=1';
  static const String legacyConfigFileName = 'settings.v1.enc';

  final FlutterSecureStorage _secureStorage;
  final AesGcm _cipher = AesGcm.with256bits();

  Future<String?> readSavedBaseFilesRoot() => _secureStorage.read(key: _basePathKey);

  Future<void> saveBaseFilesRoot(String root) =>
      _secureStorage.write(key: _basePathKey, value: p.normalize(root));

  String configDirectory(String baseFilesRoot) => p.join(baseFilesRoot, 'ELN');
  /// Each Windows profile gets a distinct encrypted file name. This allows a
  /// shared BaseFiles folder to be used by multiple workstations/users without
  /// making one user's OS-protected AES key capable of decrypting another's file.
  Future<String> configFilePath(String baseFilesRoot) async {
    final directory = configDirectory(baseFilesRoot);
    final profileId = await _readProfileId();
    if (profileId == null) return p.join(directory, legacyConfigFileName);
    final profilePath = p.join(directory, 'settings.$profileId.v1.enc');
    // If an older single-file configuration is still being used, show its path
    // until settings are next saved and migrated to this profile's file.
    final legacyPath = p.join(directory, legacyConfigFileName);
    if (!await File(profilePath).exists() && await File(legacyPath).exists()) {
      return legacyPath;
    }
    return profilePath;
  }

  Future<DbConnectionSettings?> loadSettings(String baseFilesRoot) async {
    final profileId = await _readProfileId();
    final profileFile = profileId == null
        ? null
        : File(p.join(configDirectory(baseFilesRoot), 'settings.$profileId.v1.enc'));
    if (profileFile != null && await profileFile.exists()) {
      return _decryptSettingsFile(profileFile);
    }

    // Read settings created by the earlier single-file development build.
    final legacyFile = File(p.join(configDirectory(baseFilesRoot), legacyConfigFileName));
    if (await legacyFile.exists()) return _decryptSettingsFile(legacyFile);
    return null;
  }

  Future<DbConnectionSettings> _decryptSettingsFile(File file) async {
    final envelopeText = await file.readAsString();
    final envelope = jsonDecode(envelopeText) as Map<String, dynamic>;
    if (envelope['version'] != 1 || envelope['algorithm'] != 'AES-256-GCM') {
      throw const ConfigStoreException(
        'Формат зашифрованных настроек неизвестен или не поддерживается.',
      );
    }

    final key = await _readKey(createIfMissing: false);
    if (key == null) {
      throw const ConfigStoreException(
        'Ключ шифрования не найден в защищённом хранилище Windows. Настройки не будут перезаписаны.',
      );
    }

    try {
      final box = SecretBox(
        base64Decode(envelope['ciphertext'] as String),
        nonce: base64Decode(envelope['nonce'] as String),
        mac: Mac(base64Decode(envelope['mac'] as String)),
      );
      final clearBytes = await _cipher.decrypt(
        box,
        secretKey: SecretKey(key),
        aad: utf8.encode(_aadText),
      );
      final json = jsonDecode(utf8.decode(clearBytes)) as Map<String, dynamic>;
      return DbConnectionSettings.fromJson(json);
    } on SecretBoxAuthenticationError {
      throw const ConfigStoreException(
        'Не удалось проверить целостность настроек. Файл повреждён или ключ не соответствует.',
      );
    } on FormatException {
      throw const ConfigStoreException('Файл настроек повреждён и не может быть прочитан.');
    }
  }

  Future<void> saveSettings(String baseFilesRoot, DbConnectionSettings settings) async {
    final directory = Directory(configDirectory(baseFilesRoot));
    await directory.create(recursive: true);

    final profileId = await _readProfileId(createIfMissing: true);
    final target = File(p.join(directory.path, 'settings.$profileId.v1.enc'));
    final key = await _readKey(createIfMissing: !await target.exists());
    if (key == null) {
      throw const ConfigStoreException(
        'Нельзя перезаписать существующий файл настроек: ключ шифрования отсутствует в системном хранилище. Сохрани резервную копию файла и проверь учётную запись Windows.',
      );
    }

    final clearText = utf8.encode(jsonEncode(settings.toJson()));
    final box = await _cipher.encrypt(
      clearText,
      secretKey: SecretKey(key),
      aad: utf8.encode(_aadText),
    );
    final envelope = <String, dynamic>{
      'version': 1,
      'algorithm': 'AES-256-GCM',
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };

    // Even the temporary file contains ciphertext only.
    final temp = File('${target.path}.new');
    final backup = File('${target.path}.bak');
    await temp.writeAsString(jsonEncode(envelope), flush: true);
    if (await backup.exists()) await backup.delete();
    if (await target.exists()) await target.rename(backup.path);
    try {
      await temp.rename(target.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (!await target.exists() && await backup.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
  }

  Future<String?> _readProfileId({bool createIfMissing = false}) async {
    final saved = await _secureStorage.read(key: _profileIdKey);
    if (saved != null && RegExp(r'^[a-f0-9]{32}$').hasMatch(saved)) return saved;
    if (saved != null) {
      throw const ConfigStoreException('Идентификатор профиля настроек повреждён.');
    }
    if (!createIfMissing) return null;
    final random = Random.secure();
    final id = List<int>.generate(16, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    await _secureStorage.write(key: _profileIdKey, value: id);
    return id;
  }

  Future<List<int>?> _readKey({required bool createIfMissing}) async {
    final encoded = await _secureStorage.read(key: _masterKey);
    if (encoded != null) {
      try {
        final key = base64Decode(encoded);
        if (key.length == 32) return key;
      } catch (_) {
        throw const ConfigStoreException('Ключ шифрования в системном хранилище повреждён.');
      }
      throw const ConfigStoreException('Некорректная длина ключа шифрования.');
    }
    if (!createIfMissing) return null;

    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(256));
    await _secureStorage.write(key: _masterKey, value: base64Encode(key));
    return key;
  }
}

class ConfigStoreException implements Exception {
  const ConfigStoreException(this.message);
  final String message;
  @override
  String toString() => message;
}
