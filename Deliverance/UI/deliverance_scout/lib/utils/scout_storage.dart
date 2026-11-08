import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String scoutProfile = String.fromEnvironment(
  'scoutProfile',
  defaultValue: 'default',
);

class ScoutStorage {
  static const _storage = FlutterSecureStorage();
  static const _secretKey = '${scoutProfile}_scout_secret';
  static const _logCheckpointKey = '${scoutProfile}_scout_log_checkpoint';

  static Future<String?> readSecret() => _storage.read(key: _secretKey);

  static Future<void> writeSecret(String secret) =>
      _storage.write(key: _secretKey, value: secret);

  static Future<void> deleteSecret() => _storage.delete(key: _secretKey);

  static Future<DateTime?> readLogCheckpoint() async {
    final value = await _storage.read(key: _logCheckpointKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  static Future<void> deleteLogCheckpoint() =>
      _storage.delete(key: _logCheckpointKey);

  static Future<void> writeLogCheckpoint(DateTime checkpoint) => _storage.write(
    key: _logCheckpointKey,
    value: checkpoint.toUtc().toIso8601String(),
  );
}
