import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Run with `--dart-define=scoutProfile=name` to give each scout instance on
/// the same PC its own credentials (all instances share one secure storage).
const String scoutProfile = String.fromEnvironment(
  'scoutProfile',
  defaultValue: 'default',
);

/// Keeps the scout's long-term secret and how far its logs were sent. Access
/// tokens are short-lived and only kept in memory.
class ScoutStorage {
  static const _storage = FlutterSecureStorage();
  static const _secretKey = '${scoutProfile}_scout_secret';
  static const _logCheckpointKey = '${scoutProfile}_scout_log_checkpoint';

  static Future<String?> readSecret() => _storage.read(key: _secretKey);

  static Future<void> writeSecret(String secret) =>
      _storage.write(key: _secretKey, value: secret);

  static Future<void> deleteSecret() => _storage.delete(key: _secretKey);

  /// Up to when this scout's logs were sent successfully.
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
