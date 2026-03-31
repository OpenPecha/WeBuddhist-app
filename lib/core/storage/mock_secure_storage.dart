import 'package:flutter_pecha/core/storage/storage_service.dart';

/// Mock secure storage service for testing.
///
/// In-memory implementation that doesn't actually encrypt data.
/// DO NOT use this in production - only for testing.
class MockSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> get(String key) async {
    return _storage[key];
  }

  @override
  Future<void> set(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  @override
  Future<Map<String, String>> getAll() async {
    return Map.from(_storage);
  }

  /// Get all stored keys (useful for testing).
  List<String> get keys => _storage.keys.toList();

  /// Get all stored values (useful for testing).
  Map<String, String> get all => Map.from(_storage);
}
