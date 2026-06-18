import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';

/// Secure storage implementation using FlutterSecureStorage.
///
/// Provides secure key-value storage for sensitive data like tokens.
/// On iOS, uses Keychain with proper accessibility settings.
/// On Android, uses encrypted SharedPreferences.
class SecureStorageImpl implements SecureStorage {
  SecureStorageImpl() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> get(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      // Return null on error instead of throwing
      return null;
    }
  }

  @override
  Future<void> set(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> clear() async {
    await _storage.deleteAll();
  }

  @override
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  @override
  Future<Map<String, String>> getAll() async {
    return await _storage.readAll();
  }

  /// Delete all keys that match a prefix
  Future<void> deleteByPrefix(String prefix) async {
    final all = await getAll();
    final keysToDelete = all.keys.where((key) => key.startsWith(prefix));
    for (final key in keysToDelete) {
      await delete(key);
    }
  }
}
