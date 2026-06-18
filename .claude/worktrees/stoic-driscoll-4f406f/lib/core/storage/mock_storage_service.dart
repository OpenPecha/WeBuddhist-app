import 'package:flutter_pecha/core/storage/storage_service.dart';

/// Mock storage service for testing.
///
/// In-memory implementation that doesn't persist data.
class MockStorageService implements StorageService {
  final Map<String, dynamic> _storage = {};

  @override
  Future<T?> get<T>(String key) async {
    return _storage[key] as T?;
  }

  @override
  Future<bool> set<T>(String key, T value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> delete(String key) async {
    _storage.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _storage.clear();
    return true;
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  /// Get all stored keys (useful for testing).
  List<String> get keys => _storage.keys.toList();

  /// Get all stored values (useful for testing).
  Map<String, dynamic> get all => Map.from(_storage);
}
